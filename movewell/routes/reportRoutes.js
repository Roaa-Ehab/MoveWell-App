const express = require("express");
const router = express.Router();
const { createReport, getMyReports, getReportsByPatient, getReportById, deleteReport } = require("../controllers/reportController");
const { protect } = require("../middleware/authMiddleware");
const upload = require("../config/multer");

router.post("/", protect, upload.single("file"), createReport);
router.get("/", protect, getMyReports);
router.get("/patient/:patientId", protect, getReportsByPatient);
router.get("/:id", protect, getReportById);
router.delete("/:id", protect, deleteReport);

module.exports = router;