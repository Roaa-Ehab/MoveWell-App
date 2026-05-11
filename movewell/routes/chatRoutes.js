const express = require("express");
const router = express.Router();
const { protect } = require("../middleware/authMiddleware");
const Conversation = require("../models/Conversation");
const Message = require("../models/Message");
const User = require("../models/User");

router.get("/conversations", protect, async (req, res) => {
  try {
    const conversations = await Conversation.find({
      participants: req.user._id
    }).sort({ updatedAt: -1 });
    
    const conversationsWithDetails = [];
    for (const conv of conversations) {
      const otherParticipantId = conv.participants.find(p => p.toString() !== req.user._id.toString());
      const otherUser = await User.findById(otherParticipantId).select("name email");
      conversationsWithDetails.push({
        _id: conv._id,
        doctor: otherUser,
        lastMessage: conv.lastMessage,
        lastMessageTime: conv.lastMessageTime,
      });
    }
    res.json(conversationsWithDetails);
  } catch (error) {
    res.status(500).json({ message: "Server error" });
  }
});

router.get("/messages/:conversationId", protect, async (req, res) => {
  try {
    const messages = await Message.find({
      conversationId: req.params.conversationId
    }).sort({ createdAt: 1 });
    res.json(messages);
  } catch (error) {
    res.status(500).json({ message: "Server error" });
  }
});

router.post("/messages", protect, async (req, res) => {
  try {
    const { conversationId, message } = req.body;
    
    const conversation = await Conversation.findById(conversationId);
    if (!conversation) {
      return res.status(404).json({ message: "Conversation not found" });
    }
    
    const receiverId = conversation.participants.find(p => p.toString() !== req.user._id.toString());
    
    const newMessage = await Message.create({
      conversationId,
      senderId: req.user._id,
      receiverId,
      message,
    });
    
    await Conversation.findByIdAndUpdate(conversationId, {
      lastMessage: message,
      lastMessageTime: Date.now(),
      updatedAt: Date.now()
    });
    
    res.status(201).json(newMessage);
  } catch (error) {
    res.status(500).json({ message: "Server error" });
  }
});

router.post("/conversations", protect, async (req, res) => {
  try {
    const { doctorId } = req.body;
    
    const existingConversation = await Conversation.findOne({
      participants: { $all: [req.user._id, doctorId] }
    });
    
    if (existingConversation) {
      return res.json(existingConversation);
    }
    
    const conversation = await Conversation.create({
      participants: [req.user._id, doctorId],
    });
    
    res.status(201).json(conversation);
  } catch (error) {
    res.status(500).json({ message: "Server error" });
  }
});

module.exports = router;