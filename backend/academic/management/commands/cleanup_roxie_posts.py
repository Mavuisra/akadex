"""Conserve une seule publication sur le profil Roxie (Rose) Ntumba."""

from django.contrib.auth import get_user_model
from django.core.management.base import BaseCommand

from community.models import Post

User = get_user_model()

KEEP_TITLE = 'Roxie Ntumba — Comment bien choisir sa faculté'
ROXIE_EMAIL = 'roxie.ntumba@alumni.unikin.ac.cd'


class Command(BaseCommand):
    help = 'Nettoie le profil Roxie : une seule publication conservée.'

    def handle(self, *args, **options):
        roxie = User.objects.filter(email=ROXIE_EMAIL).first()
        if not roxie:
            # fallback prénom
            roxie = User.objects.filter(
                first_name__icontains='roxie'
            ).first() or User.objects.filter(
                first_name__icontains='rose'
            ).first()
        if not roxie:
            self.stdout.write(self.style.WARNING('Profil Roxie/Rose introuvable.'))
            return

        qs = Post.objects.filter(author=roxie)
        keep = qs.filter(title__icontains='choisir sa faculté').order_by(
            '-created_at'
        ).first()
        if keep is None:
            keep = qs.filter(video_url__icontains='tiktok').order_by(
                '-created_at'
            ).first()
        if keep is None:
            keep = qs.order_by('-created_at').first()

        if keep is None:
            self.stdout.write('Aucune publication à nettoyer.')
            return

        deleted, _ = qs.exclude(pk=keep.pk).delete()
        self.stdout.write(
            self.style.SUCCESS(
                f'Roxie ({roxie.email}) : conservé « {keep.title} » '
                f'— {deleted} publication(s) supprimée(s).'
            )
        )
