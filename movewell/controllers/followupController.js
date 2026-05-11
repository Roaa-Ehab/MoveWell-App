
const WeeklyFollowup = require("../models/WeeklyFollowup");

const submitFollowup = async (req, res) => {
  try {
    const { weekNumber, painLevel, improvement, notes } = req.body;
    
    const followup = await WeeklyFollowup.create({
      patientId: req.user._id,
      weekNumber,
      painLevel,
      improvement,
      notes: notes || "",
    });
    
    res.status(201).json(followup);
  } catch (error) {
    console.error(error);
    res.status(500).json({ message: "Server error" });
  }
};

const getPatientFollowups = async (req, res) => {
  try {
    const { patientId } = req.params;
    
    const followups = await WeeklyFollowup.find({ patientId }).sort({ weekNumber: -1 });
    res.json(followups);
  } catch (error) {
    console.error(error);
    res.status(500).json({ message: "Server error" });
  }
};

module.exports = { submitFollowup, getPatientFollowups };