import express from "express";
import { GoogleGenAI } from "@google/genai";
import "dotenv/config";

const app = express();
app.use(express.json());

const ai = new GoogleGenAI({ apiKey: process.env.GEMINI_API_KEY });

function sanitizeJSON(rawText) {
  return rawText
    .replace(/```json\n?/g, "")
    .replace(/```/g, "")
    .trim();
}

app.post("/api/generate-plan", async (req, res) => {
  try {
    // 1. IN RA LOG ĐỂ KIỂM TRA DỮ LIỆU ĐẦU VÀO
    console.log("=========================================");
    console.log("📥 Dữ liệu nhận được từ app:", req.body);
    console.log("=========================================");

    const { name, gender, age, weight, height, goal, daysPerWeek } = req.body;

    // 2. CHẶN LỖI: Nếu không nhận được tên hoặc cân nặng, báo lỗi 400 ngay
    if (!name || !weight) {
      return res.status(400).json({
        status: "error",
        message:
          "Server không nhận được dữ liệu! Hãy kiểm tra lại Header Content-Type: application/json",
      });
    }

    console.log(`💪 Đang gọi Gemini tạo lịch tập cho ${name}...`);

    let bmr = 10 * weight + 6.25 * height - 5 * age;
    bmr = gender === "Nam" ? bmr + 5 : bmr - 161;
    let tdee = Math.round(bmr * 1.55);
    let targetCalories = tdee;

    if (goal === "Giảm Cân") targetCalories -= 500;
    if (goal === "Tăng Cơ Bắp") targetCalories += 300;

    const prompt = `
      Bạn là một huấn luyện viên thể hình chuyên nghiệp. Hãy tạo một lịch tập gym chi tiết.
      - Tên: ${name}, ${age} tuổi, ${gender}, Nặng ${weight}kg, Cao ${height}cm.
      - Mục tiêu: ${goal}. Lượng Calo mục tiêu: ${targetCalories} kcal/ngày.
      - Số ngày tập: ${daysPerWeek} ngày/tuần.

      TRẢ VỀ DUY NHẤT ĐỊNH DẠNG JSON. KHÔNG GIẢI THÍCH, KHÔNG CHÀO HỎI. Cấu trúc:
      {
        "nutrition": {
          "calories": ${targetCalories},
          "protein": "150g",
          "carbs": "200g",
          "fat": "60g"
        },
        "workoutPlan": [
          {
            "day": "Ngày 1 - Ngực & Triceps",
            "exercises": [
              { "name": "Barbell Bench Press", "muscle": "CHEST", "sets": 4, "reps": 8 }
            ]
          }
        ]
      }
    `;

    const response = await ai.models.generateContent({
      model: "gemini-1.5-flash",
      contents: prompt,
      config: {
        responseMimeType: "application/json",
      },
    });

    const rawText = response.text;
    console.log("-> AI trả về (Nguyên gốc):", rawText); // Log ra để xem AI có phá bĩnh không

    const cleanText = sanitizeJSON(rawText);
    const aiResult = JSON.parse(cleanText);

    res.json({ status: "success", data: aiResult });
  } catch (error) {
    // 3. LOG LỖI CHI TIẾT RA TERMINAL
    console.error("❌ LỖI RỒI BẠN ƠI:", error);
    res.status(500).json({ status: "error", message: error.message });
  }
});

const PORT = 3000;
app.listen(PORT, () => {
  console.log(`🚀 Server đang chạy tại http://localhost:${PORT}`);
});
