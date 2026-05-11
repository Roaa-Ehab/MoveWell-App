const ClinicalNote = require("../models/ClinicalNote");

// Add a clinical note for a patient
const addClinicalNote = async (req, res) => {
  try {
    const { patientId, type, content } = req.body;
    
    if (!content || content.trim().isEmpty) {
      return res.status(400).json({ message: "Note content is required" });
    }
    
    const note = await ClinicalNote.create({
      patientId,
      doctorId: req.user._id,
      type: type || "Progress",
      content: content.trim(),
    });
    
    res.status(201).json(note);
  } catch (error) {
    console.error(error);
    res.status(500).json({ message: "Server error" });
  }
};

// Get all clinical notes for a patient
const getClinicalNotesByPatient = async (req, res) => {
  try {
    const { patientId } = req.params;
    
    // Check authorization
    if (req.user.role === "patient" && req.user._id.toString() !== patientId) {
      return res.status(403).json({ message: "Not authorized" });
    }
    
    const notes = await ClinicalNote.find({ patientId })
      .populate("doctorId", "name email")
      .sort({ createdAt: -1 });
    
    res.json(notes);
  } catch (error) {
    console.error(error);
    res.status(500).json({ message: "Server error" });
  }
};

// Delete a clinical note
const deleteClinicalNote = async (req, res) => {
  try {
    const note = await ClinicalNote.findById(req.params.id);
    
    if (!note) {
      return res.status(404).json({ message: "Note not found" });
    }
    
    // Only the doctor who created it can delete
    if (note.doctorId.toString() !== req.user._id.toString()) {
      return res.status(403).json({ message: "Not authorized" });
    }
    
    await note.deleteOne();
    res.json({ message: "Note deleted" });
  } catch (error) {
    console.error(error);
    res.status(500).json({ message: "Server error" });
  }
};

module.exports = { addClinicalNote, getClinicalNotesByPatient, deleteClinicalNote };