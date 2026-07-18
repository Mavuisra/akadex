"""
Module Learning — architecture évolutive pour les cours professeurs.

Conçu pour accueillir plus tard sans refonte :
- live / visioconférence (Lesson.content_type = live)
- évaluations / quiz
- certificats
- devoirs
- hors-ligne (progress + cached URLs)
"""

from django.conf import settings
from django.db import models


class CourseModule(models.Model):
    """Chapitre / module d’un cours."""

    course = models.ForeignKey(
        'academic.Course',
        on_delete=models.CASCADE,
        related_name='modules',
    )
    title = models.CharField(max_length=255)
    description = models.TextField(blank=True)
    order = models.PositiveSmallIntegerField(default=0)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ['order', 'id']
        unique_together = ('course', 'order')

    def __str__(self):
        return f'{self.course.code} · {self.title}'


class LessonContentType(models.TextChoices):
    VIDEO = 'video', 'Vidéo'
    PDF = 'pdf', 'PDF'
    SLIDES = 'slides', 'Diapositives'
    TP = 'tp', 'TP'
    TD = 'td', 'TD'
    EXERCISE = 'exercise', 'Exercice'
    EXAM = 'exam', 'Examen'
    SOLUTION = 'solution', 'Corrigé'
    BOOK = 'book', 'Livre'
    LINK = 'link', 'Lien'
    TEXT = 'text', 'Texte'
    # Extensions futures (stubs)
    LIVE = 'live', 'Cours en direct'
    QUIZ = 'quiz', 'Évaluation'
    ASSIGNMENT = 'assignment', 'Devoir'


class CourseLesson(models.Model):
    """Leçon / ressource dans un module."""

    module = models.ForeignKey(
        CourseModule,
        on_delete=models.CASCADE,
        related_name='lessons',
    )
    title = models.CharField(max_length=255)
    description = models.TextField(blank=True)
    content_type = models.CharField(
        max_length=20,
        choices=LessonContentType.choices,
        default=LessonContentType.VIDEO,
    )
    order = models.PositiveSmallIntegerField(default=0)
    video_url = models.URLField(blank=True)
    file = models.FileField(upload_to='lessons/', blank=True, null=True)
    external_url = models.URLField(blank=True)
    duration_seconds = models.PositiveIntegerField(default=0)
    subtitles_url = models.URLField(
        blank=True,
        help_text='Piste de sous-titres (VTT/SRT) — prévu pour lecture.',
    )
    document = models.ForeignKey(
        'academic.Document',
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name='lessons',
    )
    is_published = models.BooleanField(default=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        ordering = ['order', 'id']

    def __str__(self):
        return self.title

    @property
    def course(self):
        return self.module.course


class LessonProgress(models.Model):
    """Reprise de lecture / progression (base hors-ligne future)."""

    user = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name='lesson_progress',
    )
    lesson = models.ForeignKey(
        CourseLesson,
        on_delete=models.CASCADE,
        related_name='progress_entries',
    )
    position_seconds = models.PositiveIntegerField(default=0)
    completed = models.BooleanField(default=False)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        unique_together = ('user', 'lesson')
        ordering = ['-updated_at']


class CourseComment(models.Model):
    """Questions / commentaires sur un cours (fil threadable)."""

    course = models.ForeignKey(
        'academic.Course',
        on_delete=models.CASCADE,
        related_name='course_comments',
    )
    lesson = models.ForeignKey(
        CourseLesson,
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name='comments',
    )
    author = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name='course_comments',
    )
    content = models.TextField()
    parent = models.ForeignKey(
        'self',
        on_delete=models.CASCADE,
        null=True,
        blank=True,
        related_name='replies',
    )
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ['created_at']
