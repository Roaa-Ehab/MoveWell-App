const mongoose = require("mongoose");

const patientSchema = new mongoose.Schema({
  userId: { type: mongoose.Schema.Types.ObjectId, ref: "User", required: true, unique: true },
  age: { type: Number, default: null },
  weight: { type: Number, default: null },
  height: { type: Number, default: null },
  injuryType: { type: String, default: "" },
  medicalHistory: { type: String, default: "" },
  bloodType: { type: String, default: "" },
  emergencyContact: { type: String, default: "" },
  files: { type: [String], default: [] },
  status: { type: String, enum: ["pending", "active", "recovered", "needs_attention", "discharged"], default: "pending" },
  medicalNotes: [{
    note: { type: String, required: true },
    date: { type: Date, default: Date.now },
    doctor: { type: String, default: "" },
    type: { type: String, enum: ["Progress", "Assessment", "Discharge"], default: "Progress" }
  }],
  createdAt: { type: Date, default: Date.now }
});

module.exports = mongoose.model("Patient", patientSchema);