from flask import Flask, request, jsonify
from flask_cors import CORS
import json

app = Flask(__name__)
CORS(app)

# Load exercise database
with open('exercises_dataset.json', 'r', encoding='utf-8') as f:
    EXERCISES = json.load(f)

# Map injury types to body parts
INJURY_MAP = {
    'back': 'back', 'knee': 'knee', 'neck': 'neck',
    'shoulder': 'shoulder', 'ankle': 'ankle', 'hip': 'hip',
    'arm': 'arm', 'wrist': 'wrist', 'leg': 'leg'
}

@app.route('/health', methods=['GET'])
def health():
    return jsonify({'status': 'AI Server Running'})

@app.route('/recommend', methods=['POST'])
def recommend():
    try:
        data = request.json
        injury = data.get('injury_type', 'back').lower()
        age = data.get('age', 30)
        pain = data.get('pain_level', 5)
        
        body_part = INJURY_MAP.get(injury, 'back')
        exercises = EXERCISES.get(body_part, EXERCISES.get('back', []))
        
        # Age filter
        if age > 65:
            exercises = [ex for ex in exercises if ex.get('difficulty') != 'hard']
        
        # Pain filter
        if pain > 7:
            exercises = exercises[:3]
        
        recommendations = []
        for ex in exercises[:5]:
            recommendations.append({
                'name': ex.get('exercise_name', 'Exercise'),
                'duration': ex.get('duration', 10),
                'difficulty': ex.get('difficulty', 'easy')
            })
        
        return jsonify({'success': True, 'recommendations': recommendations})
    
    except Exception as e:
        return jsonify({'success': False, 'error': str(e)}), 500

@app.route('/predict-recovery', methods=['POST'])
def predict_recovery():
    try:
        data = request.json
        pain = data.get('pain_level', 5)
        
        if pain <= 3:
            outcome = 'improving'
        elif pain <= 7:
            outcome = 'stable'
        else:
            outcome = 'declining'
        
        return jsonify({
            'success': True,
            'predicted_outcome': outcome,
            'confidence': 0.85
        })
    
    except Exception as e:
        return jsonify({'success': False, 'error': str(e)}), 500

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5001, debug=False)