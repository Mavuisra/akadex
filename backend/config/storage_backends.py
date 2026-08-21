"""Stockage média compatible Supabase S3 (bucket public ou privé).

Tous les FileField / ImageField Django passent par STORAGES['default']
→ ce backend quand USE_S3_MEDIA est actif.
"""

from django.conf import settings
from storages.backends.s3boto3 import S3Boto3Storage


class SupabaseMediaStorage(S3Boto3Storage):
    """Supabase Storage via protocole S3."""

    default_acl = None
    file_overwrite = False
    # Préfixes utilisés dans le projet (tous → même bucket) :
    # avatars/ covers/ course_covers/ documents/ lessons/
    # posts/ posts/images/ chat/ universities/

    def url(self, name, parameters=None, expire=None, http_method=None):
        # Bucket privé : URL signée temporaire (Flutter / web sans JWT Storage).
        if getattr(settings, 'AWS_QUERYSTRING_AUTH', False):
            ttl = expire or getattr(settings, 'AWS_QUERYSTRING_EXPIRE', 3600)
            return super().url(name, parameters, ttl, http_method)

        # Bucket public : URL Supabase Storage permanente.
        base = settings.MEDIA_URL.rstrip('/')
        path = name.lstrip('/')
        return f'{base}/{path}'
