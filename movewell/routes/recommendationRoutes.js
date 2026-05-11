
const express = require("express");
const router = express.Router();
const { getRecommendations, getRecommendationsByInjury } = require("../controllers/recommendationController");
const { protect } = require("../middleware/authMiddleware");

router.get("/", protect, getRecommendations);
router.get("/injury/:injuryType", protect, getRecommendationsByInjury);

module.exports = router;