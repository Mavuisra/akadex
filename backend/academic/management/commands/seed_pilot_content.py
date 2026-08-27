"""
Vague B — contenu pilote pour usage réel.

Usage (staging / Render shell) :
  python manage.py seed_pilot_content

Prérequis : catalogue uni minimal (seed_demo ou seed_rdc_universities).
Si aucun département : lance seed_demo d’abord.
"""

from django.contrib.auth import get_user_model
from django.core.management import call_command
from django.core.management.base import BaseCommand

from academic.models import Department, Document, DocumentType, Faculty, University
from academic.management.commands.seed_demo import seed_learning_domains
from academic.management.commands.seed_flagship_courses import FLAGSHIP, _seed_course

User = get_user_model()

PILOT_PASSWORD = 'akadex2026'

BETA_TEACHERS = [
    {
        'email': 'beta.enseignant1@akadex.cd',
        'first_name': 'Grace',
        'last_name': 'Ilunga',
        'headline': 'Enseignante beta Akadex',
        'professional_domain': 'Informatique',
        'bio': 'Compte enseignant pilote pour tester la publication de cours.',
    },
    {
        'email': 'beta.enseignant2@akadex.cd',
        'first_name': 'Patrick',
        'last_name': 'Mbuyi',
        'headline': 'Enseignant beta Akadex',
        'professional_domain': 'Droit',
        'bio': 'Compte enseignant pilote pour tester la publication de cours.',
    },
    {
        'email': 'beta.enseignant3@akadex.cd',
        'first_name': 'Nadia',
        'last_name': 'Kabasele',
        'headline': 'Enseignante beta Akadex',
        'professional_domain': 'Médecine',
        'bio': 'Compte enseignant pilote pour tester la publication de cours.',
    },
]


class Command(BaseCommand):
    help = (
        'Seed Vague B : domaines, cours vitrine AKX, docs Ma Fac (2 facs), '
        '3 enseignants beta.'
    )

    def add_arguments(self, parser):
        parser.add_argument(
            '--password',
            default=PILOT_PASSWORD,
            help='Mot de passe des enseignants beta (défaut akadex2026).',
        )
        parser.add_argument(
            '--limit',
            type=int,
            default=6,
            help='Nombre de cours vitrine AKX (défaut 6).',
        )

    def handle(self, *args, **options):
        password = options['password']
        limit = max(1, options['limit'])

        self.stdout.write(self.style.NOTICE('1/4 Domaines Apprendre…'))
        domains = seed_learning_domains()
        self.stdout.write(self.style.SUCCESS(f'  {len(domains)} domaines OK'))

        if not Department.objects.exists():
            self.stdout.write(
                self.style.WARNING(
                    'Aucun département — exécution seed_demo (peut être long)…'
                )
            )
            call_command('seed_demo')

        self.stdout.write(self.style.NOTICE('2/4 Cours vitrine AKX…'))
        specs = FLAGSHIP[:limit]
        for spec in specs:
            _seed_course(spec, self.stdout)

        self.stdout.write(self.style.NOTICE('3/4 Docs Ma Fac (Sciences + Droit)…'))
        n_docs = self._seed_ma_fac_docs()
        self.stdout.write(self.style.SUCCESS(f'  {n_docs} documents OK'))

        self.stdout.write(self.style.NOTICE('4/4 Enseignants beta…'))
        uni = University.objects.filter(slug='unikin').first()
        if uni is None:
            uni = University.objects.first()
        for spec in BETA_TEACHERS:
            self._ensure_beta_teacher(spec, uni, password)

        self.stdout.write('')
        self.stdout.write(self.style.SUCCESS('Vague B seed terminé.'))
        self.stdout.write('Comptes enseignants beta :')
        for spec in BETA_TEACHERS:
            self.stdout.write(f'  • {spec["email"]}  /  {password}')
        self.stdout.write(
            'Crashlytics : surveiller Firebase Console après les premiers installs.'
        )

    def _ensure_beta_teacher(self, data, university, password):
        user, created = User.objects.update_or_create(
            email=data['email'],
            defaults={
                'username': data['email'].split('@')[0][:40],
                'first_name': data['first_name'],
                'last_name': data['last_name'],
                'role': User.Role.TEACHER,
                'headline': data['headline'],
                'professional_domain': data['professional_domain'],
                'bio': data['bio'],
                'university': university,
                'is_active': True,
            },
        )
        user.set_password(password)
        user.save()
        flag = 'créé' if created else 'mis à jour'
        self.stdout.write(f'  OK {data["email"]} ({flag})')
        return user

    def _seed_ma_fac_docs(self) -> int:
        count = 0
        author = User.objects.filter(role=User.Role.TEACHER).first()
        fac_specs = [
            (
                'sciences',
                [
                    (
                        'Résumé INF111 — Algorithmique',
                        DocumentType.RESUME,
                        'Fiche de révision : complexité, récursivité, tris.',
                    ),
                    (
                        'TP INF221 — Bases de données',
                        DocumentType.TP,
                        'Énoncé TP SQL (jointures, agrégations).',
                    ),
                    (
                        'Examen corrigé INF312 — Réseaux',
                        DocumentType.EXAMEN,
                        'Sujet + corrigé type session.',
                    ),
                ],
            ),
            (
                'droit',
                [
                    (
                        'Résumé Droit constitutionnel L1',
                        DocumentType.RESUME,
                        'Organisation des pouvoirs et contrôle de constitutionnalité.',
                    ),
                    (
                        'TD Droit civil — obligations',
                        DocumentType.SUPPORT_COURS,
                        'Cas pratiques sur la responsabilité contractuelle.',
                    ),
                    (
                        'Examen Droit pénal — session',
                        DocumentType.EXAMEN,
                        'Sujet d’examen type avec barème indicatif.',
                    ),
                ],
            ),
        ]

        for slug_kw, docs in fac_specs:
            fac = (
                Faculty.objects.filter(slug__icontains=slug_kw).first()
                or Faculty.objects.filter(name__icontains=slug_kw).first()
            )
            if fac is None:
                self.stdout.write(
                    self.style.WARNING(f'  Faculté « {slug_kw} » introuvable — skip')
                )
                continue
            dept = fac.departments.first()
            uni = fac.university
            for title, doc_type, description in docs:
                Document.objects.update_or_create(
                    title=title,
                    university=uni,
                    defaults={
                        'description': description,
                        'doc_type': doc_type,
                        'author': author,
                        'department': dept,
                        'academic_year': '2025-2026',
                        'external_url': 'https://akadex.onrender.com/legal/privacy/',
                        'is_approved': True,
                        'is_featured': True,
                    },
                )
                count += 1
                self.stdout.write(f'  OK [{fac.name}] {title}')
        return count
