
const Plan = require("../models/Plan");

const createPlan = async (req, res) => {
  try {
    const { patientId, name, description, exercises, startDate, endDate } = req.body;
    
    const plan = await Plan.create({
      patientId,
      doctorId: req.user._id,
      name,
      description: description || "",
      exercises: exercises || [],
      startDate: startDate || Date.now(),
      endDate: endDate || null,
    });
    
    res.status(201).json(plan);
  } catch (error) {
    console.error(error);
    res.status(500).json({ message: "Server error" });
  }
};

const getPatientPlans = async (req, res) => {
  try {
    const { patientId } = req.params;
    
    if (req.user.role === "patient" && req.user._id.toString() !== patientId) {
      return res.status(403).json({ message: "Not authorized" });
    }
    
    const plans = await Plan.find({ patientId }).populate("exercises.exerciseId");
    res.json(plans);
  } catch (error) {
    console.error(error);
    res.status(500).json({ message: "Server error" });
  }
};

const getPlanById = async (req, res) => {
  try {
    const plan = await Plan.findById(req.params.id).populate("exercises.exerciseId").populate("patientId", "name").populate("doctorId", "name");
    if (!plan) {
      return res.status(404).json({ message: "Plan not found" });
    }
    res.json(plan);
  } catch (error) {
    console.error(error);
    res.status(500).json({ message: "Server error" });
  }
};

const updatePlanStatus = async (req, res) => {
  try {
    const { status } = req.body;
    const plan = await Plan.findByIdAndUpdate(req.params.id, { status }, { new: true });
    if (!plan) {
      return res.status(404).json({ message: "Plan not found" });
    }
    res.json(plan);
  } catch (error) {
    console.error(error);
    res.status(500).json({ message: "Server error" });
  }
};

const deletePlan = async (req, res) => {
  try {
    const plan = await Plan.findByIdAndDelete(req.params.id);
    if (!plan) {
      return res.status(404).json({ message: "Plan not found" });
    }
    res.json({ message: "Plan deleted" });
  } catch (error) {
    console.error(error);
    res.status(500).json({ message: "Server error" });
  }
};

module.exports = { createPlan, getPatientPlans, getPlanById, updatePlanStatus, deletePlan };