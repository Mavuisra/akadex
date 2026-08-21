"""Enregistrement d’événements d’apprentissage (source : actions Apprendre)."""

from __future__ import annotations

from datetime import timedelta

from django.db.models import Q
from django.utils import timezone

from .models import StudentLearningEvent

# Événements assez importants pour notifier l’enseignant (pas la progression fine).
NOTIFY_EVENT_TYPES = frozenset({
    StudentLearningEvent.EventType.COURSE_OPENED,
    StudentLearningEvent.EventType.LESSON_COMPLETED,
    StudentLearningEvent.EventType.VIDEO_COMPLETED,
    StudentLearningEvent.EventType.COURSE_COMMENTED,
})


def resolve_course_teacher_id(course) -> int | None:
    if getattr(course, 'submitted_by_id', None):
        return course.submitted_by_id
    teacher = course.teachers.order_by('id').first()
    return teacher.id if teacher else None


def _notify_teacher(event: StudentLearningEvent) -> None:
    """Notification in-app (→ push via signal) pour les jalons pédagogiques."""
    if event.event_type not in NOTIFY_EVENT_TYPES:
        return
    teacher_id = event.teacher_id
    if not teacher_id or teacher_id == event.student_id:
        return

    # Nouveau participant : seulement la 1ʳᵉ ouverture de ce cours.
    if event.event_type == StudentLearningEvent.EventType.COURSE_OPENED:
        prior = StudentLearningEvent.objects.filter(
            student_id=event.student_id,
            course_id=event.course_id,
            event_type=StudentLearningEvent.EventType.COURSE_OPENED,
        ).exclude(pk=event.pk).exists()
        if prior:
            return

    # Évite le spam vidéo+leçon terminées en même temps.
    if event.event_type == StudentLearningEvent.EventType.VIDEO_COMPLETED:
        return

    from accounts.models import AppNotification

    student_name = event.student.get_full_name() or event.student.email
    course_title = event.course.title if event.course_id else 'votre cours'
    lesson_title = event.lesson.title if event.lesson_id else ''

    if event.event_type == StudentLearningEvent.EventType.COURSE_OPENED:
        title = 'Nouvel étudiant actif'
        message = f'{student_name} a commencé à consulter « {course_title} ».'
    elif event.event_type == StudentLearningEvent.EventType.LESSON_COMPLETED:
        title = 'Leçon terminée'
        message = (
            f'{student_name} a terminé « {lesson_title or "une leçon"} » '
            f'dans {course_title}.'
        )
    elif event.event_type == StudentLearningEvent.EventType.COURSE_COMMENTED:
        title = 'Nouveau commentaire'
        message = f'{student_name} a commenté « {course_title} ».'
    else:
        title = 'Activité étudiant'
        message = f'{student_name} — {event.event_type} — {course_title}'

    AppNotification.objects.create(
        user_id=teacher_id,
        kind=AppNotification.Kind.GENERAL,
        title=title[:255],
        message=message,
    )


def record_learning_event(
    *,
    student,
    course,
    event_type: str,
    lesson=None,
    module=None,
    event_data: dict | None = None,
    throttle_seconds: int = 0,
    notify: bool = True,
) -> StudentLearningEvent | None:
    """Persiste un événement ; ignore si throttle (anti-spam progression)."""
    from .visits import is_real_learner

    if student is None or not getattr(student, 'is_authenticated', False):
        return None
    if course is None:
        return None
    # Pas d’événements « pédagogiques » pour enseignants / propriétaires.
    if not is_real_learner(student, course):
        return None

    data = dict(event_data or {})
    if throttle_seconds > 0:
        since = timezone.now() - timedelta(seconds=throttle_seconds)
        q = Q(
            student=student,
            course=course,
            event_type=event_type,
            created_at__gte=since,
        )
        if lesson is not None:
            q &= Q(lesson=lesson)
        if StudentLearningEvent.objects.filter(q).exists():
            return None

    module_obj = module
    if module_obj is None and lesson is not None:
        module_obj = getattr(lesson, 'module', None)

    event = StudentLearningEvent.objects.create(
        student=student,
        course=course,
        module=module_obj,
        lesson=lesson,
        teacher_id=resolve_course_teacher_id(course),
        event_type=event_type,
        event_data=data,
    )
    if notify:
        try:
            _notify_teacher(event)
        except Exception:
            # Le tracking ne doit jamais casser l’action étudiant.
            pass
    return event


EVENT_LABELS = {
    StudentLearningEvent.EventType.COURSE_OPENED: 'a ouvert un cours',
    StudentLearningEvent.EventType.CONTENT_OPENED: 'a ouvert un contenu',
    StudentLearningEvent.EventType.VIDEO_STARTED: 'a démarré une vidéo',
    StudentLearningEvent.EventType.VIDEO_PROGRESS: 'progresse sur une vidéo',
    StudentLearningEvent.EventType.VIDEO_COMPLETED: 'a terminé une vidéo',
    StudentLearningEvent.EventType.LESSON_COMPLETED: 'a terminé une leçon',
    StudentLearningEvent.EventType.DOCUMENT_OPENED: 'a ouvert un document',
    StudentLearningEvent.EventType.COURSE_COMMENTED: 'a commenté un cours',
}


def humanize_event(event: StudentLearningEvent) -> dict:
    student_name = event.student.get_full_name() or event.student.email
    verb = EVENT_LABELS.get(event.event_type, event.event_type)
    lesson_title = event.lesson.title if event.lesson_id else ''
    module_title = event.module.title if event.module_id else ''
    course_title = event.course.title if event.course_id else ''
    content = lesson_title or module_title or '—'
    score = (event.event_data or {}).get('score')
    position = (event.event_data or {}).get('position_seconds')
    extra = ''
    if score is not None:
        extra = f' · score {score}%'
    elif position is not None and event.event_type == 'video_progress':
        extra = f' · {int(position)} s'
    return {
        'id': event.id,
        'event_type': event.event_type,
        'student_id': event.student_id,
        'student_name': student_name,
        'student_email': event.student.email,
        'course_id': event.course_id,
        'course_title': course_title,
        'module_id': event.module_id,
        'module_title': module_title,
        'lesson_id': event.lesson_id,
        'lesson_title': lesson_title,
        'content_label': content,
        'title': f'{student_name} {verb}',
        'message': f'« {content} » — {course_title}{extra}'.strip(' —'),
        'event_data': event.event_data or {},
        'created_at': event.created_at.isoformat() if event.created_at else None,
    }
