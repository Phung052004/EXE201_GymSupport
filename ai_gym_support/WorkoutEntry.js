import mongoose from "mongoose";

const WorkoutEntryExerciseSchema = new mongoose.Schema({
  exerciseId: { type: String, required: true },
  name: { type: String, required: true },
  muscleGroup: { type: String, required: true },
  sets: { type: String, required: true },
  reps: { type: String, required: true },
});

const WorkoutEntrySchema = new mongoose.Schema({
  userId: { type: String, required: true, index: true },
  date: { type: String, required: true },
  status: { type: String, default: "draft" },
  exercises: [WorkoutEntryExerciseSchema],
  startedAt: { type: Date, default: Date.now },
  updatedAt: { type: Date, default: Date.now },
  completedAt: { type: Date },
});

WorkoutEntrySchema.index({ userId: 1, date: 1 }, { unique: true });

export const WorkoutEntry = mongoose.model("WorkoutEntry", WorkoutEntrySchema);
