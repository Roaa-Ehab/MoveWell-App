import pandas as pd
import numpy as np
import random
import os

RANDOM_SEED = 42
random.seed(RANDOM_SEED)
np.random.seed(RANDOM_SEED)

CSV_PATH = 'injury_data.csv'
df = pd.read_csv(CSV_PATH)

print("Original columns:", df.columns.tolist())

df = df.rename(columns={
    'Age': 'age',
    'Weight_kg': 'weight_kg',
    'Height_cm': 'height_cm',
    'Training_Intensity': 'training_intensity',
    'Recovery_Days_Per_Week': 'recovery_days',
    'Injury_Indicator': 'likelihood_of_injury',
})

df['recovery_time'] = df['recovery_days'] + np.random.randint(0, 3, len(df))
df['previous_injuries'] = (df['likelihood_of_injury'] > 0).astype(int)

def map_severity(rt):
    if rt <= 2:
        return "mild"
    elif rt <= 4:
        return "moderate"
    return "severe"

def map_pain(ti):
    return max(1, min(10, round(ti * 10)))

def map_injury_type(row):
    age = row['age']
    prev = row['previous_injuries']
    h = row['height_cm']
    ti = row['training_intensity']

    if age >= 35 and prev == 1:
        return random.choice(["knee", "hip", "back"])
    elif age >= 35 and prev == 0:
        return random.choice(["shoulder", "neck", "back"])
    elif age < 25 and ti > 0.7:
        return random.choice(["ankle", "knee", "arm"])
    elif h > 185:
        return random.choice(["back", "knee", "hip"])
    else:
        return random.choice(["knee", "shoulder", "back", "neck", "ankle", "hip", "arm", "wrist"])

def map_outcome(row):
    score = 0
    severity_map = {'mild': 2.5, 'moderate': 0.5, 'severe': -1.5}
    score += severity_map.get(row['severity'], 0)
    score += (5 - row['pain_level']) * 0.3
    if row['age'] > 55:
        score -= 1.0
    elif row['age'] < 30:
        score += 0.5
    if row['weight_kg'] > 95:
        score -= 0.5
    if row['previous_injuries']:
        score -= 0.8
    score += (0.5 - row['training_intensity']) * 1.0
    score += np.random.normal(0, 0.5)

    if score >= 1.5:
        return "improving"
    elif score >= -0.5:
        return "stable"
    else:
        return "declining"

df['severity'] = df['recovery_time'].apply(map_severity)
df['pain_level'] = df['training_intensity'].apply(map_pain)
df['injury_type'] = df.apply(map_injury_type, axis=1)
df['recovery_outcome'] = df.apply(map_outcome, axis=1)

os.makedirs('movewell_outputs', exist_ok=True)
df.to_csv('movewell_outputs/patients_engineered.csv', index=False)

print("Feature Engineering Done!")
print(f"Shape: {df.shape}")
print(f"Saved: movewell_outputs/patients_engineered.csv")