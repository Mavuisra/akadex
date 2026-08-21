"""Permission partagée : rôle admin app OU staff Django."""

from rest_framework.permissions import BasePermission


class IsAkadexAdmin(BasePermission):
    """Admin métier (role=admin) ou is_staff / superuser."""

    message = 'Réservé aux administrateurs Akadex.'

    def has_permission(self, request, view):
        user = request.user
        if not user or not user.is_authenticated:
            return False
        if user.is_staff or user.is_superuser:
            return True
        return getattr(user, 'role', '') == 'admin'
