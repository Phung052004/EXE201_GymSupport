import express from "express";
import mongoose from "mongoose";
import { GoogleGenAI } from "@google/genai";
import { Workout } from "./Workout.js";
import { ScanHistory } from "./ScanHistory.js";
import { User } from "./User.js"; // 1. IMPORT USER SCHEMA
import { OnboardingProfile } from "./OnboardingProfile.js";
import multer from "multer";
import bcrypt from "bcrypt"; // 2. IMPORT BCRYPT
import jwt from "jsonwebtoken"; // 3. IMPORT JWT
import cors from "cors";
import "dotenv/config";

const app = express();
app.use(cors());
app.use(express.json());

const upload = multer({ storage: multer.memoryStorage() });
const uploadMiddleware = upload.single("image");

const MONGO_URI =
  process.env.MONGO_URI || "mongodb://localhost:27017/gym_support_db";
const JWT_SECRET = process.env.JWT_SECRET || "sieubaomat_gymsupport_2026";

mongoose
  .connect(MONGO_URI)
  .then(() => console.log("🍃 Kết nối thành công đến cơ sở dữ liệu MongoDB!"))
  .catch((err) => console.error("❌ Lỗi kết nối MongoDB:", err));

const ai = new GoogleGenAI({ apiKey: process.env.GEMINI_API_KEY });

function sanitizeJSON(rawText) {
  return rawText
    .replace(/```json\n?/g, "")
    .replace(/```/g, "")
    .trim();
}

app.get("/api/health", (req, res) => {
  res.json({ status: "ok", message: "GymSupport backend is running" });
});

app.post("/api/profiles", async (req, res) => {
  try {
    const { email, name, gender, age, weight, height, bmi, goal, schedule } =
      req.body;

    if (
      !email ||
      !name ||
      !gender ||
      !weight ||
      !height ||
      !bmi ||
      !goal ||
      !schedule
    ) {
      return res.status(400).json({
        status: "error",
        message: "Thiếu dữ liệu hồ sơ onboarding",
      });
    }

    const profile = new OnboardingProfile({
      email,
      name,
      gender,
      age: age || "",
      weight,
      height,
      bmi,
      goal,
      schedule,
    });

    await profile.save();

    return res.status(201).json({
      status: "success",
      message: "Đã lưu hồ sơ người dùng",
      profile,
    });
  } catch (error) {
    console.error("❌ LỖI API PROFILES:", error);
    res.status(500).json({ status: "error", message: error.message });
  }
});

app.get("/api/profiles/:email", async (req, res) => {
  try {
    const email = req.params.email?.toLowerCase();
    const profile = await OnboardingProfile.findOne({ email });

    if (!profile) {
      return res.status(404).json({
        status: "error",
        message: "Chưa có hồ sơ onboarding cho tài khoản này",
      });
    }

    res.json({ status: "success", profile });
  } catch (error) {
    console.error("❌ LỖI API GET PROFILE:", error);
    res.status(500).json({ status: "error", message: error.message });
  }
});

// [GIỮ NGUYÊN CÁC ROUTE CŨ: /, /api/generate-plan, /api/workout-plan/:userId, /api/scan-equipment, /api/scan-history/:userId]

// ====================================================
// TÍNH NĂNG 3: API ĐĂNG KÝ TÀI KHOẢN (REGISTER)
// ====================================================
app.post("/api/auth/register", async (req, res) => {
  try {
    const { email, password, name } = req.body;

    if (!email || !password || !name) {
      return res
        .status(400)
        .json({ status: "error", message: "Vui lòng điền đầy đủ thông tin!" });
    }

    // Kiểm tra xem email đã tồn tại trong DB chưa
    const userExists = await User.findOne({ email });
    if (userExists) {
      return res.status(400).json({
        status: "error",
        message: "Email này đã được đăng ký sử dụng!",
      });
    }

    // Tiến hành băm (mã hóa) mật khẩu để bảo mật dữ liệu khách hàng
    const salt = await bcrypt.genSalt(10);
    const hashedPassword = await bcrypt.hash(password, salt);

    // Lưu user mới vào MongoDB
    const newUser = new User({
      email,
      name,
      password: hashedPassword,
    });
    await newUser.save();

    console.log(`👤 Tài khoản mới được tạo: ${email}`);
    res.json({ status: "success", message: "Đăng ký tài khoản thành công!" });
  } catch (error) {
    console.error("❌ LỖI API REGISTER:", error);
    res.status(500).json({ status: "error", message: error.message });
  }
});

// ====================================================
// TÍNH NĂNG 3.5: API ĐĂNG NHẬP NHẬN TOKEN (LOGIN)
// ====================================================
app.post("/api/auth/login", async (req, res) => {
  try {
    const { email, password } = req.body;

    if (!email || !password) {
      return res
        .status(400)
        .json({ status: "error", message: "Vui lòng nhập Email và Mật khẩu!" });
    }

    // Tìm xem có user nào trùng email không
    const user = await User.findOne({ email });
    if (!user) {
      return res.status(400).json({
        status: "error",
        message: "Tài khoản hoặc mật khẩu không chính xác!",
      });
    }

    // So sánh mật khẩu nhập vào với mật khẩu đã mã hóa trong DB
    const isMatch = await bcrypt.compare(password, user.password);
    if (!isMatch) {
      return res.status(400).json({
        status: "error",
        message: "Tài khoản hoặc mật khẩu không chính xác!",
      });
    }

    // Tạo mã Token JWT (Có giá trị trong 30 ngày) để cấp hộ chiếu cho App Flutter sử dụng
    const token = jwt.sign({ userId: user._id, name: user.name }, JWT_SECRET, {
      expiresIn: "30d",
    });

    console.log(`🔑 ${user.name} đã đăng nhập thành công!`);
    res.json({
      status: "success",
      message: "Đăng nhập thành công!",
      token,
      user: { id: user._id, name: user.name, email: user.email },
    });
  } catch (error) {
    console.error("❌ LỖI API LOGIN:", error);
    res.status(500).json({ status: "error", message: error.message });
  }
});

// ====================================================
// TÍNH NĂNG: TẠO LỊCH TẬP BẰNG AI (Google Gemini)
// ====================================================
app.post("/api/generate-plan", async (req, res) => {
  try {
    const { name, gender, age, weight, height, goal, daysPerWeek } = req.body;

    if (!name || !weight) {
      return res
        .status(400)
        .json({
          status: "error",
          message: "Thiếu dữ liệu cho việc tạo lịch tập",
        });
    }

    console.log(
      `💪 Tạo lịch tập AI cho ${name} (${email || "no-email-provided"})`,
    );

    // Simple BMR/TDEE calc
    let bmr =
      10 * Number(weight) + 6.25 * Number(height) - 5 * Number(age || 30);
    bmr = gender === "Nam" ? bmr + 5 : bmr - 161;
    let tdee = Math.round(bmr * 1.55);
    let targetCalories = tdee;
    if (goal === "Giảm Cân") targetCalories -= 500;
    if (goal === "Tăng Cơ Bắp") targetCalories += 300;

    const prompt = `Bạn là một huấn luyện viên thể hình chuyên nghiệp. Trả về DUY NHẤT JSON với cấu trúc {"nutrition":{...},"workoutPlan":[...]}. Tên: ${name}, Tuổi: ${age}, Giới tính: ${gender}, Cân nặng: ${weight}kg, Chiều cao: ${height}cm, Mục tiêu: ${goal}, Số ngày/tuần: ${daysPerWeek}, Calo mục tiêu: ${targetCalories}`;

    const response = await ai.models.generateContent({
      model: "gemini-1.5-flash",
      contents: prompt,
      config: { responseMimeType: "application/json" },
    });

    const rawText = response.text;
    console.log("-> AI raw:", rawText);
    const clean = sanitizeJSON(rawText);
    const parsed = JSON.parse(clean);

    // Save workout plan to DB (optional)
    try {
      const workout = new Workout({
        userEmail: req.body.email || "unknown",
        workoutPlan: parsed.workoutPlan || [],
        nutrition: parsed.nutrition || {},
      });
      await workout.save();
    } catch (e) {
      console.warn("Không thể lưu workout:", e.message);
    }

    res.json({ status: "success", data: parsed });
  } catch (error) {
    console.error("❌ LỖI AI GENERATE:", error);
    res.status(500).json({ status: "error", message: error.message });
  }
});

// ====================================================
// TÍNH NĂNG: NHẬN ẢNH QUÉT THIẾT BỊ (UPLOAD) và LƯU LỊCH SỬ
// ====================================================
app.post("/api/scan-equipment", uploadMiddleware, async (req, res) => {
  try {
    if (!req.file)
      return res
        .status(400)
        .json({ status: "error", message: "Không tìm thấy file image" });

    // For now we just store the scan history and return a mock detection result.
    const record = new ScanHistory({
      userEmail: req.body.email || "anonymous",
      filename: req.file.originalname || "upload.jpg",
      metadata: { size: req.file.size },
    });
    await record.save();

    // TODO: integrate real vision model. For now return a mock list.
    const detections = [
      { name: "Dumbbell", confidence: 0.92 },
      { name: "Barbell", confidence: 0.35 },
    ];

    res.json({ status: "success", detections, recordId: record._id });
  } catch (error) {
    console.error("❌ LỖI SCAN-EQUIPMENT:", error);
    res.status(500).json({ status: "error", message: error.message });
  }
});

const PORT = 3000;
// Bind to 0.0.0.0 so the server is reachable from other devices on the LAN
app.listen(PORT, "0.0.0.0", () => {
  console.log(`🚀 Server GymSupport đang chạy tại http://0.0.0.0:${PORT}`);
});
