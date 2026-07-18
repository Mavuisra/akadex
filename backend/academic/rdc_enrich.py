"""Données pédagogiques réalistes supplémentaires (documents, modules, alumni)."""

from academic.models import Document, DocumentType
from community.models import AlumniFollow, Post, PostKind
from learning.models import CourseComment, CourseLesson, CourseModule, LessonContentType

VIDEO_SAMPLES = [
    'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4',
    'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ElephantsDream.mp4',
    'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerBlazes.mp4',
    'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerEscapes.mp4',
]


def enrich_real_content(
    *,
    unikin,
    upn,
    upc,
    dept_info,
    dept_math,
    dept_gest,
    dept_droit,
    dept_upn,
    dept_fasi,
    course_ref,
    teacher,
    teacher2,
    aicha,
    samuel,
    joseph,
    grace,
    fatou,
    david,
    alumni,
    alumni2,
):
    """Enrichit la base avec contenus proches du terrain universitaire RDC."""

    c_bdd = course_ref('unikin', 'sciences-technologies', 'informatique', 'INF221')
    if c_bdd:
        for order, title, desc in [
            (1, 'Chapitre 1 — Modèle relationnel', 'Entités, associations, clés.'),
            (2, 'Chapitre 2 — SQL', 'SELECT, jointures, agrégats.'),
            (3, 'Chapitre 3 — Conception', 'Normalisation 1FN–3FN.'),
        ]:
            mod, _ = CourseModule.objects.update_or_create(
                course=c_bdd,
                order=order,
                defaults={'title': title, 'description': desc},
            )
            if order == 1:
                CourseLesson.objects.update_or_create(
                    module=mod,
                    order=1,
                    defaults={
                        'title': 'Cours magistral — modèle relationnel',
                        'description': 'Prof. Kabongo — UNIKIN Sciences.',
                        'content_type': LessonContentType.VIDEO,
                        'video_url': VIDEO_SAMPLES[0],
                        'duration_seconds': 596,
                        'is_published': True,
                    },
                )
                CourseLesson.objects.update_or_create(
                    module=mod,
                    order=2,
                    defaults={
                        'title': 'Syllabus Bases de données 2025–2026',
                        'content_type': LessonContentType.PDF,
                        'description': 'Objectifs, évaluation, bibliographie.',
                        'external_url': 'https://www.unikin.ac.cd/',
                        'is_published': True,
                    },
                )
            if order == 2:
                CourseLesson.objects.update_or_create(
                    module=mod,
                    order=1,
                    defaults={
                        'title': 'TP SQL — Boutique Kinshasa',
                        'content_type': LessonContentType.TP,
                        'description': 'Schéma + 12 requêtes.',
                        'external_url': 'https://example.com/tp-sql-unikin',
                        'is_published': True,
                    },
                )
                CourseLesson.objects.update_or_create(
                    module=mod,
                    order=2,
                    defaults={
                        'title': 'Vidéo — jointures internes/externes',
                        'content_type': LessonContentType.VIDEO,
                        'video_url': VIDEO_SAMPLES[1],
                        'duration_seconds': 653,
                        'is_published': True,
                    },
                )
            if order == 3:
                CourseLesson.objects.update_or_create(
                    module=mod,
                    order=1,
                    defaults={
                        'title': 'Examen session juin 2024',
                        'content_type': LessonContentType.EXAM,
                        'description': 'Sujet officiel Fac. Sciences et Technologies.',
                        'is_published': True,
                    },
                )
                CourseLesson.objects.update_or_create(
                    module=mod,
                    order=2,
                    defaults={
                        'title': 'Corrigé examen juin 2024',
                        'content_type': LessonContentType.SOLUTION,
                        'is_published': True,
                    },
                )
        CourseComment.objects.get_or_create(
            course=c_bdd,
            author=samuel,
            content='Prof, le TP SQL compte-t-il pour 30 % comme l’an passé ?',
        )

    c_droit = course_ref('unikin', 'droit', 'droit-prive', 'DRT111')
    if c_droit:
        mod, _ = CourseModule.objects.update_or_create(
            course=c_droit,
            order=1,
            defaults={
                'title': 'Introduction au droit congolais',
                'description': 'Sources du droit en RDC, institutions.',
            },
        )
        CourseLesson.objects.update_or_create(
            module=mod,
            order=1,
            defaults={
                'title': 'Cours — Sources du droit',
                'content_type': LessonContentType.VIDEO,
                'video_url': VIDEO_SAMPLES[2],
                'duration_seconds': 15,
                'is_published': True,
            },
        )
        CourseLesson.objects.update_or_create(
            module=mod,
            order=2,
            defaults={
                'title': 'Code civil — extraits annotés',
                'content_type': LessonContentType.PDF,
                'external_url': 'https://www.unikin.ac.cd/',
                'is_published': True,
            },
        )

    c_fasi = course_ref('upc', 'fasi', 'genie-informatique', 'INF311')
    if c_fasi:
        mod, _ = CourseModule.objects.update_or_create(
            course=c_fasi,
            order=1,
            defaults={
                'title': 'Génie logiciel — cycle de vie',
                'description': 'FASI UPC — exigences, conception, tests.',
            },
        )
        CourseLesson.objects.update_or_create(
            module=mod,
            order=1,
            defaults={
                'title': 'Conférence FASI — méthodes agiles',
                'content_type': LessonContentType.VIDEO,
                'video_url': VIDEO_SAMPLES[3],
                'duration_seconds': 15,
                'is_published': True,
            },
        )
        CourseLesson.objects.update_or_create(
            module=mod,
            order=2,
            defaults={
                'title': 'Cahier des charges type projet L3',
                'content_type': LessonContentType.ASSIGNMENT,
                'description': 'Template officiel FASI.',
                'is_published': True,
            },
        )

    extra_docs = [
        {
            'title': 'Syllabus Algorithmique L1 — UNIKIN 2025–2026',
            'doc_type': DocumentType.SUPPORT_COURS,
            'author': teacher,
            'uni': unikin,
            'dept': dept_info,
            'key': ('unikin', 'sciences-technologies', 'informatique', 'INF111'),
            'year': '2025',
            'downloads': 890,
            'views': 2400,
            'favorites_count': 160,
            'rating_avg': 4.7,
            'file_size': 420_000,
            'description': (
                'Maquette LMD : CC 40 %, examen 60 %. '
                'Bibliographie Cormen & Sedgewick.'
            ),
        },
        {
            'title': 'Annales Structures de données — Session août 2023',
            'doc_type': DocumentType.EXAMEN,
            'author': aicha,
            'uni': unikin,
            'dept': dept_info,
            'key': ('unikin', 'sciences-technologies', 'informatique', 'INF211'),
            'year': '2023',
            'downloads': 1120,
            'views': 3100,
            'favorites_count': 240,
            'rating_avg': 4.8,
            'file_size': 1_050_000,
            'description': 'Sujet + barème. Arbres AVL et graphes.',
        },
        {
            'title': 'Fiche révision — Normalisation 3FN (exemples RDC)',
            'doc_type': DocumentType.FICHE_REVISION,
            'author': samuel,
            'uni': unikin,
            'dept': dept_info,
            'key': ('unikin', 'sciences-technologies', 'informatique', 'INF221'),
            'year': '2025',
            'downloads': 760,
            'views': 1900,
            'favorites_count': 188,
            'rating_avg': 4.9,
            'file_size': 680_000,
            'description': 'Cas « pharmacie Gombe » et « transport Transco ».',
        },
        {
            'title': 'Introduction au droit — Notes de cours L1',
            'doc_type': DocumentType.SUPPORT_COURS,
            'author': teacher,
            'uni': unikin,
            'dept': dept_droit,
            'key': ('unikin', 'droit', 'droit-prive', 'DRT111'),
            'year': '2025',
            'downloads': 540,
            'views': 1300,
            'favorites_count': 95,
            'rating_avg': 4.4,
            'file_size': 2_100_000,
            'description': 'Sources, hiérarchie des normes, organisation judiciaire en RDC.',
        },
        {
            'title': 'Microéconomie I — Exercices corrigés',
            'doc_type': DocumentType.CORRIGE,
            'author': grace,
            'uni': unikin,
            'dept': dept_gest,
            'key': ('unikin', 'sciences-eco-gestion', 'economie', 'ECO111'),
            'year': '2025',
            'downloads': 430,
            'views': 980,
            'favorites_count': 72,
            'rating_avg': 4.5,
            'file_size': 1_200_000,
            'description': 'Offre/demande, élasticités — FASEG UNIKIN.',
        },
        {
            'title': 'Didactique générale — Séquence type UPN',
            'doc_type': DocumentType.FICHE_REVISION,
            'author': fatou,
            'uni': upn,
            'dept': dept_upn,
            'key': ('upn', 'psychologie-sciences-education', 'sciences-education', 'PED211'),
            'year': '2025',
            'downloads': 310,
            'views': 720,
            'favorites_count': 58,
            'rating_avg': 4.3,
            'file_size': 900_000,
            'description': 'Fiche de préparation de leçon (compétences, activités).',
        },
        {
            'title': 'Projet L3 FASI — Spécification mini-ERP campus',
            'doc_type': DocumentType.PROJET,
            'author': david,
            'uni': upc,
            'dept': dept_fasi,
            'key': ('upc', 'fasi', 'genie-informatique', 'INF311'),
            'year': '2025',
            'downloads': 205,
            'views': 510,
            'favorites_count': 41,
            'rating_avg': 4.6,
            'file_size': 780_000,
            'description': 'Cahier des charges pour le projet de génie logiciel FASI.',
        },
        {
            'title': 'Probabilités — Formulaire lois discrètes',
            'doc_type': DocumentType.FICHE_REVISION,
            'author': teacher2,
            'uni': unikin,
            'dept': dept_math,
            'key': ('unikin', 'sciences-technologies', 'mathematiques', 'MAT212'),
            'year': '2025',
            'downloads': 690,
            'views': 1600,
            'favorites_count': 150,
            'rating_avg': 4.8,
            'file_size': 350_000,
            'description': 'Bernoulli, binomiale, Poisson, géométrique.',
        },
    ]

    for d in extra_docs:
        course = course_ref(*d['key'])
        if course is None:
            continue
        Document.objects.update_or_create(
            title=d['title'],
            university=d['uni'],
            defaults={
                'description': d['description'],
                'doc_type': d['doc_type'],
                'author': d['author'],
                'department': d['dept'],
                'course': course,
                'academic_year': d['year'],
                'downloads': d['downloads'],
                'views': d['views'],
                'favorites_count': d['favorites_count'],
                'rating_avg': d['rating_avg'],
                'rating_count': max(8, d['favorites_count'] // 2),
                'file_size': d['file_size'],
                'is_approved': True,
                'is_featured': d['downloads'] > 500,
                'points_awarded': 30,
            },
        )

    for author, dept, title, content, kind, tags, likes, comments, *rest in [
        (
            alumni,
            dept_info,
            'Erreurs à éviter en L1 Informatique UNIKIN',
            (
                'Ne négligez pas Algorithmique et Maths discrètes. '
                'Formez un groupe stable dès le premier semestre.'
            ),
            PostKind.ALUMNI_ADVICE,
            ['L1', 'UNIKIN'],
            134,
            28,
        ),
        (
            alumni,
            dept_info,
            'Comment j’ai décroché un stage en fintech à Kinshasa',
            (
                'CV projet GitHub + portfolio Flutter/Django. '
                'Préparez structures de données et un pitch de 2 minutes.'
            ),
            PostKind.ALUMNI_CAREER,
            ['stage', 'emploi'],
            189,
            37,
        ),
        (
            alumni2,
            dept_upn,
            'Préparer le mémoire de didactique — méthode UPN',
            (
                'Cadrez la problématique avec votre promoteur en semaine 2. '
                'Formalisez l’autorisation de l’école pour le terrain.'
            ),
            PostKind.ALUMNI_TFC,
            ['mémoire', 'UPN'],
            88,
            19,
        ),
        (
            alumni,
            dept_info,
            'Vidéo : organiser sa semaine de révision avant les examens',
            'Planning type L3 Info : 2 matières / jour, annales le week-end.',
            PostKind.ALUMNI_VIDEO,
            ['révision', 'examens'],
            102,
            15,
            VIDEO_SAMPLES[0],
        ),
    ]:
        video = rest[0] if rest else ''
        Post.objects.update_or_create(
            title=title,
            department=dept,
            defaults={
                'author': author,
                'content': content,
                'kind': kind,
                'tags': tags,
                'likes_count': likes,
                'comments_count': comments,
                'video_url': video,
                'is_approved': True,
            },
        )

    AlumniFollow.objects.get_or_create(follower=aicha, alumni=alumni)
    AlumniFollow.objects.get_or_create(follower=joseph, alumni=alumni)
    AlumniFollow.objects.get_or_create(follower=fatou, alumni=alumni2)
