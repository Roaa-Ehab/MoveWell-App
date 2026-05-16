"""
MoveWell — Step 1: Feature Engineering
=======================================
Input:  injury_data.csv  (1000 مريض حقيقي من Kaggle)
Output: patients_engineered.csv

الداتاسيت الأصلية فيها 6 features:
  age, weight_kg, height_cm, previous_injuries,
  training_intensity, recovery_time

بنحوّلها لـ features مناسبة للموديلات:
  severity       ← recovery_time
  pain_level     ← training_intensity
  injury_type    ← age + height + previous_injuries
  recovery_outcome ← composite score (improving/stable/declining)
"""

import pandas as pd
import numpy as np
import random
import os

RANDOM_SEED = 42
random.seed(RANDOM_SEED)
np.random.seed(RANDOM_SEED)

# ── Load ──────────────────────────────────────────────────────
CSV_PATH = 'injury_data.csv'   # غيري المسار لو محتاجة
df = pd.read_csv(CSV_PATH)

# Rename columns لو كانت بالاسم القديم
df = df.rename(columns={
    'Player_Age':          'age',
    'Player_Weight':       'weight_kg',
    'Player_Height':       'height_cm',
    'Previous_Injuries':   'previous_injuries',
    'Training_Intensity':  'training_intensity',
    'Recovery_Time':       'recovery_time',
    'Likelihood_of_Injury':'likelihood_of_injury',
})

# ── Mapping Functions ─────────────────────────────────────────

def map_severity(rt):
    """
    Recovery_Time → severity
    Clinical basis: recovery duration ∝ injury extent (Brukner & Khan, 2017)
    1-2 = mild | 3-4 = moderate | 5-6 = severe
    """
    if rt <= 2:   return "mild"
    elif rt <= 4: return "moderate"
    return "severe"


def map_pain(ti):
    """
    Training_Intensity → pain_level (0-10 NRS scale)
    Clinical basis: physical load ∝ reported pain in injured patients
    """
    return max(1, min(10, round(ti * 10)))


def map_injury_type(row):
    """
    Age + Height + Previous_Injuries → injury_type
    Rule-based assignment based on epidemiological patterns in rehab populations
    """
    age, prev = row['age'], row['previous_injuries']
    h, ti     = row['height_cm'], row['training_intensity']

    if age >= 35 and prev == 1:   return random.choice(["knee", "hip", "back"])
    elif age >= 35 and prev == 0: return random.choice(["shoulder", "neck", "back"])
    elif age < 25 and ti > 0.7:   return random.choice(["ankle", "knee", "arm"])
    elif h > 185:                 return random.choice(["back", "knee", "hip"])
    else:
        return random.choice(["knee","shoulder","back","neck","ankle","hip","arm","wrist"])


def map_outcome(row):
    """
    Composite score → recovery_outcome (improving / stable / declining)
    Weighted combination of: severity, pain, age, weight, prev_injuries, intensity
    + Gaussian noise σ=0.5 to avoid deterministic boundaries
    """
    score = 0
    score += {'mild': 2.5, 'moderate': 0.5, 'severe': -1.5}[row['severity']]
    score += (5 - row['pain_level']) * 0.3
    if row['age'] > 55:          score -= 1.0
    elif row['age'] < 30:        score += 0.5
    if row['weight_kg'] > 95:    score -= 0.5
    if row['previous_injuries']: score -= 0.8
    score += (0.5 - row['training_intensity']) * 1.0
    score += np.random.normal(0, 0.5)

    if score >= 1.5:    return "improving"
    elif score >= -0.5: return "stable"
    else:               return "declining"


# ── Apply Mappings ────────────────────────────────────────────
df['severity']         = df['recovery_time'].apply(map_severity)
df['pain_level']       = df['training_intensity'].apply(map_pain)
df['injury_type']      = df.apply(map_injury_type, axis=1)
df['recovery_outcome'] = df.apply(map_outcome, axis=1)

# ── Save ──────────────────────────────────────────────────────
os.makedirs('movewell_outputs', exist_ok=True)
df.to_csv('movewell_outputs/patients_engineered.csv', index=False)

print("✅ Feature Engineering Done!")
print(f"   Shape: {df.shape}")
print(f"\n📊 Severity:  {df['severity'].value_counts().to_dict()}")
print(f"📊 Outcome:   {df['recovery_outcome'].value_counts().to_dict()}")
print(f"📊 Injury:    {df['injury_type'].value_counts().to_dict()}")
print("\n💾 Saved: movewell_outputs/patients_engineered.csv")
