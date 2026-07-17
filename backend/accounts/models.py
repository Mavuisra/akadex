from django.contrib.auth.models import AbstractUser
from django.db import models


class User(AbstractUser):
    class Role(models.TextChoices):
        STUDENT = 'student', 'Étudiant'
        ALUMNI = 'alumni', 'Alumni'
        TEACHER = 'teacher', 'Enseignant'
        ASSISTANT = 'assistant', 'Assistant'
        REP = 'rep', 'Représentant'
        ASSOCIATION = 'association', 'Association'
        LIBRARY = 'library', 'Bibliothèque'
        ADMIN = 'admin', 'Administration'

    email = models.EmailField('email', unique=True)
    phone = models.CharField(max_length=32, blank=True)
    role = models.CharField(
        max_length=20,
        choices=Role.choices,
        default=Role.STUDENT,
    )
    avatar = models.ImageField(upload_to='avatars/', blank=True, null=True)
    bio = models.TextField(blank=True)
    university = models.ForeignKey(
        'academic.University',
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name='users',
    )
    faculty = models.ForeignKey(
        'academic.Faculty',
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name='users',
    )
    department = models.ForeignKey(
        'academic.Department',
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name='users',
    )
    promotion = models.ForeignKey(
        'academic.Promotion',
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name='users',
    )
    level = models.CharField(max_length=64, blank=True)
    reputation = models.PositiveIntegerField(default=0)
    contributions_count = models.PositiveIntegerField(default=0)
    badges = models.JSONField(default=list, blank=True)

    USERNAME_FIELD = 'email'
    REQUIRED_FIELDS = ['username']

    class Meta:
        ordering = ['-date_joined']

    def __str__(self):
        return self.get_full_name() or self.email
