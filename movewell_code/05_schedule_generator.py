"""
PhysioAI — Weekly Schedule Generator
يبني جدول أسبوعي ذكي بناءً على التمارين ومواعيد الطبيب
"""

from dataclasses import dataclass, field
from typing import Optional
from datetime import datetime, timedelta
import math


# ──────────────────────────────────────────────
# نموذج مواعيد الطبيب
# ──────────────────────────────────────────────
@dataclass
class DoctorAvailability:
    """أوقات الطبيب المتاحة للجلسات"""
    available_days: list[int]        # 0=الأحد ... 6=السبت
    start_hour: int = 18             # 6 مساءً
    end_hour: int = 22               # 10 مساءً
    session_duration_minutes: int = 45
    doctor_name: str = "الطبيب"


# ──────────────────────────────────────────────
# نموذج خانة في الجدول
# ──────────────────────────────────────────────
@dataclass
class ScheduleSlot:
    day_name: str
    day_index: int              # 0-6
    slot_type: str              # "home_exercise" | "video_session" | "rest"
    time: Optional[str] = None
    exercises: list = field(default_factory=list)
    duration_minutes: int = 0
    notes: str = ""
    is_bookable: bool = False   # صح لو ممكن يحجز فيديو كول


# ──────────────────────────────────────────────
# مولّد الجدول الأسبوعي
# ──────────────────────────────────────────────
class ScheduleGenerator:

    DAYS_AR = ["الأحد", "الإثنين", "الثلاثاء", "الأربعاء", "الخميس", "الجمعة", "السبت"]

    def __init__(self):
        self.days_ar = self.DAYS_AR

    # ── الدالة الرئيسية ──────────────────────
    def generate(
        self,
        exercises: list,
        sessions_per_week: int,
        doctor_availability: DoctorAvailability,
        patient_preferred_time: Optional[str] = None,   # "morning" | "evening"
        start_date: Optional[datetime] = None
    ) -> dict:
        """
        يرجع:
        - week_schedule: الجدول كاملاً (7 أيام)
        - video_slots: الأوقات المتاحة للفيديو كول
        - weekly_stats: إحصائيات الأسبوع
        """
        if start_date is None:
            start_date = datetime.now()

        # ── 1. قسّم التمارين على أيام الأسبوع ─
        home_days, rest_days, video_days = self._plan_days(
            sessions_per_week, doctor_availability.available_days
        )

        # ── 2. قسّم التمارين بالتساوي ────────
        exercise_groups = self._split_exercises(exercises, len(home_days) + len(video_days))

        # ── 3. ابنِ الجدول اليومي ─────────────
        week_schedule = []
        group_idx = 0
        for day_idx in range(7):
            day_name = self.days_ar[day_idx]
            day_date = start_date + timedelta(days=day_idx)

            if day_idx in video_days:
                # يوم جلسة فيديو مع الطبيب
                slot = ScheduleSlot(
                    day_name=day_name,
                    day_index=day_idx,
                    slot_type="video_session",
                    exercises=exercise_groups[group_idx] if group_idx < len(exercise_groups) else [],
                    duration_minutes=doctor_availability.session_duration_minutes,
                    notes=f"جلسة متابعة مع {doctor_availability.doctor_name}",
                    is_bookable=True,
                )
                group_idx += 1

            elif day_idx in home_days:
                # يوم تمرين منزلي
                grp = exercise_groups[group_idx] if group_idx < len(exercise_groups) else []
                total_time = sum(ex.get("duration_minutes", 10) for ex in grp)
                slot = ScheduleSlot(
                    day_name=day_name,
                    day_index=day_idx,
                    slot_type="home_exercise",
                    exercises=grp,
                    duration_minutes=total_time,
                    notes="تمارين منزلية",
                )
                group_idx += 1

            else:
                # يوم راحة
                slot = ScheduleSlot(
                    day_name=day_name,
                    day_index=day_idx,
                    slot_type="rest",
                    notes="يوم راحة — مهم للشفاء",
                )

            slot.date = day_date.strftime("%Y-%m-%d")
            week_schedule.append(slot)

        # ── 4. أنشئ أوقات الفيديو كول المتاحة ─
        video_slots = self._generate_video_slots(
            doctor_availability, video_days, start_date
        )

        # ── 5. إحصائيات الأسبوع ───────────────
        stats = self._compute_stats(week_schedule, exercises)

        return {
            "week_schedule": [self._slot_to_dict(s) for s in week_schedule],
            "video_slots": video_slots,
            "weekly_stats": stats,
            "next_week_note": "ستُحدَّث التمارين بعد مراجعة الطبيب كل 4 أسابيع",
        }

    # ── توزيع أيام الأسبوع ───────────────────
    def _plan_days(self, sessions_per_week: int, doctor_days: list[int]) -> tuple:
        """
        يقرر: أيام الفيديو كول، أيام التمرين المنزلي، أيام الراحة
        القاعدة: يومي راحة على الأقل، توزيع متوازن
        """
        all_days = list(range(7))

        # أيام الفيديو كول = أقل من sessions_per_week (1-2 مرة)
        video_days = [d for d in doctor_days if d in all_days][:2]

        # الأيام المتبقية للتمارين حتى نصل لعدد الجلسات
        remaining_sessions = sessions_per_week - len(video_days)
        candidate_home = [d for d in all_days if d not in video_days]

        # توزيع متوازن مع راحة يوم بعد يوم كلما أمكن
        home_days = self._pick_balanced(candidate_home, remaining_sessions)

        rest_days = [d for d in all_days if d not in video_days and d not in home_days]

        return home_days, rest_days, video_days

    def _pick_balanced(self, candidates: list, count: int) -> list:
        """يختار أياماً موزعة بالتساوي قدر الإمكان"""
        if count <= 0 or not candidates:
            return []
        if count >= len(candidates):
            return candidates

        step = len(candidates) / count
        chosen = []
        for i in range(count):
            idx = int(i * step)
            chosen.append(candidates[min(idx, len(candidates) - 1)])
        return list(set(chosen))[:count]

    # ── تقسيم التمارين على الأيام ─────────────
    def _split_exercises(self, exercises: list, num_days: int) -> list:
        """يوزع التمارين بالتساوي على الأيام"""
        if not exercises or num_days == 0:
            return [[] for _ in range(max(num_days, 1))]

        groups = [[] for _ in range(num_days)]
        for i, ex in enumerate(exercises):
            groups[i % num_days].append(ex)
        return groups

    # ── توليد أوقات الفيديو كول ──────────────
    def _generate_video_slots(
        self, availability: DoctorAvailability, video_days: list, start_date: datetime
    ) -> list:
        """يولد قائمة بالأوقات المتاحة للحجز"""
        slots = []
        for day_idx in availability.available_days:
            day_date = start_date + timedelta(days=day_idx)
            hour = availability.start_hour
            while hour < availability.end_hour:
                slots.append({
                    "day": self.days_ar[day_idx],
                    "date": day_date.strftime("%Y-%m-%d"),
                    "time": f"{hour:02d}:00",
                    "time_display": self._format_time(hour),
                    "doctor": availability.doctor_name,
                    "duration_minutes": availability.session_duration_minutes,
                    "is_video_day": day_idx in video_days,
                    "slot_id": f"{day_date.strftime('%Y%m%d')}_{hour:02d}00",
                })
                hour += 1  # كل ساعة slot
        return slots

    # ── تنسيق الوقت بالعربي ──────────────────
    def _format_time(self, hour: int) -> str:
        if hour < 12:
            return f"{hour}:00 ص"
        elif hour == 12:
            return "12:00 م"
        else:
            return f"{hour - 12}:00 م"

    # ── إحصائيات الأسبوع ─────────────────────
    def _compute_stats(self, schedule: list, exercises: list) -> dict:
        total_sessions  = sum(1 for s in schedule if s.slot_type in ["home_exercise", "video_session"])
        total_rest      = sum(1 for s in schedule if s.slot_type == "rest")
        video_sessions  = sum(1 for s in schedule if s.slot_type == "video_session")
        total_time_mins = sum(s.duration_minutes for s in schedule)
        total_exercises = len(exercises)
        avg_difficulty  = (
            sum(ex.get("difficulty", 1) for ex in exercises) / total_exercises
            if total_exercises > 0 else 1
        )

        return {
            "total_sessions": total_sessions,
            "video_sessions": video_sessions,
            "home_sessions": total_sessions - video_sessions,
            "rest_days": total_rest,
            "total_weekly_minutes": total_time_mins,
            "total_exercises": total_exercises,
            "avg_difficulty": round(avg_difficulty, 1),
        }

    # ── تحويل Slot لـ dict ────────────────────
    def _slot_to_dict(self, slot: ScheduleSlot) -> dict:
        return {
            "day": slot.day_name,
            "day_index": slot.day_index,
            "date": getattr(slot, "date", ""),
            "type": slot.slot_type,
            "time": slot.time,
            "exercises": [
                {
                    "id": ex.get("id"),
                    "name": ex.get("name"),
                    "prescription": ex.get("final_prescription", ""),
                    "duration_minutes": ex.get("duration_minutes", 0),
                }
                for ex in slot.exercises
            ],
            "duration_minutes": slot.duration_minutes,
            "notes": slot.notes,
            "is_bookable": slot.is_bookable,
        }


# ──────────────────────────────────────────────
# تنسيق الجدول للعرض
# ──────────────────────────────────────────────
def format_schedule_text(schedule_result: dict) -> str:
    """يطبع الجدول بشكل مقروء في الـ terminal"""
    lines = []
    lines.append("=" * 55)
    lines.append("       الجدول الأسبوعي — PhysioAI")
    lines.append("=" * 55)

    icons = {"home_exercise": "🏠", "video_session": "📹", "rest": "😴"}
    labels = {"home_exercise": "تمرين منزلي", "video_session": "جلسة فيديو كول", "rest": "راحة"}

    for day in schedule_result["week_schedule"]:
        icon  = icons.get(day["type"], "•")
        label = labels.get(day["type"], day["type"])
        lines.append(f"\n{icon} {day['day']} ({day['date']})")
        lines.append(f"   النوع: {label}")
        if day["exercises"]:
            lines.append(f"   التمارين ({len(day['exercises'])}):")
            for ex in day["exercises"]:
                lines.append(f"     - {ex['name']} | {ex['prescription']}")
        if day["notes"]:
            lines.append(f"   ملاحظة: {day['notes']}")

    stats = schedule_result["weekly_stats"]
    lines.append("\n" + "─" * 55)
    lines.append("📊 إحصائيات الأسبوع:")
    lines.append(f"   جلسات: {stats['total_sessions']} (فيديو: {stats['video_sessions']} | منزلية: {stats['home_sessions']})")
    lines.append(f"   أيام راحة: {stats['rest_days']}")
    lines.append(f"   وقت أسبوعي: ~{stats['total_weekly_minutes']} دقيقة")

    lines.append("\n📅 أوقات الفيديو كول المتاحة:")
    for slot in schedule_result["video_slots"][:6]:
        marker = " ← موصى به" if slot["is_video_day"] else ""
        lines.append(f"   {slot['day']} {slot['time_display']} — {slot['doctor']}{marker}")

    return "\n".join(lines)
