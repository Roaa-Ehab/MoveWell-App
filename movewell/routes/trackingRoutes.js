const express = require("express");
const router = express.Router();
const { createTracking, getMyTracking, getPatientTracking, getTrackingByDate, getTrackingSummary } = require("../controllers/trackingController");
const { protect, doctorOnly } = require("../middleware/authMiddleware");

router.post("/", protect, createTracking);
router.get("/me", protect, getMyTracking);
router.get("/me/:date", protect, getTrackingByDate);
router.get("/patient/:patientId", protect, doctorOnly, getPatientTracking);
router.get("/summary/:patientId", protect, doctorOnly, getTrackingSummary);

module.exports = router;