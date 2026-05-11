const express = require("express");
const router = express.Router();
const { addClinicalNote, getClinicalNotesByPatient, deleteClinicalNote } = require("../controllers/clinicalNoteController");
const { protect, doctorOnly } = require("../middleware/authMiddleware");

router.post("/", protect, doctorOnly, addClinicalNote);
router.get("/patient/:patientId", protect, getClinicalNotesByPatient);
router.delete("/:id", protect, doctorOnly, deleteClinicalNote);

module.exports = router;