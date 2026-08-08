"""Stockage média compatible Supabase S3 (bucket public ou privé)."""

from django.conf import settings
from storages.backends.s3boto3 import S3Boto3Storage


class SupabaseMediaStorage(S3Boto3Storage):
    """Supabase Storage via protocole S3."""

    default_acl = None
    file_overwrite = False

    def url(self, name, parameters=None, expire=None, http_method=None):
        # Bucket privé : URL signée temporaire (Flutter peut l’ouvrir sans header JWT).
        if getattr(settings, 'AWS_QUERYSTRING_AUTH', False):
            ttl = expire or getattr(settings, 'AWS_QUERYSTRING_EXPIRE', 3600)
            return super().url(name, parameters, ttl, http_method)

        # Bucket public : URL Supabase Storage permanente.
        base = settings.MEDIA_URL.rstrip('/')
        path = name.lstrip('/')
        return f'{base}/{path}'
