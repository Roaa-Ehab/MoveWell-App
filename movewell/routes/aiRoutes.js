const express = require('express');
const router = express.Router();
const axios = require('axios');

const AI_URL = 'http://localhost:5001';

// AI recommendation endpoint
router.post('/recommend', async (req, res) => {
  try {
    const response = await axios.post(`${AI_URL}/recommend`, req.body);
    res.json(response.data);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// AI health check
router.get('/health', async (req, res) => {
  try {
    const response = await axios.get(`${AI_URL}/health`);
    res.json({ ai_status: 'connected', ai: response.data });
  } catch (error) {
    res.json({ ai_status: 'disconnected' });
  }
});

module.exports = router;