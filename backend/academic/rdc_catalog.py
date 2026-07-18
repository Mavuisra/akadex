"""
Catalogue académique RDC — UNIKIN, UPN, UPC.

Sources principales :
- UNIKIN : https://www.unikin.ac.cd/facultes-et-entites
- UPN : https://faculte.upnrdc.net/public/domains
- UPC : https://upc.ac.cd / Wikipedia (5 facultés, FASI 2017)

Les programmes de cours listés ci-dessous s’appuient sur les filières
officiellement annoncées et sur les enseignements typiques des départements
concernés (LMD). Ils seront affinés au fur et à mesure des maquettes publiées.
"""

CYCLES = ('L1', 'L2', 'L3', 'Master 1', 'Master 2')

# Cours types par domaine (réutilisés selon le département)
INFO_COURSES = [
    ('INF111', 'Algorithmique', 'Introduction aux algorithmes et à la complexité.', 5, 'L1'),
    ('INF112', 'Introduction à la programmation', 'Bases de la programmation structurée.', 5, 'L1'),
    ('INF121', 'Architecture des ordinateurs', 'Composants, mémoire, jeux d’instructions.', 4, 'L1'),
    ('INF122', 'Mathématiques discrètes', 'Logique, ensembles, graphes élémentaires.', 4, 'L1'),
    ('INF211', 'Structures de données', 'Listes, piles, files, arbres, tables de hachage.', 5, 'L2'),
    ('INF212', 'Programmation orientée objet', 'Classes, héritage, polymorphisme, UML.', 5, 'L2'),
    ('INF221', 'Bases de données', 'Modèle relationnel, SQL, normalisation.', 5, 'L2'),
    ('INF222', 'Systèmes d’exploitation', 'Processus, mémoire, fichiers, concurrence.', 5, 'L2'),
    ('INF311', 'Génie logiciel', 'Cycle de vie, exigences, conception, tests.', 5, 'L3'),
    ('INF312', 'Réseaux informatiques', 'OSI/TCP-IP, routage, services réseau.', 5, 'L3'),
    ('INF313', 'Développement Web', 'HTML/CSS/JS, backends, API REST.', 5, 'L3'),
    ('INF314', 'Sécurité informatique', 'Cryptographie, menaces, sécurisation des systèmes.', 4, 'L3'),
    ('INF411', 'Intelligence artificielle', 'Recherche, apprentissage, applications.', 5, 'Master 1'),
    ('INF412', 'Compilation', 'Analyse lexicale/syntaxique, génération de code.', 5, 'Master 1'),
    ('INF421', 'Data Science et Big Data', 'Pipelines de données, visualisation, ML.', 5, 'Master 2'),
    ('INF422', 'Projet / mémoire de fin d’études', 'Réalisation d’un projet académique encadré.', 6, 'Master 2'),
]

MATH_COURSES = [
    ('MAT111', 'Analyse I', 'Fonctions, limites, dérivées.', 5, 'L1'),
    ('MAT112', 'Algèbre linéaire I', 'Espaces vectoriels, matrices.', 5, 'L1'),
    ('MAT211', 'Analyse II', 'Intégrales, suites et séries.', 5, 'L2'),
    ('MAT212', 'Probabilités', 'Lois discrètes et continues.', 4, 'L2'),
    ('MAT311', 'Statistique mathématique', 'Estimateurs, tests d’hypothèses.', 5, 'L3'),
    ('MAT411', 'Analyse numérique', 'Méthodes numériques et approximation.', 5, 'Master 1'),
]

PHY_COURSES = [
    ('PHY111', 'Mécanique', 'Cinématique, dynamique, énergie.', 5, 'L1'),
    ('PHY121', 'Électricité et magnétisme', 'Lois de Maxwell élémentaires.', 5, 'L1'),
    ('PHY211', 'Thermodynamique', 'Principes et applications.', 4, 'L2'),
    ('PHY311', 'Physique moderne', 'Relativité et quantique introductive.', 5, 'L3'),
]

CHIM_COURSES = [
    ('CHM111', 'Chimie générale', 'Structure de la matière, réactions.', 5, 'L1'),
    ('CHM211', 'Chimie organique', 'Fonctions et mécanismes.', 5, 'L2'),
    ('CHM311', 'Chimie analytique', 'Méthodes qualitatives et quantitatives.', 5, 'L3'),
]

BIO_COURSES = [
    ('BIO111', 'Biologie cellulaire', 'Cellule, organites, métabolisme.', 5, 'L1'),
    ('BIO211', 'Génétique', 'Hérédité, ADN, mutations.', 5, 'L2'),
    ('BIO311', 'Écologie', 'Écosystèmes et biodiversité.', 4, 'L3'),
]

GEO_COURSES = [
    ('GEO111', 'Géologie générale', 'Roches, minéraux, structure terrestre.', 5, 'L1'),
    ('GEO211', 'Pétrologie', 'Roches magmatiques, sédimentaires, métamorphiques.', 5, 'L2'),
    ('GEO311', 'Géologie du Congo', 'Bassins et ressources minérales.', 4, 'L3'),
]

DROIT_COURSES = [
    ('DRT111', 'Introduction au droit', 'Sources, branches et institutions.', 5, 'L1'),
    ('DRT112', 'Droit constitutionnel', 'État, pouvoirs, droits fondamentaux.', 5, 'L1'),
    ('DRT211', 'Droit civil — personnes et famille', 'Personnalité juridique, mariage, filiation.', 5, 'L2'),
    ('DRT212', 'Droit pénal général', 'Infraction, responsabilité, peines.', 5, 'L2'),
    ('DRT311', 'Droit des affaires', 'Sociétés, actes de commerce, contrats.', 5, 'L3'),
    ('DRT312', 'Procédure civile', 'Action en justice et voies de recours.', 5, 'L3'),
    ('DRT411', 'Droit international public', 'Sujets, traités, règlement des différends.', 5, 'Master 1'),
    ('DRT421', 'Mémoire de Master en droit', 'Recherche et rédaction juridique.', 6, 'Master 2'),
]

ECO_COURSES = [
    ('ECO111', 'Microéconomie I', 'Offre, demande, marchés.', 5, 'L1'),
    ('ECO112', 'Macroéconomie I', 'PIB, inflation, politique monétaire.', 5, 'L1'),
    ('GES121', 'Comptabilité générale', 'Cycle comptable, bilan, résultat.', 5, 'L1'),
    ('GES211', 'Gestion financière', 'Analyse financière et décisions d’investissement.', 5, 'L2'),
    ('GES221', 'Marketing', 'Mix marketing et comportement du consommateur.', 4, 'L2'),
    ('ECO311', 'Économie du développement', 'Croissance, pauvreté, politiques publiques.', 5, 'L3'),
    ('GES311', 'Management des organisations', 'Stratégie, RH, pilotage.', 5, 'L3'),
    ('ECO411', 'Économétrie', 'Modèles linéaires et inférence.', 5, 'Master 1'),
    ('GES421', 'Mémoire / projet de gestion', 'Travail de fin de cycle.', 6, 'Master 2'),
]

MED_COURSES = [
    ('MED111', 'Anatomie I', 'Appareils et systèmes du corps humain.', 6, 'L1'),
    ('MED112', 'Physiologie I', 'Fonctions vitales de base.', 5, 'L1'),
    ('MED211', 'Biochimie médicale', 'Métabolisme et pathologie.', 5, 'L2'),
    ('MED311', 'Sémiologie', 'Examen clinique et signes.', 5, 'L3'),
    ('MED411', 'Pathologie médicale', 'Principales affections et thérapeutiques.', 6, 'Master 1'),
]

PEDAGO_COURSES = [
    ('PED111', 'Introduction aux sciences de l’éducation', 'Finalités et acteurs de l’éducation.', 4, 'L1'),
    ('PED121', 'Psychologie de l’apprentissage', 'Motivation, mémoire, stratégies.', 4, 'L1'),
    ('PED211', 'Didactique générale', 'Conception de séquences d’apprentissage.', 5, 'L2'),
    ('PED221', 'Évaluation des apprentissages', 'Types d’évaluation et feedback.', 4, 'L2'),
    ('PED311', 'Didactique du numérique', 'TICE et pédagogie active.', 4, 'L3'),
    ('PED411', 'Recherche en éducation', 'Méthodologie et mémoire.', 5, 'Master 1'),
]

PSY_COURSES = [
    ('PSY111', 'Introduction à la psychologie', 'Courants et méthodes.', 4, 'L1'),
    ('PSY211', 'Psychologie du développement', 'Enfance, adolescence, adulte.', 5, 'L2'),
    ('PSY311', 'Psychologie clinique', 'Diagnostic et accompagnement.', 5, 'L3'),
]

LETTRES_COURSES = [
    ('LET111', 'Méthodologie du travail universitaire', 'Recherche documentaire et rédaction.', 3, 'L1'),
    ('LET121', 'Linguistique générale', 'Langue, signe, communication.', 4, 'L1'),
    ('LET211', 'Littérature africaine', 'Auteurs et courants contemporains.', 4, 'L2'),
    ('HIS211', 'Histoire de l’Afrique centrale', 'Colonisation, indépendances, État.', 4, 'L2'),
    ('LET311', 'Séminaire de recherche', 'Problématique et sources.', 5, 'L3'),
]

SOC_COURSES = [
    ('SOC111', 'Introduction à la sociologie', 'Concepts et méthodes.', 4, 'L1'),
    ('POL211', 'Sciences politiques', 'Pouvoir, État, partis.', 5, 'L2'),
    ('ADM311', 'Administration publique', 'Institutions et gestion publique.', 5, 'L3'),
    ('REL411', 'Relations internationales', 'Acteurs et enjeux mondiaux.', 5, 'Master 1'),
]

AGRO_COURSES = [
    ('AGR111', 'Introduction à l’agronomie', 'Sols, plantes, systèmes de production.', 5, 'L1'),
    ('AGR211', 'Production végétale', 'Cultures tropicales et techniques.', 5, 'L2'),
    ('AGR311', 'Gestion durable des ressources', 'Environnement et sécurité alimentaire.', 5, 'L3'),
]

POLY_CIVIL = [
    ('GC111', 'Dessin technique', 'Plans, cotation, conventions.', 4, 'L1'),
    ('GC211', 'Résistance des matériaux', 'Contraintes, déformations, poutres.', 5, 'L2'),
    ('GC311', 'Béton armé', 'Dimensionnement des structures.', 5, 'L3'),
]

POLY_ELEC = [
    ('GE111', 'Électrotechnique de base', 'Circuits et machines.', 5, 'L1'),
    ('GE211', 'Électronique', 'Composants et montage.', 5, 'L2'),
    ('GE311', 'Automatique', 'Asservissements et régulation.', 5, 'L3'),
]

POLY_MECA = [
    ('GM111', 'Mécanique appliquée', 'Statique et cinématique des machines.', 5, 'L1'),
    ('GM211', 'Technologie de fabrication', 'Usinage et procédés.', 5, 'L2'),
    ('GM311', 'Conception mécanique', 'CAO et dimensionnement.', 5, 'L3'),
]

THEO_COURSES = [
    ('THE111', 'Introduction à la théologie', 'Sources et méthodes.', 4, 'L1'),
    ('THE211', 'Exégèse biblique', 'Ancien et Nouveau Testament.', 5, 'L2'),
    ('THE311', 'Théologie systématique', 'Dogmatique et éthique chrétienne.', 5, 'L3'),
]

PHARMA_COURSES = [
    ('PHA111', 'Chimie pharmaceutique', 'Principes actifs et formulations.', 5, 'L1'),
    ('PHA211', 'Pharmacologie', 'Action des médicaments.', 5, 'L2'),
    ('PHA311', 'Pharmacie galénique', 'Formes pharmaceutiques.', 5, 'L3'),
]

SANTE_PUB = [
    ('SP111', 'Introduction à la santé publique', 'Déterminants de la santé.', 4, 'L1'),
    ('SP211', 'Épidémiologie', 'Mesures et enquêtes.', 5, 'L2'),
    ('SP311', 'Politiques de santé', 'Systèmes de santé en RDC.', 5, 'L3'),
]

VET_COURSES = [
    ('VET111', 'Anatomie animale', 'Espèces domestiques.', 5, 'L1'),
    ('VET211', 'Pathologie vétérinaire', 'Maladies et prophylaxie.', 5, 'L2'),
    ('VET311', 'Santé publique vétérinaire', 'One Health et sécurité alimentaire.', 5, 'L3'),
]

DENT_COURSES = [
    ('DEN111', 'Anatomie dentaire', 'Morphologie et occlusions.', 5, 'L1'),
    ('DEN211', 'Odontologie conservatrice', 'Soins et restaurations.', 5, 'L2'),
    ('DEN311', 'Chirurgie buccale', 'Extractions et actes chirurgicaux.', 5, 'L3'),
]

PETROLE_COURSES = [
    ('PET111', 'Introduction au pétrole et gaz', 'Filière énergétique.', 4, 'L1'),
    ('PET211', 'Géologie pétrolière', 'Bassins et réservoirs.', 5, 'L2'),
    ('PET311', 'Énergies renouvelables', 'Solaire, hydro, biomasse.', 5, 'L3'),
]

IA_COURSES = [
    ('IA111', 'Fondements de l’IA', 'Histoire, agents, problèmes.', 5, 'L1'),
    ('IA211', 'Apprentissage automatique', 'Supervisé, non supervisé.', 5, 'L2'),
    ('IA311', 'Deep learning', 'Réseaux de neurones et applications.', 5, 'L3'),
    ('IA411', 'IA éthique et société', 'Biais, régulation, impacts.', 4, 'Master 1'),
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
            'Plus grande université publique de la RDC. '
            'Source : https://www.unikin.ac.cd/facultes-et-entites'
        ),
        'faculties': [
            {
                'slug': 'droit',
                'name': 'Faculté de Droit',
                'description': 'Formation juridique pour la justice et l’État de droit.',
                'departments': [
                    {'slug': 'droit-prive', 'name': 'Droit privé', 'courses': DROIT_COURSES},
                    {'slug': 'droit-public', 'name': 'Droit public', 'courses': DROIT_COURSES[:6]},
                ],
            },
            {
                'slug': 'sciences-eco-gestion',
                'name': 'Faculté des Sciences Économiques et de Gestion',
                'description': 'FASEG — économistes et gestionnaires (système LMD).',
                'departments': [
                    {'slug': 'economie', 'name': 'Sciences économiques', 'courses': ECO_COURSES},
                    {'slug': 'gestion', 'name': 'Gestion', 'courses': ECO_COURSES},
                ],
            },
            {
                'slug': 'medecine',
                'name': 'Faculté de Médecine',
                'description': 'Formation médicale et santé publique.',
                'departments': [
                    {'slug': 'medecine-generale', 'name': 'Médecine', 'courses': MED_COURSES},
                ],
            },
            {
                'slug': 'sciences-technologies',
                'name': 'Faculté des Sciences et Technologies',
                'description': (
                    'Pôle scientifique UNIKIN. Départements alignés sur les '
                    'filières sciences (maths-stat-informatique, physique, chimie, etc.).'
                ),
                'departments': [
                    {
                        'slug': 'informatique',
                        'name': 'Informatique',
                        'description': (
                            'Filière informatique du pôle Mathématiques, '
                            'Statistique et Informatique.'
                        ),
                        'courses': INFO_COURSES,
                    },
                    {
                        'slug': 'mathematiques',
                        'name': 'Mathématiques',
                        'courses': MATH_COURSES,
                    },
                    {'slug': 'physique', 'name': 'Physique', 'courses': PHY_COURSES},
                    {'slug': 'chimie', 'name': 'Chimie', 'courses': CHIM_COURSES},
                    {'slug': 'biologie', 'name': 'Biologie', 'courses': BIO_COURSES},
                    {'slug': 'geologie', 'name': 'Géologie', 'courses': GEO_COURSES},
                ],
            },
            {
                'slug': 'polytechnique',
                'name': 'Faculté Polytechnique',
                'description': 'Génie civil, électrique, mécanique et informatique.',
                'departments': [
                    {'slug': 'genie-civil', 'name': 'Génie civil', 'courses': POLY_CIVIL},
                    {'slug': 'genie-electrique', 'name': 'Génie électrique', 'courses': POLY_ELEC},
                    {'slug': 'genie-mecanique', 'name': 'Génie mécanique', 'courses': POLY_MECA},
                    {
                        'slug': 'genie-informatique',
                        'name': 'Génie informatique',
                        'courses': INFO_COURSES,
                    },
                ],
            },
            {
                'slug': 'lettres-sciences-humaines',
                'name': 'Faculté des Lettres et Sciences Humaines',
                'description': 'FLSH — formation critique et intellectuelle (depuis 1956).',
                'departments': [
                    {'slug': 'lettres', 'name': 'Lettres', 'courses': LETTRES_COURSES},
                    {'slug': 'histoire', 'name': 'Histoire', 'courses': LETTRES_COURSES},
                ],
            },
            {
                'slug': 'psychologie-sciences-education',
                'name': 'Faculté de Psychologie et Sciences de l’Éducation',
                'description': 'FPSE — psychologie, éducation et organisations.',
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
                'slug': 'sciences-agronomiques',
                'name': 'Faculté des Sciences Agronomiques',
                'description': 'Agronomie et environnement.',
                'departments': [
                    {'slug': 'agronomie', 'name': 'Agronomie', 'courses': AGRO_COURSES},
                ],
            },
            {
                'slug': 'medecine-dentaire',
                'name': 'Faculté de Médecine Dentaire',
                'description': 'Formation clinique et chirurgie dentaire.',
                'departments': [
                    {'slug': 'odontologie', 'name': 'Odontologie', 'courses': DENT_COURSES},
                ],
            },
            {
                'slug': 'pharmacie',
                'name': 'Faculté des Sciences Pharmaceutiques',
                'description': 'Formation des pharmaciens (PharmD).',
                'departments': [
                    {'slug': 'pharmacie', 'name': 'Pharmacie', 'courses': PHARMA_COURSES},
                ],
            },
            {
                'slug': 'sante-publique',
                'name': 'École de Santé Publique de Kinshasa',
                'description': 'École postuniversitaire de santé publique.',
                'departments': [
                    {'slug': 'sante-publique', 'name': 'Santé publique', 'courses': SANTE_PUB},
                ],
            },
            {
                'slug': 'sciences-sociales',
                'name': 'Faculté des Sciences Sociales, Administratives et Politiques',
                'description': 'FSSAP — politique, RI, administration, travail.',
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
                'description': 'Santé animale et One Health.',
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
                'description': 'Souveraineté énergétique et énergies renouvelables.',
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
