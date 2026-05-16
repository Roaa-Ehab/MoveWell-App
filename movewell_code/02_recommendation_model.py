"""
MoveWell — Step 2: Exercise Recommendation Model
=================================================
Input:  movewell_outputs/patients_engineered.csv
        exercises_dataset.json
Output: movewell_outputs/recommendation_model.pkl
        movewell_outputs/rec_results.json

Model: Random Forest — Binary Classification
Target: هل التمرين ده مناسب للمريض ده؟ (recommended=1 / not=0)

Stage 1: Clinical Safety Filters (rule-based)
  - Age range check
  - Weight limit check
  - Difficulty vs severity check
  - Contraindication check

Stage 2: ML Scoring (Random Forest)
  - Ranks exercises by confidence score
  - Physiotherapist makes final decision
"""

import pandas as pd
import numpy as np
import json, os
import joblib
from sklearn.ensemble import RandomForestClassifier
from sklearn.model_selection import train_test_split, cross_val_score
from sklearn.preprocessing import LabelEncoder, StandardScaler
from sklearn.metrics import (accuracy_score, precision_score, recall_score,
                             f1_score, roc_auc_score, classification_report)

RANDOM_SEED = 42
np.random.seed(RANDOM_SEED)

# ── Load ──────────────────────────────────────────────────────
df = pd.read_csv('movewell_outputs/patients_engineered.csv')

with open('exercises_dataset.json', encoding='utf-8') as f:
    ex_data = json.load(f)

# ── Build Patient-Exercise Pairs ──────────────────────────────
rows = []
for _, pat in df.iterrows():
    exercises = ex_data['exercises'].get(pat['injury_type'], [])
    sev_num   = {'mild':1, 'moderate':2, 'severe':3}[pat['severity']]

    for ex in exercises:
        # Evidence-based clinical safety rules (Stage 1 labels)
        rec = 1
        if ex['difficulty'] == 2 and pat['severity'] == 'severe':  rec = 0
        if pat['age'] > 65 and ex['difficulty'] == 2:              rec = 0
        if pat['pain_level'] >= 7 and ex['phase'] == 2:            rec = 0
        if pat['weight_kg'] > 100 and ex['difficulty'] == 2:       rec = 0
        if np.random.random() < 0.05:                              rec = 1 - rec  # 5% noise

        rows.append({
            'age':            pat['age'],
            'weight_kg':      pat['weight_kg'],
            'pain_level':     pat['pain_level'],
            'severity':       pat['severity'],
            'severity_num':   sev_num,
            'injury_type':    pat['injury_type'],
            'ex_difficulty':  ex['difficulty'],
            'ex_phase':       ex['phase'],
            'recommended':    rec
        })

rec_df = pd.DataFrame(rows)
print(f"📦 Patient-exercise pairs: {len(rec_df):,}")
print(f"   Positive (recommended): {rec_df['recommended'].mean():.1%}")

# ── Preprocess ────────────────────────────────────────────────
enc = LabelEncoder()
sc  = StandardScaler()
rec_df['injury_type_enc'] = enc.fit_transform(rec_df['injury_type'])
rec_df['severity_num']    = rec_df['severity'].map({'mild':1,'moderate':2,'severe':3})

FEAT = ['age','weight_kg','pain_level','severity_num',
        'injury_type_enc','ex_difficulty','ex_phase']
X, y = rec_df[FEAT], rec_df['recommended']
Xtr, Xte, ytr, yte = train_test_split(
    X, y, test_size=0.2, stratify=y, random_state=RANDOM_SEED
)
Xtr_s = sc.fit_transform(Xtr)
Xte_s = sc.transform(Xte)

# ── Train ─────────────────────────────────────────────────────
rf = RandomForestClassifier(n_estimators=100, random_state=RANDOM_SEED)
rf.fit(Xtr_s, ytr)

yp  = rf.predict(Xte_s)
ypr = rf.predict_proba(Xte_s)[:,1]
cv  = cross_val_score(rf, Xtr_s, ytr, cv=5, scoring='f1')

# ── Results ───────────────────────────────────────────────────
results = {
    'accuracy':         round(accuracy_score(yte, yp), 4),
    'precision':        round(precision_score(yte, yp), 4),
    'recall':           round(recall_score(yte, yp), 4),
    'f1':               round(f1_score(yte, yp), 4),
    'auc_roc':          round(roc_auc_score(yte, ypr), 4),
    'cv_f1_mean':       round(cv.mean(), 4),
    'cv_f1_std':        round(cv.std(), 4),
}

print("\n" + "="*50)
print("  Model 2 — Exercise Recommendation (Random Forest)")
print("="*50)
for k, v in results.items():
    print(f"  {k:<16}: {v}")
print(f"\n{classification_report(yte, yp, target_names=['Not Recommended','Recommended'])}")

# ── Save ──────────────────────────────────────────────────────
joblib.dump({'model':rf,'encoder':enc,'scaler':sc},
            'movewell_outputs/recommendation_model.pkl')
with open('movewell_outputs/rec_results.json','w') as f:
    json.dump(results, f, indent=2)

print("💾 Saved: recommendation_model.pkl + rec_results.json")
