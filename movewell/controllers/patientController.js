const Patient = require("../models/Patient");
const User = require("../models/User");
const Conversation = require("../models/Conversation");

const getPatientProfile = async (req, res) => {
  try {
    let profile = await Patient.findOne({ userId: req.user._id }).populate("userId", "name email phone");
    
    if (!profile) {
      profile = await Patient.create({
        userId: req.user._id,
      });
    }
    
    res.json(profile);
  } catch (error) {
    console.error(error);
    res.status(500).json({ message: "Server error" });
  }
};

const updatePatientProfile = async (req, res) => {
  try {
    const { 
      age, weight, height, injuryType, medicalHistory, 
      name, email, phone, bloodType, emergencyContact 
    } = req.body;
    
    // Update user info
    if (name || email || phone) {
      const user = await User.findById(req.user._id);
      if (name) user.name = name;
      if (email) user.email = email;
      if (phone) user.phone = phone;
      await user.save();
    }

    // Update or create patient profile
    let profile = await Patient.findOne({ userId: req.user._id });

    if (!profile) {
      profile = await Patient.create({
        userId: req.user._id,
        age: age || null,
        weight: weight || null,
        height: height || null,
        injuryType: injuryType || "",
        medicalHistory: medicalHistory || "",
        bloodType: bloodType || "",
        emergencyContact: emergencyContact || "",
      });
    } else {
      if (age !== undefined) profile.age = age;
      if (weight !== undefined) profile.weight = weight;
      if (height !== undefined) profile.height = height;
      if (injuryType !== undefined) profile.injuryType = injuryType;
      if (medicalHistory !== undefined) profile.medicalHistory = medicalHistory;
      if (bloodType !== undefined && bloodType != null) profile.bloodType = bloodType;
      if (emergencyContact !== undefined && emergencyContact != null) profile.emergencyContact = emergencyContact;
      await profile.save();
    }

    res.json({ 
      message: "Profile updated",
      patient: profile
    });
  } catch (error) {
    console.error("Update error:", error);
    res.status(500).json({ message: "Server error" });
  }
};

const uploadFile = async (req, res) => {
  try {
    if (!req.file) {
      return res.status(400).json({ message: "No file uploaded" });
    }
    
    const fileUrl = `/uploads/${req.file.filename}`;
    
    let profile = await Patient.findOne({ userId: req.user._id });
    
    if (!profile) {
      profile = await Patient.create({
        userId: req.user._id,
        files: [fileUrl]
      });
    } else {
      profile.files = profile.files || [];
      profile.files.push(fileUrl);
      await profile.save();
    }
    
    res.json({ 
      message: "File uploaded successfully",
      fileUrl: fileUrl
    });
  } catch (error) {
    console.error(error);
    res.status(500).json({ message: "Server error" });
  }
};

const getPatientById = async (req, res) => {
  try {
    const { id } = req.params;
    
    const patient = await Patient.findOne({ userId: id }).populate("userId", "name email phone");
    
    if (!patient) {
      return res.status(404).json({ message: "Patient not found" });
    }
    
    res.json(patient);
  } catch (error) {
    console.error(error);
    res.status(500).json({ message: "Server error" });
  }
};

const getAllPatients = async (req, res) => {
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
          const patientProfile = await Patient.findOne({ userId: user._id });
          
          patients.push({
            _id: patientProfile?._id,
            userId: {
              _id: user._id,
              name: user.name,
              email: user.email,
              phone: user.phone,
            },
            age: patientProfile?.age || null,
            weight: patientProfile?.weight || null,
            height: patientProfile?.height || null,
            injuryType: patientProfile?.injuryType || "",
            medicalHistory: patientProfile?.medicalHistory || "",
            bloodType: patientProfile?.bloodType || "",
            emergencyContact: patientProfile?.emergencyContact || "",
            status: patientProfile?.status || "active",
            files: patientProfile?.files || [],
            createdAt: patientProfile?.createdAt || user.createdAt,
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
};

module.exports = { 
  getPatientProfile, 
  updatePatientProfile, 
  uploadFile,
  getPatientById, 
  getAllPatients 
};