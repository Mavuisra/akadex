from django.conf import settings
from django.db import models


class PostKind(models.TextChoices):
    DISCUSSION = 'discussion', 'Discussion'
    QUESTION = 'question', 'Question'
    ALUMNI_ADVICE = 'alumni_advice', 'Conseil académique'
    ALUMNI_PATH = 'alumni_path', 'Parcours universitaire'
    ALUMNI_CAREER = 'alumni_career', 'Parcours professionnel'
    ALUMNI_TFC = 'alumni_tfc', 'Stages / mémoire / TFC'
    ALUMNI_VIDEO = 'alumni_video', 'Vidéo de conseil'


class Post(models.Model):
    author = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name='posts',
    )
    department = models.ForeignKey(
        'academic.Department',
        on_delete=models.CASCADE,
        related_name='posts',
        null=True,
        blank=True,
    )
    title = models.CharField(max_length=255)
    content = models.TextField()
    kind = models.CharField(
        max_length=32,
        choices=PostKind.choices,
        default=PostKind.DISCUSSION,
        db_index=True,
    )
    video_url = models.URLField(blank=True)
    tags = models.JSONField(default=list, blank=True)
    likes_count = models.PositiveIntegerField(default=0)
    comments_count = models.PositiveIntegerField(default=0)
    is_approved = models.BooleanField(default=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        ordering = ['-created_at']

    def __str__(self):
        return self.title

    @property
    def is_alumni_content(self):
        return self.kind.startswith('alumni_')


class PostComment(models.Model):
    post = models.ForeignKey(
        Post,
        on_delete=models.CASCADE,
        related_name='comments',
    )
    author = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name='post_comments',
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


class PostLike(models.Model):
    post = models.ForeignKey(
        Post,
        on_delete=models.CASCADE,
        related_name='likes',
    )
    user = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name='post_likes',
    )
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        unique_together = ('post', 'user')


class AlumniFollow(models.Model):
    """Étudiant suit un alumni (mentorat)."""

    follower = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name='alumni_following',
    )
    alumni = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name='alumni_followers',
    )
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        unique_together = ('follower', 'alumni')
        ordering = ['-created_at']


class SavedPost(models.Model):
    """Enregistrement de contenus utiles (alumni / communauté)."""

    user = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name='saved_posts',
    )
    post = models.ForeignKey(
        Post,
        on_delete=models.CASCADE,
        related_name='saves',
    )
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        unique_together = ('user', 'post')
        ordering = ['-created_at']
