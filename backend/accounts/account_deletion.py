"""Suppression / anonymisation de compte (exigence App Store)."""

from django.contrib.auth import get_user_model
from django.db import transaction

from .models import AppNotification, PushDeviceToken

User = get_user_model()


@transaction.atomic
def delete_user_account(user: User) -> None:
    """Désactive le compte et efface les données personnelles identifiables.

    Les contenus académiques / messages liés peuvent rester pour l’intégrité
    référentielle, mais ne sont plus rattachés à une identité réelle.
    """
    uid = user.pk
    PushDeviceToken.objects.filter(user=user).delete()
    AppNotification.objects.filter(user=user).delete()

    if user.avatar:
        user.avatar.delete(save=False)
    if user.cover:
        user.cover.delete(save=False)

    user.is_active = False
    user.email = f'deleted+{uid}@deleted.akadex.local'
    user.username = f'deleted_{uid}'
    user.first_name = 'Compte'
    user.last_name = 'supprimé'
    user.postnom = ''
    user.phone = ''
    user.gender = ''
    user.birth_date = None
    user.matricule = ''
    user.photo_url = ''
    user.bio = ''
    user.headline = ''
    user.professional_domain = ''
    user.company = ''
    user.graduation_year = None
    user.university = None
    user.faculty = None
    user.department = None
    user.promotion = None
    user.level = ''
    user.badges = []
    user.pending_email = ''
    user.email_verification_token = ''
    user.password_reset_token = ''
    user.password_reset_expires = None
    user.set_unusable_password()
    user.save()
