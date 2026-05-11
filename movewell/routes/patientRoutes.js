const express = require("express");
const router = express.Router();
const { 
  getPatientProfile, 
  updatePatientProfile, 
  uploadFile,
  getPatientById
} = require("../controllers/patientController");
const { protect, doctorOnly } = require("../middleware/authMiddleware");
const upload = require("../config/multer");
const Conversation = require("../models/Conversation");
const User = require("../models/User");
const Patient = require("../models/Patient");

router.get("/profile", protect, getPatientProfile);
router.put("/profile", protect, updatePatientProfile);
router.post("/upload", protect, upload.single("file"), uploadFile);

// Get all patients for doctor - from conversations
router.get("/", protect, doctorOnly, async (req, res) => {
  try {
    const conversations = await Conversation.find({
      participants: req.user._id
    }).sort({ updatedAt: -1 });
    
    const patients = [];
    const addedPatientIds = [];
    
    for (const conv of conversations) {
      const patientId = conv.participants.find(p => p.toString() !== req.user._id.toString());
      
      if (patientId && !addedPatientIds.includes(patientId.toString())) {
        addedPatientIds.push(patientId.toString());
        
        const user = await User.findById(patientId).select("-password");
        
        if (user && user.role === "patient") {
          let patientProfile = await Patient.findOne({ userId: user._id });
          
          if (!patientProfile) {
            patientProfile = await Patient.create({
              userId: user._id,
              status: "active",
            });
          }
          
          patients.push({
            _id: patientProfile._id,
            userId: {
              _id: user._id,
              name: user.name,
              email: user.email,
              phone: user.phone,
            },
            age: patientProfile.age || null,
            weight: patientProfile.weight || null,
            height: patientProfile.height || null,
            injuryType: patientProfile.injuryType || "",
            medicalHistory: patientProfile.medicalHistory || "",
            bloodType: patientProfile.bloodType || "",
            emergencyContact: patientProfile.emergencyContact || "",
            status: patientProfile.status || "active",
            files: patientProfile.files || [],
            createdAt: patientProfile.createdAt || user.createdAt,
            lastMessage: conv.lastMessage,
            lastMessageTime: conv.lastMessageTime,
          });
        }
      }
    }
    
    res.json(patients);
  } catch (error) {
    console.error(error);
    res.status(500).json({ message: "Server error" });
  }
});

router.get("/:id", protect, getPatientById);

router.patch("/:id/status", protect, doctorOnly, async (req, res) => {
  try {
    const { status, injuryType } = req.body;
    
    const patient = await Patient.findOneAndUpdate(
      { userId: req.params.id },
      { 
        status: status,
        injuryType: injuryType !== undefined ? injuryType : undefined
      },
      { new: true }
    );
    
    if (!patient) {
      return res.status(404).json({ message: "Patient not found" });
    }
    
    res.json({ message: "Status updated", patient });
  } catch (error) {
    res.status(500).json({ message: "Server error" });
  }
});

router.post("/:id/notes", protect, doctorOnly, async (req, res) => {
  try {
    const { type, content } = req.body;
    
    const doctor = await User.findById(req.user._id);
    const patient = await Patient.findOne({ userId: req.params.id });
    
    if (!patient) {
      return res.status(404).json({ message: "Patient not found" });
    }
    
    patient.medicalNotes = patient.medicalNotes || [];
    patient.medicalNotes.push({
      note: content,
      date: new Date(),
      doctor: doctor?.name || "Doctor",
      type: type,
    });
    await patient.save();
    
    res.json({ message: "Note added", notes: patient.medicalNotes });
  } catch (error) {
    res.status(500).json({ message: "Server error" });
  }
});

module.exports = router;