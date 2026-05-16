from flask import Flask, request, jsonify
from flask_cors import CORS
import json

app = Flask(__name__)
CORS(app)

# Load exercise database
with open('exercises_dataset.json', 'r', encoding='utf-8') as f:
    exercises = json.load(f)

print("🤖 AI Server Started on port 5001")

@app.route('/health', methods=['GET'])
def health():
    return {'status': 'ok', 'message': 'AI Server Running'}

@app.route('/recommend', methods=['POST'])
def recommend():
    data = request.json
    injury = data.get('injury_type', 'back')
    
    # Get exercises for this injury
    exercises_list = exercises.get(injury, exercises.get('back', []))
    
    # Return top 5
    results = []
    for ex in exercises_list[:5]:
        results.append({
            'name': ex.get('exercise_name'),
            'duration': ex.get('duration'),
            'difficulty': ex.get('difficulty')
        })
    
    return jsonify({'success': True, 'recommendations': results})

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5001)