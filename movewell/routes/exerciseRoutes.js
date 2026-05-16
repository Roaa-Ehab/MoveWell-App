const express = require("express");
const router = express.Router();
const { getExercises, getExercisesByInjury, getExerciseById, createExercise, updateExercise, deleteExercise } = require("../controllers/exerciseController");
const { protect, doctorOnly } = require("../middleware/authMiddleware");

router.get("/", getExercises);
router.get("/injury/:injuryType", protect, getExercisesByInjury);
router.get("/:id", protect, getExerciseById);
router.post("/", protect, doctorOnly, createExercise);
router.put("/:id", protect, doctorOnly, updateExercise);
router.delete("/:id", protect, doctorOnly, deleteExercise);

module.exports = router;