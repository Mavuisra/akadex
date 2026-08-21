"""Visites cours : compteur brut + HyperLogLog (visiteurs uniques réels)."""

from __future__ import annotations

from django.db.models import F

from .hll import empty_sketch, estimate, merge_register


def is_real_learner(user, course=None) -> bool:
    """
    True uniquement pour un apprenant réel (étudiant / alumni),
    jamais pour l’enseignant du cours, un admin ou un staff.
    """
    if user is None or not getattr(user, 'is_authenticated', False):
        return False
    if getattr(user, 'is_staff', False) or getattr(user, 'is_superuser', False):
        return False
    role = (getattr(user, 'role', '') or '').strip().lower()
    if role in ('teacher', 'admin', 'assistant', 'library', 'association', 'rep'):
        return False
    if course is not None:
        if getattr(course, 'submitted_by_id', None) == user.pk:
            return False
        teachers = getattr(course, 'teachers', None)
        if teachers is not None and teachers.filter(pk=user.pk).exists():
            return False
    # Étudiants / alumni (et rôles vides traités comme apprenant).
    return role in ('student', 'alumni', '')


def visitor_key_from_request(request) -> str | None:
    """Clé HLL uniquement si visiteur = apprenant authentifié."""
    user = getattr(request, 'user', None)
    if user is None or not getattr(user, 'is_authenticated', False):
        return None
    return f'u:{user.pk}'


def record_course_visit(course, request) -> tuple[int, int] | None:
    """
    Enregistre une visite réelle (étudiant).

    Ignore : anonyme, enseignant propriétaire, staff, aperçus dashboard.
    Retourne (views, unique_visitors) ou None si ignoré.
    """
    from academic.models import Course
    from learning.models import StudentLearningEvent

    user = getattr(request, 'user', None)
    if not is_real_learner(user, course):
        return None

    visitor_key = visitor_key_from_request(request)
    if not visitor_key:
        return None

    sketch = course.views_hll or bytes(empty_sketch())
    updated = bytes(merge_register(sketch, visitor_key))

    already_seen = StudentLearningEvent.objects.filter(
        student=user,
        course=course,
    ).exists()
    prev = int(course.unique_visitors or 0)
    est = estimate(updated)
    if already_seen:
        uniques = max(prev, est)
    else:
        uniques = max(prev + 1, est)

    Course.objects.filter(pk=course.pk).update(
        views=F('views') + 1,
        views_hll=updated,
        unique_visitors=uniques,
    )
    course.views = (course.views or 0) + 1
    course.views_hll = updated
    course.unique_visitors = uniques
    return course.views, uniques


def reconcile_course_from_events(course) -> dict:
    """Recalcule vues / uniques à partir des événements étudiants réels."""
    from learning.models import StudentLearningEvent

    from academic.models import Course

    qs = StudentLearningEvent.objects.filter(course=course).exclude(
        student__role__in=(
            'teacher', 'admin', 'assistant', 'library', 'association', 'rep',
        ),
    )
    if course.submitted_by_id:
        qs = qs.exclude(student_id=course.submitted_by_id)

    opened = qs.filter(
        event_type=StudentLearningEvent.EventType.COURSE_OPENED,
    ).count()
    student_ids = sorted({
        int(sid)
        for sid in qs.values_list('student_id', flat=True)
        if sid is not None
    })

    sketch = empty_sketch()
    for sid in student_ids:
        sketch = merge_register(sketch, f'u:{sid}')
    sketch_b = bytes(sketch)
    # Cardinalité exacte au recalcul ; HLL sert ensuite aux nouvelles visites.
    uniques = len(student_ids)
    views = max(opened, uniques)

    Course.objects.filter(pk=course.pk).update(
        views=views,
        views_hll=sketch_b,
        unique_visitors=uniques,
    )
    return {'views': views, 'unique_visitors': uniques, 'students': len(student_ids)}
