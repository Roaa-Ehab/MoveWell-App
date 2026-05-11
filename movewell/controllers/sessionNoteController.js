
const SessionNote = require("../models/SessionNote");

const saveSessionNote = async (req, res) => {
  try {
    const { patientId, notes, summary, recommendations } = req.body;
    
    const sessionNote = await SessionNote.create({
      patientId,
      doctorId: req.user._id,
      notes: notes || "",
      summary: summary || "",
      recommendations: recommendations || "",
    });
    
    res.status(201).json(sessionNote);
  } catch (error) {
    console.error(error);
    res.status(500).json({ message: "Server error" });
  }
};

const getSessionNotesByPatient = async (req, res) => {
  try {
    const { patientId } = req.params;
    
    if (req.user.role === "patient" && req.user._id.toString() !== patientId) {
      return res.status(403).json({ message: "Not authorized" });
    }
    
    const notes = await SessionNote.find({ patientId }).populate("doctorId", "name email").sort({ createdAt: -1 });
    res.json(notes);
  } catch (error) {
    console.error(error);
    res.status(500).json({ message: "Server error" });
  }
};

const getAllSessionNotes = async (req, res) => {
  try {
    if (req.user.role !== "doctor") {
      return res.status(403).json({ message: "Not authorized" });
    }
    
    const notes = await SessionNote.find({}).populate("patientId", "name").populate("doctorId", "name").sort({ createdAt: -1 });
    res.json(notes);
  } catch (error) {
    console.error(error);
    res.status(500).json({ message: "Server error" });
  }
};

module.exports = { saveSessionNote, getSessionNotesByPatient, getAllSessionNotes };