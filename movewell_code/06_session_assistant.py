"""
PhysioAI — AI Session Assistant
المساعد الذكي خلال جلسات الفيديو كول
- يسجل ملاحظات الطبيب
- يتابع تقدم المريض
- يعمل double-agent للطبيب والمريض
"""

from dataclasses import dataclass, field
from datetime import datetime
from typing import Optional
import json
import sys, os
sys.path.insert(0, os.path.dirname(os.path.dirname(__file__)))
from utils.anthropic_client import get_ai_response_stream, get_ai_response


# ──────────────────────────────────────────────
# نماذج البيانات
# ──────────────────────────────────────────────
@dataclass
class SessionNote:
    timestamp: str
    content: str
    note_type: str              # "doctor_instruction" | "patient_feedback" | "ai_observation"
    importance: str = "normal"  # "normal" | "important" | "critical"


@dataclass
class SessionRecord:
    session_id: str
    patient_id: str
    doctor_id: str
    date: str
    week_number: int
    notes: list[SessionNote] = field(default_factory=list)
    pain_level_start: int = 0
    pain_level_end: int = 0
    exercises_completed: list = field(default_factory=list)
    exercises_skipped: list = field(default_factory=list)
    overall_progress: str = "stable"   # "improving" | "stable" | "declining"
    doctor_modifications: list = field(default_factory=list)
    next_session_goals: list = field(default_factory=list)


@dataclass
class PatientProgress:
    patient_id: str
    patient_name: str
    sessions: list[SessionRecord] = field(default_factory=list)
    baseline_pain: int = 0
    current_pain: int = 0
    total_sessions_completed: int = 0
    adherence_rate: float = 0.0
    trend: str = "stable"


# ──────────────────────────────────────────────
# AI Session Assistant
# ──────────────────────────────────────────────
class SessionAssistant:

    def __init__(self, patient_profile: dict, progress_store: Optional[PatientProgress] = None):
        self.patient = patient_profile
        self.progress = progress_store or PatientProgress(
            patient_id=patient_profile.get("id", "P001"),
            patient_name=patient_profile.get("name", "المريض"),
        )
        self.current_session: Optional[SessionRecord] = None
        self.conversation_history = []  # تاريخ المحادثة مع Claude

    # ── بدء جلسة جديدة ───────────────────────
    def start_session(self, week_number: int, doctor_id: str = "D001") -> dict:
        session_id = f"S{datetime.now().strftime('%Y%m%d%H%M')}"
        self.current_session = SessionRecord(
            session_id=session_id,
            patient_id=self.patient.get("id", "P001"),
            doctor_id=doctor_id,
            date=datetime.now().strftime("%Y-%m-%d"),
            week_number=week_number,
        )
        self.conversation_history = []

        # بناء الـ system prompt للـ AI
        self._init_ai_context()

        return {
            "session_id": session_id,
            "status": "started",
            "briefing": self._generate_session_briefing(),
        }

    # ── تهيئة سياق الـ AI ────────────────────
    def _init_ai_context(self):
        """يحضر الـ AI بكل معلومات المريض والجلسات السابقة"""
        prev_summary = self._summarize_previous_sessions()
        self.system_prompt = f"""
أنت مساعد علاج طبيعي ذكي يعمل خلال جلسة فيديو كول بين طبيب ومريض.

معلومات المريض:
- الاسم: {self.patient.get('name')}
- العمر: {self.patient.get('age')} سنة
- الوزن: {self.patient.get('weight_kg')} كجم
- الإصابة: {self.patient.get('injury_category')} - {self.patient.get('severity')}
- مستوى الألم الأساسي: {self.patient.get('pain_level')}/10

ملخص الجلسات السابقة:
{prev_summary}

دورك:
1. إذا كتب الطبيب: سجّل الملاحظات وأكدها
2. إذا سأل المريض: أجب بناءً على ما قاله الطبيب في هذه الجلسة والسابقة
3. تذكّر الطبيب بتقدم المريض في بداية الجلسة
4. في نهاية الجلسة: لخّص أهم النقاط للمريض

كن ودياً، موجزاً، ومركزاً على الصحة. لا تعطِ تشخيصاً طبياً.
"""

    # ── ملخص ذكي للجلسات السابقة ─────────────
    def _summarize_previous_sessions(self) -> str:
        if not self.progress.sessions:
            return "لا توجد جلسات سابقة — هذه أول جلسة."

        lines = []
        for s in self.progress.sessions[-3:]:   # آخر 3 جلسات
            notes_text = " | ".join(n.content for n in s.notes if n.note_type == "doctor_instruction")
            lines.append(
                f"أسبوع {s.week_number} ({s.date}): ألم {s.pain_level_start}→{s.pain_level_end}/10 "
                f"| تقدم: {s.overall_progress} | ملاحظات: {notes_text[:200]}"
            )

        adherence = self.progress.adherence_rate
        trend = self.progress.trend
        lines.append(f"معدل الالتزام الإجمالي: {adherence:.0f}% | الاتجاه العام: {trend}")
        return "\n".join(lines)

    # ── ملخص تشغيلي للطبيب في بداية الجلسة ──
    def _generate_session_briefing(self) -> str:
        sessions_count = len(self.progress.sessions)
        if sessions_count == 0:
            return f"جلسة أولى مع {self.patient.get('name')} — لا يوجد تاريخ سابق."

        last = self.progress.sessions[-1]
        return (
            f"مرحباً دكتور، ملخص سريع عن {self.patient.get('name')}:\n"
            f"- عدد الجلسات المكتملة: {sessions_count}\n"
            f"- آخر جلسة ({last.date}): ألم {last.pain_level_start}→{last.pain_level_end}/10\n"
            f"- الاتجاه العام: {self.progress.trend}\n"
            f"- معدل الالتزام: {self.progress.adherence_rate:.0f}%\n"
            + (f"- آخر ملاحظة للطبيب: {last.notes[-1].content[:100]}..." if last.notes else "")
        )

    # ── معالجة رسالة أثناء الجلسة ────────────
    async def process_message(self, message: str, sender: str = "patient") -> dict:
        """
        sender: "doctor" | "patient"
        يرجع: رد الـ AI + إذا تم اكتشاف ملاحظة مهمة يسجلها
        """
        if self.current_session is None:
            return {"error": "لم تبدأ الجلسة بعد — استدعِ start_session أولاً"}

        # إضافة الرسالة لتاريخ المحادثة
        self.conversation_history.append({
            "role": "user",
            "content": f"[{sender.upper()}]: {message}"
        })

        # كشف إذا كانت الرسالة تعليمات طبية مهمة
        is_instruction = self._detect_medical_instruction(message, sender)
        if is_instruction:
            importance = "important" if sender == "doctor" else "normal"
            self.current_session.notes.append(SessionNote(
                timestamp=datetime.now().strftime("%H:%M"),
                content=message,
                note_type="doctor_instruction" if sender == "doctor" else "patient_feedback",
                importance=importance,
            ))

        # الحصول على رد من Claude
        ai_response = await get_ai_response(
            system=self.system_prompt,
            messages=self.conversation_history,
        )

        self.conversation_history.append({
            "role": "assistant",
            "content": ai_response
        })

        return {
            "ai_response": ai_response,
            "note_saved": is_instruction,
            "total_notes": len(self.current_session.notes),
        }

    # ── كشف التعليمات الطبية ─────────────────
    def _detect_medical_instruction(self, message: str, sender: str) -> bool:
        """يكشف إذا كانت الرسالة تحتوي على تعليمات يجب حفظها"""
        if sender == "doctor":
            # كل ما يقوله الطبيب مهم
            keywords = ["امل", "ارفع", "اخفض", "زد", "قلل", "وقف", "استمر", "احذر",
                       "تمرين", "مجموعات", "تكرار", "أسبوع", "يوم", "دواء", "ألم"]
            return any(kw in message for kw in keywords) or len(message) > 20
        else:
            # من المريض: فقط لو فيه معلومات صحية مهمة
            pain_words = ["ألم", "وجع", "أحس", "تحسن", "ساء", "صعب", "سهل"]
            return any(kw in message for kw in pain_words)

    # ── إنهاء الجلسة وتوليد الملخص ───────────
    async def end_session(
        self,
        pain_end: int,
        completed_exercises: list,
        skipped_exercises: list,
        doctor_assessment: str = ""
    ) -> dict:
        if self.current_session is None:
            return {"error": "لا توجد جلسة نشطة"}

        self.current_session.pain_level_end = pain_end
        self.current_session.exercises_completed = completed_exercises
        self.current_session.exercises_skipped = skipped_exercises

        # تحديد الاتجاه
        if self.progress.sessions:
            last_pain = self.progress.sessions[-1].pain_level_end
            if pain_end < last_pain - 1:
                self.current_session.overall_progress = "improving"
            elif pain_end > last_pain + 1:
                self.current_session.overall_progress = "declining"
            else:
                self.current_session.overall_progress = "stable"

        # توليد ملخص بالـ AI
        summary = await self._generate_session_summary(doctor_assessment)

        # حفظ الجلسة
        self.progress.sessions.append(self.current_session)
        self.progress.total_sessions_completed += 1
        self._update_progress_metrics()

        result = {
            "session_id": self.current_session.session_id,
            "summary_for_patient": summary["patient"],
            "summary_for_doctor": summary["doctor"],
            "notes_saved": [
                {"time": n.timestamp, "content": n.content, "type": n.note_type}
                for n in self.current_session.notes
            ],
            "progress": self.current_session.overall_progress,
            "next_steps": summary.get("next_steps", []),
        }

        self.current_session = None
        return result

    # ── توليد ملخص الجلسة بالـ AI ─────────────
    async def _generate_session_summary(self, doctor_assessment: str) -> dict:
        notes_text = "\n".join(
            f"- [{n.timestamp}] {n.content}"
            for n in self.current_session.notes
        )

        prompt_patient = f"""
لخّص هذه الجلسة للمريض {self.patient.get('name')} بشكل بسيط وودي (5-7 نقاط):
- الجلسة كانت: أسبوع {self.current_session.week_number}
- ملاحظات الطبيب: {notes_text}
- تقييم الطبيب: {doctor_assessment}
- التمارين المكتملة: {len(self.current_session.exercises_completed)}

اكتب للمريض ماذا يجب أن يتذكر ويطبق هذا الأسبوع.
"""

        prompt_doctor = f"""
لخّص الجلسة للطبيب بشكل مختصر ومهني:
- المريض: {self.patient.get('name')}
- أسبوع {self.current_session.week_number}
- ألم: {self.current_session.pain_level_start} → {self.current_session.pain_level_end}/10
- تقدم: {self.current_session.overall_progress}
- الملاحظات: {notes_text}

ملاحظات سريعة لتذكير الطبيب في الجلسة القادمة.
"""
        patient_summary = await get_ai_response(system="أنت مساعد علاج طبيعي ودي.", messages=[{"role": "user", "content": prompt_patient}])
        doctor_summary  = await get_ai_response(system="أنت مساعد طبي مهني موجز.", messages=[{"role": "user", "content": prompt_doctor}])

        return {
            "patient": patient_summary,
            "doctor": doctor_summary,
            "next_steps": [n.content for n in self.current_session.notes if n.importance == "important"],
        }

    # ── تحديث مقاييس التقدم ──────────────────
    def _update_progress_metrics(self):
        sessions = self.progress.sessions
        if not sessions:
            return

        # معدل الالتزام
        total_ex = sum(len(s.exercises_completed) + len(s.exercises_skipped) for s in sessions)
        done_ex  = sum(len(s.exercises_completed) for s in sessions)
        self.progress.adherence_rate = (done_ex / total_ex * 100) if total_ex > 0 else 0

        # ألم حالي
        self.progress.current_pain = sessions[-1].pain_level_end

        # الاتجاه العام
        improving = sum(1 for s in sessions if s.overall_progress == "improving")
        declining = sum(1 for s in sessions if s.overall_progress == "declining")
        if improving > declining:
            self.progress.trend = "improving"
        elif declining > improving:
            self.progress.trend = "declining"
        else:
            self.progress.trend = "stable"

    # ── استرجاع ملاحظات سابقة للمريض ─────────
    def get_patient_notes(self, last_n_sessions: int = 3) -> list:
        """يرجع ملاحظات الطبيب من آخر n جلسات"""
        all_notes = []
        for session in self.progress.sessions[-last_n_sessions:]:
            for note in session.notes:
                all_notes.append({
                    "date": session.date,
                    "week": session.week_number,
                    "content": note.content,
                    "type": note.note_type,
                    "time": note.timestamp,
                })
        return all_notes

    # ── تصدير بيانات التقدم للطبيب ───────────
    def export_progress_report(self) -> dict:
        """يصدر تقرير كامل للطبيب قبل الجلسة"""
        return {
            "patient": self.patient.get("name"),
            "total_sessions": self.progress.total_sessions_completed,
            "adherence_rate": f"{self.progress.adherence_rate:.1f}%",
            "pain_trend": f"{self.progress.baseline_pain} → {self.progress.current_pain}",
            "overall_trend": self.progress.trend,
            "recent_notes": self.get_patient_notes(3),
            "sessions_summary": [
                {
                    "week": s.week_number,
                    "date": s.date,
                    "progress": s.overall_progress,
                    "pain": f"{s.pain_level_start}→{s.pain_level_end}",
                    "completed": len(s.exercises_completed),
                    "skipped": len(s.exercises_skipped),
                }
                for s in self.progress.sessions
            ],
        }
