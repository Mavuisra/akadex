from django.conf import settings
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

    class Gender(models.TextChoices):
        MALE = 'M', 'Masculin'
        FEMALE = 'F', 'Féminin'
        OTHER = 'O', 'Autre'

    email = models.EmailField('email', unique=True)
    phone = models.CharField(max_length=32, blank=True)
    role = models.CharField(
        max_length=20,
        choices=Role.choices,
        default=Role.STUDENT,
    )
    # Nom congolais : first_name=prénom, last_name=nom de famille, postnom=postnom
    postnom = models.CharField(max_length=150, blank=True)
    gender = models.CharField(max_length=1, choices=Gender.choices, blank=True)
    birth_date = models.DateField(null=True, blank=True)
    matricule = models.CharField(max_length=64, blank=True)
    avatar = models.ImageField(upload_to='avatars/', blank=True, null=True)
    cover = models.ImageField(upload_to='covers/', blank=True, null=True)
    # URL externe (seed / Unsplash) quand pas d’avatar fichier.
    photo_url = models.URLField(max_length=500, blank=True)
    bio = models.TextField(blank=True)
    headline = models.CharField(max_length=255, blank=True)
    professional_domain = models.CharField(max_length=255, blank=True)
    company = models.CharField(max_length=255, blank=True)
    graduation_year = models.PositiveIntegerField(null=True, blank=True)
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
    pending_email = models.EmailField(blank=True)
    email_verification_token = models.CharField(max_length=64, blank=True)
    password_reset_token = models.CharField(max_length=64, blank=True)
    password_reset_expires = models.DateTimeField(null=True, blank=True)
    last_seen_at = models.DateTimeField(null=True, blank=True)

    USERNAME_FIELD = 'email'
    REQUIRED_FIELDS = ['username']

    class Meta:
        ordering = ['-date_joined']

    def __str__(self):
        return self.get_full_name() or self.email

    def get_full_name(self):
        parts = [self.first_name, self.postnom, self.last_name]
        return ' '.join(p for p in parts if p).strip()


class AppNotification(models.Model):
    class Kind(models.TextChoices):
        DOCUMENT_APPROVED = 'document_approved', 'Document validé'
        DOCUMENT_REJECTED = 'document_rejected', 'Document refusé'
        POST_APPROVED = 'post_approved', 'Publication validée'
        POST_REJECTED = 'post_rejected', 'Publication refusée'
        POINTS = 'points', 'Points'
        MESSAGE = 'message', 'Message'
        PAYMENT = 'payment', 'Paiement'
        GENERAL = 'general', 'Général'

    user = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name='notifications',
    )
    kind = models.CharField(
        max_length=32,
        choices=Kind.choices,
        default=Kind.GENERAL,
    )
    title = models.CharField(max_length=255)
    message = models.TextField()
    points = models.PositiveIntegerField(default=0)
    # Deep-link app (ex. /messages/chat/12, /learn)
    link = models.CharField(max_length=255, blank=True)
    is_read = models.BooleanField(default=False)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ['-created_at']

    def __str__(self):
        return f'{self.user_id}: {self.title}'


class PushDeviceToken(models.Model):
    """Token FCM enregistré par appareil pour les push notifications."""

    class Platform(models.TextChoices):
        ANDROID = 'android', 'Android'
        IOS = 'ios', 'iOS'
        UNKNOWN = 'unknown', 'Inconnu'

    user = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name='push_tokens',
    )
    token = models.CharField(max_length=512, unique=True)
    platform = models.CharField(
        max_length=16,
        choices=Platform.choices,
        default=Platform.UNKNOWN,
    )
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        ordering = ['-updated_at']

    def __str__(self):
        return f'{self.user_id} ({self.platform})'
