"""
Seed de 6 cours vitrine Akadex : modules, leçons YouTube publiques,
enseignants professionnels, images académiques africaines.
"""

from django.contrib.auth import get_user_model
from django.core.management.base import BaseCommand

from academic.models import Course, Department, Faculty, University
from learning.models import CourseLesson, CourseModule

User = get_user_model()

YT = 'https://www.youtube.com/watch?v={}'

# Images Unsplash — environnements académiques / étudiants africains
IMG = {
    'campus': 'https://images.unsplash.com/photo-1523050854058-8df90110c9f1?w=1200&q=80',
    'classroom': 'https://images.unsplash.com/photo-1509062522246-3755977927d7?w=1200&q=80',
    'lab': 'https://images.unsplash.com/photo-1532094349884-543bc11b234d?w=1200&q=80',
    'library': 'https://images.unsplash.com/photo-1524995997946-a1c2e315a42f?w=1200&q=80',
    'medical': 'https://images.unsplash.com/photo-1576091160399-112ba8d25d1d?w=1200&q=80',
    'business': 'https://images.unsplash.com/photo-1454165804606-c3d57bc86b40?w=1200&q=80',
    'law': 'https://images.unsplash.com/photo-1589829545856-d10d557cf95f?w=1200&q=80',
    'coding': 'https://images.unsplash.com/photo-1517694712202-14dd9538aa97?w=1200&q=80',
    'students': 'https://images.unsplash.com/photo-1523240795612-9a054b0db644?w=1200&q=80',
    'lecture': 'https://images.unsplash.com/photo-1427504494785-3a9ca7044f45?w=1200&q=80',
}

# Portraits professionnels (Unsplash)
PHOTO = {
    'jp': 'https://images.unsplash.com/photo-1531384441138-2736e62e0919?w=400&q=80',
    'aisha': 'https://images.unsplash.com/photo-1589156280159-276898a84425?w=400&q=80',
    'koffi': 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=400&q=80',
    'fatou': 'https://images.unsplash.com/photo-1573496359142-b8d87734a5a2?w=400&q=80',
    'emmanuel': 'https://images.unsplash.com/photo-1560250097-0b93528c311a?w=400&q=80',
    'grace': 'https://images.unsplash.com/photo-1551836022-d5d88e9218df?w=400&q=80',
}


def yt(video_id):
    return YT.format(video_id)


FLAGSHIP = [
    {
        'code': 'AKX-IA101',
        'title': 'Fondamentaux de l’Intelligence Artificielle',
        'dept_keywords': ['info', 'fasi', 'génie', 'computer'],
        'semester': 'L2',
        'credits': 6,
        'level': 'Débutant',
        'hours': 28,
        'cover': IMG['coding'],
        'description': (
            'Ce cours introduit les concepts essentiels de l’intelligence artificielle '
            'pour les étudiants africains : historique, apprentissage automatique, '
            'réseaux de neurones et cas d’usage (santé, agriculture, éducation). '
            'Vous construisez une culture IA solide avant de passer aux spécialisations.'
        ),
        'objectives': (
            'Comprendre ce qu’est l’IA et ses limites.\n'
            'Distinguer apprentissage supervisé, non supervisé et par renforcement.\n'
            'Expliquer le fonctionnement d’un réseau de neurones simple.\n'
            'Identifier des applications IA pertinentes pour l’Afrique.'
        ),
        'skills': (
            'Vocabulaire IA et machine learning\n'
            'Lecture de modèles simples\n'
            'Éthique et biais algorithmiques\n'
            'Présentation d’un cas d’usage local'
        ),
        'prerequisites': 'Notions de mathématiques du secondaire et curiosité scientifique.',
        'outcomes': 'À la fin, vous pourrez expliquer l’IA à un public non technique et proposer un projet d’application locale.',
        'teacher': {
            'email': 'jean.mukendi@akadex.cd',
            'first_name': 'Jean-Pierre',
            'last_name': 'Mukendi',
            'postnom': 'Kalala',
            'gender': 'M',
            'headline': 'Professeur',
            'professional_domain': 'Spécialiste en Intelligence Artificielle',
            'bio': (
                'Professeur Jean-Pierre Mukendi Kalala enseigne l’informatique à l’Université '
                'de Kinshasa depuis 12 ans. Chercheur en vision par ordinateur appliquée à '
                'l’agriculture urbaine, il a formé plus de 2 000 étudiants en RDC et anime '
                'des ateliers IA pour le secteur public.'
            ),
            'photo_url': PHOTO['jp'],
        },
        'modules': [
            {
                'title': 'Module 1 — Qu’est-ce que l’IA ?',
                'description': 'Définitions, histoire et enjeux contemporains.',
                'lessons': [
                    ('L’IA expliquée simplement', 'video', 'aircAruvnKk', 620, 'Introduction visuelle aux réseaux de neurones.'),
                    ('Machine Learning en 10 minutes', 'video', 'ukzFI9rgwfU', 540, 'Vue d’ensemble accessible du ML.'),
                    ('Quiz — Concepts de base', 'quiz', '', 900, '10 questions sur les définitions IA / ML.'),
                ],
            },
            {
                'title': 'Module 2 — Données et apprentissage',
                'description': 'Données, features et entraînement.',
                'lessons': [
                    ('Données pour le ML', 'video', 'i_LwzRVP7bg', 720, 'Rôle des données dans les modèles.'),
                    ('Exercice — Jeu de données local', 'exercise', '', 1800, 'Décrire un jeu de données congolais fictif.'),
                    ('Lecture PDF — Glossaire IA', 'pdf', '', 600, 'Glossaire FR des termes essentiels.'),
                ],
            },
            {
                'title': 'Module 3 — Réseaux de neurones',
                'description': 'Intuition et architecture.',
                'lessons': [
                    ('Neural Networks — 3Blue1Brown', 'video', 'aircAruvnKk', 1140, 'Comprendre les couches et poids.'),
                    ('TP — Dessiner un réseau', 'tp', '', 2400, 'Schéma d’un réseau à 2 couches.'),
                ],
            },
            {
                'title': 'Module 4 — IA pour l’Afrique',
                'description': 'Cas d’usage santé, agro, éducation.',
                'lessons': [
                    ('Cas d’usage continentaux', 'text', '', 900, 'Notes de cours sur les applications locales.'),
                    ('Projet — Pitch d’une solution IA', 'assignment', '', 3600, 'Présenter une idée IA pour Kinshasa ou votre ville.'),
                ],
            },
            {
                'title': 'Module 5 — Éthique et avenir',
                'description': 'Biais, responsabilité, carrières.',
                'lessons': [
                    ('Éthique de l’IA', 'video', 'tCdPkmLxPL8', 780, 'Biais et responsabilités.'),
                    ('Quiz final', 'quiz', '', 1200, 'Évaluation sommative du cours.'),
                    ('Projet pratique final', 'assignment', '', 7200, 'Livrable : note de 3 pages + schéma.'),
                ],
            },
        ],
    },
    {
        'code': 'AKX-PY101',
        'title': 'Python pour les sciences et le numérique',
        'dept_keywords': ['info', 'fasi', 'math', 'science'],
        'semester': 'L1',
        'credits': 5,
        'level': 'Débutant',
        'hours': 32,
        'cover': IMG['lab'],
        'description': (
            'Apprenez Python de zéro jusqu’aux bases utiles pour la science, '
            'l’analyse de données et l’automatisation — avec une pédagogie progressive '
            'inspirée des meilleurs MOOC (freeCodeCamp, OpenClassrooms).'
        ),
        'objectives': (
            'Écrire des scripts Python clairs.\n'
            'Manipuler listes, dictionnaires et fichiers.\n'
            'Résoudre des problèmes algorithmiques simples.\n'
            'Préparer un mini-projet de données.'
        ),
        'skills': (
            'Syntaxe Python 3\n'
            'Structures de contrôle\n'
            'Fonctions et modules\n'
            'Lecture/écriture de fichiers'
        ),
        'prerequisites': 'Aucun. Un ordinateur et de la motivation suffisent.',
        'outcomes': 'Vous serez capable d’écrire un programme Python autonome de 100–200 lignes.',
        'teacher': {
            'email': 'aisha.mbala@akadex.cd',
            'first_name': 'Aïsha',
            'last_name': 'Mbala',
            'postnom': 'Ngoy',
            'gender': 'F',
            'headline': 'Maître de conférences',
            'professional_domain': 'Spécialiste en génie logiciel et pédagogie numérique',
            'bio': (
                'Maître de conférences Aïsha Mbala Ngoy forme les étudiants de L1–L2 à '
                'l’UPC. Elle a co-fondé un club coding pour jeunes filles à Kinshasa et '
                'publie des tutoriels Python en lingala et français.'
            ),
            'photo_url': PHOTO['aisha'],
        },
        'modules': [
            {
                'title': 'Module 1 — Démarrer avec Python',
                'lessons': [
                    ('Python pour débutants', 'video', 'kqtD5dpn9C8', 3600, 'Installation et premiers programmes.'),
                    ('Exercice — Hello Akadex', 'exercise', '', 1200, 'Afficher votre nom et université.'),
                ],
            },
            {
                'title': 'Module 2 — Variables et types',
                'lessons': [
                    ('Types et opérateurs', 'video', 'rfscVS0vtbw', 2400, 'Extraits freeCodeCamp — bases.'),
                    ('Quiz — Types Python', 'quiz', '', 600, 'QCM sur int, str, list, dict.'),
                ],
            },
            {
                'title': 'Module 3 — Contrôle de flux',
                'lessons': [
                    ('Conditions et boucles', 'video', 'HGOBQPFzWKo', 1800, 'if, for, while.'),
                    ('TP — Table de multiplication', 'tp', '', 1800, 'Générer une table 1–12.'),
                ],
            },
            {
                'title': 'Module 4 — Fonctions',
                'lessons': [
                    ('Écrire des fonctions', 'video', '9Os0o3wzS_I', 1200, 'def, return, paramètres.'),
                    ('Exercice — Calculateur de moyenne', 'exercise', '', 2400, 'Moyenne de notes LMD.'),
                ],
            },
            {
                'title': 'Module 5 — Fichiers et projet',
                'lessons': [
                    ('Lire/écrire des fichiers', 'video', 'Uh2ebFW8OYM', 900, 'open, with, csv simple.'),
                    ('Projet — Journal de notes', 'assignment', '', 7200, 'App CLI pour stocker des notes.'),
                    ('Quiz final Python', 'quiz', '', 1200, 'Validation des acquis.'),
                ],
            },
            {
                'title': 'Module 6 — Aller plus loin',
                'lessons': [
                    ('Ressources PDF', 'pdf', '', 600, 'Aide-mémoire Python FR.'),
                    ('Orientations data / web', 'text', '', 900, 'Pistes de spécialisation.'),
                ],
            },
        ],
    },
    {
        'code': 'AKX-DR201',
        'title': 'Introduction au droit public congolais',
        'dept_keywords': ['droit', 'jurid'],
        'semester': 'L1',
        'credits': 5,
        'level': 'Débutant',
        'hours': 24,
        'cover': IMG['law'],
        'description': (
            'Découvrez les bases du droit public en RDC : État, Constitution, '
            'séparation des pouvoirs et droits fondamentaux. Cours structuré pour '
            'étudiants de première année, avec lectures et cas pratiques.'
        ),
        'objectives': (
            'Situer le droit public dans le système juridique.\n'
            'Expliquer les institutions de la RDC.\n'
            'Analyser un article constitutionnel simple.\n'
            'Rédiger une fiche de jurisprudence courte.'
        ),
        'skills': (
            'Lecture d’un texte juridique\n'
            'Commentaire d’article\n'
            'Vocabulaire du droit public\n'
            'Méthode de dissertation juridique'
        ),
        'prerequisites': 'Aucun prérequis juridique. Maîtrise du français académique recommandée.',
        'outcomes': 'Vous saurez situer les pouvoirs publics congolais et commenter un texte constitutionnel.',
        'teacher': {
            'email': 'koffi.tshisekedi@akadex.cd',
            'first_name': 'Koffi',
            'last_name': 'Tshisekedi',
            'postnom': 'Ilunga',
            'gender': 'M',
            'headline': 'Docteur',
            'professional_domain': 'Spécialiste en droit constitutionnel et institutions africaines',
            'bio': (
                'Docteur Koffi Tshisekedi Ilunga est enseignant-chercheur en droit public. '
                'Il a publié sur la décentralisation en Afrique centrale et accompagne '
                'les étudiants de L1–L3 en méthodologie juridique.'
            ),
            'photo_url': PHOTO['koffi'],
        },
        'modules': [
            {
                'title': 'Module 1 — Le droit et l’État',
                'lessons': [
                    ('Gouvernement et institutions', 'video', 'lrk4oY7UxpQ', 720, 'Crash Course — intro institutions.'),
                    ('Lecture — Notion d’État', 'pdf', '', 1200, 'Fiche de lecture commentée.'),
                ],
            },
            {
                'title': 'Module 2 — Constitution',
                'lessons': [
                    ('Pourquoi une Constitution ?', 'video', 'P9VJBINGO0s', 600, 'Principes constitutionnels.'),
                    ('Exercice — Analyser un article', 'exercise', '', 1800, 'Commentaire guidé.'),
                ],
            },
            {
                'title': 'Module 3 — Séparation des pouvoirs',
                'lessons': [
                    ('Exécutif, législatif, judiciaire', 'video', '0ISyY2rXuEQ', 540, 'Équilibres institutionnels.'),
                    ('Cas pratique RDC', 'tp', '', 2400, 'Identifier les pouvoirs dans un scénario.'),
                ],
            },
            {
                'title': 'Module 4 — Droits fondamentaux',
                'lessons': [
                    ('Droits et libertés', 'text', '', 900, 'Synthèse pédagogique.'),
                    ('Quiz — Droits fondamentaux', 'quiz', '', 900, 'QCM.'),
                ],
            },
            {
                'title': 'Module 5 — Méthode et projet',
                'lessons': [
                    ('Méthode du commentaire', 'video', '0hLjuVyIIrs', 780, 'Technique de dissertation.'),
                    ('Projet — Fiche d’arrêt', 'assignment', '', 5400, 'Rédiger une fiche structurée.'),
                ],
            },
        ],
    },
    {
        'code': 'AKX-ECO201',
        'title': 'Économie du développement en Afrique',
        'dept_keywords': ['écon', 'econ', 'gestion', 'commerce'],
        'semester': 'L2',
        'credits': 5,
        'level': 'Intermédiaire',
        'hours': 26,
        'cover': IMG['business'],
        'description': (
            'Analysez les enjeux du développement économique en Afrique : croissance, '
            'inégalités, commerce, dette et politiques publiques. Approche pédagogique '
            'proche des MOOC Coursera / edX, adaptée au contexte centrafricain et congolais.'
        ),
        'objectives': (
            'Définir le développement économique.\n'
            'Comparer des indicateurs (PIB, IDH, Gini).\n'
            'Discuter des stratégies de développement.\n'
            'Proposer une note de politique publique courte.'
        ),
        'skills': (
            'Lecture d’indicateurs\n'
            'Analyse comparative\n'
            'Argumentation économique\n'
            'Rédaction de policy brief'
        ),
        'prerequisites': 'Notions d’économie générale (offre/demande) utiles mais non obligatoires.',
        'outcomes': 'Vous pourrez rédiger une note de 2 pages sur un défi économique national.',
        'teacher': {
            'email': 'fatou.diallo@akadex.cd',
            'first_name': 'Fatou',
            'last_name': 'Diallo',
            'postnom': '',
            'gender': 'F',
            'headline': 'Professeure',
            'professional_domain': 'Spécialiste en économie du développement et finance inclusive',
            'bio': (
                'Professeure Fatou Diallo a travaillé avec des organisations régionales sur '
                'la microfinance et l’emploi des jeunes. Elle enseigne l’économie du '
                'développement et dirige un séminaire sur l’entrepreneuriat féminin.'
            ),
            'photo_url': PHOTO['fatou'],
        },
        'modules': [
            {
                'title': 'Module 1 — Qu’est-ce que le développement ?',
                'lessons': [
                    ('Crash Course Economics', 'video', 'g9aDizJpdIk', 660, 'Intro aux concepts économiques.'),
                    ('Indicateurs IDH / PIB', 'pdf', '', 900, 'Fiche indicateurs Afrique.'),
                ],
            },
            {
                'title': 'Module 2 — Croissance et inégalités',
                'lessons': [
                    ('Croissance économique', 'video', 'd0nERTFo-Sk', 600, 'Moteurs de croissance.'),
                    ('Exercice — Lire un tableau IDH', 'exercise', '', 1500, 'Analyser 3 pays.'),
                ],
            },
            {
                'title': 'Module 3 — Commerce et intégration',
                'lessons': [
                    ('Commerce international', 'video', 'TDT58-p2-6k', 720, 'Avantage comparatif.'),
                    ('Cas ZLECAF', 'text', '', 1200, 'Notes sur l’intégration africaine.'),
                ],
            },
            {
                'title': 'Module 4 — Dette et financement',
                'lessons': [
                    ('Financer le développement', 'video', 'PHe0bXAIuk0', 540, 'Aide, dette, IDE.'),
                    ('Quiz — Concepts clés', 'quiz', '', 900, 'QCM modules 1–4.'),
                ],
            },
            {
                'title': 'Module 5 — Projet policy brief',
                'lessons': [
                    ('Méthode policy brief', 'video', 'lT3vGaYLQys', 480, 'Structure d’une note.'),
                    ('Projet — Note 2 pages', 'assignment', '', 7200, 'Sujet libre sur un défi national.'),
                ],
            },
        ],
    },
    {
        'code': 'AKX-MED101',
        'title': 'Bases de la santé publique',
        'dept_keywords': ['méd', 'med', 'santé', 'sante', 'pharma'],
        'semester': 'L1',
        'credits': 4,
        'level': 'Débutant',
        'hours': 22,
        'cover': IMG['medical'],
        'description': (
            'Introduction à la santé publique : prévention, épidémiologie de base, '
            'systèmes de santé et déterminants sociaux. Conçu pour les étudiants en '
            'médecine, sciences infirmières et santé communautaire.'
        ),
        'objectives': (
            'Définir la santé publique.\n'
            'Différencier prévention primaire, secondaire, tertiaire.\n'
            'Lire un taux d’incidence / prévalence.\n'
            'Proposer une action communautaire simple.'
        ),
        'skills': (
            'Vocabulaire épidémiologique\n'
            'Lecture de statistiques sanitaires\n'
            'Éducation pour la santé\n'
            'Travail en équipe communautaire'
        ),
        'prerequisites': 'Aucun. Ouvert aux non-médecins intéressés par la santé collective.',
        'outcomes': 'Vous pourrez concevoir une mini-campagne de sensibilisation locale.',
        'teacher': {
            'email': 'emmanuel.kabongo@akadex.cd',
            'first_name': 'Emmanuel',
            'last_name': 'Kabongo',
            'postnom': 'Mwamba',
            'gender': 'M',
            'headline': 'Docteur',
            'professional_domain': 'Spécialiste en santé publique et épidémiologie',
            'bio': (
                'Docteur Emmanuel Kabongo Mwamba a exercé en santé communautaire dans '
                'plusieurs provinces. Il enseigne l’épidémiologie descriptive et forme '
                'des agents de santé aux bonnes pratiques de prévention.'
            ),
            'photo_url': PHOTO['emmanuel'],
        },
        'modules': [
            {
                'title': 'Module 1 — Introduction',
                'lessons': [
                    ('Qu’est-ce que la santé publique ?', 'video', 'j8zy-YZSDc8', 600, 'Définition et champs.'),
                    ('Quiz — Vocabulaire', 'quiz', '', 600, 'Termes essentiels.'),
                ],
            },
            {
                'title': 'Module 2 — Déterminants de la santé',
                'lessons': [
                    ('Déterminants sociaux', 'video', 'wr-m-FxrL9Y', 720, 'Environnement, revenus, éducation.'),
                    ('Cas Kinshasa', 'text', '', 900, 'Lecture contextualisée.'),
                ],
            },
            {
                'title': 'Module 3 — Prévention',
                'lessons': [
                    ('Niveaux de prévention', 'video', 'y5Dtm0_wK9s', 540, 'Primaire à tertiaire.'),
                    ('TP — Affiche de sensibilisation', 'tp', '', 2400, 'Concevoir une affiche.'),
                ],
            },
            {
                'title': 'Module 4 — Épidémiologie de base',
                'lessons': [
                    ('Incidence et prévalence', 'video', 'VdP8nZ0sZ1E', 660, 'Calculs simples.'),
                    ('Exercice — Calculs', 'exercise', '', 1800, '3 exercices guidés.'),
                ],
            },
            {
                'title': 'Module 5 — Projet communautaire',
                'lessons': [
                    ('Conduire une campagne', 'pdf', '', 900, 'Guide pratique PDF.'),
                    ('Projet — Plan d’action', 'assignment', '', 5400, 'Plan sur 4 semaines.'),
                ],
            },
        ],
    },
    {
        'code': 'AKX-ENT301',
        'title': 'Entrepreneuriat digital en Afrique',
        'dept_keywords': ['gestion', 'écon', 'econ', 'commerce', 'info'],
        'semester': 'L3',
        'credits': 6,
        'level': 'Intermédiaire',
        'hours': 30,
        'cover': IMG['students'],
        'description': (
            'De l’idée au MVP : apprenez à valider un problème, concevoir une offre '
            'numérique et pitcher devant un jury. Pédagogie inspirée de Y Combinator / '
            'OpenClassrooms, ancrée dans les réalités des startups africaines.'
        ),
        'objectives': (
            'Formuler un problème client clair.\n'
            'Construire un lean canvas.\n'
            'Prototyper une offre digitale simple.\n'
            'Pitcher en 3 minutes.'
        ),
        'skills': (
            'Customer discovery\n'
            'Lean canvas\n'
            'Storytelling\n'
            'Pitch deck'
        ),
        'prerequisites': 'Avoir une idée de projet (même embryonnaire) ou accepter un sujet imposé.',
        'outcomes': 'Vous livrerez un lean canvas + pitch vidéo de 3 minutes.',
        'teacher': {
            'email': 'grace.lumumba@akadex.cd',
            'first_name': 'Grace',
            'last_name': 'Lumumba',
            'postnom': 'Kasongo',
            'gender': 'F',
            'headline': 'Professeure',
            'professional_domain': 'Spécialiste en entrepreneuriat et innovation digitale',
            'bio': (
                'Professeure Grace Lumumba Kasongo a accompagné des dizaines de startups '
                'à Kinshasa et Nairobi. Elle enseigne l’innovation et dirige l’incubateur '
                'campus Akadex.'
            ),
            'photo_url': PHOTO['grace'],
        },
        'modules': [
            {
                'title': 'Module 1 — Esprit startup',
                'lessons': [
                    ('How to Start a Startup', 'video', 'CBYCci0ja-Y', 2400, 'Y Combinator — lecture fondatrice.'),
                    ('Quiz — Mindset', 'quiz', '', 600, 'Auto-évaluation.'),
                ],
            },
            {
                'title': 'Module 2 — Problème & client',
                'lessons': [
                    ('Trouver un problème réel', 'video', 'BKtdsLYjjQQ', 900, 'Customer discovery.'),
                    ('Exercice — 5 interviews', 'exercise', '', 3600, 'Mener 5 entretiens.'),
                ],
            },
            {
                'title': 'Module 3 — Lean canvas',
                'lessons': [
                    ('Remplir un lean canvas', 'video', '7o8uAQ92K9I', 720, 'Blocs du canvas.'),
                    ('TP — Votre canvas', 'tp', '', 2400, 'Canvas du projet Akadex.'),
                ],
            },
            {
                'title': 'Module 4 — MVP digital',
                'lessons': [
                    ('Qu’est-ce qu’un MVP ?', 'video', '0P7n-mdds_w', 600, 'Produit minimum viable.'),
                    ('Prototype no-code', 'text', '', 1200, 'Outils gratuits recommandés.'),
                ],
            },
            {
                'title': 'Module 5 — Pitch',
                'lessons': [
                    ('Pitch en 3 minutes', 'video', 'iKtW4EcqLRw', 780, 'Structure narrative.'),
                    ('Ressource PDF — Template pitch', 'pdf', '', 600, 'Trame PowerPoint.'),
                ],
            },
            {
                'title': 'Module 6 — Projet final',
                'lessons': [
                    ('Checklist de livraison', 'text', '', 600, 'Canvas + pitch + feedback.'),
                    ('Projet — Pitch final', 'assignment', '', 10800, 'Soumettre canvas + lien vidéo.'),
                    ('Quiz de clôture', 'quiz', '', 900, 'Validation des acquis.'),
                ],
            },
        ],
    },
]


def _find_department(keywords):
    deps = list(Department.objects.select_related('faculty__university').all())
    for kw in keywords:
        for d in deps:
            blob = f'{d.name} {d.faculty.name}'.lower()
            if kw.lower() in blob:
                return d
    return deps[0] if deps else None


def _ensure_teacher(data, university):
    user, created = User.objects.update_or_create(
        email=data['email'],
        defaults={
            'username': data['email'].split('@')[0][:40],
            'first_name': data['first_name'],
            'last_name': data['last_name'],
            'postnom': data.get('postnom', ''),
            'gender': data.get('gender', ''),
            'role': User.Role.TEACHER,
            'headline': data['headline'],
            'professional_domain': data['professional_domain'],
            'bio': data['bio'],
            'photo_url': data['photo_url'],
            'university': university,
            'is_active': True,
        },
    )
    if created:
        user.set_password('akadex2026')
        user.save(update_fields=['password'])
    return user


def _seed_course(spec, stdout):
    dept = _find_department(spec['dept_keywords'])
    if dept is None:
        stdout.write('  ✗ Aucun département — lancez seed_demo d’abord.')
        return None

    uni = dept.faculty.university
    teacher = _ensure_teacher(spec['teacher'], uni)

    course, _ = Course.objects.update_or_create(
        department=dept,
        code=spec['code'],
        defaults={
            'title': spec['title'],
            'description': spec['description'],
            'objectives': spec['objectives'],
            'skills': spec['skills'],
            'prerequisites': spec['prerequisites'],
            'bibliography': spec.get('outcomes', ''),
            'credits': spec['credits'],
            'semester': spec['semester'],
            'cover_url': spec['cover'],
            'level_label': spec['level'],
            'estimated_hours': spec['hours'],
        },
    )
    course.teachers.set([teacher])

    # Remplacer modules pour un contenu propre
    course.modules.all().delete()
    for mi, mod in enumerate(spec['modules'], start=1):
        module = CourseModule.objects.create(
            course=course,
            title=mod['title'],
            description=mod.get('description', ''),
            order=mi,
        )
        for li, lesson in enumerate(mod['lessons'], start=1):
            title, ctype, vid, duration, desc = lesson
            CourseLesson.objects.create(
                module=module,
                title=title,
                description=desc,
                content_type=ctype,
                order=li,
                video_url=yt(vid) if vid else '',
                duration_seconds=duration,
                is_published=True,
            )

    stdout.write(f'  OK {course.code} - {course.title} ({course.modules.count()} modules)')
    return course


class Command(BaseCommand):
    help = 'Cree 6 cours vitrine complets (YouTube, modules, enseignants pro).'

    def handle(self, *args, **options):
        if not Department.objects.exists():
            self.stderr.write(
                self.style.ERROR('Aucun departement. Executez d abord: python manage.py seed_demo')
            )
            return

        self.stdout.write(self.style.NOTICE('Seed des 6 cours vitrine Akadex...'))
        for spec in FLAGSHIP:
            _seed_course(spec, self.stdout)
        self.stdout.write(self.style.SUCCESS('Termine - 6 cours prets.'))
