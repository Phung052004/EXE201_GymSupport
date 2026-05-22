import mongoose from "mongoose";

const ExerciseSchema = new mongoose.Schema({
  name: { type: String, required: true },
  muscle: { type: String, required: true }, // CHEST, LEGS, ARMS...

  // SỬA HAI DÒNG NÀY THÀNH STRING ĐỂ CHỨA ĐƯỢC CHỮ "60 sec" CỦA AI
  sets: { type: String, required: true },
  reps: { type: String, required: true },
});

const DailyPlanSchema = new mongoose.Schema({
  day: { type: String, required: true },
  exercises: [ExerciseSchema],
});

const WorkoutPlanSchema = new mongoose.Schema({
  userId: { type: String, default: "alex_test_id" },
  createdAt: { type: Date, default: Date.now },
  nutrition: {
    calories: { type: Number, required: true },
    protein: { type: String, required: true },
    carbs: { type: String, required: true },
    fat: { type: String, required: true },
  },
  workoutPlan: [DailyPlanSchema],
});

export const Workout = mongoose.model("Workout", WorkoutPlanSchema);
