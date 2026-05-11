
const mongoose = require("mongoose");

const sessionNoteSchema = new mongoose.Schema({
  patientId: { type: mongoose.Schema.Types.ObjectId, ref: "User", required: true },
  doctorId: { type: mongoose.Schema.Types.ObjectId, ref: "User", required: true },
  notes: { type: String, default: "" },
  summary: { type: String, default: "" },
  recommendations: { type: String, default: "" },
  createdAt: { type: Date, default: Date.now }
});

module.exports = mongoose.model("SessionNote", sessionNoteSchema);