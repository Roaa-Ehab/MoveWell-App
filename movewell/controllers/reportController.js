const Report = require("../models/Report");
const fs = require("fs");
const path = require("path");

const createReport = async (req, res) => {
  if (!req.file) {
    return res.status(400).json({ message: "No file uploaded" });
  }
  
  try {
    const fileUrl = `/uploads/${req.file.filename}`;
    const title = req.body.title || req.file.originalname;
    
    const report = new Report({
      patientId: req.user._id,
      doctorId: req.user._id,
      title: title,
      fileUrl: fileUrl,
      type: req.body.type || "general",
      notes: req.body.notes || "",
    });
    
    const savedReport = await report.save();
    res.status(201).json(savedReport);
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

const getMyReports = async (req, res) => {
  try {
    const reports = await Report.find({ patientId: req.user._id }).sort({ createdAt: -1 });
    res.json(reports);
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

const getReportsByPatient = async (req, res) => {
  try {
    const patientId = req.params.patientId;
    
    if (req.user.role === "patient" && req.user._id.toString() !== patientId) {
      return res.status(403).json({ message: "Not authorized" });
    }
    
    const reports = await Report.find({ patientId }).sort({ createdAt: -1 });
    res.json(reports);
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

const getReportById = async (req, res) => {
  try {
    const report = await Report.findById(req.params.id);
    if (!report) {
      return res.status(404).json({ message: "Report not found" });
    }
    
    if (req.user.role === "patient" && report.patientId.toString() !== req.user._id.toString()) {
      return res.status(403).json({ message: "Not authorized" });
    }
    
    res.json(report);
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

const deleteReport = async (req, res) => {
  try {
    const report = await Report.findById(req.params.id);
    if (!report) {
      return res.status(404).json({ message: "Report not found" });
    }
    
    if (report.patientId.toString() !== req.user._id.toString() && req.user.role !== "doctor") {
      return res.status(403).json({ message: "Not authorized" });
    }
    
    if (report.fileUrl) {
      const filePath = path.join(__dirname, "..", report.fileUrl);
      if (fs.existsSync(filePath)) {
        fs.unlinkSync(filePath);
      }
    }
    
    await Report.findByIdAndDelete(req.params.id);
    res.json({ message: "Report deleted" });
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

module.exports = { createReport, getMyReports, getReportsByPatient, getReportById, deleteReport };