from datetime import timedelta

from django.contrib.auth import get_user_model
from django.core.management.base import BaseCommand
from django.utils import timezone
from academic.models import (
    Announcement,
    CalendarEvent,
    Course,
    Department,
    Document,
    DocumentType,
    Faculty,
    LearningDomain,
    Promotion,
    RewardPrize,
    University,
)
from academic.rdc_catalog import CYCLES, REWARD_PRIZES, UNIVERSITIES
from academic.rdc_enrich import enrich_real_content
from community.models import Post, PostComment, PostKind
from learning.models import CourseComment, CourseLesson, CourseModule, LessonContentType
from messaging.models import Conversation, Message

User = get_user_model()

LEARNING_DOMAINS = [
    {
        'slug': 'informatique',
        'name': 'Informatique',
        'order': 1,
        'keywords': 'informatique,fasi,génie logiciel,info,digital,algorithme,python,sql,base de données',
        'description': 'Programmation, bases de données, réseaux, IA et développement.',
    },
    {
        'slug': 'droit',
        'name': 'Droit',
        'order': 2,
        'keywords': 'droit,juridique,loi,constitutionnel,pénal',
        'description': 'Droit public, privé, constitutionnel et procédures.',
    },
    {
        'slug': 'medecine',
        'name': 'Médecine',
        'order': 3,
        'keywords': 'médecine,medecine,santé,sante,pharmacie,anatomie',
        'description': 'Sciences médicales, anatomie, pharmacie et santé.',
    },
    {
        'slug': 'economie',
        'name': 'Économie & Gestion',
        'order': 4,
        'keywords': 'économie,economie,gestion,commerce,finance',
        'description': 'Économie, gestion d’entreprise et finance.',
    },
    {
        'slug': 'comptabilite',
        'name': 'Comptabilité',
        'order': 5,
        'keywords': 'comptabilité,comptabilite,ohada,audit,fiscal',
        'description': 'Comptabilité générale, OHADA, audit et fiscalité.',
    },
    {
        'slug': 'marketing',
        'name': 'Marketing',
        'order': 6,
        'keywords': 'marketing,vente,communication commerciale,stratégie',
        'description': 'Marketing stratégique, digital et commercial.',
    },
    {
        'slug': 'sciences',
        'name': 'Sciences',
        'order': 7,
        'keywords': 'science,physique,chimie,math,biologie',
        'description': 'Mathématiques, physique, chimie et biologie.',
    },
    {
        'slug': 'lettres',
        'name': 'Lettres & SHS',
        'order': 8,
        'keywords': 'lettre,langue,histoire,socio,psycho,communication',
        'description': 'Lettres, langues et sciences humaines.',
    },
    {
        'slug': 'ingenierie',
        'name': 'Ingénierie',
        'order': 9,
        'keywords': 'ingénieur,ingenieur,polytech,civil,électri,electri',
        'description': 'Génie civil, électrique, mécanique et polytechnique.',
    },
    {
        'slug': 'agronomie',
        'name': 'Agronomie',
        'order': 10,
        'keywords': 'agro,agronomie,vétérinaire,veterinaire',
        'description': 'Agronomie, élevage et sciences vétérinaires.',
    },
]


def seed_learning_domains():
    domains = {}
    for spec in LEARNING_DOMAINS:
        domain, _ = LearningDomain.objects.update_or_create(
            slug=spec['slug'],
            defaults={
                'name': spec['name'],
                'description': spec['description'],
                'keywords': spec['keywords'],
                'order': spec['order'],
                'is_active': True,
            },
        )
        domains[spec['slug']] = domain
    return domains


def link_courses_to_domains(domains):
    """Associe automatiquement les cours seedés aux domaines via mots-clés."""
    linked = 0
    for course in Course.objects.select_related(
        'department', 'department__faculty'
    ).prefetch_related('domains'):
        if course.domains.exists():
            continue
        hay = ' '.join(
            [
                course.title or '',
                course.description or '',
                course.department.name if course.department_id else '',
                course.department.faculty.name
                if course.department_id
                else '',
                course.code or '',
            ]
        ).lower()
        matched = []
        for slug, domain in domains.items():
            keys = [k.strip() for k in domain.keywords.split(',') if k.strip()]
            if any(k.lower() in hay for k in keys):
                matched.append(domain)
        if matched:
            course.domains.set(matched)
            linked += 1
    return linked


class Command(BaseCommand):
    help = (
        'Charge le catalogue universitaire RDC (UNIKIN, UPN, UPC) '
        'et des données de démonstration Akadex.'
    )

    def handle(self, *args, **options):
        now = timezone.now()
        unis = {}
        depts = {}
        courses = {}

        self.stdout.write('Domaines d’apprentissage…')
        domains = seed_learning_domains()

        for uni_spec in UNIVERSITIES:
            uni, _ = University.objects.update_or_create(
                slug=uni_spec['slug'],
                defaults={
                    'name': uni_spec['name'],
                    'country': 'RD Congo',
                    'city': uni_spec['city'],
                    'primary_color': uni_spec['primary_color'],
                    'accent_color': uni_spec['accent_color'],
                    'description': uni_spec['description'],
                    'is_active': True,
                },
            )
            unis[uni.slug] = uni

            for fac_spec in uni_spec['faculties']:
                fac, _ = Faculty.objects.update_or_create(
                    university=uni,
                    slug=fac_spec['slug'],
                    defaults={
                        'name': fac_spec['name'],
                        'description': fac_spec.get('description', ''),
                    },
                )
                for dept_spec in fac_spec['departments']:
                    dept, _ = Department.objects.update_or_create(
                        faculty=fac,
                        slug=dept_spec['slug'],
                        defaults={
                            'name': dept_spec['name'],
                            'description': dept_spec.get('description', ''),
                        },
                    )
                    key = f'{uni.slug}/{fac.slug}/{dept.slug}'
                    depts[key] = dept

                    for level in CYCLES:
                        Promotion.objects.update_or_create(
                            department=dept,
                            name=level,
                            year=2025,
                            defaults={'level': level, 'is_verified': True},
                        )
                    # Nettoyer les anciennes promotions verbeuses (seed précédent).
                    Promotion.objects.filter(department=dept, year=2025).exclude(
                        name__in=list(CYCLES)
                    ).delete()

                    # Cours catalogue (grilles indicatives) : plus seedés.
                    # Les programmes se construisent via contributions étudiantes validées.
                    # Conservé pour référence éventuelle : dept_spec.get('courses', [])

        # Retirer l’ancienne univ de démo ISP Gombe si présente
        University.objects.filter(slug='isp-gombe').update(is_active=False)

        unikin = unis['unikin']
        upn = unis['upn']
        upc = unis['upc']

        dept_info = depts['unikin/sciences-technologies/informatique']
        dept_math = depts['unikin/sciences-technologies/mathematiques']
        dept_gest = depts['unikin/sciences-eco-gestion/gestion']
        dept_droit = depts['unikin/droit/droit-prive']
        dept_upn = depts['upn/pedagogie-didactique/informatique-pedagogique']
        dept_fasi = depts['upc/fasi/genie-informatique']
        fac_sciences = dept_info.faculty
        fac_eco = dept_gest.faculty
        fac_upn = dept_upn.faculty
        fac_fasi = dept_fasi.faculty

        promo_l3 = Promotion.objects.get(
            department=dept_info,
            name='L3',
            year=2025,
        )
        promo_l2 = Promotion.objects.get(
            department=dept_info,
            name='L2',
            year=2025,
        )
        promo_gest = Promotion.objects.get(
            department=dept_gest,
            name='L3',
            year=2025,
        )

        def ensure_user(email, username, first, last, role, **extra):
            """Idempotent : retrouve par email ou username (évite UNIQUE username)."""
            user = User.objects.filter(email=email).first()
            if user is None:
                user = User.objects.filter(username=username).first()
            if user is None:
                user = User(email=email, username=username)

            desired = username
            clash = User.objects.filter(username=desired)
            if user.pk:
                clash = clash.exclude(pk=user.pk)
            if clash.exists():
                n = 2
                while User.objects.filter(username=f'{username}{n}').exclude(
                    pk=user.pk or 0
                ).exists():
                    n += 1
                desired = f'{username}{n}'

            user.email = email
            user.username = desired
            user.first_name = first
            user.last_name = last
            user.role = role
            user.is_active = True
            for k, v in extra.items():
                setattr(user, k, v)
            # Toujours réaligner le mot de passe démo
            user.set_password('akadex2026')
            user.save()
            return user

        admin = ensure_user(
            'admin@akadex.app',
            'admin',
            'Grace',
            'Kalonji',
            User.Role.ADMIN,
            university=unikin,
            is_staff=True,
            is_superuser=True,
            bio='Administratrice de la plateforme Akadex.',
        )
        teacher = ensure_user(
            'kabongo@unikin.ac.cd',
            'pkabongo',
            'Pierre',
            'Kabongo',
            User.Role.TEACHER,
            university=unikin,
            faculty=fac_sciences,
            department=dept_info,
            is_staff=True,
            bio='Chargé de cours en algorithmique et structures de données.',
            reputation=2400,
            contributions_count=18,
            badges=['Enseignant actif', 'Mentor'],
            level='Enseignant',
        )
        teacher2 = ensure_user(
            'mwamba.claire@unikin.ac.cd',
            'cmwamba',
            'Claire',
            'Mwamba',
            User.Role.TEACHER,
            university=unikin,
            faculty=fac_sciences,
            department=dept_math,
            bio='Probabilités et statistiques pour les sciences.',
            reputation=1100,
            contributions_count=9,
            level='Enseignant',
        )
        aicha = ensure_user(
            'aicha.mbemba@unikin.ac.cd',
            'aicha',
            'Aïcha',
            'Mbemba',
            User.Role.STUDENT,
            university=unikin,
            faculty=fac_sciences,
            department=dept_info,
            promotion=promo_l3,
            level='L3',
            bio='Passionnée par le génie logiciel. Je partage mes fiches après chaque exam.',
            reputation=1280,
            contributions_count=47,
            badges=['Top contributeur', 'Aide aux L1', 'Roue débloquée'],
            phone='+243 810 000 001',
        )
        samuel = ensure_user(
            'samuel.okito@unikin.ac.cd',
            'samuel',
            'Samuel',
            'Okito',
            User.Role.STUDENT,
            university=unikin,
            faculty=fac_sciences,
            department=dept_info,
            promotion=promo_l3,
            level='L3',
            bio='Fan de réseaux et de Linux. Toujours partant pour un TP de nuit.',
            reputation=640,
            contributions_count=22,
            badges=['Early adopter'],
        )
        grace = ensure_user(
            'grace.tshibanda@unikin.ac.cd',
            'grace_t',
            'Grâce',
            'Tshibanda',
            User.Role.STUDENT,
            university=unikin,
            faculty=fac_eco,
            department=dept_gest,
            promotion=promo_gest,
            level='L3',
            bio='Éco-gestion. J’organise des groupes de révision à la BU.',
            reputation=410,
            contributions_count=15,
        )
        joseph = ensure_user(
            'joseph.kalala@unikin.ac.cd',
            'jkalala',
            'Joseph',
            'Kalala',
            User.Role.STUDENT,
            university=unikin,
            faculty=fac_sciences,
            department=dept_info,
            promotion=promo_l2,
            level='L2',
            bio='L2 Info — je cherche surtout les annales corrigées.',
            reputation=180,
            contributions_count=6,
        )
        fatou = ensure_user(
            'fatou.diallo@upn.ac.cd',
            'fatou',
            'Fatou',
            'Diallo',
            User.Role.STUDENT,
            university=upn,
            faculty=fac_upn,
            department=dept_upn,
            level='L2',
            bio='UPN — pédagogie et numérique éducatif.',
            reputation=220,
            contributions_count=8,
        )
        david = ensure_user(
            'david.mukendi@upc.ac.cd',
            'dmukendi',
            'David',
            'Mukendi',
            User.Role.STUDENT,
            university=upc,
            faculty=fac_fasi,
            department=dept_fasi,
            level='L3',
            bio='FASI UPC — génie informatique et projets open source.',
            reputation=350,
            contributions_count=12,
        )
        alumni = ensure_user(
            'marie.kasongo@alumni.unikin.ac.cd',
            'mkasongo',
            'Marie',
            'Kasongo',
            User.Role.ALUMNI,
            university=unikin,
            faculty=fac_sciences,
            department=dept_info,
            level='Alumni',
            bio=(
                'Diplômée L3 Info UNIKIN (2022). Développeuse fullstack à Kinshasa. '
                'Je mentorise les L2–L3 sur stages et TFC.'
            ),
            reputation=2100,
            contributions_count=31,
            badges=['Mentor alumni', 'Parcours pro'],
        )
        alumni2 = ensure_user(
            'jean.mbuyi@alumni.upn.ac.cd',
            'jmbuyi',
            'Jean',
            'Mbuyi',
            User.Role.ALUMNI,
            university=upn,
            faculty=fac_upn,
            department=dept_upn,
            level='Alumni',
            bio='Alumni UPN — inspecteur pédagogique. Conseils didactique et concours.',
            reputation=980,
            contributions_count=14,
        )
        alumni_roxie = ensure_user(
            'roxie.ntumba@alumni.unikin.ac.cd',
            'rntumba',
            'Roxie',
            'Ntumba',
            User.Role.ALUMNI,
            university=unikin,
            faculty=fac_sciences,
            department=dept_info,
            level='Alumni',
            bio=(
                'Alumni Informatique — Université de Kinshasa.\n'
                'Créatrice de contenus éducatifs (@roxientumba sur TikTok). '
                'J’aide les lycéens et L1 à choisir une faculté, réussir les examens '
                'et décrocher un premier stage à Kinshasa.\n'
                'Ex-étudiante passionnée méthodes de travail & soft skills.'
            ),
            reputation=2650,
            contributions_count=48,
            badges=[
                'Mentor alumni',
                'Vidéos conseils',
                'Top créatrice',
                'Orientation filière',
                'TikTok éducatif',
            ],
            phone='+243 890 000 042',
        )
        alumni_patrick = ensure_user(
            'patrick.ilunga@alumni.upc.ac.cd',
            'pilunga',
            'Patrick',
            'Ilunga',
            User.Role.ALUMNI,
            university=upc,
            faculty=fac_fasi,
            department=dept_fasi,
            level='Alumni',
            bio=(
                'Alumni FASI UPC — ingénieur logiciel. Partage retours d’entretiens tech '
                'et projets open source depuis Kinshasa.'
            ),
            reputation=1540,
            contributions_count=22,
            badges=['Mentor tech', 'Open source'],
        )
        alumni_esther = ensure_user(
            'esther.kalala@alumni.upn.ac.cd',
            'ekalala',
            'Esther',
            'Kalala',
            User.Role.ALUMNI,
            university=upn,
            faculty=fac_upn,
            department=dept_upn,
            level='Alumni',
            bio=(
                'Alumni UPN — enseignante. Conseils pédagogiques, TFC et préparation aux concours.'
            ),
            reputation=1120,
            contributions_count=17,
            badges=['Pédagogie', 'Mentorat'],
        )

        # Associer enseignants aux cours clés
        for code in ('UNI-INF111', 'UNI-INF211', 'UNI-INF221', 'UNI-INF312', 'UNI-INF311'):
            c = courses.get(code)
            if c:
                c.teachers.add(teacher)
        for code in ('UNI-MAT111', 'UNI-MAT212', 'UNI-MAT311'):
            c = courses.get(code)
            if c:
                c.teachers.add(teacher2)

        def course_ref(uni_slug, fac_slug, dept_slug, code):
            return courses.get(f'{uni_slug}/{fac_slug}/{dept_slug}:{code}')

        c_algo = course_ref('unikin', 'sciences-technologies', 'informatique', 'INF111')
        c_bdd = course_ref('unikin', 'sciences-technologies', 'informatique', 'INF221')
        c_res = course_ref('unikin', 'sciences-technologies', 'informatique', 'INF312')
        c_poo = course_ref('unikin', 'sciences-technologies', 'informatique', 'INF212')
        c_proba = course_ref('unikin', 'sciences-technologies', 'mathematiques', 'MAT212')
        c_compta = course_ref('unikin', 'sciences-eco-gestion', 'gestion', 'GES121')
        c_peda = course_ref('upn', 'pedagogie-didactique', 'informatique-pedagogique', 'PED311')
        c_fasi = course_ref('upc', 'fasi', 'genie-informatique', 'INF311')

        docs_spec = [
            {
                'title': 'Algorithmique — Support de cours L1',
                'doc_type': DocumentType.SUPPORT_COURS,
                'author': teacher,
                'uni': unikin,
                'dept': dept_info,
                'course': c_algo,
                'year': '2025',
                'downloads': 1240,
                'views': 3890,
                'favorites_count': 312,
                'rating_avg': 4.8,
                'file_size': 2_400_000,
                'description': 'Cours magistral avec exercices corrigés. Idéal pour la promo L1.',
            },
            {
                'title': 'Examen final Bases de données — Session juin 2024',
                'doc_type': DocumentType.EXAMEN,
                'author': aicha,
                'uni': unikin,
                'dept': dept_info,
                'course': c_bdd,
                'year': '2024',
                'downloads': 980,
                'views': 2100,
                'favorites_count': 190,
                'rating_avg': 4.6,
                'file_size': 1_100_000,
                'description': 'Sujet officiel + barème. Attention : la partie normalisation est longue.',
            },
            {
                'title': 'TP Réseaux — Configuration VLAN et ACL',
                'doc_type': DocumentType.TP,
                'author': samuel,
                'uni': unikin,
                'dept': dept_info,
                'course': c_res,
                'year': '2025',
                'downloads': 420,
                'views': 890,
                'favorites_count': 76,
                'rating_avg': 4.5,
                'file_size': 3_200_000,
                'description': 'Scénario Packet Tracer : 3 VLANs, trunk et règles ACL basiques.',
            },
            {
                'title': 'Fiche de révision — Probabilités (lois discrètes)',
                'doc_type': DocumentType.FICHE_REVISION,
                'author': aicha,
                'uni': unikin,
                'dept': dept_math,
                'course': c_proba,
                'year': '2025',
                'downloads': 650,
                'views': 1400,
                'favorites_count': 210,
                'rating_avg': 4.9,
                'file_size': 800_000,
                'description': 'Bernoulli, binomiale, Poisson — formules + 8 exercices types.',
            },
            {
                'title': 'Corrigé interrogation POO — UML & héritage',
                'doc_type': DocumentType.CORRIGE,
                'author': joseph,
                'uni': unikin,
                'dept': dept_info,
                'course': c_poo,
                'year': '2025',
                'downloads': 310,
                'views': 720,
                'favorites_count': 55,
                'rating_avg': 4.3,
                'file_size': 640_000,
                'description': 'Corrigé détaillé de l’interro de mars, validé par un camarade L3.',
            },
            {
                'title': 'Résumé Comptabilité générale — Cycle complet',
                'doc_type': DocumentType.RESUME,
                'author': grace,
                'uni': unikin,
                'dept': dept_gest,
                'course': c_compta,
                'year': '2025',
                'downloads': 540,
                'views': 1180,
                'favorites_count': 98,
                'rating_avg': 4.4,
                'file_size': 1_500_000,
                'description': 'Journal → grand livre → balance → bilans. Schémas clairs.',
            },
            {
                'title': 'Tutoriel Git pour débutants (promo L2)',
                'doc_type': DocumentType.TUTORIEL,
                'author': samuel,
                'uni': unikin,
                'dept': dept_info,
                'course': c_poo,
                'year': '2025',
                'downloads': 870,
                'views': 2600,
                'favorites_count': 201,
                'rating_avg': 4.8,
                'file_size': 2_100_000,
                'description': 'clone, commit, branch, PR — exemples avec GitHub Classroom.',
            },
            {
                'title': 'Didactique du numérique — séquences Moodle UPN',
                'doc_type': DocumentType.FICHE_REVISION,
                'author': fatou,
                'uni': upn,
                'dept': dept_upn,
                'course': c_peda,
                'year': '2025',
                'downloads': 260,
                'views': 610,
                'favorites_count': 40,
                'rating_avg': 4.1,
                'file_size': 900_000,
                'description': 'Exemples de séquences pédagogiques avec Moodle.',
            },
            {
                'title': 'Génie logiciel FASI — cahier des charges projet L3',
                'doc_type': DocumentType.PROJET,
                'author': david,
                'uni': upc,
                'dept': dept_fasi,
                'course': c_fasi,
                'year': '2025',
                'downloads': 180,
                'views': 420,
                'favorites_count': 35,
                'rating_avg': 4.5,
                'file_size': 450_000,
                'description': 'Spécification du projet de fin de module à la FASI (UPC).',
            },
            {
                'title': 'Vidéo courte — Normalisation 3FN expliquée',
                'doc_type': DocumentType.VIDEO,
                'author': teacher,
                'uni': unikin,
                'dept': dept_info,
                'course': c_bdd,
                'year': '2025',
                'downloads': 720,
                'views': 4100,
                'favorites_count': 260,
                'rating_avg': 4.9,
                'file_size': 48_000_000,
                'description': '12 minutes pour comprendre 1FN → 3FN avec un exemple boutique.',
                'external_url': 'https://example.com/video/3fn',
            },
        ]

        for d in docs_spec:
            if not d['course']:
                continue
            Document.objects.update_or_create(
                title=d['title'],
                university=d['uni'],
                defaults={
                    'description': d.get('description', ''),
                    'doc_type': d['doc_type'],
                    'author': d['author'],
                    'department': d['dept'],
                    'course': d['course'],
                    'academic_year': d['year'],
                    'downloads': d['downloads'],
                    'views': d['views'],
                    'favorites_count': d['favorites_count'],
                    'rating_avg': d['rating_avg'],
                    'rating_count': max(5, d['favorites_count'] // 3),
                    'file_size': d['file_size'],
                    'external_url': d.get('external_url', ''),
                    'is_approved': True,
                    'is_featured': d['downloads'] > 500,
                    'points_awarded': 25,
                },
            )

        for prize in REWARD_PRIZES:
            RewardPrize.objects.update_or_create(
                name=prize['name'],
                defaults={
                    'description': prize['description'],
                    'category': prize['category'],
                    'min_points': prize['min_points'],
                    'points_cost': prize['points_cost'],
                    'weight': prize['weight'],
                    'is_active': True,
                },
            )

        announcements = [
            (
                unikin,
                'Calendrier des examens — session LMD',
                'Les épreuves débutent le 5 août. Consultez le planning par département sur le portail facultaire.',
                'Examens',
            ),
            (
                unikin,
                'Atelier rédaction de mémoire',
                'Samedi 10h — Bibliothèque centrale, salle B2. Places limitées à 40 étudiants.',
                'Événement',
            ),
            (
                unikin,
                'Système de récompenses Akadex',
                'Publie des contenus validés pour gagner des points et débloquer la roue de récompenses.',
                'Info',
            ),
            (
                upn,
                'Inscriptions rentrée pédagogique',
                'Les dossiers se déposent à la scolarité jusqu’au 30 septembre.',
                'Admin',
            ),
            (
                upc,
                'Hackathon FASI',
                'Inscriptions ouvertes pour le hackathon de la Faculté des Sciences Informatiques.',
                'Événement',
            ),
        ]
        for uni, title, body, cat in announcements:
            Announcement.objects.get_or_create(
                university=uni,
                title=title,
                defaults={
                    'body': body,
                    'category': cat,
                    'author': admin,
                    'is_published': True,
                },
            )

        events = [
            (
                unikin,
                'Début des examens L2 / L3',
                'Session d’examens du cycle Licence.',
                'examen',
                18,
                'Campus principal',
            ),
            (
                unikin,
                'Remise des projets génie logiciel',
                'Dépôt sur la plateforme avant minuit.',
                'deadline',
                7,
                'En ligne',
            ),
            (
                unikin,
                'Délibération L3 Informatique',
                'Résultats provisoires affichés le lendemain.',
                'deliberation',
                32,
                'Faculté des Sciences et Technologies',
            ),
            (
                unikin,
                'Journée portes ouvertes clubs',
                'Stand IA, robotique et cybersécurité.',
                'evenement',
                12,
                'Amphi 1',
            ),
            (
                upn,
                'Forum métiers de l’éducation',
                'Rencontre avec des inspecteurs et directeurs d’école.',
                'evenement',
                21,
                'UPN — Hall central',
            ),
            (
                upc,
                'Soutenances FASI Master 1',
                'Présentation des projets d’intelligence artificielle.',
                'examen',
                25,
                'FASI — Amphi',
            ),
        ]
        for uni, title, desc, etype, days, loc in events:
            CalendarEvent.objects.get_or_create(
                university=uni,
                title=title,
                defaults={
                    'description': desc,
                    'event_type': etype,
                    'starts_at': now + timedelta(days=days),
                    'ends_at': now + timedelta(days=days, hours=3),
                    'location': loc,
                },
            )

        posts_spec = [
            (
                samuel,
                dept_info,
                'Qui a les annales Structures de données 2022–2023 ?',
                'Salut la promo 👋 Quelqu’un a-t-il les annales avec corrigés ? Je bloque sur la partie graphes.',
                ['examens', 'L2'],
                24,
                11,
                PostKind.QUESTION,
            ),
            (
                aicha,
                dept_info,
                'Groupe de révision Probabilités — demain 18h',
                'On se retrouve à la BU, table près des imprimantes. Amenez vos fiches, on fait des QCM entre nous.',
                ['révision', 'entraide'],
                38,
                17,
                PostKind.DISCUSSION,
            ),
            (
                teacher,
                dept_info,
                'Hackathon campus — inscriptions ouvertes',
                '48h pour prototyper une solution étudiante. Thème : accès aux ressources académiques.',
                ['événement', 'clubs'],
                92,
                34,
                PostKind.DISCUSSION,
            ),
            (
                grace,
                dept_gest,
                'Partage : modèle Excel pour le bilan',
                'J’ai mis un template propre pour le TP de compta. Dites-moi si ça vous aide !',
                ['compta', 'ressources'],
                19,
                6,
                PostKind.DISCUSSION,
            ),
            (
                joseph,
                dept_info,
                'Erreur sur le sujet du TP VLAN ?',
                'Dans l’énoncé, le VLAN 30 n’a pas de gateway. C’est voulu ou oubli du prof ?',
                ['TP', 'réseaux'],
                11,
                8,
                PostKind.QUESTION,
            ),
            (
                aicha,
                dept_info,
                'Examen corrigé de Programmation Orientée Objet',
                'Voici les corrigés complets de l’examen 2025.\n\nBonne préparation à tous.',
                ['POO', 'examen', 'L2'],
                128,
                34,
                PostKind.EXAM,
            ),
            (
                samuel,
                dept_info,
                'TP Réseaux — Configuration VLAN et ACL (corrigé)',
                'Scénario Packet Tracer avec 3 VLANs, trunk et ACL. J’ai ajouté les captures d’écran clés.',
                ['TP', 'réseaux', 'L3'],
                86,
                19,
                PostKind.TP,
            ),
            (
                grace,
                dept_gest,
                'Résumé Comptabilité générale — Chapitre bilan',
                'Synthèse claire pour réviser avant l’interro. Formules + exemples chiffrés.',
                ['résumé', 'compta', 'L1'],
                64,
                12,
                PostKind.SUMMARY,
            ),
            (
                joseph,
                dept_info,
                'Notes de cours — Algorithmique L1 (complexité)',
                'Mes notes propres sur la notation grand O, avec 6 exemples types d’examens.',
                ['notes', 'algo', 'L1'],
                73,
                15,
                PostKind.NOTES,
            ),
            (
                david,
                dept_fasi,
                'Support de cours — Bases de données relationnelles',
                'Slides du cours + exercices sur la normalisation (1NF → 3NF).',
                ['support', 'BDD', 'FASI'],
                51,
                9,
                PostKind.SUPPORT,
            ),
            (
                fatou,
                dept_upn,
                'Ressources didactique numérique UPN',
                'Bonjour, je cherche des exemples de séquences pédagogiques avec Moodle. Merci d’avance.',
                ['UPN', 'pédagogie'],
                7,
                3,
                PostKind.QUESTION,
            ),
            (
                david,
                dept_fasi,
                'Projets open source FASI UPC',
                'Qui veut contribuer à un repo Django/Flutter pour le projet L3 ?',
                ['UPC', 'FASI'],
                15,
                5,
                PostKind.DISCUSSION,
            ),
            (
                alumni,
                dept_info,
                'Comment j’ai préparé mon TFC en 8 semaines',
                'Choisissez un sujet lié à un vrai besoin campus, validez tôt avec l’encadreur, '
                'et livrez un MVP avant la rédaction. Je détaille mon planning semaine par semaine.',
                ['TFC', 'méthode'],
                156,
                42,
                PostKind.ALUMNI_TFC,
            ),
            (
                alumni,
                dept_info,
                'Mon parcours : de L1 Info UNIKIN au premier CDI',
                'Stages à la RTNC puis freelance, puis CDI fullstack. Les soft skills comptent autant que Java.',
                ['carrière', 'stages'],
                210,
                55,
                PostKind.ALUMNI_CAREER,
            ),
            (
                alumni,
                dept_info,
                'Conseil L2 : ne négligez pas les structures de données',
                'C’est le filtre des entretiens techniques à Kin. Pratiquez 3 problèmes / semaine.',
                ['conseil', 'L2'],
                98,
                21,
                PostKind.ALUMNI_ADVICE,
            ),
            (
                alumni2,
                dept_upn,
                'Réussir le concours d’inspecteur — retour d’expérience',
                'Annales + oral de didactique. Je partage ma grille de révision sur 3 mois.',
                ['concours', 'UPN'],
                67,
                18,
                PostKind.ALUMNI_PATH,
            ),
            (
                alumni_roxie,
                dept_info,
                'Roxie Ntumba — Comment bien choisir sa faculté',
                'Conseils concrets pour lycéens et futurs L1 : passions, débouchés, '
                'réalité des filières en RDC. Vidéo TikTok @roxientumba.',
                ['orientation', 'faculté', 'TikTok', 'Roxie'],
                890,
                152,
                PostKind.ALUMNI_VIDEO,
            ),
            (
                alumni_patrick,
                dept_fasi,
                'Entretien tech à Kin : 5 questions qu’on m’a posées',
                'Structures de données, SQL, un mini projet Flutter. Je détaille les réponses '
                'attendues dans la vidéo.',
                ['emploi', 'FASI', 'TikTok'],
                188,
                41,
                PostKind.ALUMNI_VIDEO,
            ),
            (
                alumni_esther,
                dept_upn,
                'Comment cadrer ton TFC dès la 2ᵉ semaine',
                'Grille de cadrage + checklist promoteur. Méthode que j’utilise avec mes étudiants.',
                ['TFC', 'UPN'],
                145,
                33,
                PostKind.ALUMNI_TFC,
            ),
        ]
        # URLs vidéo pour les posts alumni_video du seed principal
        video_by_title = {
            'Ma routine L3 pour passer les examens sans burn-out': (
                'https://www.youtube.com/watch?v=rfscVS0vtbw'
            ),
            'Roxie Ntumba — Comment bien choisir sa faculté': (
                'https://www.tiktok.com/@roxientumba/video/7663144965132029205'
            ),
            'Entretien tech à Kin : 5 questions qu’on m’a posées': (
                'https://www.tiktok.com/@akadex.demo/video/7234567890123456789'
            ),
        }
        # URLs PDF démo (aperçu LinkedIn dans le fil)
        pdf_by_title = {
            'Examen corrigé de Programmation Orientée Objet': (
                'https://mozilla.github.io/pdf.js/web/compressed.tracemonkey-pldi-09.pdf',
                14,
            ),
            'TP Réseaux — Configuration VLAN et ACL (corrigé)': (
                'https://mozilla.github.io/pdf.js/web/compressed.tracemonkey-pldi-09.pdf',
                8,
            ),
            'Résumé Comptabilité générale — Chapitre bilan': (
                'https://mozilla.github.io/pdf.js/web/compressed.tracemonkey-pldi-09.pdf',
                5,
            ),
            'Notes de cours — Algorithmique L1 (complexité)': (
                'https://mozilla.github.io/pdf.js/web/compressed.tracemonkey-pldi-09.pdf',
                6,
            ),
            'Support de cours — Bases de données relationnelles': (
                'https://mozilla.github.io/pdf.js/web/compressed.tracemonkey-pldi-09.pdf',
                12,
            ),
        }
        created_posts = []
        for author, dept, title, content, tags, likes, comments, kind in posts_spec:
            pdf = pdf_by_title.get(title)
            post, _ = Post.objects.update_or_create(
                title=title,
                department=dept,
                defaults={
                    'author': author,
                    'content': content,
                    'tags': tags,
                    'likes_count': likes,
                    'comments_count': comments,
                    'is_approved': True,
                    'kind': kind,
                    'video_url': video_by_title.get(title, ''),
                    'file_url': pdf[0] if pdf else '',
                    'page_count': pdf[1] if pdf else 0,
                },
            )
            created_posts.append(post)

        # Modules / leçons pour un cours Info (page type Coursera)
        algo_course = c_algo or course_ref(
            'unikin', 'sciences-technologies', 'informatique', 'INF211'
        )
        if algo_course:
            mod1, _ = CourseModule.objects.update_or_create(
                course=algo_course,
                order=1,
                defaults={
                    'title': 'Chapitre 1 — Fondamentaux',
                    'description': 'Complexité, structures de base et récursivité.',
                },
            )
            mod2, _ = CourseModule.objects.update_or_create(
                course=algo_course,
                order=2,
                defaults={
                    'title': 'Chapitre 2 — Structures avancées',
                    'description': 'Arbres, graphes et applications.',
                },
            )
            mod3, _ = CourseModule.objects.update_or_create(
                course=algo_course,
                order=3,
                defaults={
                    'title': 'Chapitre 3 — Ressources & examens',
                    'description': 'TP, annales et corrigés.',
                },
            )
            lessons_spec = [
                (mod1, 1, 'Introduction à l’algorithmique', LessonContentType.VIDEO,
                 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4',
                 596, 'Présentation du module et objectifs.'),
                (mod1, 2, 'Complexité temporelle', LessonContentType.VIDEO,
                 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ElephantsDream.mp4',
                 653, 'Notation grand O, exemples.'),
                (mod1, 3, 'Syllabus du cours (PDF)', LessonContentType.PDF,
                 '', 0, 'Objectifs, évaluation, bibliographie.'),
                (mod2, 1, 'Arbres binaires de recherche', LessonContentType.VIDEO,
                 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerBlazes.mp4',
                 15, 'Insertion, parcours, complexité.'),
                (mod2, 2, 'TP — Implémentation d’un graphe', LessonContentType.TP,
                 '', 0, 'Sujet TP + livrables.'),
                (mod3, 1, 'Examen blanc 2024', LessonContentType.EXAM,
                 '', 0, 'Sujet session précédente.'),
                (mod3, 2, 'Corrigé examen blanc', LessonContentType.SOLUTION,
                 '', 0, 'Corrigé détaillé.'),
            ]
            for mod, order, title, ctype, vurl, dur, desc in lessons_spec:
                CourseLesson.objects.update_or_create(
                    module=mod,
                    order=order,
                    defaults={
                        'title': title,
                        'description': desc,
                        'content_type': ctype,
                        'video_url': vurl,
                        'duration_seconds': dur,
                        'is_published': True,
                        'external_url': '' if vurl else 'https://example.com/ressource',
                    },
                )
            CourseComment.objects.get_or_create(
                course=algo_course,
                author=aicha,
                content='Prof, la vidéo sur la complexité est-elle au programme du contrôle ?',
                defaults={'parent': None},
            )
            CourseComment.objects.get_or_create(
                course=algo_course,
                author=teacher,
                content='Oui, sections 1 à 3 inclus. Bonne révision !',
                defaults={'parent': None},
            )

        if created_posts:
            PostComment.objects.get_or_create(
                post=created_posts[0],
                author=aicha,
                content='Je te les envoie ce soir sur le groupe WhatsApp promo.',
            )
            PostComment.objects.get_or_create(
                post=created_posts[1],
                author=samuel,
                content='Je serai là ! J’apporte les exercices du polycopié.',
            )
            PostComment.objects.get_or_create(
                post=created_posts[7],
                author=joseph,
                content='Merci Marie ! Est-ce que tu conseilles un template LaTeX particulier ?',
            )
            PostComment.objects.get_or_create(
                post=created_posts[7],
                author=alumni,
                content='Oui — Overleaf « UNIKIN TFC » fonctionne très bien. Je te le partage.',
            )

        conv, created = Conversation.objects.get_or_create(
            name='Promo L3 Info UNIKIN',
            is_group=True,
        )
        if created or conv.participants.count() == 0:
            conv.participants.set([aicha, samuel, joseph, teacher])
        if not conv.messages.exists():
            Message.objects.create(
                conversation=conv,
                sender=teacher,
                content='Le TP VLAN est reporté à jeudi 14h. Salle labo 2.',
            )
            Message.objects.create(
                conversation=conv,
                sender=samuel,
                content='Parfait, merci Prof. On prépare Packet Tracer.',
            )
            Message.objects.create(
                conversation=conv,
                sender=aicha,
                content='Je mets le .pkt sur Akadex dans la section TP.',
            )

        dm, created = Conversation.objects.get_or_create(
            name='',
            is_group=False,
        )
        if created or dm.participants.count() == 0:
            dm.participants.set([aicha, samuel])
        if not dm.messages.exists():
            Message.objects.create(
                conversation=dm,
                sender=samuel,
                content='Je t’envoie le résumé de graphes ce soir 👌',
            )
            Message.objects.create(
                conversation=dm,
                sender=aicha,
                content='Top, merci ! On révise ensemble demain ?',
            )

        enrich_real_content(
            unikin=unikin,
            upn=upn,
            upc=upc,
            dept_info=dept_info,
            dept_math=dept_math,
            dept_gest=dept_gest,
            dept_droit=dept_droit,
            dept_upn=dept_upn,
            dept_fasi=dept_fasi,
            course_ref=course_ref,
            teacher=teacher,
            teacher2=teacher2,
            aicha=aicha,
            samuel=samuel,
            joseph=joseph,
            grace=grace,
            fatou=fatou,
            david=david,
            alumni=alumni,
            alumni2=alumni2,
            alumni_roxie=alumni_roxie,
            alumni_patrick=alumni_patrick,
            alumni_esther=alumni_esther,
        )

        # Pas de cours vitrine AKX dans le catalogue Ma Fac (promotions).
        # Les ressources Apprendre restent gérées via les domaines.
        purged, _ = Course.objects.filter(submitted_by__isnull=True).delete()
        self.stdout.write(
            self.style.WARNING(
                f'Cours seedés / fictifs purgés : {purged} '
                '(conservées : contributions étudiantes uniquement).'
            )
        )

        linked = link_courses_to_domains(domains)
        self.stdout.write(f'Domaines liés à {linked} cours.')

        self.stdout.write(self.style.SUCCESS('Catalogue RDC + démo chargés.'))
        self.stdout.write(
            f'Universités={University.objects.filter(is_active=True).count()} '
            f'Facultés={Faculty.objects.count()} '
            f'Départements={Department.objects.count()} '
            f'Domaines={LearningDomain.objects.count()} '
            f'Cours={Course.objects.count()} '
            f'Docs={Document.objects.count()} '
            f'Récompenses={RewardPrize.objects.count()}'
        )
        self.stdout.write('Comptes (mot de passe: akadex2026) :')
        self.stdout.write('  aicha.mbemba@unikin.ac.cd')
        self.stdout.write('  samuel.okito@unikin.ac.cd')
        self.stdout.write('  david.mukendi@upc.ac.cd')
        self.stdout.write('  fatou.diallo@upn.ac.cd')
        self.stdout.write('  kabongo@unikin.ac.cd')
        self.stdout.write('  marie.kasongo@alumni.unikin.ac.cd (alumni)')
        self.stdout.write('  jean.mbuyi@alumni.upn.ac.cd (alumni)')
        self.stdout.write('  roxie.ntumba@alumni.unikin.ac.cd (alumni — Roxie Ntumba)')
        self.stdout.write('  patrick.ilunga@alumni.upc.ac.cd (alumni)')
        self.stdout.write('  esther.kalala@alumni.upn.ac.cd (alumni)')
        self.stdout.write('  admin@akadex.app')
