
const Exercise = require("../models/Exercise");

const exerciseDatabase = {
  neck_pain: [
    { name: "Neck Stretch", description: "Gently tilt your head to each side holding for 15 seconds", videoUrl: "https://youtu.be/example1", difficulty: "beginner", duration: 5 },
    { name: "Chin Tuck", description: "Pull your chin straight back creating a double chin", videoUrl: "https://youtu.be/example2", difficulty: "beginner", duration: 3 },
    { name: "Neck Rotation", description: "Slowly turn your head left and right", videoUrl: "https://youtu.be/example3", difficulty: "beginner", duration: 4 },
    { name: "Shoulder Rolls", description: "Roll your shoulders backward in a circular motion", videoUrl: "https://youtu.be/example4", difficulty: "beginner", duration: 5 },
    { name: "Side Bend", description: "Bring your ear toward your shoulder", videoUrl: "https://youtu.be/example5", difficulty: "beginner", duration: 4 }
  ],
  back_pain: [
    { name: "Child's Pose", description: "Kneel on floor sit back on heels reach arms forward", videoUrl: "https://youtu.be/example6", difficulty: "beginner", duration: 30 },
    { name: "Cat Cow Stretch", description: "On hands and knees alternate between arching and rounding your back", videoUrl: "https://youtu.be/example7", difficulty: "beginner", duration: 10 },
    { name: "Pelvic Tilt", description: "Lie on back flatten your lower back against floor", videoUrl: "https://youtu.be/example8", difficulty: "beginner", duration: 5 },
    { name: "Bridge Exercise", description: "Lie on back lift hips toward ceiling", videoUrl: "https://youtu.be/example9", difficulty: "intermediate", duration: 10 },
    { name: "Partial Crunch", description: "Lie on back with knees bent lift head and shoulders slightly", videoUrl: "https://youtu.be/example10", difficulty: "intermediate", duration: 10 }
  ],
  knee_pain: [
    { name: "Straight Leg Raise", description: "Lie on back lift straight leg to 45 degrees", videoUrl: "https://youtu.be/example11", difficulty: "beginner", duration: 10 },
    { name: "Hamstring Stretch", description: "Sit with leg straight reach toward toes", videoUrl: "https://youtu.be/example12", difficulty: "beginner", duration: 15 },
    { name: "Quad Stretch", description: "Standing pull heel toward glutes", videoUrl: "https://youtu.be/example13", difficulty: "intermediate", duration: 15 },
    { name: "Wall Squat", description: "Lean against wall slide down into sitting position", videoUrl: "https://youtu.be/example14", difficulty: "intermediate", duration: 20 },
    { name: "Step Up", description: "Step onto a low platform with one foot", videoUrl: "https://youtu.be/example15", difficulty: "intermediate", duration: 10 }
  ],
  shoulder_pain: [
    { name: "Pendulum Swing", description: "Lean forward swing arm in small circles", videoUrl: "https://youtu.be/example16", difficulty: "beginner", duration: 5 },
    { name: "Cross Body Reach", description: "Pull arm across chest", videoUrl: "https://youtu.be/example17", difficulty: "beginner", duration: 15 },
    { name: "Doorway Stretch", description: "Place hands on door frame lean forward", videoUrl: "https://youtu.be/example18", difficulty: "beginner", duration: 15 },
    { name: "External Rotation", description: "With band or light weight rotate arm outward", videoUrl: "https://youtu.be/example19", difficulty: "intermediate", duration: 10 }
  ]
};

const getRecommendations = async (req, res) => {
  try {
    const { injuryType, patientId } = req.query;
    
    let exercises = [];
    
    if (injuryType && exerciseDatabase[injuryType]) {
      exercises = exerciseDatabase[injuryType];
    } else {
      const dbExercises = await Exercise.find({ injuryType: injuryType || "back_pain" }).limit(5);
      if (dbExercises.length > 0) {
        exercises = dbExercises.map(ex => ({
          name: ex.name,
          description: ex.description,
          videoUrl: ex.videoUrl,
          difficulty: ex.difficulty,
          duration: ex.duration
        }));
      } else {
        exercises = exerciseDatabase.back_pain;
      }
    }
    
    res.json({
      patientId: patientId || null,
      injuryType: injuryType || "back_pain",
      recommendations: exercises,
      total: exercises.length
    });
  } catch (error) {
    console.error(error);
    res.status(500).json({ message: "Server error" });
  }
};

const getRecommendationsByInjury = async (req, res) => {
  try {
    const { injuryType } = req.params;
    
    let exercises = [];
    
    if (exerciseDatabase[injuryType]) {
      exercises = exerciseDatabase[injuryType];
    } else {
      const dbExercises = await Exercise.find({ injuryType: injuryType });
      if (dbExercises.length > 0) {
        exercises = dbExercises.map(ex => ({
          name: ex.name,
          description: ex.description,
          videoUrl: ex.videoUrl,
          difficulty: ex.difficulty,
          duration: ex.duration
        }));
      } else {
        exercises = exerciseDatabase.back_pain;
      }
    }
    
    res.json({
      injuryType: injuryType,
      recommendations: exercises,
      total: exercises.length
    });
  } catch (error) {
    console.error(error);
    res.status(500).json({ message: "Server error" });
  }
};

module.exports = { getRecommendations, getRecommendationsByInjury };