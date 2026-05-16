const mongoose = require('mongoose');
require('dotenv').config();
const Exercise = require('./models/Exercise');

const exercises = [
  { name: "Neck Stretch", description: "Gently tilt your head", category: "stretching", injuryType: "neck", difficulty: "beginner", duration: 5 },
  { name: "Chin Tuck", description: "Pull chin straight back", category: "stretching", injuryType: "neck", difficulty: "beginner", duration: 3 },
  { name: "Cat Cow Stretch", description: "Arch and round your back", category: "stretching", injuryType: "back", difficulty: "beginner", duration: 10 },
  { name: "Child's Pose", description: "Kneel and reach forward", category: "stretching", injuryType: "back", difficulty: "beginner", duration: 30 },
  { name: "Straight Leg Raise", description: "Lift straight leg", category: "strength", injuryType: "knee", difficulty: "beginner", duration: 10 },
];

async function seed() {
  try {
    await mongoose.connect(process.env.MONGO_URI);
    await Exercise.deleteMany({});
    await Exercise.insertMany(exercises);
    console.log('✅ 5 exercises added to database!');
    process.exit();
  } catch (error) {
    console.error(error);
    process.exit(1);
  }
}

seed();