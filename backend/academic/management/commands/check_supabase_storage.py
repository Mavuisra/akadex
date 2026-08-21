"""Vérifie que le stockage média pointe bien vers Supabase."""

from django.conf import settings
from django.core.files.base import ContentFile
from django.core.files.storage import default_storage
from django.core.management.base import BaseCommand, CommandError


class Command(BaseCommand):
    help = 'Teste l’écriture / lecture sur le storage média (Supabase S3 ou local).'

    def handle(self, *args, **options):
        backend = settings.STORAGES['default']['BACKEND']
        use_s3 = getattr(settings, 'USE_S3_MEDIA', False)
        self.stdout.write(f'Backend : {backend}')
        self.stdout.write(f'USE_S3_MEDIA : {use_s3}')
        self.stdout.write(f'MEDIA_URL : {settings.MEDIA_URL}')

        if not use_s3:
            self.stdout.write(
                self.style.WARNING(
                    'Supabase désactivé — les fichiers vont sur le disque local. '
                    'Ajoute AWS_ACCESS_KEY_ID / AWS_SECRET_ACCESS_KEY dans .env '
                    'puis USE_S3_MEDIA=True.'
                )
            )
            return

        key = 'akadex-storage-check/ping.txt'
        payload = b'akadex-supabase-ok'
        try:
            if default_storage.exists(key):
                default_storage.delete(key)
            saved = default_storage.save(key, ContentFile(payload))
            url = default_storage.url(saved)
            exists = default_storage.exists(saved)
            default_storage.delete(saved)
        except Exception as exc:
            raise CommandError(f'Échec Supabase Storage : {exc}') from exc

        if not exists:
            raise CommandError('Fichier écrit mais introuvable juste après.')

        self.stdout.write(self.style.SUCCESS('Supabase Storage OK'))
        self.stdout.write(f'URL exemple : {url[:120]}…')
