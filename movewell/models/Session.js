const mongoose = require("mongoose");

const sessionSchema = new mongoose.Schema({
  patientId: { type: mongoose.Schema.Types.ObjectId, ref: "User", required: true },
  doctorId: { type: mongoose.Schema.Types.ObjectId, ref: "User", required: true },
  sessionDate: { type: Date, required: true },
  duration: { type: Number, default: 30 },
  notes: { type: String, default: "" },
  summary: { type: String, default: "" },
  recommendations: { type: String, default: "" },
  status: { type: String, enum: ["scheduled", "completed", "cancelled"], default: "scheduled" },
  createdAt: { type: Date, default: Date.now }
});

module.exports = mongoose.model("Session", sessionSchema);