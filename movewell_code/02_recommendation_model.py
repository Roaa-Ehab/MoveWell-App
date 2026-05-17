import pandas as pd
import numpy as np
import json, os
import joblib
from sklearn.ensemble import RandomForestClassifier
from sklearn.model_selection import train_test_split, cross_val_score
from sklearn.preprocessing import LabelEncoder, StandardScaler
from sklearn.metrics import accuracy_score, precision_score, recall_score, f1_score, roc_auc_score, classification_report

RANDOM_SEED = 42
np.random.seed(RANDOM_SEED)

df = pd.read_csv('movewell_outputs/patients_engineered.csv')

with open('exercises_dataset.json', encoding='utf-8') as f:
    exercises_dict = json.load(f)

print(f"Available body parts: {list(exercises_dict.keys())}")

# Map injury types to body parts
injury_to_bodypart = {
    'neck': 'neck', 'shoulder': 'shoulder', 'arm': 'arm', 'wrist': 'wrist',
    'back': 'back', 'hip': 'hip', 'knee': 'knee', 'leg': 'leg', 'ankle': 'ankle'
}

rows = []
for _, pat in df.iterrows():
    injury = pat['injury_type']
    bodypart = injury_to_bodypart.get(injury, 'back')
    exercises = exercises_dict.get(bodypart, exercises_dict.get('back', []))
    
    sev_num = {'mild':1, 'moderate':2, 'severe':3}[pat['severity']]

    for ex in exercises:
        rec = 1
        difficulty = 1 if ex.get('difficulty') == 'easy' else (2 if ex.get('difficulty') == 'medium' else 3)
        
        if difficulty == 2 and pat['severity'] == 'severe':
            rec = 0
        if pat['age'] > 65 and difficulty == 2:
            rec = 0
        if pat['pain_level'] >= 7:
            rec = 0
        if pat['weight_kg'] > 100 and difficulty == 2:
            rec = 0
        if np.random.random() < 0.05:
            rec = 1 - rec

        rows.append({
            'age': pat['age'],
            'weight_kg': pat['weight_kg'],
            'pain_level': pat['pain_level'],
            'severity': pat['severity'],
            'severity_num': sev_num,
            'injury_type': pat['injury_type'],
            'ex_difficulty': difficulty,
            'ex_phase': 1,
            'recommended': rec
        })

rec_df = pd.DataFrame(rows)
print(f"Patient-exercise pairs: {len(rec_df):,}")
print(f"Positive (recommended): {rec_df['recommended'].mean():.1%}")

enc = LabelEncoder()
sc = StandardScaler()
rec_df['injury_type_enc'] = enc.fit_transform(rec_df['injury_type'])
rec_df['severity_num'] = rec_df['severity'].map({'mild':1, 'moderate':2, 'severe':3})

FEAT = ['age','weight_kg','pain_level','severity_num',
        'injury_type_enc','ex_difficulty','ex_phase']
X, y = rec_df[FEAT], rec_df['recommended']
Xtr, Xte, ytr, yte = train_test_split(X, y, test_size=0.2, stratify=y, random_state=RANDOM_SEED)
Xtr_s = sc.fit_transform(Xtr)
Xte_s = sc.transform(Xte)

rf = RandomForestClassifier(n_estimators=100, random_state=RANDOM_SEED)
rf.fit(Xtr_s, ytr)

yp = rf.predict(Xte_s)
ypr = rf.predict_proba(Xte_s)[:,1]
cv = cross_val_score(rf, Xtr_s, ytr, cv=5, scoring='f1')

results = {
    'accuracy': round(accuracy_score(yte, yp), 4),
    'precision': round(precision_score(yte, yp), 4),
    'recall': round(recall_score(yte, yp), 4),
    'f1': round(f1_score(yte, yp), 4),
    'auc_roc': round(roc_auc_score(yte, ypr), 4),
    'cv_f1_mean': round(cv.mean(), 4),
    'cv_f1_std': round(cv.std(), 4),
}

print("\n" + "="*50)
print("  Model 2 — Exercise Recommendation (Random Forest)")
print("="*50)
for k, v in results.items():
    print(f"  {k:<16}: {v}")

# Save model and transformers together
joblib.dump({
    'model': rf,
    'encoder': enc,
    'scaler': sc
}, 'movewell_outputs/recommendation_model.pkl')

with open('movewell_outputs/rec_results.json','w') as f:
    json.dump(results, f, indent=2)

print("Saved: recommendation_model.pkl + rec_results.json")