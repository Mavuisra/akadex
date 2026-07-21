"""
Catalogue académique RDC — UNIKIN, UPN, UPC.

Sources officielles UNIKIN (2024-2025) :
- Facultés : https://www.unikin.ac.cd/facultes-et-entites
- Programmes : https://www.unikin.ac.cd/programme-des-cours
- Charges horaires SGA (PDF) :
  https://www.unikin.ac.cd/wp-content/uploads/2025/07/Faculte-des-Sciences-et-Technologies-1.pdf
  https://www.unikin.ac.cd/wp-content/uploads/2025/07/FACULTE-de-Droit.pdf
  https://www.unikin.ac.cd/wp-content/uploads/2025/07/Faculte-des-Sciences-Agronomiques-et-Environnement.pdf
  https://www.unikin.ac.cd/wp-content/uploads/2025/07/Faculte-des-sciences-Pharmaceutiques.pdf
  https://www.unikin.ac.cd/wp-content/uploads/2025/07/Faculte-de-Psychologie-et-SED.pdf
  https://www.unikin.ac.cd/wp-content/uploads/2025/07/CHARGE-HORAIRE-FACULTE-DE-MEDECINE-.pdf
  https://www.unikin.ac.cd/wp-content/uploads/2025/07/Faculte-de-Medecine-Dentaire.pdf
  https://www.unikin.ac.cd/wp-content/uploads/2025/07/Faculte-de-Petrole-Gaz-et-Energie-Renouvelable.pdf

Les intitulés UNIKIN (toutes facultés) sont dans academic/unikin_courses.py
(plus INFO/MATH dans ce fichier). Codes UE = identifiants internes Akadex.
"""

CYCLES = ('L1', 'L2', 'L3', 'Master 1', 'Master 2')

# --- UNIKIN · Faculté des Sciences et Technologies · Informatique ---
# Source : Charge horaire Mentions Math-Stat-Info, Physique, Chimie (PDF SGA 2024-2025)
INFO_COURSES = [
    (
        'INF111',
        'Algorithmique',
        'Licence 1 Math, Stat et Info — algorithmes et complexité (UNIKIN).',
        5,
        'L1',
    ),
    (
        'INF112',
        'Informatique générale',
        'Licence 1 Math, Stat et Info — initiation aux systèmes et outils (UNIKIN).',
        5,
        'L1',
    ),
    (
        'INF113',
        'Mathématique, informatique et société',
        'Licence 1 — enjeux sociétaux du numérique (UNIKIN).',
        2,
        'L1',
    ),
    (
        'INF114',
        'Logique mathématique',
        'Licence 1 Math, Stat et Info (UNIKIN).',
        5,
        'L1',
    ),
    (
        'INF115',
        'Initiation à l’informatique',
        'Licence 1 — bases de l’informatique (UNIKIN).',
        4,
        'L1',
    ),
    (
        'INF211',
        'Génie logiciel',
        'Licence 2 Informatique — cycle de vie, exigences, tests (UNIKIN).',
        5,
        'L2',
    ),
    (
        'INF212',
        'Algorithmique orientée objet',
        'Licence 2 Informatique — classes, héritage, conception OO (UNIKIN).',
        5,
        'L2',
    ),
    (
        'INF221',
        'Bases de données',
        'Licence 2 Informatique — modèle relationnel et SQL (UNIKIN).',
        4,
        'L2',
    ),
    (
        'INF222',
        'Modélisation UML',
        'Licence 2 Informatique — analyse et conception UML (UNIKIN).',
        4,
        'L2',
    ),
    (
        'INF223',
        'Langage Python',
        'Licence 2 Informatique — programmation Python (UNIKIN).',
        4,
        'L2',
    ),
    (
        'INF224',
        'Infographie',
        'Licence 2 Informatique — graphisme et visualisation (UNIKIN).',
        4,
        'L2',
    ),
    (
        'INF225',
        'Théorie des graphes',
        'Licence 2 Informatique (UNIKIN).',
        4,
        'L2',
    ),
    (
        'INF226',
        'Éléments de la théorie des nombres',
        'Licence 2 Informatique (UNIKIN).',
        4,
        'L2',
    ),
    (
        'INF227',
        'Probabilités et statistique',
        'Licence 2 LMD — outils probabilistes pour l’informatique (UNIKIN).',
        4,
        'L2',
    ),
    (
        'INF228',
        'Projet de recherche',
        'Licence 2 Informatique — projet encadré (UNIKIN).',
        5,
        'L2',
    ),
    (
        'INF311',
        'Intelligence artificielle',
        'Licence 3 Informatique — IA et applications (UNIKIN).',
        5,
        'L3',
    ),
    (
        'INF312',
        'Réseaux informatiques et systèmes distribués',
        'Licence 3 Informatique — réseaux, parallélisme et distribution (UNIKIN).',
        6,
        'L3',
    ),
    (
        'INF313',
        'Systèmes parallèles et distribués',
        'Licence 3 Informatique (UNIKIN).',
        5,
        'L3',
    ),
    (
        'INF320',
        'Programmation parallèle',
        'Licence 3 Informatique (UNIKIN).',
        5,
        'L3',
    ),
    (
        'INF314',
        'Informatique temps réel',
        'Licence 3 Informatique (UNIKIN).',
        5,
        'L3',
    ),
    (
        'INF315',
        'Compilation',
        'Licence 3 Informatique — analyse et génération de code (UNIKIN).',
        5,
        'L3',
    ),
    (
        'INF316',
        'Cryptographie et sécurité informatique',
        'Licence 3 Informatique (UNIKIN).',
        5,
        'L3',
    ),
    (
        'INF317',
        'Droit du numérique',
        'Licence 3 Informatique — cadre juridique du numérique (UNIKIN).',
        4,
        'L3',
    ),
    (
        'INF318',
        'Projet de recherche L3',
        'Licence 3 Informatique — projet / TFC (UNIKIN).',
        5,
        'L3',
    ),
    (
        'INF319',
        'Stage',
        'Licence 3 Informatique — stage professionnel (UNIKIN).',
        6,
        'L3',
    ),
    (
        'INF411',
        'Ontologie et web sémantique',
        'Master 1 IA & Datascience (UNIKIN).',
        5,
        'Master 1',
    ),
    (
        'INF412',
        'Machine learning et deep learning',
        'Master 1 IA & Datascience (UNIKIN).',
        5,
        'Master 1',
    ),
    (
        'INF413',
        'Traitement d’images',
        'Master 1 IA & Datascience (UNIKIN).',
        4,
        'Master 1',
    ),
    (
        'INF414',
        'Internet des objets',
        'Master 1 IA & Datascience (UNIKIN).',
        4,
        'Master 1',
    ),
    (
        'INF415',
        'Bases de données avancées',
        'Master 1 Informatique (UNIKIN).',
        5,
        'Master 1',
    ),
    (
        'INF416',
        'Planification en intelligence artificielle',
        'Master 1 Informatique (UNIKIN).',
        5,
        'Master 1',
    ),
    (
        'INF417',
        'Cryptographie',
        'Master 1 Réseaux et Sécurité (UNIKIN).',
        6,
        'Master 1',
    ),
    (
        'INF418',
        'Statistique mathématique',
        'Master 1 Informatique (UNIKIN).',
        5,
        'Master 1',
    ),
    (
        'INF419',
        'Anglais technique',
        'Master 1 Informatique (UNIKIN).',
        4,
        'Master 1',
    ),
    (
        'INF420',
        'Méthode de recherche scientifique',
        'Master 1 Informatique (UNIKIN).',
        3,
        'Master 1',
    ),
    (
        'INF421',
        'Séminaire d’informatique',
        'Master 1 Informatique (UNIKIN).',
        5,
        'Master 1',
    ),
    (
        'INF422',
        'Mémoire / projet de fin d’études',
        'Master 2 — recherche et rédaction encadrée (UNIKIN).',
        6,
        'Master 2',
    ),
]

MATH_COURSES = [
    (
        'MAT111',
        'Analyse infinitésimale',
        'Licence 1 Math, Stat et Info (UNIKIN).',
        6,
        'L1',
    ),
    (
        'MAT112',
        'Théorie des probabilités',
        'Licence 1 Math, Stat et Info (UNIKIN).',
        6,
        'L1',
    ),
    (
        'MAT211',
        'Algèbre multilinéaire',
        'Licence 2 Math & Stat (UNIKIN).',
        6,
        'L2',
    ),
    (
        'MAT212',
        'Théorie des nombres',
        'Licence 2 Math & Stat (UNIKIN).',
        5,
        'L2',
    ),
    (
        'MAT213',
        'Cryptographie',
        'Licence 2 Math & Stat (UNIKIN).',
        5,
        'L2',
    ),
    (
        'MAT214',
        'Logiciels statistiques',
        'Licence 2 Math & Stat (UNIKIN).',
        5,
        'L2',
    ),
    (
        'MAT311',
        'Analyse numérique avancée',
        'Licence 3 Math & Stat (UNIKIN).',
        5,
        'L3',
    ),
    (
        'MAT312',
        'Algèbre de Galois',
        'Licence 3 Math & Stat (UNIKIN).',
        5,
        'L3',
    ),
    (
        'MAT313',
        'Probabilités appliquées',
        'Licence 3 Math & Stat (UNIKIN).',
        5,
        'L3',
    ),
    (
        'MAT314',
        'Mesure et intégration',
        'Licence 3 Math & Stat (UNIKIN).',
        5,
        'L3',
    ),
    (
        'MAT411',
        'Équations aux dérivées partielles',
        'Master 1 Mathématiques (UNIKIN).',
        6,
        'Master 1',
    ),
    (
        'MAT412',
        'Analyse fonctionnelle',
        'Master 1 Maths appliquées / fondamentales (UNIKIN).',
        5,
        'Master 1',
    ),
]


# Cours enrichis toutes facultés (PDF SGA UNIKIN 2024-2025)
from academic.unikin_courses import (  # noqa: E402
    AGRO_COURSES,
    BIO_COURSES,
    CHIM_COURSES,
    DENT_COURSES,
    DROIT_COURSES,
    ECO_COURSES,
    GEO_COURSES,
    LETTRES_COURSES,
    MED_COURSES,
    PEDAGO_COURSES,
    PETROLE_COURSES,
    PHARMA_COURSES,
    PHY_COURSES,
    POLY_CIVIL,
    POLY_ELEC,
    POLY_MECA,
    PSY_COURSES,
    SANTE_PUB,
    SOC_COURSES,
    VET_COURSES,
)

THEO_COURSES = [
    ('THE111', 'Introduction à la théologie', 'Sources et méthodes.', 4, 'L1'),
    ('THE211', 'Exégèse biblique', 'Ancien et Nouveau Testament.', 5, 'L2'),
    ('THE311', 'Théologie systématique', 'Dogmatique et éthique chrétienne.', 5, 'L3'),
]


IA_COURSES = [
    ('IA111', 'Fondements de l’IA', 'Parcours IA & Datascience UNIKIN.', 5, 'L1'),
    ('IA211', 'Apprentissage automatique', 'Parcours IA & Datascience UNIKIN.', 5, 'L2'),
    ('IA311', 'Deep learning', 'Parcours IA & Datascience UNIKIN.', 5, 'L3'),
    ('IA411', 'IA éthique et société', 'Master IA & Datascience UNIKIN.', 4, 'Master 1'),
]

SYS_INFO_COURSES = [
    ('SI111', 'Systèmes d’information', 'Architecture SI et processus métier.', 5, 'L1'),
    ('SI211', 'Analyse et conception SI', 'UML, Merise, spécifications.', 5, 'L2'),
    ('SI311', 'ERP et intégration', 'Systèmes intégrés d’entreprise.', 5, 'L3'),
]


UNIVERSITIES = [
    {
        'slug': 'unikin',
        'name': 'Université de Kinshasa',
        'city': 'Kinshasa',
        'primary_color': '#1A47B8',
        'accent_color': '#E09B2D',
        'description': (
            'Université publique de référence en RDC (13 facultés). '
            'Sources : https://www.unikin.ac.cd/facultes-et-entites — '
            'programmes SGA 2024-2025.'
        ),
        'faculties': [
            {
                'slug': 'droit',
                'name': 'Faculté de Droit',
                'description': (
                    'Formation juridique pour la justice et l’État de droit. '
                    'Départements : Droit public interne, Droits de l’homme, '
                    'Droit international public & RI.'
                ),
                'departments': [
                    {
                        'slug': 'droit-prive',
                        'name': 'Droit privé',
                        'courses': DROIT_COURSES,
                    },
                    {
                        'slug': 'droit-public',
                        'name': 'Droit public interne',
                        'courses': DROIT_COURSES[:8],
                    },
                    {
                        'slug': 'droits-homme',
                        'name': 'Droits de l’homme',
                        'courses': [
                            c
                            for c in DROIT_COURSES
                            if c[0] in ('DRT112', 'DRT412', 'DRT413', 'DRT421')
                        ]
                        or DROIT_COURSES[-4:],
                    },
                ],
            },
            {
                'slug': 'sciences-eco-gestion',
                'name': 'Faculté des Sciences Économiques et de Gestion',
                'description': (
                    'FASEG (depuis 1954 / Lovanium) — économistes et gestionnaires '
                    'selon le système LMD ; institut IRES.'
                ),
                'departments': [
                    {
                        'slug': 'economie',
                        'name': 'Sciences économiques',
                        'courses': ECO_COURSES,
                    },
                    {'slug': 'gestion', 'name': 'Gestion', 'courses': ECO_COURSES},
                ],
            },
            {
                'slug': 'medecine',
                'name': 'Faculté de Médecine',
                'description': (
                    'Plus de 4 000 étudiants — formation médicale au service '
                    'de la santé publique.'
                ),
                'departments': [
                    {
                        'slug': 'medecine-generale',
                        'name': 'Médecine',
                        'courses': MED_COURSES,
                    },
                ],
            },
            {
                'slug': 'sciences-technologies',
                'name': 'Faculté des Sciences et Technologies',
                'description': (
                    'Pôle scientifique UNIKIN (≈3 500 étudiants). Mentions : '
                    'Mathématiques-Statistique-Informatique, Physique & Technologie, '
                    'Chimie & Industrie, Géosciences, Environnement, Sciences de la vie. '
                    'PDF SGA 2024-2025.'
                ),
                'departments': [
                    {
                        'slug': 'informatique',
                        'name': 'Informatique',
                        'description': (
                            'Filière Informatique de la mention Mathématiques, '
                            'Statistique et Informatique (UNIKIN SGA 2024-2025).'
                        ),
                        'courses': INFO_COURSES,
                    },
                    {
                        'slug': 'mathematiques',
                        'name': 'Mathématiques et statistique',
                        'description': (
                            'Mention Mathématiques, Statistique et Informatique '
                            '(parcours Math & Stat).'
                        ),
                        'courses': MATH_COURSES,
                    },
                    {
                        'slug': 'physique',
                        'name': 'Physique et technologie',
                        'courses': PHY_COURSES,
                    },
                    {
                        'slug': 'chimie',
                        'name': 'Chimie et industrie',
                        'courses': CHIM_COURSES,
                    },
                    {
                        'slug': 'biologie',
                        'name': 'Sciences de la vie',
                        'courses': BIO_COURSES,
                    },
                    {
                        'slug': 'geologie',
                        'name': 'Géosciences (géologie et géomatique)',
                        'courses': GEO_COURSES,
                    },
                    {
                        'slug': 'environnement',
                        'name': 'Environnement',
                        'courses': BIO_COURSES + AGRO_COURSES[:2],
                    },
                ],
            },
            {
                'slug': 'polytechnique',
                'name': 'Faculté Polytechnique',
                'description': (
                    'Formation d’ingénieurs en génie civil, électrique, '
                    'mécanique et informatique.'
                ),
                'departments': [
                    {
                        'slug': 'genie-civil',
                        'name': 'Génie civil',
                        'courses': POLY_CIVIL,
                    },
                    {
                        'slug': 'genie-electrique',
                        'name': 'Génie électrique',
                        'courses': POLY_ELEC,
                    },
                    {
                        'slug': 'genie-mecanique',
                        'name': 'Génie mécanique',
                        'courses': POLY_MECA,
                    },
                    {
                        'slug': 'genie-informatique',
                        'name': 'Génie informatique',
                        'courses': INFO_COURSES[:18],
                    },
                ],
            },
            {
                'slug': 'lettres-sciences-humaines',
                'name': 'Faculté des Lettres et Sciences Humaines',
                'description': (
                    'FLSH (créée 1956) — formation critique et intellectuelle.'
                ),
                'departments': [
                    {'slug': 'lettres', 'name': 'Lettres', 'courses': LETTRES_COURSES},
                    {
                        'slug': 'histoire',
                        'name': 'Histoire',
                        'courses': LETTRES_COURSES,
                    },
                ],
            },
            {
                'slug': 'psychologie-sciences-education',
                'name': 'Faculté de Psychologie et Sciences de l’Éducation',
                'description': (
                    'FPSE — héritière de l’Institut de Psychologie et Pédagogie '
                    'de Lovanium.'
                ),
                'departments': [
                    {
                        'slug': 'psychologie',
                        'name': 'Psychologie',
                        'courses': PSY_COURSES,
                    },
                    {
                        'slug': 'sciences-education',
                        'name': 'Sciences de l’éducation',
                        'courses': PEDAGO_COURSES,
                    },
                ],
            },
            {
                'slug': 'sciences-agronomiques',
                'name': 'Faculté des Sciences Agronomiques et de l’Environnement',
                'description': (
                    'Ingénieurs agronomes et spécialistes du développement '
                    'durable (GRNR, GFB, GSEA, masters MAGF/MGB…).'
                ),
                'departments': [
                    {
                        'slug': 'agronomie',
                        'name': 'Gestion des ressources naturelles renouvelables',
                        'courses': AGRO_COURSES,
                    },
                    {
                        'slug': 'zootechnie',
                        'name': 'Zootechnie',
                        'courses': AGRO_COURSES[:3],
                    },
                ],
            },
            {
                'slug': 'medecine-dentaire',
                'name': 'Faculté de Médecine Dentaire',
                'description': (
                    'Consultation, chirurgie, microchirurgie et formation clinique.'
                ),
                'departments': [
                    {
                        'slug': 'odontologie',
                        'name': 'Odontologie',
                        'courses': DENT_COURSES,
                    },
                ],
            },
            {
                'slug': 'pharmacie',
                'name': 'Faculté des Sciences Pharmaceutiques',
                'description': (
                    'Formation des pharmaciens (PharmD) et techniciens '
                    'en techniques pharmaceutiques.'
                ),
                'departments': [
                    {
                        'slug': 'pharmacie',
                        'name': 'Pharmacie',
                        'courses': PHARMA_COURSES,
                    },
                ],
            },
            {
                'slug': 'sante-publique',
                'name': 'École de Santé Publique de Kinshasa',
                'description': 'École postuniversitaire de santé publique (UNIKIN).',
                'departments': [
                    {
                        'slug': 'sante-publique',
                        'name': 'Santé publique',
                        'courses': SANTE_PUB,
                    },
                ],
            },
            {
                'slug': 'sciences-sociales',
                'name': 'Faculté des Sciences Sociales, Administratives et Politiques',
                'description': (
                    'FSSAP — sciences politiques, relations internationales, '
                    'administration publique et sciences du travail.'
                ),
                'departments': [
                    {
                        'slug': 'sciences-politiques',
                        'name': 'Sciences politiques',
                        'courses': SOC_COURSES,
                    },
                    {
                        'slug': 'administration-publique',
                        'name': 'Administration publique',
                        'courses': SOC_COURSES,
                    },
                ],
            },
            {
                'slug': 'medecine-veterinaire',
                'name': 'Faculté de Médecine Vétérinaire',
                'description': (
                    'Créée 2009-2010 — sécurité alimentaire, santé animale, One Health.'
                ),
                'departments': [
                    {
                        'slug': 'medecine-veterinaire',
                        'name': 'Médecine vétérinaire',
                        'courses': VET_COURSES,
                    },
                ],
            },
            {
                'slug': 'petrole-gaz',
                'name': 'Faculté de Pétrole, Gaz et Énergies Nouvelles',
                'description': (
                    'Souveraineté énergétique et énergies renouvelables de la RDC.'
                ),
                'departments': [
                    {
                        'slug': 'petrole-gaz',
                        'name': 'Pétrole et gaz',
                        'courses': PETROLE_COURSES,
                    },
                ],
            },
        ],
    },
    {
        'slug': 'upn',
        'name': 'Université Pédagogique Nationale',
        'city': 'Kinshasa',
        'primary_color': '#0B5C56',
        'accent_color': '#F4A261',
        'description': (
            'Référence en formation des enseignants. '
            'Source : https://faculte.upnrdc.net/public/domains'
        ),
        'faculties': [
            {
                'slug': 'droit',
                'name': 'Faculté de Droit',
                'departments': [
                    {'slug': 'droit', 'name': 'Droit', 'courses': DROIT_COURSES},
                ],
            },
            {
                'slug': 'sciences-eco-gestion',
                'name': 'Faculté des Sciences Économiques et de Gestion',
                'departments': [
                    {'slug': 'economie-gestion', 'name': 'Économie et gestion', 'courses': ECO_COURSES},
                ],
            },
            {
                'slug': 'lettres-sciences-humaines',
                'name': 'Faculté des Lettres et Sciences Humaines',
                'departments': [
                    {'slug': 'lettres', 'name': 'Lettres', 'courses': LETTRES_COURSES},
                ],
            },
            {
                'slug': 'medecine-veterinaire',
                'name': 'Faculté de Médecine Vétérinaire',
                'departments': [
                    {
                        'slug': 'medecine-veterinaire',
                        'name': 'Médecine vétérinaire',
                        'courses': VET_COURSES,
                    },
                ],
            },
            {
                'slug': 'psychologie-sciences-education',
                'name': 'Faculté de Psychologie et des Sciences de l’Éducation',
                'departments': [
                    {'slug': 'psychologie', 'name': 'Psychologie', 'courses': PSY_COURSES},
                    {
                        'slug': 'sciences-education',
                        'name': 'Sciences de l’éducation',
                        'courses': PEDAGO_COURSES,
                    },
                ],
            },
            {
                'slug': 'sciences-sociales',
                'name': 'Faculté des Sciences Sociales, Administratives et Politiques',
                'departments': [
                    {
                        'slug': 'sciences-sociales',
                        'name': 'Sciences sociales',
                        'courses': SOC_COURSES,
                    },
                ],
            },
            {
                'slug': 'sciences-sante',
                'name': 'Faculté des Sciences de la Santé',
                'departments': [
                    {
                        'slug': 'sciences-sante',
                        'name': 'Sciences de la santé',
                        'courses': SANTE_PUB,
                    },
                ],
            },
            {
                'slug': 'pedagogie-didactique',
                'name': 'Faculté de Pédagogie et de Didactique des Disciplines',
                'departments': [
                    {
                        'slug': 'didactique',
                        'name': 'Didactique des disciplines',
                        'courses': PEDAGO_COURSES,
                    },
                    {
                        'slug': 'informatique-pedagogique',
                        'name': 'Informatique pédagogique',
                        'courses': INFO_COURSES[:10] + PEDAGO_COURSES[4:6],
                    },
                ],
            },
            {
                'slug': 'sciences-technologies',
                'name': 'Faculté des Sciences et Technologies',
                'departments': [
                    {'slug': 'informatique', 'name': 'Informatique', 'courses': INFO_COURSES},
                    {'slug': 'mathematiques', 'name': 'Mathématiques', 'courses': MATH_COURSES},
                    {'slug': 'physique', 'name': 'Physique', 'courses': PHY_COURSES},
                    {'slug': 'chimie', 'name': 'Chimie', 'courses': CHIM_COURSES},
                    {'slug': 'biologie', 'name': 'Biologie', 'courses': BIO_COURSES},
                ],
            },
            {
                'slug': 'sciences-agronomiques',
                'name': 'Faculté des Sciences Agronomiques et Environnement',
                'departments': [
                    {'slug': 'agronomie', 'name': 'Agronomie', 'courses': AGRO_COURSES},
                ],
            },
        ],
    },
    {
        'slug': 'upc',
        'name': 'Université Protestante au Congo',
        'city': 'Kinshasa',
        'primary_color': '#7B2D8E',
        'accent_color': '#E9C46A',
        'description': (
            'Université confessionnelle (ECC) — 5 facultés. '
            'FASI créée en 2017. Source : https://upc.ac.cd'
        ),
        'faculties': [
            {
                'slug': 'theologie',
                'name': 'Faculté de Théologie',
                'departments': [
                    {'slug': 'theologie', 'name': 'Théologie', 'courses': THEO_COURSES},
                ],
            },
            {
                'slug': 'fase',
                'name': 'Faculté d’Administration des Affaires et Sciences Économiques',
                'description': 'FASE',
                'departments': [
                    {
                        'slug': 'administration-affaires',
                        'name': 'Administration des affaires',
                        'courses': ECO_COURSES,
                    },
                    {
                        'slug': 'sciences-economiques',
                        'name': 'Sciences économiques',
                        'courses': ECO_COURSES,
                    },
                ],
            },
            {
                'slug': 'droit',
                'name': 'Faculté de Droit',
                'departments': [
                    {'slug': 'droit', 'name': 'Droit', 'courses': DROIT_COURSES},
                ],
            },
            {
                'slug': 'medecine',
                'name': 'Faculté de Médecine',
                'departments': [
                    {'slug': 'medecine', 'name': 'Médecine', 'courses': MED_COURSES},
                ],
            },
            {
                'slug': 'fasi',
                'name': 'Faculté des Sciences Informatiques',
                'description': (
                    'FASI (2017) — Génie informatique, Systèmes informatiques, '
                    'Intelligence artificielle.'
                ),
                'departments': [
                    {
                        'slug': 'genie-informatique',
                        'name': 'Génie informatique',
                        'courses': INFO_COURSES,
                    },
                    {
                        'slug': 'systemes-informatiques',
                        'name': 'Systèmes informatiques',
                        'courses': SYS_INFO_COURSES + INFO_COURSES[4:12],
                    },
                    {
                        'slug': 'intelligence-artificielle',
                        'name': 'Intelligence artificielle',
                        'courses': IA_COURSES + INFO_COURSES[:6],
                    },
                ],
            },
        ],
    },
]

REWARD_PRIZES = [
    {
        'name': '1 000 FC portefeuille',
        'description': 'Crédit cash sur ton portefeuille Akadex.',
        'category': 'cash',
        'min_points': 100,
        'points_cost': 100,
        'weight': 25,
    },
    {
        'name': '5 000 FC portefeuille',
        'description': 'Crédit cash supérieur.',
        'category': 'cash',
        'min_points': 100,
        'points_cost': 100,
        'weight': 8,
    },
    {
        'name': 'Livre numérique',
        'description': 'Un ebook académique à télécharger.',
        'category': 'ebook',
        'min_points': 100,
        'points_cost': 100,
        'weight': 20,
    },
    {
        'name': 'Livre physique',
        'description': 'Un ouvrage envoyé ou à retirer sur campus.',
        'category': 'book',
        'min_points': 200,
        'points_cost': 150,
        'weight': 10,
    },
    {
        'name': '1 mois Premium',
        'description': 'Accès Premium gratuit pendant 30 jours.',
        'category': 'premium',
        'min_points': 100,
        'points_cost': 100,
        'weight': 15,
    },
    {
        'name': 'Accès cours professeur',
        'description': 'Accès gratuit à un contenu premium d’un enseignant.',
        'category': 'teacher',
        'min_points': 150,
        'points_cost': 120,
        'weight': 12,
    },
    {
        'name': 'Réduction partenaire 15 %',
        'description': 'Code promo sur un service partenaire (librairie, coworking…).',
        'category': 'discount',
        'min_points': 100,
        'points_cost': 100,
        'weight': 18,
    },
]
