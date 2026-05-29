import mongoose from "mongoose";

const WorkoutSessionSchema = new mongoose.Schema({
  userId: { type: String, required: true, index: true },
  date: { type: String, required: true },
  completedAt: { type: Date, default: Date.now },
});

WorkoutSessionSchema.index({ userId: 1, date: 1 }, { unique: true });

export const WorkoutSession = mongoose.model(
  "WorkoutSession",
  WorkoutSessionSchema,
);
