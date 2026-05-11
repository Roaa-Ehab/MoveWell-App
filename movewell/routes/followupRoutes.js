
const express = require("express");
const router = express.Router();
const { submitFollowup, getPatientFollowups } = require("../controllers/followupController");
const { protect, doctorOnly } = require("../middleware/authMiddleware");

router.post("/", protect, submitFollowup);
router.get("/patient/:patientId", protect, doctorOnly, getPatientFollowups);

module.exports = router;