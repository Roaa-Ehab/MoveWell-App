// FILE: models/WeeklyFollowup.js
const mongoose = require("mongoose");

const weeklyFollowupSchema = new mongoose.Schema({
  patientId: { type: mongoose.Schema.Types.ObjectId, ref: "User", required: true },
  weekNumber: { type: Number, required: true },
  painLevel: { type: Number, min: 1, max: 10, required: true },
  improvement: { type: String, enum: ["worse", "same", "better"], required: true },
  notes: { type: String, default: "" },
  createdAt: { type: Date, default: Date.now }
});

module.exports = mongoose.model("WeeklyFollowup", weeklyFollowupSchema);