"""Agrégats profil étudiant — progression, streak, activité hebdo."""

from __future__ import annotations

from collections import defaultdict
from datetime import timedelta

from django.db.models import Count, Sum
from django.db.models.functions import TruncDate
from django.utils import timezone

from academic.models import Course
from academic.serializers import resolve_course_cover_url

from .models import CourseLesson, LessonProgress, StudentLearningEvent


def _week_start(now):
    local = timezone.localtime(now)
    return (local - timedelta(days=local.weekday())).replace(
        hour=0, minute=0, second=0, microsecond=0
    )


def _streak_days(user, now) -> int:
    """Jours consécutifs (jusqu’à hier ou aujourd’hui) avec au moins une activité."""
    days = set(
        StudentLearningEvent.objects.filter(student=user)
        .annotate(d=TruncDate('created_at'))
        .values_list('d', flat=True)
        .distinct()
    )
    days |= set(
        LessonProgress.objects.filter(user=user)
        .annotate(d=TruncDate('updated_at'))
        .values_list('d', flat=True)
        .distinct()
    )
    if not days:
        return 0
    today = timezone.localtime(now).date()
    streak = 0
    cursor = today
    # Si pas d’activité aujourd’hui, commencer hier (streak encore valide)
    if cursor not in days:
        cursor = today - timedelta(days=1)
    while cursor in days:
        streak += 1
        cursor -= timedelta(days=1)
    return streak


def _course_progress_map(user) -> dict[int, dict]:
    """course_id -> {completed, touched, last_lesson_id, last_updated}."""
    rows = (
        LessonProgress.objects.filter(user=user)
        .select_related('lesson', 'lesson__module')
        .order_by('-updated_at')
    )
    by_course: dict[int, dict] = {}
    for row in rows:
        cid = row.lesson.module.course_id
        bucket = by_course.setdefault(
            cid,
            {
                'completed': 0,
                'touched': 0,
                'last_lesson_id': None,
                'last_updated': None,
                'position_sum': 0,
            },
        )
        bucket['touched'] += 1
        bucket['position_sum'] += int(row.position_seconds or 0)
        if row.completed:
            bucket['completed'] += 1
        if bucket['last_lesson_id'] is None:
            bucket['last_lesson_id'] = row.lesson_id
            bucket['last_updated'] = row.updated_at
    return by_course


def build_student_dashboard(user, request=None) -> dict:
    now = timezone.now()
    week_start = _week_start(now)
    by_course = _course_progress_map(user)
    course_ids = list(by_course.keys())

    # Totaux leçons par cours
    lesson_totals = {}
    if course_ids:
        for row in (
            CourseLesson.objects.filter(
                module__course_id__in=course_ids,
                is_published=True,
            )
            .values('module__course_id')
            .annotate(n=Count('id'))
        ):
            lesson_totals[row['module__course_id']] = row['n']

    courses_qs = (
        Course.objects.filter(id__in=course_ids)
        .select_related(
            'department',
            'department__faculty',
            'department__faculty__university',
        )
        .prefetch_related('domains')
    )
    courses_by_id = {c.id: c for c in courses_qs}

    courses_out = []
    completed_courses = 0
    progress_sum = 0
    for cid, bucket in by_course.items():
        course = courses_by_id.get(cid)
        if not course:
            continue
        total = max(1, lesson_totals.get(cid, bucket['touched']))
        done = bucket['completed']
        pct = min(100, round(100 * done / total))
        status = 'completed' if done >= total and total > 0 else 'in_progress'
        if status == 'completed':
            completed_courses += 1
        progress_sum += pct

        next_lesson = None
        last_lesson = None
        lessons = list(
            CourseLesson.objects.filter(
                module__course_id=cid,
                is_published=True,
            )
            .select_related('module')
            .order_by('module__order', 'order', 'id')
        )
        done_ids = set(
            LessonProgress.objects.filter(
                user=user,
                lesson__module__course_id=cid,
                completed=True,
            ).values_list('lesson_id', flat=True)
        )
        for les in lessons:
            if les.id == bucket['last_lesson_id']:
                last_lesson = {
                    'id': les.id,
                    'title': les.title,
                    'module_title': les.module.title,
                }
            if next_lesson is None and les.id not in done_ids:
                next_lesson = {
                    'id': les.id,
                    'title': les.title,
                    'module_title': les.module.title,
                }

        courses_out.append(
            {
                'id': course.id,
                'title': course.title,
                'code': course.code,
                'cover_url': resolve_course_cover_url(course, request),
                'progress_pct': pct,
                'lessons_completed': done,
                'lessons_total': total,
                'status': status,
                'last_activity_at': bucket['last_updated'],
                'last_lesson': last_lesson,
                'next_lesson': next_lesson,
                'continue_url': f'/apprendre/#/cours/{course.id}',
            }
        )

    courses_out.sort(
        key=lambda c: (c['status'] != 'in_progress', -(c['progress_pct'] or 0))
    )

    lessons_completed = (
        LessonProgress.objects.filter(user=user, completed=True).count()
    )
    learning_seconds = (
        LessonProgress.objects.filter(user=user).aggregate(s=Sum('position_seconds'))[
            's'
        ]
        or 0
    )
    learning_minutes = max(0, int(learning_seconds // 60))

    lessons_this_week = LessonProgress.objects.filter(
        user=user,
        completed=True,
        updated_at__gte=week_start,
    ).count()
    events_this_week = StudentLearningEvent.objects.filter(
        student=user,
        created_at__gte=week_start,
    ).count()

    # Activité 7 derniers jours
    day_map = defaultdict(lambda: {'minutes': 0, 'lessons': 0, 'events': 0})
    for i in range(6, -1, -1):
        d = (timezone.localtime(now) - timedelta(days=i)).date()
        day_map[d]  # ensure key

    for row in (
        LessonProgress.objects.filter(
            user=user,
            updated_at__gte=now - timedelta(days=7),
        )
        .annotate(d=TruncDate('updated_at'))
        .values('d')
        .annotate(secs=Sum('position_seconds'), n=Count('id'))
    ):
        if row['d']:
            day_map[row['d']]['minutes'] += int((row['secs'] or 0) // 60)
            day_map[row['d']]['lessons'] += int(row['n'] or 0)

    for row in (
        StudentLearningEvent.objects.filter(
            student=user,
            created_at__gte=now - timedelta(days=7),
        )
        .annotate(d=TruncDate('created_at'))
        .values('d')
        .annotate(n=Count('id'))
    ):
        if row['d']:
            day_map[row['d']]['events'] += int(row['n'] or 0)

    weekly_activity = []
    for i in range(6, -1, -1):
        d = (timezone.localtime(now) - timedelta(days=i)).date()
        cell = day_map[d]
        weekly_activity.append(
            {
                'date': d.isoformat(),
                'label': d.strftime('%a'),
                'minutes': cell['minutes'],
                'lessons': cell['lessons'],
                'events': cell['events'],
            }
        )

    active_days_week = sum(
        1 for d in weekly_activity if d['minutes'] or d['lessons'] or d['events']
    )
    streak = _streak_days(user, now)
    started = len(courses_out)
    learning_rate_pct = round(progress_sum / started) if started else 0

    # Achievements type Khan / Coursera
    achievements = [
        {
            'id': 'first_open',
            'label': 'Premier cours ouvert',
            'hint': 'Ouvre un cours pour démarrer',
            'earned': started >= 1,
        },
        {
            'id': 'first_lesson',
            'label': 'Première leçon terminée',
            'hint': 'Termine une leçon',
            'earned': lessons_completed >= 1,
        },
        {
            'id': 'lessons_5',
            'label': '5 leçons validées',
            'hint': 'Continue à ce rythme',
            'earned': lessons_completed >= 5,
        },
        {
            'id': 'streak_3',
            'label': 'Série de 3 jours',
            'hint': 'Apprends 3 jours d’affilée',
            'earned': streak >= 3,
        },
        {
            'id': 'course_done',
            'label': 'Cours terminé',
            'hint': 'Finis un parcours complet',
            'earned': completed_courses >= 1,
        },
        {
            'id': 'week_active',
            'label': 'Semaine active',
            'hint': '3 jours actifs cette semaine',
            'earned': active_days_week >= 3,
        },
    ]

    recent = []
    for ev in (
        StudentLearningEvent.objects.filter(student=user)
        .select_related('course', 'lesson')
        .order_by('-created_at')[:12]
    ):
        recent.append(
            {
                'id': ev.id,
                'type': ev.event_type,
                'type_label': ev.get_event_type_display(),
                'course_id': ev.course_id,
                'course_title': ev.course.title if ev.course_id else '',
                'lesson_title': ev.lesson.title if ev.lesson_id else '',
                'created_at': ev.created_at,
            }
        )

    next_up = None
    for c in courses_out:
        if c['status'] == 'in_progress' and c.get('next_lesson'):
            next_up = {
                'course_id': c['id'],
                'course_title': c['title'],
                'lesson': c['next_lesson'],
                'continue_url': c['continue_url'],
                'progress_pct': c['progress_pct'],
            }
            break

    return {
        'stats': {
            'courses_started': started,
            'courses_completed': completed_courses,
            'lessons_completed': lessons_completed,
            'learning_minutes': learning_minutes,
            'learning_rate_pct': learning_rate_pct,
            'streak_days': streak,
            'active_days_this_week': active_days_week,
            'lessons_this_week': lessons_this_week,
            'events_this_week': events_this_week,
        },
        'weekly_activity': weekly_activity,
        'courses': courses_out,
        'recent_activity': recent,
        'achievements': achievements,
        'next_up': next_up,
    }
