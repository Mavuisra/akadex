"""Permission partagée : rôle admin app OU staff Django."""

from rest_framework.permissions import BasePermission


def user_is_akadex_admin(user) -> bool:
    if not user or not getattr(user, 'is_authenticated', False):
        return False
    if user.is_staff or user.is_superuser:
        return True
    return getattr(user, 'role', '') == 'admin'


class IsAkadexAdmin(BasePermission):
    """Admin métier (role=admin) ou is_staff / superuser."""

    message = 'Réservé aux administrateurs Akadex.'

    def has_permission(self, request, view):
        return user_is_akadex_admin(request.user)
