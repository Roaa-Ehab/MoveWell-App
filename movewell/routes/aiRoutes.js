const express = require('express');
const router = express.Router();
const axios = require('axios');

const AI_URL = 'http://localhost:5001';

router.post('/recommend', async (req, res) => {
  try {
    const response = await axios.post(`${AI_URL}/recommend`, req.body);
    res.json(response.data);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

router.post('/predict-recovery', async (req, res) => {
  try {
    const response = await axios.post(`${AI_URL}/predict-recovery`, req.body);
    res.json(response.data);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

router.get('/health', async (req, res) => {
  try {
    const response = await axios.get(`${AI_URL}/health`);
    res.json(response.data);
  } catch (error) {
    res.json({ status: 'AI Server not running' });
  }
});

module.exports = router;