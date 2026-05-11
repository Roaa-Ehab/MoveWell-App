const express = require("express");
const router = express.Router();
const { createSession, getPatientSessions, getMySessions, getSessionById, updateSession, updateSessionStatus, deleteSession } = require("../controllers/sessionController");
const { protect, doctorOnly } = require("../middleware/authMiddleware");

router.post("/", protect, doctorOnly, createSession);
router.get("/patient/:patientId", protect, getPatientSessions);
router.get("/me", protect, getMySessions);
router.get("/:id", protect, getSessionById);
router.put("/:id", protect, doctorOnly, updateSession);
router.patch("/:id/status", protect, doctorOnly, updateSessionStatus);
router.delete("/:id", protect, doctorOnly, deleteSession);

module.exports = router;