const express = require("express");
const router = express.Router();
const { protect } = require("../middleware/authMiddleware");
const Appointment = require("../models/Appointment");

router.get("/", protect, async (req, res) => {
  try {
    let query;
    if (req.user.role === "doctor") {
      query = { doctorId: req.user._id };
    } else {
      query = { patientId: req.user._id };
    }
    
    const appointments = await Appointment.find(query)
      .populate("patientId", "name email phone")
      .populate("doctorId", "name email")
      .sort({ appointmentDate: 1 });
    
    res.json(appointments);
  } catch (error) {
    res.status(500).json({ message: "Server error" });
  }
});

router.post("/", protect, async (req, res) => {
  try {
    const appointment = await Appointment.create({
      patientId: req.user._id,
      doctorId: req.body.doctorId,
      appointmentDate: new Date(req.body.appointmentDate),
      duration: req.body.duration || 30,
      type: req.body.type || "video",
      notes: req.body.notes || "",
      status: "scheduled",
    });
    
    res.status(201).json(appointment);
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
});

router.patch("/:id/status", protect, async (req, res) => {
  try {
    const { status } = req.body;
    const appointment = await Appointment.findByIdAndUpdate(
      req.params.id,
      { status },
      { new: true }
    );
    res.json(appointment);
  } catch (error) {
    res.status(500).json({ message: "Server error" });
  }
});

router.get("/slots/:doctorId", protect, async (req, res) => {
  try {
    const slots = [
      "09:00 AM", "09:30 AM", "10:00 AM", "10:30 AM",
      "11:00 AM", "11:30 AM", "12:00 PM", "12:30 PM",
      "01:00 PM", "01:30 PM", "02:00 PM", "02:30 PM",
      "03:00 PM", "03:30 PM", "04:00 PM", "04:30 PM",
      "05:00 PM"
    ];
    res.json(slots);
  } catch (error) {
    res.status(500).json({ message: "Server error" });
  }
});

module.exports = router;