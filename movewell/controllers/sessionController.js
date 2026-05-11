const Session = require("../models/Session");

const createSession = async (req, res) => {
  try {
    const { patientId, sessionDate, duration, notes, summary, recommendations } = req.body;
    
    const session = await Session.create({
      patientId,
      doctorId: req.user._id,
      sessionDate,
      duration: duration || 30,
      notes: notes || "",
      summary: summary || "",
      recommendations: recommendations || "",
    });
    
    res.status(201).json(session);
  } catch (error) {
    console.error(error);
    res.status(500).json({ message: "Server error" });
  }
};

const getPatientSessions = async (req, res) => {
  try {
    const { patientId } = req.params;
    
    if (req.user.role === "patient" && req.user._id.toString() !== patientId) {
      return res.status(403).json({ message: "Not authorized" });
    }
    
    const sessions = await Session.find({ patientId }).populate("doctorId", "name email").sort({ sessionDate: -1 });
    res.json(sessions);
  } catch (error) {
    console.error(error);
    res.status(500).json({ message: "Server error" });
  }
};

const getMySessions = async (req, res) => {
  try {
    const query = req.user.role === "doctor" 
      ? { doctorId: req.user._id }
      : { patientId: req.user._id };
    
    const sessions = await Session.find(query)
      .populate("patientId", "name email")
      .populate("doctorId", "name email")
      .sort({ sessionDate: -1 });
    
    res.json(sessions);
  } catch (error) {
    console.error(error);
    res.status(500).json({ message: "Server error" });
  }
};

const getSessionById = async (req, res) => {
  try {
    const session = await Session.findById(req.params.id)
      .populate("patientId", "name email")
      .populate("doctorId", "name email");
    if (!session) {
      return res.status(404).json({ message: "Session not found" });
    }
    res.json(session);
  } catch (error) {
    console.error(error);
    res.status(500).json({ message: "Server error" });
  }
};

const updateSession = async (req, res) => {
  try {
    const session = await Session.findByIdAndUpdate(req.params.id, req.body, { new: true });
    if (!session) {
      return res.status(404).json({ message: "Session not found" });
    }
    res.json(session);
  } catch (error) {
    console.error(error);
    res.status(500).json({ message: "Server error" });
  }
};

const updateSessionStatus = async (req, res) => {
  try {
    const { status } = req.body;
    const session = await Session.findByIdAndUpdate(req.params.id, { status }, { new: true });
    if (!session) {
      return res.status(404).json({ message: "Session not found" });
    }
    res.json(session);
  } catch (error) {
    console.error(error);
    res.status(500).json({ message: "Server error" });
  }
};

const deleteSession = async (req, res) => {
  try {
    const session = await Session.findByIdAndDelete(req.params.id);
    if (!session) {
      return res.status(404).json({ message: "Session not found" });
    }
    res.json({ message: "Session deleted" });
  } catch (error) {
    console.error(error);
    res.status(500).json({ message: "Server error" });
  }
};

module.exports = { createSession, getPatientSessions, getMySessions, getSessionById, updateSession, updateSessionStatus, deleteSession };