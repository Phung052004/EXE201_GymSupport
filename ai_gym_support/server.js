import express from "express";
import mongoose from "mongoose";
import { GoogleGenAI } from "@google/genai";
import { Workout } from "./Workout.js";
import { ScanHistory } from "./ScanHistory.js";
import { User } from "./User.js"; // 1. IMPORT USER SCHEMA
import { OnboardingProfile } from "./OnboardingProfile.js";
import { WorkoutSession } from "./WorkoutSession.js";
import { WorkoutEntry } from "./WorkoutEntry.js";
import multer from "multer";
import bcrypt from "bcrypt"; // 2. IMPORT BCRYPT
import jwt from "jsonwebtoken"; // 3. IMPORT JWT
import cors from "cors";
import "dotenv/config";

const app = express();
app.use(cors());
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

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

const EXERCISE_CATALOG = [
  {
    id: "bench_press",
    name: "Barbell Bench Press",
    muscleGroup: "Chest",
    setsAndReps: "4 sets x 8 reps",
  },
  {
    id: "squat",
    name: "Barbell Squat",
    muscleGroup: "Legs",
    setsAndReps: "4 sets x 8 reps",
  },
  {
    id: "deadlift",
    name: "Deadlift",
    muscleGroup: "Back",
    setsAndReps: "3 sets x 5 reps",
  },
  {
    id: "overhead_press",
    name: "Overhead Press",
    muscleGroup: "Shoulders",
    setsAndReps: "4 sets x 10 reps",
  },
  {
    id: "pull_ups",
    name: "Pull-ups",
    muscleGroup: "Back",
    setsAndReps: "3 sets x 10 reps",
  },
  {
    id: "bicep_curls",
    name: "Bicep Curls",
    muscleGroup: "Arms",
    setsAndReps: "3 sets x 12 reps",
  },
  {
    id: "leg_press",
    name: "Leg Press",
    muscleGroup: "Legs",
    setsAndReps: "4 sets x 12 reps",
  },
  {
    id: "incline_dumbbell_press",
    name: "Incline Dumbbell Press",
    muscleGroup: "Chest",
    setsAndReps: "3 sets x 10 reps",
  },
];

function getLatestWorkoutByEmail(email) {
  return Workout.findOne({ userId: email }).sort({ createdAt: -1 }).lean();
}

function toLocalDateKey(date = new Date()) {
  const local = new Date(date.getTime() - date.getTimezoneOffset() * 60000);
  return local.toISOString().slice(0, 10);
}

function pickTodayPlan(workoutPlan) {
  if (!Array.isArray(workoutPlan) || workoutPlan.length === 0) return null;
  const todayIndex = new Date().getDay(); // 0..6
  const selectedIndex = todayIndex % workoutPlan.length;
  return workoutPlan[selectedIndex] || workoutPlan[0];
}

function normalizeSetsAndReps(value) {
  if (!value) return { sets: "3", reps: "10" };
  const raw = value.toString();
  const match = raw.match(/(\d+)\s*sets?\s*x\s*([\d-]+)/i);
  if (match) return { sets: match[1], reps: match[2] };

  const alt = raw.match(/(\d+)x([\d-]+)/i);
  if (alt) return { sets: alt[1], reps: alt[2] };

  return { sets: "3", reps: raw };
}

function normalizeWorkoutPlan(workoutPlan) {
  if (!Array.isArray(workoutPlan)) return [];
  return workoutPlan
    .map((day, index) => {
      if (!day || typeof day !== "object") return null;
      const exercises = Array.isArray(day.exercises) ? day.exercises : [];
      const normalizedExercises = exercises.map((exercise) => {
        const name = exercise.name || "Exercise";
        const muscle = exercise.muscle || exercise.muscleGroup || "Unknown";
        const fromSets = exercise.sets;
        const fromReps = exercise.reps;
        const fromCombined = exercise.setsAndReps || exercise.sets_reps;

        if (fromSets && fromReps) {
          return {
            name,
            muscle,
            sets: fromSets.toString(),
            reps: fromReps.toString(),
          };
        }

        const normalized = normalizeSetsAndReps(fromCombined);
        return {
          name,
          muscle,
          sets: normalized.sets,
          reps: normalized.reps,
        };
      });

      return {
        day: day.day || day.title || `Day ${index + 1}`,
        exercises: normalizedExercises,
      };
    })
    .filter(Boolean);
}

async function calculateStreak(userId) {
  const sessions = await WorkoutSession.find({ userId })
    .sort({ date: -1 })
    .limit(60)
    .lean();

  const completed = new Set(sessions.map((s) => s.date));
  let streak = 0;
  let cursor = new Date();

  while (true) {
    const key = toLocalDateKey(cursor);
    if (!completed.has(key)) break;
    streak += 1;
    cursor = new Date(cursor.getTime() - 24 * 60 * 60 * 1000);
  }

  return streak;
}

app.get("/api/health", (req, res) => {
  res.json({ status: "ok", message: "GymSupport backend is running" });
});

app.get("/api/exercises", (req, res) => {
  const query = (req.query.q || "").toString().trim().toLowerCase();
  const muscle = (req.query.muscle || "").toString().trim().toLowerCase();

  const exercises = EXERCISE_CATALOG.filter((exercise) => {
    const matchesQuery =
      !query ||
      exercise.name.toLowerCase().includes(query) ||
      exercise.muscleGroup.toLowerCase().includes(query);
    const matchesMuscle =
      !muscle || exercise.muscleGroup.toLowerCase() === muscle;
    return matchesQuery && matchesMuscle;
  });

  res.json({ status: "success", exercises });
});

app.get("/api/dashboard/:email", async (req, res) => {
  try {
    const email = req.params.email?.toLowerCase();
    if (!email) {
      return res.status(400).json({ status: "error", message: "Email thiếu" });
    }

    const [profile, latestWorkout, latestScan, workoutCount, scanCount] =
      await Promise.all([
        OnboardingProfile.findOne({ email }).lean(),
        getLatestWorkoutByEmail(email),
        ScanHistory.findOne({ userId: email }).sort({ scannedAt: -1 }).lean(),
        Workout.countDocuments({ userId: email }),
        ScanHistory.countDocuments({ userId: email }),
      ]);

    res.json({
      status: "success",
      dashboard: {
        profile,
        latestWorkout,
        latestScan,
        workoutCount,
        scanCount,
        exerciseCount: EXERCISE_CATALOG.length,
      },
    });
  } catch (error) {
    console.error("❌ LỖI API DASHBOARD:", error);
    res.status(500).json({ status: "error", message: error.message });
  }
});

app.get("/api/home/:email", async (req, res) => {
  try {
    const email = req.params.email?.toLowerCase();
    if (!email) {
      return res.status(400).json({ status: "error", message: "Email thiếu" });
    }

    const [latestWorkout, workoutCount] = await Promise.all([
      getLatestWorkoutByEmail(email),
      Workout.countDocuments({ userId: email }),
    ]);
    const normalizedPlan = normalizeWorkoutPlan(latestWorkout?.workoutPlan);
    const todayPlan = pickTodayPlan(normalizedPlan);
    const streak = await calculateStreak(email);

    res.json({
      status: "success",
      home: {
        streak,
        todayPlan,
        nutrition: latestWorkout?.nutrition || null,
        workoutCount,
        latestWorkout,
      },
    });
  } catch (error) {
    console.error("❌ LỖI API HOME:", error);
    res.status(500).json({ status: "error", message: error.message });
  }
});

app.post("/api/workout/complete", async (req, res) => {
  try {
    const email = req.body.email?.toString().toLowerCase();
    if (!email) {
      return res.status(400).json({ status: "error", message: "Email thiếu" });
    }

    const dateKey = req.body.date || toLocalDateKey();
    const session = await WorkoutSession.findOneAndUpdate(
      { userId: email, date: dateKey },
      { userId: email, date: dateKey, completedAt: new Date() },
      { new: true, upsert: true },
    );

    await WorkoutEntry.findOneAndUpdate(
      { userId: email, date: dateKey },
      { status: "completed", completedAt: new Date(), updatedAt: new Date() },
      { new: true },
    );

    const streak = await calculateStreak(email);

    res.json({
      status: "success",
      session,
      streak,
    });
  } catch (error) {
    console.error("❌ LỖI API WORKOUT COMPLETE:", error);
    res.status(500).json({ status: "error", message: error.message });
  }
});

app.get("/api/workout/session/:email", async (req, res) => {
  try {
    const email = req.params.email?.toLowerCase();
    if (!email) {
      return res.status(400).json({ status: "error", message: "Email thiếu" });
    }

    const dateKey = req.query.date || toLocalDateKey();
    const session = await WorkoutEntry.findOne({
      userId: email,
      date: dateKey,
    }).lean();

    res.json({ status: "success", session });
  } catch (error) {
    console.error("❌ LỖI API WORKOUT SESSION:", error);
    res.status(500).json({ status: "error", message: error.message });
  }
});

app.post("/api/workout/session", async (req, res) => {
  try {
    const email = req.body.email?.toString().toLowerCase();
    const exercises = req.body.exercises;
    if (!email || !Array.isArray(exercises)) {
      return res.status(400).json({
        status: "error",
        message: "Thiếu email hoặc danh sách bài tập",
      });
    }

    const dateKey = req.body.date || toLocalDateKey();
    const normalized = exercises.map((exercise) => {
      const combined = exercise.setsAndReps || exercise.sets_reps;
      const parsed = normalizeSetsAndReps(combined);

      return {
        exerciseId: exercise.exerciseId || exercise.id || exercise.name,
        name: exercise.name || "Exercise",
        muscleGroup: exercise.muscleGroup || exercise.muscle || "Unknown",
        sets: exercise.sets ? exercise.sets.toString() : parsed.sets,
        reps: exercise.reps ? exercise.reps.toString() : parsed.reps,
      };
    });

    const session = await WorkoutEntry.findOneAndUpdate(
      { userId: email, date: dateKey },
      {
        userId: email,
        date: dateKey,
        exercises: normalized,
        status: "draft",
        updatedAt: new Date(),
      },
      { new: true, upsert: true },
    );

    res.json({ status: "success", session });
  } catch (error) {
    console.error("❌ LỖI API WORKOUT SESSION CREATE:", error);
    res.status(500).json({ status: "error", message: error.message });
  }
});

app.put("/api/workout/session/:email/exercise", async (req, res) => {
  try {
    const email = req.params.email?.toLowerCase();
    const { exerciseId, sets, reps } = req.body;
    if (!email || !exerciseId || !sets || !reps) {
      return res.status(400).json({
        status: "error",
        message: "Thiếu dữ liệu bài tập cần cập nhật",
      });
    }

    const dateKey = req.body.date || toLocalDateKey();
    const session = await WorkoutEntry.findOneAndUpdate(
      { userId: email, date: dateKey, "exercises.exerciseId": exerciseId },
      {
        $set: {
          "exercises.$.sets": sets.toString(),
          "exercises.$.reps": reps.toString(),
          updatedAt: new Date(),
        },
      },
      { new: true },
    );

    if (!session) {
      return res.status(404).json({
        status: "error",
        message: "Không tìm thấy bài tập để cập nhật",
      });
    }

    res.json({ status: "success", session });
  } catch (error) {
    console.error("❌ LỖI API WORKOUT UPDATE EXERCISE:", error);
    res.status(500).json({ status: "error", message: error.message });
  }
});

app.get("/api/workout/history/:email", async (req, res) => {
  try {
    const email = req.params.email?.toLowerCase();
    if (!email) {
      return res.status(400).json({ status: "error", message: "Email thiếu" });
    }

    const limit = Number(req.query.limit || 20);
    const history = await WorkoutEntry.find({
      userId: email,
      status: "completed",
    })
      .sort({ date: -1 })
      .limit(limit)
      .lean();

    res.json({ status: "success", history });
  } catch (error) {
    console.error("❌ LỖI API WORKOUT HISTORY:", error);
    res.status(500).json({ status: "error", message: error.message });
  }
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

app.put("/api/profiles/:email", async (req, res) => {
  try {
    const email = req.params.email?.toLowerCase();
    if (!email) {
      return res.status(400).json({ status: "error", message: "Email thiếu" });
    }

    const { goal, schedule } = req.body;
    if (!goal && !schedule) {
      return res.status(400).json({
        status: "error",
        message: "Thiếu dữ liệu cần cập nhật",
      });
    }

    const update = {};
    if (goal) update.goal = goal;
    if (schedule) update.schedule = schedule;

    const profile = await OnboardingProfile.findOneAndUpdate(
      { email },
      update,
      { new: true },
    );

    if (!profile) {
      return res.status(404).json({
        status: "error",
        message: "Không tìm thấy hồ sơ để cập nhật",
      });
    }

    res.json({ status: "success", profile });
  } catch (error) {
    console.error("❌ LỖI API UPDATE PROFILE:", error);
    res.status(500).json({ status: "error", message: error.message });
  }
});

// [GIỮ NGUYÊN CÁC ROUTE CŨ: /, /api/generate-plan, /api/workout-plan/:userId, /api/scan-equipment, /api/scan-history/:userId]

// ====================================================
// TÍNH NĂNG 3: API ĐĂNG KÝ TÀI KHOẢN (REGISTER)
// ====================================================
app.post("/api/auth/register", async (req, res) => {
  try {
    const rawEmail = req.body.email ?? req.body.gmail ?? "";
    const rawPassword = req.body.password ?? req.body.pass ?? "";
    const rawConfirmPassword =
      req.body.confirmPassword ??
      req.body.confirm ??
      req.body.confirm_pass ??
      "";
    const { name } = req.body;

    if (!rawEmail || !rawPassword || !rawConfirmPassword) {
      return res.status(400).json({
        status: "error",
        message: "Vui lòng nhập Email, Mật khẩu, và Xác nhận mật khẩu!",
      });
    }

    if (rawPassword !== rawConfirmPassword) {
      return res.status(400).json({
        status: "error",
        message: "Mật khẩu xác nhận không khớp!",
      });
    }

    const normalizedEmail = rawEmail.toLowerCase();
    const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
    if (!emailRegex.test(normalizedEmail)) {
      return res
        .status(400)
        .json({ status: "error", message: "Email không hợp lệ!" });
    }

    // Kiểm tra xem email đã tồn tại trong DB chưa
    const userExists = await User.findOne({ email: normalizedEmail });
    if (userExists) {
      return res.status(400).json({
        status: "error",
        message: "Email này đã được đăng ký sử dụng!",
      });
    }

    // Tiến hành băm (mã hóa) mật khẩu để bảo mật dữ liệu khách hàng
    const salt = await bcrypt.genSalt(10);
    const hashedPassword = await bcrypt.hash(rawPassword, salt);

    // Lưu user mới vào MongoDB
    const newUser = new User({
      email: normalizedEmail,
      name: name || normalizedEmail.split("@")[0],
      password: hashedPassword,
    });
    await newUser.save();

    console.log(`👤 Tài khoản mới được tạo: ${normalizedEmail}`);
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
    const rawEmail = req.body.email ?? req.body.gmail ?? "";
    const rawPassword = req.body.password ?? req.body.pass ?? "";

    if (!rawEmail || !rawPassword) {
      return res
        .status(400)
        .json({ status: "error", message: "Vui lòng nhập Email và Mật khẩu!" });
    }

    // Tìm xem có user nào trùng email không
    const normalizedEmail = rawEmail.toLowerCase();
    const user = await User.findOne({ email: normalizedEmail });
    if (!user) {
      return res.status(400).json({
        status: "error",
        message: "Tài khoản hoặc mật khẩu không chính xác!",
      });
    }

    // So sánh mật khẩu nhập vào với mật khẩu đã mã hóa trong DB
    const isMatch = await bcrypt.compare(rawPassword, user.password);
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
    const email = req.body.email || "";

    if (!name || !weight) {
      return res.status(400).json({
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
      model: "gemini-3.5-flash",
      contents: prompt,
      config: { responseMimeType: "application/json" },
    });

    const rawText = response.text;
    console.log("-> AI raw:", rawText);
    const clean = sanitizeJSON(rawText);
    const parsed = JSON.parse(clean);

    // Save workout plan to DB (optional) - use user email as userId
    try {
      const normalizedPlan = normalizeWorkoutPlan(parsed.workoutPlan || []);
      const workout = new Workout({
        userId: req.body.email || "unknown",
        workoutPlan: normalizedPlan,
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

    console.log("🔍 /api/scan-equipment request received", {
      email: req.body.email || null,
      filename: req.file.originalname,
      size: req.file.size,
    });

    const apiKey = process.env.GOOGLE_VISION_API_KEY;
    let detections = [];

    if (apiKey) {
      const base64 = req.file.buffer.toString("base64");
      const visionUrl = `https://vision.googleapis.com/v1/images:annotate?key=${apiKey}`;
      const body = {
        requests: [
          {
            image: { content: base64 },
            features: [
              { type: "LABEL_DETECTION", maxResults: 10 },
              { type: "OBJECT_LOCALIZATION", maxResults: 10 },
            ],
          },
        ],
      };

      const resp = await fetch(visionUrl, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify(body),
      });

      if (resp.ok) {
        const j = await resp.json();
        const annotations = j.responses?.[0];
        const labels = annotations?.labelAnnotations || [];
        const objects = annotations?.localizedObjectAnnotations || [];

        detections = [
          ...labels.map((l) => ({ name: l.description, confidence: l.score })),
          ...objects.map((o) => ({ name: o.name, confidence: o.score })),
        ];

        console.log("🔎 Vision API returned", {
          labels: labels.length,
          objects: objects.length,
        });
      } else {
        console.warn("Vision API failed:", resp.status, resp.statusText);
      }
    }

    if (detections.length === 0) {
      detections = [
        { name: "Dumbbell", confidence: 0.92 },
        { name: "Barbell", confidence: 0.35 },
      ];
    }

    const top = detections[0];
    const equipmentName = top?.name || req.file.originalname || "unknown";

    const fallbackMap = {
      dumbbell: {
        targetMuscle: "Biceps/Forearms",
        instructions: [
          "Giữ lưng thẳng và siết cơ bụng.",
          "Thực hiện động tác chậm, kiểm soát tạ.",
          "Mỗi hiệp 8-12 lần, 3 hiệp.",
        ],
        commonMistakes: "Không đung đưa người và không khóa khớp khuỷu tay.",
      },
      barbell: {
        targetMuscle: "Chest/Back/Legs",
        instructions: [
          "Kiểm tra khóa tạ trước khi tập.",
          "Giữ cổ tay trung tính và lưng ổn định.",
          "Mỗi hiệp 8-10 lần, 3 hiệp.",
        ],
        commonMistakes: "Không cong lưng quá mức và không thả tạ đột ngột.",
      },
      treadmill: {
        targetMuscle: "Cardio",
        instructions: [
          "Bắt đầu với tốc độ thấp rồi tăng dần.",
          "Giữ tư thế đứng thẳng và nhìn về phía trước.",
        ],
        commonMistakes:
          "Không bám tay vịn liên tục và không tăng tốc quá nhanh.",
      },
    };

    let enriched = {
      targetMuscle: "UNKNOWN",
      difficulty: "Medium",
      instructions: [],
      commonMistakes: "",
    };

    const geminiKey = process.env.GEMINI_API_KEY;
    if (geminiKey) {
      try {
        const detectedNames = detections.map((d) => d.name).join(", ");
        const prompt = `Bạn là chuyên gia huấn luyện. Dựa trên các đối tượng phát hiện: ${detectedNames}. Trả về DUY NHẤT JSON với các trường: {"targetMuscle":"...","difficulty":"...","instructions":["step1","step2"],"commonMistakes":"..."}. Viết ngắn gọn, tiếng Việt.`;

        const aiResp = await ai.models.generateContent({
          model: "gemini-3.5-flash",
          contents: prompt,
          config: { responseMimeType: "application/json" },
        });

        const clean = sanitizeJSON(aiResp.text || "");
        const parsed = JSON.parse(clean);
        enriched.targetMuscle = parsed.targetMuscle || enriched.targetMuscle;
        enriched.difficulty = parsed.difficulty || enriched.difficulty;
        enriched.instructions = parsed.instructions || enriched.instructions;
        enriched.commonMistakes =
          parsed.commonMistakes || enriched.commonMistakes;
        console.log("🤖 Gemini enrichment result", parsed);
      } catch (error) {
        console.warn("Gemini enrichment failed:", error.message);
      }
    }

    if (enriched.targetMuscle === "UNKNOWN") {
      const mapped = fallbackMap[equipmentName.toLowerCase()];
      if (mapped) {
        enriched.targetMuscle = mapped.targetMuscle;
        enriched.instructions = mapped.instructions;
        enriched.commonMistakes = mapped.commonMistakes;
      } else if (enriched.instructions.length === 0) {
        enriched.instructions = [
          `Sử dụng ${equipmentName} theo tư thế an toàn. Thực hiện 3 hiệp x 8-12 lần.`,
        ];
      }
    }

    console.log("✅ Enriched scan result", enriched);

    const record = new ScanHistory({
      userId: req.body.email || "anonymous",
      equipmentName,
      targetMuscle: enriched.targetMuscle,
      difficulty: enriched.difficulty,
      instructions: enriched.instructions,
      commonMistakes: enriched.commonMistakes,
    });
    await record.save();

    res.json({ status: "success", detections, recordId: record._id, enriched });
  } catch (error) {
    console.error("❌ LỖI SCAN-EQUIPMENT:", error);
    res.status(500).json({ status: "error", message: error.message });
  }
});

app.post("/api/ai/chat", async (req, res) => {
  try {
    const { email, message } = req.body;
    if (!message) {
      return res
        .status(400)
        .json({ status: "error", message: "Thiếu nội dung chat" });
    }

    const profile = email
      ? await OnboardingProfile.findOne({ email: email.toLowerCase() }).lean()
      : null;
    const latestWorkout = email
      ? await getLatestWorkoutByEmail(email.toLowerCase())
      : null;

    const profileContext = profile
      ? `Hồ sơ: tên=${profile.name}, giới tính=${profile.gender}, tuổi=${profile.age}, cân nặng=${profile.weight}, chiều cao=${profile.height}, BMI=${profile.bmi}, mục tiêu=${profile.goal}, lịch=${profile.schedule}`
      : "Không có hồ sơ người dùng.";
    const workoutContext = latestWorkout
      ? `Lịch tập gần nhất: ${JSON.stringify(latestWorkout.workoutPlan || [])}`
      : "Chưa có lịch tập gần nhất.";

    if (process.env.GEMINI_API_KEY) {
      const prompt = `Bạn là AI coach cho ứng dụng GymSupport. Trả lời ngắn gọn, hữu ích, tiếng Việt, chỉ trả về JSON với dạng {"reply":"..."}. ${profileContext} ${workoutContext} Câu hỏi người dùng: ${message}`;
      const aiResp = await ai.models.generateContent({
        model: "gemini-3.5-flash",
        contents: prompt,
        config: { responseMimeType: "application/json" },
      });

      const clean = sanitizeJSON(aiResp.text || "");
      const parsed = JSON.parse(clean);
      return res.json({
        status: "success",
        reply: parsed.reply || "Mình có thể giúp gì thêm?",
      });
    }

    return res.json({
      status: "success",
      reply: `Mình đã nhận câu hỏi: "${message}". Hiện backend chưa có Gemini key nên tạm phản hồi mẫu.`,
    });
  } catch (error) {
    console.error("❌ LỖI API AI CHAT:", error);
    res.status(500).json({ status: "error", message: error.message });
  }
});

const PORT = Number(process.env.PORT || 3000);
// Bind to 0.0.0.0 so the server is reachable from other devices on the LAN
app.listen(PORT, "0.0.0.0", () => {
  console.log(`🚀 Server GymSupport đang chạy tại http://0.0.0.0:${PORT}`);
});

// ====================================================
// Lấy workout plan mới nhất theo email
// ====================================================
app.get("/api/workout-plan/:email", async (req, res) => {
  try {
    const email = req.params.email?.toString();
    if (!email)
      return res.status(400).json({ status: "error", message: "Email thiếu" });

    const workout = await Workout.findOne({ userId: email })
      .sort({ createdAt: -1 })
      .lean();
    if (!workout)
      return res
        .status(404)
        .json({ status: "error", message: "Không tìm thấy lịch tập" });

    res.json({ status: "success", data: workout });
  } catch (error) {
    console.error("❌ LỖI GET WORKOUT:", error);
    res.status(500).json({ status: "error", message: error.message });
  }
});
