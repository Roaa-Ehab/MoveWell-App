import pandas as pd
import numpy as np
import json, os, warnings
warnings.filterwarnings('ignore')
import joblib

from sklearn.ensemble import RandomForestClassifier
from sklearn.model_selection import train_test_split
from sklearn.preprocessing import LabelEncoder, StandardScaler
from sklearn.metrics import accuracy_score, f1_score

RANDOM_SEED = 42
np.random.seed(RANDOM_SEED)

df = pd.read_csv('movewell_outputs/patients_engineered.csv')

enc = LabelEncoder()
lenc = LabelEncoder()
sc = StandardScaler()

df['severity_num'] = df['severity'].map({'mild':1, 'moderate':2, 'severe':3})
df['injury_enc'] = enc.fit_transform(df['injury_type'])
df['outcome_enc'] = lenc.fit_transform(df['recovery_outcome'])

df['adherence_rate'] = ((1 - df['training_intensity']) * 60 + 40).clip(40, 100)
df['sessions_attended'] = (df['recovery_time'] * 1.5).astype(int).clip(2, 10)
df['avg_pain_change'] = -df['pain_level'] * 0.2 + np.random.normal(0, 0.3, len(df))
df['completed_ratio'] = (1 - df['training_intensity'] * 0.3).clip(0.5, 1.0)
df['has_comorbidity'] = (df['previous_injuries'] & (df['age'] > 35)).astype(int)
df['doctor_sessions'] = (df['recovery_time'] * 0.8).astype(int).clip(1, 5)
df['weeks_in_program'] = df['recovery_time'].clip(2, 8)

FEAT = ['age', 'weight_kg', 'pain_level', 'adherence_rate', 'sessions_attended',
        'avg_pain_change', 'completed_ratio', 'has_comorbidity',
        'doctor_sessions', 'weeks_in_program', 'severity_num', 'injury_enc']

X, y = df[FEAT], df['outcome_enc']

# Remove stratify due to small sample size
Xtr, Xte, ytr, yte = train_test_split(X, y, test_size=0.2, random_state=RANDOM_SEED)
Xtr_s = sc.fit_transform(Xtr)
Xte_s = sc.transform(Xte)

model = RandomForestClassifier(n_estimators=100, random_state=RANDOM_SEED)
model.fit(Xtr_s, ytr)

yp = model.predict(Xte_s)
acc = accuracy_score(yte, yp)
f1 = f1_score(yte, yp, average='weighted')

print("=" * 50)
print("  Recovery Model Training")
print("=" * 50)
print(f"Accuracy: {acc:.1%}")
print(f"F1 Score: {f1:.1%}")

labels = lenc.classes_.tolist()
joblib.dump({
    'model': model,
    'encoder': enc,
    'label_enc': lenc,
    'scaler': sc
}, 'movewell_outputs/recovery_best_model.pkl')

with open('movewell_outputs/recovery_results.json', 'w') as f:
    json.dump({'accuracy': round(acc, 4), 'f1': round(f1, 4), 'labels': labels}, f, indent=2)

print("Saved: recovery_best_model.pkl")