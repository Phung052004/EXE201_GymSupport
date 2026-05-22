import mongoose from "mongoose";

const ScanHistorySchema = new mongoose.Schema({
  userId: { type: String, default: "alex_test_id" }, // Định danh để biết máy này do ai quét
  equipmentName: { type: String, required: true }, // Tên máy tập
  targetMuscle: { type: String, required: true }, // Nhóm cơ tác động (CHEST, BACK...)
  difficulty: { type: String, required: true }, // Độ khó
  instructions: [{ type: String }], // Mảng các bước hướng dẫn
  commonMistakes: { type: String }, // Lỗi sai thường gặp
  scannedAt: { type: Date, default: Date.now }, // Thời gian quét máy
});

export const ScanHistory = mongoose.model("ScanHistory", ScanHistorySchema);
