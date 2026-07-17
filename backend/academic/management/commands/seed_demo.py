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
    Promotion,
    University,
)
from community.models import Post
from messaging.models import Conversation, Message

User = get_user_model()


class Command(BaseCommand):
    help = 'Charge des données de démonstration Akadex (UNIKIN)'

    def handle(self, *args, **options):
        uni, _ = University.objects.get_or_create(
            slug='unikin',
            defaults={
                'name': 'Université de Kinshasa',
                'country': 'RD Congo',
                'city': 'Kinshasa',
                'primary_color': '#0B5C56',
                'accent_color': '#E09B2D',
                'description': 'Espace académique officiel UNIKIN sur Akadex.',
            },
        )

        faculty, _ = Faculty.objects.get_or_create(
            university=uni,
            slug='sciences',
            defaults={
                'name': 'Faculté des Sciences',
                'description': 'Sciences exactes et appliquées.',
            },
        )

        dept, _ = Department.objects.get_or_create(
            faculty=faculty,
            slug='informatique',
            defaults={
                'name': 'Informatique',
                'description': 'Génie logiciel, réseaux et systèmes.',
            },
        )

        promo, _ = Promotion.objects.get_or_create(
            department=dept,
            name='L3 Info 2025',
            year=2025,
            defaults={'level': 'Licence 3'},
        )

        teacher, _ = User.objects.get_or_create(
            email='kabongo@unikin.ac.cd',
            defaults={
                'username': 'pkabongo',
                'first_name': 'Pierre',
                'last_name': 'Kabongo',
                'role': User.Role.TEACHER,
                'university': uni,
                'faculty': faculty,
                'department': dept,
                'is_staff': True,
            },
        )
        if not teacher.has_usable_password():
            teacher.set_password('akadex2026')
            teacher.save()

        student, created = User.objects.get_or_create(
            email='aicha.mbemba@unikin.ac.cd',
            defaults={
                'username': 'aicha',
                'first_name': 'Aïcha',
                'last_name': 'Mbemba',
                'role': User.Role.STUDENT,
                'university': uni,
                'faculty': faculty,
                'department': dept,
                'promotion': promo,
                'level': 'Licence 3',
                'bio': 'Passionnée par le génie logiciel et le partage de notes.',
                'reputation': 1280,
                'contributions_count': 47,
                'badges': ['Top contributeur', 'Aide aux L1', 'Examen master'],
            },
        )
        if created or not student.has_usable_password():
            student.set_password('akadex2026')
            student.save()

        samuel, _ = User.objects.get_or_create(
            email='samuel.okito@unikin.ac.cd',
            defaults={
                'username': 'samuel',
                'first_name': 'Samuel',
                'last_name': 'Okito',
                'role': User.Role.STUDENT,
                'university': uni,
                'faculty': faculty,
                'department': dept,
                'promotion': promo,
                'level': 'Licence 3',
            },
        )
        if not samuel.has_usable_password():
            samuel.set_password('akadex2026')
            samuel.save()

        admin, _ = User.objects.get_or_create(
            email='admin@akadex.app',
            defaults={
                'username': 'admin',
                'first_name': 'Admin',
                'last_name': 'Akadex',
                'role': User.Role.ADMIN,
                'is_staff': True,
                'is_superuser': True,
                'university': uni,
            },
        )
        if not admin.has_usable_password():
            admin.set_password('akadex2026')
            admin.save()

        courses_data = [
            {
                'code': 'INF301',
                'title': 'Algorithmes avancés',
                'description': 'Complexité, graphes, programmation dynamique.',
                'credits': 6,
                'semester': 'S5',
            },
            {
                'code': 'INF205',
                'title': 'Bases de données',
                'description': 'Modèle relationnel, SQL, normalisation.',
                'credits': 5,
                'semester': 'S4',
            },
            {
                'code': 'INF312',
                'title': 'Réseaux informatiques',
                'description': 'Couches OSI, TCP/IP, routage et sécurité.',
                'credits': 5,
                'semester': 'S5',
            },
        ]

        courses = {}
        for data in courses_data:
            course, _ = Course.objects.get_or_create(
                department=dept,
                code=data['code'],
                defaults={
                    'title': data['title'],
                    'description': data['description'],
                    'credits': data['credits'],
                    'semester': data['semester'],
                },
            )
            course.teachers.add(teacher)
            courses[data['code']] = course

        docs = [
            {
                'title': 'Algorithmes & Structures de données — Support complet',
                'doc_type': DocumentType.SUPPORT_COURS,
                'author': teacher,
                'course': courses['INF301'],
                'year': '2025',
                'downloads': 1240,
                'views': 3890,
                'favorites_count': 312,
                'rating_avg': 4.8,
                'description': 'Cours magistral + exercices corrigés.',
                'file_size': 2_400_000,
            },
            {
                'title': 'Examen final Bases de données 2024',
                'doc_type': DocumentType.EXAMEN,
                'author': student,
                'course': courses['INF205'],
                'year': '2024',
                'downloads': 980,
                'views': 2100,
                'favorites_count': 190,
                'rating_avg': 4.6,
                'file_size': 1_100_000,
            },
            {
                'title': 'TP Réseaux — Configuration VLAN',
                'doc_type': DocumentType.TP,
                'author': samuel,
                'course': courses['INF312'],
                'year': '2025',
                'downloads': 420,
                'views': 890,
                'favorites_count': 76,
                'rating_avg': 4.5,
                'file_size': 3_200_000,
            },
            {
                'title': 'Fiche de révision — Probabilités',
                'doc_type': DocumentType.FICHE_REVISION,
                'author': student,
                'course': courses['INF301'],
                'year': '2025',
                'downloads': 650,
                'views': 1400,
                'favorites_count': 210,
                'rating_avg': 4.9,
                'file_size': 800_000,
            },
            {
                'title': 'Introduction aux systèmes d’exploitation',
                'doc_type': DocumentType.LIVRE,
                'author': teacher,
                'course': courses['INF205'],
                'year': '2023',
                'downloads': 2100,
                'views': 5400,
                'favorites_count': 480,
                'rating_avg': 4.7,
                'file_size': 12_000_000,
            },
        ]

        for d in docs:
            Document.objects.get_or_create(
                title=d['title'],
                university=uni,
                defaults={
                    'description': d.get('description', ''),
                    'doc_type': d['doc_type'],
                    'author': d['author'],
                    'department': dept,
                    'course': d['course'],
                    'academic_year': d['year'],
                    'downloads': d['downloads'],
                    'views': d['views'],
                    'favorites_count': d['favorites_count'],
                    'rating_avg': d['rating_avg'],
                    'file_size': d['file_size'],
                    'is_approved': True,
                    'is_featured': True,
                },
            )

        Announcement.objects.get_or_create(
            university=uni,
            title='Calendrier des examens du second semestre',
            defaults={
                'body': 'Les épreuves débutent le 5 août. Consultez le planning par département.',
                'category': 'Examens',
                'author': admin,
            },
        )
        Announcement.objects.get_or_create(
            university=uni,
            title='Atelier rédaction de mémoire',
            defaults={
                'body': 'Samedi 10h — Bibliothèque centrale, salle B2.',
                'category': 'Événement',
                'author': admin,
            },
        )

        CalendarEvent.objects.get_or_create(
            university=uni,
            title='Début des examens S2',
            defaults={
                'description': 'Session d’examens du second semestre.',
                'event_type': 'examen',
                'starts_at': timezone.now() + timezone.timedelta(days=18),
                'location': 'Campus principal',
            },
        )

        posts = [
            {
                'author': samuel,
                'title': 'Quelques qui pour INF301 ?',
                'content': 'Quelqu’un a-t-il les annales 2022–2023 avec corrigés ?',
                'tags': ['examens', 'INF301'],
                'likes_count': 24,
                'comments_count': 11,
            },
            {
                'author': student,
                'title': 'Groupe de révision Probabilités',
                'content': 'On se retrouve demain 18h à la BU. Places limitées.',
                'tags': ['révision', 'entraide'],
                'likes_count': 38,
                'comments_count': 17,
            },
            {
                'author': teacher,
                'title': 'Hackathon campus — inscriptions ouvertes',
                'content': '48h pour prototyper une solution étudiante.',
                'tags': ['événement', 'clubs'],
                'likes_count': 92,
                'comments_count': 34,
            },
        ]
        for p in posts:
            Post.objects.get_or_create(
                title=p['title'],
                department=dept,
                defaults={
                    'author': p['author'],
                    'content': p['content'],
                    'tags': p['tags'],
                    'likes_count': p['likes_count'],
                    'comments_count': p['comments_count'],
                    'is_approved': True,
                },
            )

        conv, created = Conversation.objects.get_or_create(
            name='Promo L3 Info',
            is_group=True,
        )
        if created:
            conv.participants.add(student, samuel, teacher)
            Message.objects.create(
                conversation=conv,
                sender=teacher,
                content='Le TP est reporté à jeudi.',
            )

        dm, created = Conversation.objects.get_or_create(
            name='',
            is_group=False,
        )
        if created:
            dm.participants.add(student, samuel)
            Message.objects.create(
                conversation=dm,
                sender=samuel,
                content='Je t’envoie le résumé ce soir.',
            )

        self.stdout.write(self.style.SUCCESS('Données de démo chargées.'))
        self.stdout.write('Comptes :')
        self.stdout.write('  admin@akadex.app / akadex2026')
        self.stdout.write('  aicha.mbemba@unikin.ac.cd / akadex2026')
        self.stdout.write('  samuel.okito@unikin.ac.cd / akadex2026')
        self.stdout.write('  kabongo@unikin.ac.cd / akadex2026')
