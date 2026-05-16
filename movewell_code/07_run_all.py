"""
MoveWell — Run All Steps
========================
بيشغّل الـ 4 steps بالترتيب:
  01_feature_engineering.py
  02_recommendation_model.py
  03_recovery_model.py
  04_ablation_study.py

ملاحظة: تأكدي إن الملفات دي موجودة في نفس الفولدر:
  - injury_data.csv
  - exercises_dataset.json
"""

import subprocess
import sys

steps = [
    ("Step 1: Feature Engineering",   "01_feature_engineering.py"),
    ("Step 2: Recommendation Model",  "02_recommendation_model.py"),
    ("Step 3: Recovery Model",        "03_recovery_model.py"),
    ("Step 4: Ablation Study",        "04_ablation_study.py"),
]

for title, script in steps:
    print(f"\n{'='*60}")
    print(f"  {title}")
    print(f"{'='*60}")
    result = subprocess.run([sys.executable, script], capture_output=False)
    if result.returncode != 0:
        print(f"❌ {script} failed!")
        sys.exit(1)

print("\n" + "="*60)
print("  ✅ All steps completed!")
print("  Output files in: movewell_outputs/")
print("    - patients_engineered.csv")
print("    - recommendation_model.pkl")
print("    - rec_results.json")
print("    - recovery_best_model.pkl")
print("    - recovery_results.json")
print("    - ablation_results.json")
print("="*60)
