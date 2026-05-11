
const express = require("express");
const router = express.Router();
const { saveSessionNote, getSessionNotesByPatient, getAllSessionNotes } = require("../controllers/sessionNoteController");
const { protect, doctorOnly } = require("../middleware/authMiddleware");

router.post("/", protect, doctorOnly, saveSessionNote);
router.get("/patient/:patientId", protect, getSessionNotesByPatient);
router.get("/", protect, doctorOnly, getAllSessionNotes);

module.exports = router;