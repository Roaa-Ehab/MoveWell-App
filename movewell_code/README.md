# MoveWell — AI Pipeline (Full)

## ترتيب التشغيل

```bash
python 01_feature_engineering.py
python 02_recommendation_model.py
python 03_recovery_model.py
python 04_ablation_study.py
python 05_schedule_generator.py
python 06_session_assistant.py
```

أو شغّلي كل حاجة بأمر واحد:
```bash
python 07_run_all.py
```

## الملفات المطلوبة في نفس الفولدر
- `injury_data.csv` — الداتاسيت من Kaggle
- `exercises_dataset.json` — قاعدة التمارين

## الملفات

| الملف | بيعمل إيه |
|-------|-----------|
| `01_feature_engineering.py` | يحوّل الداتا الخام لـ features مناسبة |
| `02_recommendation_model.py` | يدرّب Random Forest لاقتراح التمارين |
| `03_recovery_model.py` | يقارن 12 موديل للـ recovery prediction |
| `04_ablation_study.py` | ablation study: rules vs ML vs hybrid |
| `05_schedule_generator.py` | يعمل جدول أسبوعي ذكي للمريض |
| `06_session_assistant.py` | AI assistant وقت الـ video sessions |
| `anthropic_client.py` | Claude API client للـ session assistant |
| `07_run_all.py` | يشغّل كل الـ steps بأمر واحد |

## النتايج المتوقعة

### Recommendation Model (Random Forest)
- Accuracy: 96.5% | F1: 97.5% | AUC: 89.8%

### Recovery Model (Best: Linear SVM)
- CV F1: 89.3% | 95% CI: [83.2% – 95.3%]

### Ablation Study
| Approach | F1 |
|---|---|
| Heuristic | 17.3% |
| Rule-based only | 92.4% |
| ML only | ~84.4% |
| Hybrid (MoveWell) | 97.5% |

## Requirements
```
pip install pandas numpy scikit-learn joblib anthropic
```
