const express = require("express");
const router = express.Router();
const { protect } = require("../middleware/authMiddleware");

// For agora or zegocloud token generation
router.post("/create-room", protect, async (req, res) => {
  try {
    const { sessionId } = req.body;
    // Generate token based on your video provider
    // For agora:
    // const token = await generateAgoraToken(sessionId, req.user._id);
    res.json({ roomId: sessionId, token: "generated_token" });
  } catch (error) {
    res.status(500).json({ message: "Server error" });
  }
});

router.post("/join-room", protect, async (req, res) => {
  try {
    const { roomId } = req.body;
    // Generate token for joining
    res.json({ roomId, token: "generated_token" });
  } catch (error) {
    res.status(500).json({ message: "Server error" });
  }
});

module.exports = router;