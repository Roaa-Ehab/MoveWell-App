const Tracking = require("../models/Tracking");

const createTracking = async (req, res) => {
  try {
    const { painLevel, progress, mobilityScore, strengthScore, sleepQuality, notes, date } = req.body;
    
    const trackingData = {
      patientId: req.user._id,
      painLevel,
      progress: progress || 0,
      mobilityScore: mobilityScore || 0,
      strengthScore: strengthScore || 0,
      sleepQuality: sleepQuality || 0,
      notes: notes || "",
    };
    
    if (date) {
      trackingData.date = new Date(date);
    }
    
    const tracking = await Tracking.create(trackingData);
    
    res.status(201).json(tracking);
  } catch (error) {
    console.error(error);
    res.status(500).json({ message: "Server error" });
  }
};

const getMyTracking = async (req, res) => {
  try {
    const tracking = await Tracking.find({ patientId: req.user._id }).sort({ date: -1 });
    res.json(tracking);
  } catch (error) {
    console.error(error);
    res.status(500).json({ message: "Server error" });
  }
};

const getTrackingByDate = async (req, res) => {
  try {
    const { date } = req.params;
    const startOfDay = new Date(date);
    startOfDay.setHours(0, 0, 0, 0);
    const endOfDay = new Date(date);
    endOfDay.setHours(23, 59, 59, 999);
    
    const tracking = await Tracking.findOne({
      patientId: req.user._id,
      date: { $gte: startOfDay, $lte: endOfDay }
    });
    
    res.json(tracking || null);
  } catch (error) {
    console.error(error);
    res.status(500).json({ message: "Server error" });
  }
};

const getPatientTracking = async (req, res) => {
  try {
    const { patientId } = req.params;
    
    if (req.user.role === "patient" && req.user._id.toString() !== patientId) {
      return res.status(403).json({ message: "Not authorized" });
    }
    
    const tracking = await Tracking.find({ patientId }).sort({ date: -1 });
    res.json(tracking);
  } catch (error) {
    console.error(error);
    res.status(500).json({ message: "Server error" });
  }
};

const getTrackingSummary = async (req, res) => {
  try {
    const { patientId } = req.params;
    
    const allTracking = await Tracking.find({ patientId }).sort({ date: 1 });
    
    if (allTracking.length === 0) {
      return res.json({ message: "No tracking data available" });
    }
    
    const first = allTracking[0];
    const last = allTracking[allTracking.length - 1];
    
    const avgPainLevel = allTracking.reduce((sum, t) => sum + t.painLevel, 0) / allTracking.length;
    const avgProgress = allTracking.reduce((sum, t) => sum + (t.progress || 0), 0) / allTracking.length;
    
    res.json({
      patientId,
      startDate: first.date,
      lastUpdate: last.date,
      initialPainLevel: first.painLevel,
      currentPainLevel: last.painLevel,
      painImprovement: first.painLevel - last.painLevel,
      initialProgress: first.progress || 0,
      currentProgress: last.progress || 0,
      progressImprovement: (last.progress || 0) - (first.progress || 0),
      averagePainLevel: avgPainLevel.toFixed(1),
      averageProgress: avgProgress.toFixed(1),
      totalEntries: allTracking.length
    });
  } catch (error) {
    console.error(error);
    res.status(500).json({ message: "Server error" });
  }
};

module.exports = { createTracking, getMyTracking, getPatientTracking, getTrackingByDate, getTrackingSummary };