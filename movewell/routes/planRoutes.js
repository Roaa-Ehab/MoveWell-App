
const express = require("express");
const router = express.Router();
const { createPlan, getPatientPlans, getPlanById, updatePlanStatus, deletePlan } = require("../controllers/planController");
const { protect, doctorOnly } = require("../middleware/authMiddleware");

router.post("/", protect, doctorOnly, createPlan);
router.get("/patient/:patientId", protect, getPatientPlans);
router.get("/:id", protect, getPlanById);
router.patch("/:id/status", protect, doctorOnly, updatePlanStatus);
router.delete("/:id", protect, doctorOnly, deletePlan);

module.exports = router;