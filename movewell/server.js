const express = require("express");
const mongoose = require("mongoose");
const cors = require("cors");
const fs = require("fs");
require("dotenv").config();

const app = express();

app.use(cors({
  origin: '*',
  credentials: true,
}));
app.use(express.json());
app.use(express.urlencoded({ extended: true }));
app.use("/uploads", express.static("uploads"));

if (!fs.existsSync("uploads")) {
  fs.mkdirSync("uploads");
}

mongoose.connect(process.env.MONGO_URI)
  .then(() => console.log("MongoDB connected"))
  .catch((err) => console.log("DB connection error:", err.message));

// Routes
app.use("/api/auth", require("./routes/authRoutes"));
app.use("/api/patients", require("./routes/patientRoutes"));
app.use("/api/reports", require("./routes/reportRoutes"));
app.use("/api/exercises", require("./routes/exerciseRoutes"));
app.use("/api/plans", require("./routes/planRoutes"));
app.use("/api/sessions", require("./routes/sessionRoutes"));
app.use("/api/tracking", require("./routes/trackingRoutes"));
app.use("/api/session-notes", require("./routes/sessionNoteRoutes"));
app.use("/api/followup", require("./routes/followupRoutes"));
app.use("/api/recommendations", require("./routes/recommendationRoutes"));
app.use("/api/video-call", require("./routes/videoCallRoutes"));
app.use("/api/chat", require("./routes/chatRoutes"));
app.use("/api/appointments", require("./routes/appointmentRoutes"));
app.use("/api/users", require("./routes/userRoutes"));
app.use("/uploads", express.static("uploads"));
app.use("/api/reports", require("./routes/reportRoutes"));
app.use("/api/clinical-notes", require("./routes/clinicalNoteRoutes"));
app.get("/", (req, res) => {
  res.send("MoveWell API Running");
});

app.get("/api", (req, res) => {
  res.json({ message: "MoveWell API is working", status: "ok" });
});

// Error handler
app.use((err, req, res, next) => {
  console.error(err.stack);
  res.status(500).json({ error: err.message || "Internal Server Error" });
});

const PORT = process.env.PORT || 5000;
app.listen(PORT, () => {
  console.log(`Server running on port ${PORT}`);
});