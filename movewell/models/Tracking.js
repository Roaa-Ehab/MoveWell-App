const mongoose = require("mongoose");

const trackingSchema = new mongoose.Schema({
  patientId: { type: mongoose.Schema.Types.ObjectId, ref: "User", required: true },
  date: { type: Date, default: Date.now },
  painLevel: { type: Number, min: 0, max: 10, required: true },
  progress: { type: Number, min: 0, max: 100, default: 0 },
  mobilityScore: { type: Number, min: 0, max: 100, default: 0 },
  strengthScore: { type: Number, min: 0, max: 100, default: 0 },
  sleepQuality: { type: Number, min: 0, max: 10, default: 0 },
  notes: { type: String, default: "" },
  createdAt: { type: Date, default: Date.now }
});

module.exports = mongoose.model("Tracking", trackingSchema);