import mongoose from "mongoose";

const UserSchema = new mongoose.Schema({
  email: {
    type: String,
    required: true,
    unique: true,
    lowercase: true,
    trim: true,
  },
  password: { type: String, required: true },
  name: { type: String, required: false },
  createdAt: { type: Date, default: Date.now },
});

export const User = mongoose.model("User", UserSchema);
