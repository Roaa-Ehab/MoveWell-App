
const mongoose = require("mongoose");

const planSchema = new mongoose.Schema({
  patientId: { type: mongoose.Schema.Types.ObjectId, ref: "User", required: true },
  doctorId: { type: mongoose.Schema.Types.ObjectId, ref: "User", required: true },
  name: { type: String, required: true },
  description: { type: String, default: "" },
  exercises: [{
    exerciseId: { type: mongoose.Schema.Types.ObjectId, ref: "Exercise", required: true },
    sets: { type: Number, default: 3 },
    reps: { type: Number, default: 10 },
    duration: { type: Number, default: 0 },
    notes: { type: String, default: "" }
  }],
  status: { type: String, enum: ["active", "completed", "cancelled"], default: "active" },
  startDate: { type: Date, default: Date.now },
  endDate: { type: Date, default: null },
  createdAt: { type: Date, default: Date.now }
});

module.exports = mongoose.model("Plan", planSchema);