from django.conf import settings
from django.db import models


class University(models.Model):
    name = models.CharField(max_length=255)
    slug = models.SlugField(unique=True)
    country = models.CharField(max_length=100, default='RD Congo')
    city = models.CharField(max_length=100, blank=True)
    logo = models.ImageField(upload_to='universities/', blank=True, null=True)
    primary_color = models.CharField(max_length=7, default='#0B5C56')
    accent_color = models.CharField(max_length=7, default='#E09B2D')
    description = models.TextField(blank=True)
    is_active = models.BooleanField(default=True)
    is_verified = models.BooleanField(
        default=True,
        help_text='False = suggestion utilisateur en attente de validation.',
    )
    is_user_suggested = models.BooleanField(default=False)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        verbose_name_plural = 'universities'
        ordering = ['name']

    def __str__(self):
        return self.name


class Campus(models.Model):
    university = models.ForeignKey(
        University,
        on_delete=models.CASCADE,
        related_name='campuses',
    )
    name = models.CharField(max_length=255)
    address = models.CharField(max_length=255, blank=True)

    class Meta:
        verbose_name_plural = 'campuses'
        unique_together = ('university', 'name')
        ordering = ['name']

    def __str__(self):
        return f'{self.name} ({self.university})'


class Faculty(models.Model):
    university = models.ForeignKey(
        University,
        on_delete=models.CASCADE,
        related_name='faculties',
    )
    campus = models.ForeignKey(
        Campus,
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name='faculties',
    )
    name = models.CharField(max_length=255)
    slug = models.SlugField()
    description = models.TextField(blank=True)
    is_verified = models.BooleanField(default=True)
    is_user_suggested = models.BooleanField(default=False)

    class Meta:
        verbose_name_plural = 'faculties'
        unique_together = ('university', 'slug')
        ordering = ['name']

    def __str__(self):
        return f'{self.name} — {self.university}'


class Department(models.Model):
    faculty = models.ForeignKey(
        Faculty,
        on_delete=models.CASCADE,
        related_name='departments',
    )
    name = models.CharField(max_length=255)
    slug = models.SlugField()
    description = models.TextField(blank=True)
    is_verified = models.BooleanField(default=True)
    is_user_suggested = models.BooleanField(default=False)

    class Meta:
        unique_together = ('faculty', 'slug')
        ordering = ['name']

    def __str__(self):
        return self.name

    @property
    def university(self):
        return self.faculty.university


class Promotion(models.Model):
    department = models.ForeignKey(
        Department,
        on_delete=models.CASCADE,
        related_name='promotions',
    )
    name = models.CharField(max_length=255)
    year = models.PositiveIntegerField()
    level = models.CharField(max_length=64, blank=True)
    is_verified = models.BooleanField(default=True)
    is_user_suggested = models.BooleanField(default=False)

    class Meta:
        unique_together = ('department', 'name', 'year')
        ordering = ['-year', 'name']

    def __str__(self):
        return f'{self.name} ({self.year})'


class LearningDomain(models.Model):
    """Domaine Apprendre (Informatique, Droit…) — liaison cours ↔ vidéos."""

    slug = models.SlugField(unique=True)
    name = models.CharField(max_length=120)
    description = models.TextField(blank=True)
    keywords = models.CharField(
        max_length=500,
        blank=True,
        help_text='Mots-clés séparés par des virgules',
    )
    is_active = models.BooleanField(default=True)
    order = models.PositiveSmallIntegerField(default=0)

    class Meta:
        ordering = ['order', 'name']

    def __str__(self):
        return self.name


class Course(models.Model):
    class ModerationStatus(models.TextChoices):
        PENDING = 'pending', 'En attente de validation'
        APPROVED = 'approved', 'Validé'
        CHANGES_REQUESTED = 'changes_requested', 'Modification demandée'
        REJECTED = 'rejected', 'Rejeté'

    department = models.ForeignKey(
        Department,
        on_delete=models.CASCADE,
        related_name='courses',
    )
    promotion = models.ForeignKey(
        Promotion,
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name='courses',
    )
    code = models.CharField(max_length=32)
    title = models.CharField(max_length=255)
    description = models.TextField(blank=True)
    objectives = models.TextField(blank=True)
    skills = models.TextField(blank=True)
    prerequisites = models.TextField(blank=True)
    bibliography = models.TextField(blank=True)
    credits = models.PositiveSmallIntegerField(default=0)
    semester = models.CharField(
        max_length=32,
        blank=True,
        help_text='Cycle / semestre : L1, L2, L3, Master 1, Master 2, S1, S2…',
    )
    cover_url = models.URLField(
        max_length=500,
        blank=True,
        help_text='Image de couverture (URL publique)',
    )
    level_label = models.CharField(
        max_length=32,
        blank=True,
        help_text='Débutant / Intermédiaire / Avancé',
    )
    estimated_hours = models.PositiveSmallIntegerField(
        default=0,
        help_text='Volume horaire estimé',
    )
    views = models.PositiveIntegerField(
        default=0,
        help_text='Nombre de consultations de la page cours',
    )
    teacher_name = models.CharField(
        max_length=255,
        blank=True,
        help_text='Titulaire du cours (saisie libre)',
    )
    teachers = models.ManyToManyField(
        settings.AUTH_USER_MODEL,
        blank=True,
        related_name='taught_courses',
    )
    domains = models.ManyToManyField(
        LearningDomain,
        blank=True,
        related_name='courses',
    )
    submitted_by = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name='submitted_courses',
    )
    is_approved = models.BooleanField(default=True)
    moderation_status = models.CharField(
        max_length=32,
        choices=ModerationStatus.choices,
        default=ModerationStatus.APPROVED,
        db_index=True,
    )
    moderation_note = models.TextField(blank=True)
    validated_by = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name='validated_courses',
    )
    validated_at = models.DateTimeField(null=True, blank=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        unique_together = ('department', 'code')
        ordering = ['code']

    def __str__(self):
        return f'{self.code} — {self.title}'

    @property
    def document_count(self):
        return self.documents.filter(is_approved=True).count()

    @property
    def is_pending(self):
        return self.moderation_status == self.ModerationStatus.PENDING


class CourseValidationLog(models.Model):
    class Action(models.TextChoices):
        SUBMITTED = 'submitted', 'Soumis'
        APPROVED = 'approved', 'Validé'
        CHANGES_REQUESTED = 'changes_requested', 'Modification demandée'
        REJECTED = 'rejected', 'Rejeté'

    course = models.ForeignKey(
        Course,
        on_delete=models.CASCADE,
        related_name='validation_logs',
    )
    actor = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name='course_validation_actions',
    )
    action = models.CharField(max_length=32, choices=Action.choices)
    note = models.TextField(blank=True)
    domain_slugs = models.CharField(
        max_length=500,
        blank=True,
        help_text='Domaines liés au moment de l’action (slugs CSV)',
    )
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ['-created_at']

    def __str__(self):
        return f'{self.course_id} — {self.action}'


class DocumentType(models.TextChoices):
    SUPPORT_COURS = 'support_cours', 'Support de cours'
    RESUME = 'resume', 'Résumé'
    PDF = 'pdf', 'PDF'
    WORD = 'word', 'Word'
    POWERPOINT = 'powerpoint', 'PowerPoint'
    IMAGE = 'image', 'Image'
    VIDEO = 'video', 'Vidéo'
    LIEN = 'lien', 'Lien'
    LIVRE = 'livre', 'Livre'
    TP = 'tp', 'TP'
    CORRIGE = 'corrige', 'Corrigé'
    INTERROGATION = 'interrogation', 'Interrogation'
    EXAMEN = 'examen', 'Examen'
    RAPPORT = 'rapport', 'Rapport de stage'
    PROJET = 'projet', 'Projet'
    PROJET_TUTORE = 'projet_tutore', 'Projet tuteuré'
    TFC = 'tfc', 'Travail de Fin de Cycle'
    MEMOIRE = 'memoire', 'Mémoire'
    THESE = 'these', 'Thèse'
    ARTICLE = 'article', 'Article scientifique'
    TUTORIEL = 'tutoriel', 'Tutoriel'
    FICHE_REVISION = 'fiche_revision', 'Fiche de révision'
    AUTRE = 'autre', 'Autre travail académique'


class Document(models.Model):
    title = models.CharField(max_length=255)
    description = models.TextField(blank=True)
    doc_type = models.CharField(
        max_length=32,
        choices=DocumentType.choices,
        default=DocumentType.PDF,
    )
    author = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.SET_NULL,
        null=True,
        related_name='documents',
    )
    university = models.ForeignKey(
        University,
        on_delete=models.CASCADE,
        related_name='documents',
    )
    department = models.ForeignKey(
        Department,
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name='documents',
    )
    course = models.ForeignKey(
        Course,
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name='documents',
    )
    academic_year = models.CharField(max_length=16, blank=True)
    file = models.FileField(upload_to='documents/', blank=True, null=True)
    external_url = models.URLField(blank=True)
    file_size = models.PositiveBigIntegerField(default=0)
    downloads = models.PositiveIntegerField(default=0)
    views = models.PositiveIntegerField(default=0)
    favorites_count = models.PositiveIntegerField(default=0)
    rating_avg = models.DecimalField(max_digits=3, decimal_places=2, default=0)
    rating_count = models.PositiveIntegerField(default=0)
    is_approved = models.BooleanField(default=False)
    is_featured = models.BooleanField(default=False)
    moderation_status = models.CharField(
        max_length=16,
        choices=[
            ('pending', "En cours d'examen"),
            ('approved', 'Validée'),
            ('rejected', 'Refusée'),
        ],
        default='pending',
        db_index=True,
    )
    rejection_reason = models.CharField(max_length=500, blank=True)
    points_awarded = models.PositiveIntegerField(
        default=0,
        help_text='Points déjà crédités à l’auteur après validation.',
    )
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        ordering = ['-created_at']

    def __str__(self):
        return self.title

    def save(self, *args, **kwargs):
        was_approved = False
        if self.pk:
            was_approved = (
                type(self)
                .objects.filter(pk=self.pk)
                .values_list('is_approved', flat=True)
                .first()
            ) or False
        if self.is_approved:
            self.moderation_status = 'approved'
        elif self.moderation_status != 'rejected':
            self.moderation_status = 'pending'
        super().save(*args, **kwargs)
        if self.is_approved and not was_approved:
            from academic.rewards import award_approval_points

            award_approval_points(self)

    @property
    def size_label(self):
        if not self.file_size:
            return '—'
        size = float(self.file_size)
        for unit in ('o', 'Ko', 'Mo', 'Go'):
            if size < 1024:
                return f'{size:.1f} {unit}' if unit != 'o' else f'{int(size)} {unit}'
            size /= 1024
        return f'{size:.1f} To'


class RewardCategory(models.TextChoices):
    CASH = 'cash', 'Argent / portefeuille'
    EBOOK = 'ebook', 'Livre numérique'
    BOOK = 'book', 'Livre physique'
    PREMIUM = 'premium', 'Abonnement Premium'
    TEACHER = 'teacher', 'Contenu professeurs'
    DISCOUNT = 'discount', 'Réduction partenaire'
    OTHER = 'other', 'Autre'


class RewardPrize(models.Model):
    """Récompense gagnable via la roue (points de contribution)."""

    name = models.CharField(max_length=120)
    description = models.TextField(blank=True)
    category = models.CharField(
        max_length=20,
        choices=RewardCategory.choices,
        default=RewardCategory.OTHER,
    )
    min_points = models.PositiveIntegerField(
        default=100,
        help_text='Points minimum pour accéder à la roue.',
    )
    points_cost = models.PositiveIntegerField(
        default=100,
        help_text='Points déduits à chaque tour.',
    )
    weight = models.PositiveSmallIntegerField(
        default=10,
        help_text='Poids relatif pour le tirage (plus élevé = plus fréquent).',
    )
    is_active = models.BooleanField(default=True)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ['min_points', 'name']

    def __str__(self):
        return self.name


class RewardRedemption(models.Model):
    user = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name='reward_redemptions',
    )
    prize = models.ForeignKey(
        RewardPrize,
        on_delete=models.PROTECT,
        related_name='redemptions',
    )
    points_spent = models.PositiveIntegerField()
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ['-created_at']

    def __str__(self):
        return f'{self.user} → {self.prize}'


class DocumentComment(models.Model):
    document = models.ForeignKey(
        Document,
        on_delete=models.CASCADE,
        related_name='comments',
    )
    author = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name='document_comments',
    )
    content = models.TextField()
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ['-created_at']


class Favorite(models.Model):
    user = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name='favorites',
    )
    document = models.ForeignKey(
        Document,
        on_delete=models.CASCADE,
        related_name='favorited_by',
    )
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        unique_together = ('user', 'document')
        ordering = ['-created_at']


class Announcement(models.Model):
    university = models.ForeignKey(
        University,
        on_delete=models.CASCADE,
        related_name='announcements',
    )
    title = models.CharField(max_length=255)
    body = models.TextField()
    category = models.CharField(max_length=64, default='Annonce')
    author = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name='announcements',
    )
    is_published = models.BooleanField(default=True)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ['-created_at']

    def __str__(self):
        return self.title


class CalendarEvent(models.Model):
    university = models.ForeignKey(
        University,
        on_delete=models.CASCADE,
        related_name='events',
    )
    title = models.CharField(max_length=255)
    description = models.TextField(blank=True)
    event_type = models.CharField(max_length=64, default='événement')
    starts_at = models.DateTimeField()
    ends_at = models.DateTimeField(null=True, blank=True)
    location = models.CharField(max_length=255, blank=True)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ['starts_at']

    def __str__(self):
        return self.title
