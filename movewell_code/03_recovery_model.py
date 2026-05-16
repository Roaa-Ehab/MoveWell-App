"""
MoveWell — Step 3: Recovery Prediction — 12 Models Comparison
=============================================================
Input:  movewell_outputs/patients_engineered.csv
Output: movewell_outputs/recovery_best_model.pkl
        movewell_outputs/recovery_results.json

Target: recovery_outcome (improving / stable / declining)
Features: 12 features (original + session-derived)

Models tested:
  Original 9: KNN, Linear SVM, Naive Bayes, Decision Tree,
              Random Forest, AdaBoost, MLP, Gradient Boosting,
              Logistic Regression
  New 3:      HistGradient (XGB-equivalent), Extra Trees, Bagging Trees

Evaluation: CV F1 weighted + 95% CI + per-class metrics
"""

import pandas as pd
import numpy as np
import json, os, warnings
warnings.filterwarnings('ignore')
import joblib

from sklearn.ensemble import (RandomForestClassifier, GradientBoostingClassifier,
                               AdaBoostClassifier, HistGradientBoostingClassifier,
                               ExtraTreesClassifier, BaggingClassifier)
from sklearn.tree import DecisionTreeClassifier
from sklearn.svm import SVC
from sklearn.naive_bayes import GaussianNB
from sklearn.neighbors import KNeighborsClassifier
from sklearn.neural_network import MLPClassifier
from sklearn.linear_model import LogisticRegression
from sklearn.model_selection import train_test_split, cross_val_score, StratifiedKFold
from sklearn.preprocessing import LabelEncoder, StandardScaler
from sklearn.metrics import (accuracy_score, f1_score, classification_report,
                              confusion_matrix)

RANDOM_SEED = 42
np.random.seed(RANDOM_SEED)

# ── Load & Prep ───────────────────────────────────────────────
df = pd.read_csv('movewell_outputs/patients_engineered.csv')

enc  = LabelEncoder()
lenc = LabelEncoder()
sc   = StandardScaler()

df['severity_num']     = df['severity'].map({'mild':1,'moderate':2,'severe':3})
df['injury_enc']       = enc.fit_transform(df['injury_type'])
df['outcome_enc']      = lenc.fit_transform(df['recovery_outcome'])

# Session-derived features
df['adherence_rate']   = ((1 - df['training_intensity']) * 60 + 40).clip(40, 100)
df['sessions_attended']= (df['recovery_time'] * 1.5).astype(int).clip(2, 10)
df['avg_pain_change']  = -df['pain_level'] * 0.2 + np.random.normal(0, 0.3, len(df))
df['completed_ratio']  = (1 - df['training_intensity'] * 0.3).clip(0.5, 1.0)
df['has_comorbidity']  = (df['previous_injuries'] & (df['age'] > 35)).astype(int)
df['doctor_sessions']  = (df['recovery_time'] * 0.8).astype(int).clip(1, 5)
df['weeks_in_program'] = df['recovery_time'].clip(2, 8)

FEAT = ['age','weight_kg','pain_level','adherence_rate','sessions_attended',
        'avg_pain_change','completed_ratio','has_comorbidity',
        'doctor_sessions','weeks_in_program','severity_num','injury_enc']

X, y = df[FEAT], df['outcome_enc']
Xtr, Xte, ytr, yte = train_test_split(
    X, y, test_size=0.2, stratify=y, random_state=RANDOM_SEED
)
Xtr_s = sc.fit_transform(Xtr)
Xte_s = sc.transform(Xte)
cv_kfold = StratifiedKFold(n_splits=5, shuffle=True, random_state=RANDOM_SEED)

# ── All 12 Models ─────────────────────────────────────────────
models = {
    "KNN":                      KNeighborsClassifier(n_neighbors=5),
    "Linear SVM":               SVC(kernel='linear', probability=True, random_state=RANDOM_SEED),
    "Naive Bayes":              GaussianNB(),
    "Decision Tree":            DecisionTreeClassifier(random_state=RANDOM_SEED),
    "Random Forest":            RandomForestClassifier(n_estimators=100, random_state=RANDOM_SEED),
    "AdaBoost":                 AdaBoostClassifier(n_estimators=100, random_state=RANDOM_SEED),
    "MLP":                      MLPClassifier(hidden_layer_sizes=(100,50), max_iter=500, random_state=RANDOM_SEED),
    "Gradient Boosting":        GradientBoostingClassifier(n_estimators=200, max_depth=4,
                                                            learning_rate=0.05, random_state=RANDOM_SEED),
    "Logistic Regression":      LogisticRegression(max_iter=1000, random_state=RANDOM_SEED),
    "HistGradient (XGB-equiv)": HistGradientBoostingClassifier(max_iter=300, max_depth=6,
                                                                 learning_rate=0.05, random_state=RANDOM_SEED),
    "Extra Trees":              ExtraTreesClassifier(n_estimators=100, random_state=RANDOM_SEED),
    "Bagging Trees":            BaggingClassifier(
                                    estimator=DecisionTreeClassifier(max_depth=8),
                                    n_estimators=200, random_state=RANDOM_SEED),
}

print("=" * 78)
print("  Model 3 — Recovery Prediction (12 Models)")
print("=" * 78)
print(f"{'Model':<32} {'Acc':>7} {'F1-W':>7} {'CV F1':>8} {'95% CI':>20}")
print("─" * 78)

results      = []
best_cv      = 0
best_name    = ""
best_model   = None

for name, model in models.items():
    model.fit(Xtr_s, ytr)
    yp   = model.predict(Xte_s)
    acc  = accuracy_score(yte, yp)
    f1   = f1_score(yte, yp, average='weighted')
    cvs  = cross_val_score(model, Xtr_s, ytr, cv=cv_kfold, scoring='f1_weighted')
    mu   = cvs.mean()
    se   = cvs.std()
    ci_lo = mu - 1.96 * se
    ci_hi = mu + 1.96 * se

    star = " ★" if mu > best_cv else ""
    print(f"{name:<32} {acc:>6.1%} {f1:>7.1%} {mu:>7.1%}  [{ci_lo:.1%} – {ci_hi:.1%}]{star}")

    results.append({
        'model':       name,
        'accuracy':    round(acc, 4),
        'f1_weighted': round(f1, 4),
        'cv_f1':       round(mu, 4),
        'cv_std':      round(se, 4),
        'ci_low':      round(ci_lo, 4),
        'ci_high':     round(ci_hi, 4),
    })

    if mu > best_cv:
        best_cv, best_name, best_model = mu, name, model

print("─" * 78)
print(f"\n🏆 Best: {best_name} — CV F1: {best_cv:.1%}")

# ── Per-class report ──────────────────────────────────────────
labels  = lenc.classes_
yp_best = best_model.predict(Xte_s)
print(f"\n📋 Per-class report ({best_name}):")
print(classification_report(yte, yp_best, target_names=labels))
print("Confusion Matrix:")
cm = confusion_matrix(yte, yp_best)
print(pd.DataFrame(cm, index=labels, columns=labels).to_string())

# ── Save ──────────────────────────────────────────────────────
joblib.dump({'model':best_model,'encoder':enc,'label_enc':lenc,'scaler':sc},
            'movewell_outputs/recovery_best_model.pkl')
with open('movewell_outputs/recovery_results.json','w') as f:
    json.dump({'models':results,'best':best_name,
               'best_cv':round(best_cv,4),'labels':list(labels)}, f, indent=2)

print(f"\n💾 Saved: recovery_best_model.pkl ({best_name}) + recovery_results.json")
