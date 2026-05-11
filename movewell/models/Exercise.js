const mongoose = require("mongoose");

const exerciseSchema = new mongoose.Schema({
  name: { type: String, required: true },
  description: { type: String, required: true },
  category: { type: String, enum: ["strength", "flexibility", "balance", "cardio", "stretching"], required: true },
  injuryType: { type: String, required: true },
  difficulty: { type: String, enum: ["beginner", "intermediate", "advanced"], default: "beginner" },
  duration: { type: Number, default: 5 },
  videoUrl: { type: String, default: "" },
  imageUrl: { type: String, default: "" },
  instructions: { type: [String], default: [] },
  createdAt: { type: Date, default: Date.now }
});

module.exports = mongoose.model("Exercise", exerciseSchema);