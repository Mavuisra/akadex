import uuid

from django.conf import settings
from django.db import models


class CourseDeposit(models.Model):
    """Dépôt PawaPay initié depuis l’app (achat de cours)."""

    class Status(models.TextChoices):
        PENDING = 'PENDING', 'En attente'
        ACCEPTED = 'ACCEPTED', 'Accepté'
        COMPLETED = 'COMPLETED', 'Terminé'
        FAILED = 'FAILED', 'Échoué'
        REJECTED = 'REJECTED', 'Rejeté'

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    deposit_id = models.UUIDField(unique=True, db_index=True)
    user = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name='course_deposits',
    )
    amount = models.DecimalField(max_digits=12, decimal_places=2)
    currency = models.CharField(max_length=3, default='USD')
    phone = models.CharField(max_length=20)
    provider = models.CharField(max_length=32)
    correspondent = models.CharField(max_length=64, blank=True)
    status = models.CharField(
        max_length=16,
        choices=Status.choices,
        default=Status.PENDING,
        db_index=True,
    )
    course_ids = models.JSONField(default=list, blank=True)
    pawapay_response = models.JSONField(default=dict, blank=True)
    failure_message = models.CharField(max_length=500, blank=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        ordering = ['-created_at']

    def __str__(self) -> str:
        return f'{self.deposit_id} · {self.status} · {self.amount} {self.currency}'
