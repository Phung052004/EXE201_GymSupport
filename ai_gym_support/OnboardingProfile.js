import mongoose from "mongoose";

const OnboardingProfileSchema = new mongoose.Schema({
  email: {
    type: String,
    required: true,
    unique: true,
    lowercase: true,
    trim: true,
  },
  name: { type: String, required: true, trim: true },
  gender: { type: String, required: true, trim: true },
  age: { type: String, default: "" },
  weight: { type: String, required: true },
  height: { type: String, required: true },
  bmi: { type: String, required: true },
  goal: { type: String, required: true },
  schedule: { type: String, required: true },
  createdAt: { type: Date, default: Date.now },
});

export const OnboardingProfile = mongoose.model(
  "OnboardingProfile",
  OnboardingProfileSchema,
);
