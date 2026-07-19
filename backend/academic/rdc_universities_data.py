"""
Données de seed — universités et établissements d’enseignement supérieur de la RDC.

Catalogue structurel (noms, sigles, facultés, départements) destiné au seeding
Django / LMD congolais. Les intitulés s’alignent sur les filières typiques des
établissements publics et privés reconnus.

Référence officielle — Registre national des établissements d’enseignement
supérieur et universitaire (MINESURSI) :
https://re.minesursi.gouv.cd/

Sources complémentaires : sites institutionnels et pages Wikipedia des
universités de la République démocratique du Congo. À croiser avec le registre
MINESURSI pour toute mise à jour réglementaire.
"""

# Promotions LMD par défaut : (libellé, ordre)
DEFAULT_PROMOTIONS = [
    ('L1', 1),
    ('L2', 2),
    ('L3', 3),
    ('M1', 4),
    ('M2', 5),
]

RDC_UNIVERSITIES = [
    # -------------------------------------------------------------------------
    # Kinshasa
    # -------------------------------------------------------------------------
    {
        'name': 'Université de Kinshasa',
        'slug': 'unikin',
        'city': 'Kinshasa',
        'sigle': 'UNIKIN',
        'faculties': [
            {
                'name': 'Faculté des Sciences',
                'slug': 'sciences',
                'departments': [
                    'Mathématiques-Informatique',
                    'Physique',
                    'Chimie',
                    'Biologie',
                    'Géologie',
                ],
            },
            {
                'name': 'Faculté de Médecine',
                'slug': 'medecine',
                'departments': [
                    'Médecine générale',
                    'Sciences biomédicales',
                    'Santé publique',
                ],
            },
            {
                'name': 'Faculté de Droit',
                'slug': 'droit',
                'departments': [
                    'Droit privé',
                    'Droit public',
                    'Droit économique et social',
                ],
            },
            {
                'name': 'Faculté des Lettres et Sciences Humaines',
                'slug': 'lettres',
                'departments': [
                    'Lettres et civilisations africaines',
                    'Histoire',
                    'Philosophie',
                    'Langues et littératures',
                ],
            },
            {
                'name': 'Faculté des Sciences Économiques et de Gestion',
                'slug': 'economie',
                'departments': [
                    'Sciences économiques',
                    'Gestion des entreprises',
                    'Sciences commerciales et financières',
                ],
            },
            {
                'name': 'Faculté Polytechnique',
                'slug': 'polytechnique',
                'departments': [
                    'Génie civil',
                    'Génie électrique',
                    'Génie mécanique',
                    'Génie informatique',
                ],
            },
            {
                'name': 'Faculté des Sciences Sociales, Administratives et Politiques',
                'slug': 'sciences-sociales',
                'departments': [
                    'Sciences politiques',
                    'Administration publique',
                    'Relations internationales',
                    'Sociologie',
                ],
            },
            {
                'name': 'Faculté des Sciences Pharmaceutiques',
                'slug': 'pharmacie',
                'departments': [
                    'Pharmacie',
                    'Chimie pharmaceutique',
                    'Biologie pharmaceutique',
                ],
            },
            {
                'name': 'Faculté des Sciences Agronomiques',
                'slug': 'agronomie',
                'departments': [
                    'Production végétale',
                    'Production animale',
                    'Économie agricole',
                    'Ressources naturelles',
                ],
            },
        ],
    },
    {
        'name': 'Université pédagogique nationale',
        'slug': 'upn',
        'city': 'Kinshasa',
        'sigle': 'UPN',
        'faculties': [
            {
                'name': 'Faculté de Pédagogie et de Didactique des Disciplines',
                'slug': 'pedagogie-didactique',
                'departments': [
                    'Didactique des sciences',
                    'Didactique des lettres',
                    'Informatique pédagogique',
                    'Éducation physique et sportive',
                ],
            },
            {
                'name': 'Faculté de Psychologie et des Sciences de l’Éducation',
                'slug': 'psychologie-education',
                'departments': [
                    'Psychologie',
                    'Sciences de l’éducation',
                    'Orientation scolaire et professionnelle',
                ],
            },
            {
                'name': 'Faculté des Sciences et Technologies',
                'slug': 'sciences-technologies',
                'departments': [
                    'Mathématiques',
                    'Physique',
                    'Chimie',
                    'Biologie',
                    'Informatique',
                ],
            },
            {
                'name': 'Faculté des Lettres et Sciences Humaines',
                'slug': 'lettres',
                'departments': [
                    'Lettres françaises',
                    'Histoire-Géographie',
                    'Langues africaines',
                ],
            },
            {
                'name': 'Faculté des Sciences Économiques et de Gestion',
                'slug': 'economie',
                'departments': [
                    'Économie',
                    'Gestion',
                    'Commerce international',
                ],
            },
            {
                'name': 'Faculté de Droit',
                'slug': 'droit',
                'departments': [
                    'Droit privé',
                    'Droit public',
                ],
            },
            {
                'name': 'Faculté des Sciences Agronomiques et Environnement',
                'slug': 'agronomie',
                'departments': [
                    'Agronomie générale',
                    'Environnement et développement durable',
                ],
            },
        ],
    },
    {
        'name': 'Université protestante du Congo',
        'slug': 'upc',
        'city': 'Kinshasa',
        'sigle': 'UPC',
        'faculties': [
            {
                'name': 'Faculté de Théologie',
                'slug': 'theologie',
                'departments': [
                    'Théologie systématique',
                    'Théologie pratique',
                    'Études bibliques',
                ],
            },
            {
                'name': 'Faculté d’Administration des Affaires et Sciences Économiques',
                'slug': 'fase',
                'departments': [
                    'Administration des affaires',
                    'Sciences économiques',
                    'Comptabilité et finance',
                ],
            },
            {
                'name': 'Faculté de Droit',
                'slug': 'droit',
                'departments': [
                    'Droit privé',
                    'Droit public',
                ],
            },
            {
                'name': 'Faculté de Médecine',
                'slug': 'medecine',
                'departments': [
                    'Médecine générale',
                    'Sciences fondamentales',
                ],
            },
            {
                'name': 'Faculté des Sciences Informatiques',
                'slug': 'fasi',
                'departments': [
                    'Génie informatique',
                    'Systèmes informatiques',
                    'Intelligence artificielle',
                ],
            },
        ],
    },
    {
        'name': 'Université catholique du Congo',
        'slug': 'ucc',
        'city': 'Kinshasa',
        'sigle': 'UCC',
        'faculties': [
            {
                'name': 'Faculté de Théologie',
                'slug': 'theologie',
                'departments': [
                    'Théologie dogmatique',
                    'Théologie morale',
                    'Histoire de l’Église',
                ],
            },
            {
                'name': 'Faculté de Philosophie',
                'slug': 'philosophie',
                'departments': [
                    'Philosophie générale',
                    'Philosophie africaine',
                    'Éthique et société',
                ],
            },
            {
                'name': 'Faculté de Droit Canonique',
                'slug': 'droit-canonique',
                'departments': [
                    'Droit canonique',
                    'Droit civil ecclésiastique',
                ],
            },
            {
                'name': 'Faculté des Sciences Sociales',
                'slug': 'sciences-sociales',
                'departments': [
                    'Sociologie',
                    'Sciences politiques',
                    'Développement communautaire',
                ],
            },
            {
                'name': 'Faculté des Sciences Économiques et de Gestion',
                'slug': 'economie',
                'departments': [
                    'Économie',
                    'Gestion',
                    'Entrepreneuriat',
                ],
            },
            {
                'name': 'Faculté de Droit',
                'slug': 'droit',
                'departments': [
                    'Droit privé',
                    'Droit public',
                    'Droit international',
                ],
            },
        ],
    },
    {
        'name': 'Université libre de Kinshasa',
        'slug': 'ulk',
        'city': 'Kinshasa',
        'sigle': 'ULK',
        'faculties': [
            {
                'name': 'Faculté de Droit',
                'slug': 'droit',
                'departments': [
                    'Droit privé',
                    'Droit public',
                    'Droit des affaires',
                ],
            },
            {
                'name': 'Faculté des Sciences Économiques et de Gestion',
                'slug': 'economie',
                'departments': [
                    'Économie',
                    'Gestion des entreprises',
                    'Banque et finance',
                ],
            },
            {
                'name': 'Faculté des Sciences Informatiques',
                'slug': 'informatique',
                'departments': [
                    'Informatique de gestion',
                    'Réseaux et télécoms',
                    'Génie logiciel',
                ],
            },
            {
                'name': 'Faculté des Sciences Sociales',
                'slug': 'sciences-sociales',
                'departments': [
                    'Relations internationales',
                    'Communication',
                    'Administration publique',
                ],
            },
            {
                'name': 'Faculté de Médecine',
                'slug': 'medecine',
                'departments': [
                    'Médecine',
                    'Sciences infirmières',
                ],
            },
        ],
    },
    {
        'name': 'Académie des beaux-arts',
        'slug': 'aba',
        'city': 'Kinshasa',
        'sigle': 'ABA',
        'faculties': [
            {
                'name': 'Faculté des Arts plastiques',
                'slug': 'arts-plastiques',
                'departments': [
                    'Peinture',
                    'Sculpture',
                    'Arts graphiques',
                ],
            },
            {
                'name': 'Faculté d’Architecture et d’Urbanisme',
                'slug': 'architecture',
                'departments': [
                    'Architecture',
                    'Urbanisme',
                    'Design d’espace',
                ],
            },
            {
                'name': 'Faculté des Arts du spectacle',
                'slug': 'arts-spectacle',
                'departments': [
                    'Théâtre',
                    'Musique',
                    'Danse et chorégraphie',
                ],
            },
            {
                'name': 'Faculté de Communication visuelle',
                'slug': 'communication-visuelle',
                'departments': [
                    'Design graphique',
                    'Photographie',
                    'Cinéma et audiovisuel',
                ],
            },
        ],
    },
    {
        'name': 'Institut supérieur de techniques appliquées de Kinshasa',
        'slug': 'ista-kinshasa',
        'city': 'Kinshasa',
        'sigle': 'ISTA',
        'faculties': [
            {
                'name': 'Faculté de Génie civil et Architecture',
                'slug': 'genie-civil',
                'departments': [
                    'Génie civil',
                    'Topographie',
                    'Bâtiment et travaux publics',
                ],
            },
            {
                'name': 'Faculté de Génie électrique et Électronique',
                'slug': 'genie-electrique',
                'departments': [
                    'Électrotechnique',
                    'Électronique',
                    'Automatique et régulation',
                ],
            },
            {
                'name': 'Faculté de Génie mécanique',
                'slug': 'genie-mecanique',
                'departments': [
                    'Mécanique générale',
                    'Maintenance industrielle',
                    'Énergétique',
                ],
            },
            {
                'name': 'Faculté d’Informatique et Télécommunications',
                'slug': 'informatique-telecoms',
                'departments': [
                    'Informatique industrielle',
                    'Télécommunications',
                    'Systèmes embarqués',
                ],
            },
            {
                'name': 'Faculté de Chimie et Industries',
                'slug': 'chimie-industries',
                'departments': [
                    'Génie chimique',
                    'Industries alimentaires',
                ],
            },
        ],
    },
    {
        'name': 'Université américaine de Kinshasa',
        'slug': 'auk',
        'city': 'Kinshasa',
        'sigle': 'AUK',
        'faculties': [
            {
                'name': 'Faculté des Sciences de gestion',
                'slug': 'gestion',
                'departments': [
                    'Business Administration',
                    'Finance et comptabilité',
                    'Marketing digital',
                ],
            },
            {
                'name': 'Faculté des Sciences et Technologies',
                'slug': 'sciences-technologies',
                'departments': [
                    'Informatique',
                    'Science des données',
                    'Cybersécurité',
                ],
            },
            {
                'name': 'Faculté de Droit et Sciences politiques',
                'slug': 'droit-sciences-politiques',
                'departments': [
                    'Droit',
                    'Relations internationales',
                ],
            },
            {
                'name': 'Faculté des Sciences de la santé',
                'slug': 'sciences-sante',
                'departments': [
                    'Santé publique',
                    'Sciences infirmières',
                ],
            },
        ],
    },
    # -------------------------------------------------------------------------
    # Lubumbashi
    # -------------------------------------------------------------------------
    {
        'name': 'Université de Lubumbashi',
        'slug': 'unilu',
        'city': 'Lubumbashi',
        'sigle': 'UNILU',
        'faculties': [
            {
                'name': 'Faculté des Sciences',
                'slug': 'sciences',
                'departments': [
                    'Mathématiques-Informatique',
                    'Physique',
                    'Chimie',
                    'Biologie',
                    'Géologie',
                ],
            },
            {
                'name': 'Faculté Polytechnique',
                'slug': 'polytechnique',
                'departments': [
                    'Génie civil',
                    'Génie minier',
                    'Génie métallurgique',
                    'Génie électrique',
                ],
            },
            {
                'name': 'Faculté de Médecine',
                'slug': 'medecine',
                'departments': [
                    'Médecine générale',
                    'Sciences biomédicales',
                    'Santé publique',
                ],
            },
            {
                'name': 'Faculté de Droit',
                'slug': 'droit',
                'departments': [
                    'Droit privé',
                    'Droit public',
                    'Droit minier et environnemental',
                ],
            },
            {
                'name': 'Faculté des Sciences Économiques et de Gestion',
                'slug': 'economie',
                'departments': [
                    'Sciences économiques',
                    'Gestion',
                    'Économie minière',
                ],
            },
            {
                'name': 'Faculté des Lettres et Sciences Humaines',
                'slug': 'lettres',
                'departments': [
                    'Lettres',
                    'Histoire',
                    'Langues',
                ],
            },
            {
                'name': 'Faculté des Sciences Sociales',
                'slug': 'sciences-sociales',
                'departments': [
                    'Sociologie',
                    'Anthropologie',
                    'Sciences politiques',
                ],
            },
            {
                'name': 'Faculté des Sciences Agronomiques',
                'slug': 'agronomie',
                'departments': [
                    'Agronomie',
                    'Zootechnie',
                    'Environnement',
                ],
            },
        ],
    },
    {
        'name': 'Université Nouveaux Horizons',
        'slug': 'unh',
        'city': 'Lubumbashi',
        'sigle': 'UNH',
        'faculties': [
            {
                'name': 'Faculté des Sciences Économiques et de Gestion',
                'slug': 'economie',
                'departments': [
                    'Gestion des entreprises',
                    'Finance',
                    'Marketing',
                ],
            },
            {
                'name': 'Faculté de Droit',
                'slug': 'droit',
                'departments': [
                    'Droit privé',
                    'Droit des affaires',
                ],
            },
            {
                'name': 'Faculté des Sciences Informatiques',
                'slug': 'informatique',
                'departments': [
                    'Informatique de gestion',
                    'Réseaux et systèmes',
                    'Développement logiciel',
                ],
            },
            {
                'name': 'Faculté des Sciences de la santé',
                'slug': 'sciences-sante',
                'departments': [
                    'Médecine',
                    'Pharmacie',
                    'Sciences infirmières',
                ],
            },
            {
                'name': 'Faculté des Sciences sociales et de la communication',
                'slug': 'sciences-sociales',
                'departments': [
                    'Communication',
                    'Relations publiques',
                    'Journalisme',
                ],
            },
        ],
    },
    # -------------------------------------------------------------------------
    # Autres villes majeures
    # -------------------------------------------------------------------------
    {
        'name': 'Université de Kisangani',
        'slug': 'unikis',
        'city': 'Kisangani',
        'sigle': 'UNIKIS',
        'faculties': [
            {
                'name': 'Faculté des Sciences',
                'slug': 'sciences',
                'departments': [
                    'Mathématiques-Informatique',
                    'Physique',
                    'Chimie',
                    'Biologie',
                ],
            },
            {
                'name': 'Faculté de Médecine et Pharmacie',
                'slug': 'medecine-pharmacie',
                'departments': [
                    'Médecine',
                    'Pharmacie',
                    'Sciences biomédicales',
                ],
            },
            {
                'name': 'Faculté de Droit',
                'slug': 'droit',
                'departments': [
                    'Droit privé',
                    'Droit public',
                ],
            },
            {
                'name': 'Faculté des Sciences Économiques et de Gestion',
                'slug': 'economie',
                'departments': [
                    'Économie',
                    'Gestion',
                ],
            },
            {
                'name': 'Faculté des Sciences Agronomiques',
                'slug': 'agronomie',
                'departments': [
                    'Agronomie tropicale',
                    'Foresterie',
                    'Environnement',
                ],
            },
            {
                'name': 'Faculté des Lettres et Sciences Humaines',
                'slug': 'lettres',
                'departments': [
                    'Lettres',
                    'Histoire',
                    'Langues africaines',
                ],
            },
            {
                'name': 'Faculté des Sciences Sociales',
                'slug': 'sciences-sociales',
                'departments': [
                    'Sociologie',
                    'Anthropologie',
                    'Développement rural',
                ],
            },
        ],
    },
    {
        'name': 'Université de Goma',
        'slug': 'unigom',
        'city': 'Goma',
        'sigle': 'UNIGOM',
        'faculties': [
            {
                'name': 'Faculté des Sciences',
                'slug': 'sciences',
                'departments': [
                    'Mathématiques-Informatique',
                    'Physique-Chimie',
                    'Biologie-Géologie',
                ],
            },
            {
                'name': 'Faculté de Médecine',
                'slug': 'medecine',
                'departments': [
                    'Médecine générale',
                    'Santé publique',
                ],
            },
            {
                'name': 'Faculté de Droit',
                'slug': 'droit',
                'departments': [
                    'Droit privé',
                    'Droit public',
                    'Droit international humanitaire',
                ],
            },
            {
                'name': 'Faculté des Sciences Économiques et de Gestion',
                'slug': 'economie',
                'departments': [
                    'Économie',
                    'Gestion',
                    'Entrepreneuriat',
                ],
            },
            {
                'name': 'Faculté des Sciences Sociales et Politiques',
                'slug': 'sciences-sociales',
                'departments': [
                    'Sciences politiques',
                    'Relations internationales',
                    'Sociologie',
                ],
            },
            {
                'name': 'Faculté des Sciences Agronomiques et Environnement',
                'slug': 'agronomie',
                'departments': [
                    'Agronomie',
                    'Environnement volcanique',
                ],
            },
        ],
    },
    {
        'name': 'Université officielle de Bukavu',
        'slug': 'uob',
        'city': 'Bukavu',
        'sigle': 'UOB',
        'faculties': [
            {
                'name': 'Faculté des Sciences',
                'slug': 'sciences',
                'departments': [
                    'Mathématiques-Informatique',
                    'Physique',
                    'Chimie',
                    'Biologie',
                ],
            },
            {
                'name': 'Faculté de Médecine',
                'slug': 'medecine',
                'departments': [
                    'Médecine',
                    'Sciences biomédicales',
                ],
            },
            {
                'name': 'Faculté de Droit',
                'slug': 'droit',
                'departments': [
                    'Droit privé',
                    'Droit public',
                ],
            },
            {
                'name': 'Faculté des Sciences Économiques et de Gestion',
                'slug': 'economie',
                'departments': [
                    'Économie',
                    'Gestion',
                ],
            },
            {
                'name': 'Faculté des Sciences Sociales',
                'slug': 'sciences-sociales',
                'departments': [
                    'Sociologie',
                    'Sciences politiques',
                    'Développement',
                ],
            },
            {
                'name': 'Faculté des Sciences Agronomiques',
                'slug': 'agronomie',
                'departments': [
                    'Agronomie',
                    'Zootechnie',
                    'Environnement',
                ],
            },
        ],
    },
    {
        'name': 'Université catholique de Bukavu',
        'slug': 'ucb',
        'city': 'Bukavu',
        'sigle': 'UCB',
        'faculties': [
            {
                'name': 'Faculté de Médecine',
                'slug': 'medecine',
                'departments': [
                    'Médecine générale',
                    'Sciences fondamentales',
                    'Santé publique',
                ],
            },
            {
                'name': 'Faculté de Droit',
                'slug': 'droit',
                'departments': [
                    'Droit privé',
                    'Droit public',
                    'Droit des affaires',
                ],
            },
            {
                'name': 'Faculté des Sciences Économiques et de Gestion',
                'slug': 'economie',
                'departments': [
                    'Économie',
                    'Gestion',
                    'Comptabilité',
                ],
            },
            {
                'name': 'Faculté des Sciences Agronomiques',
                'slug': 'agronomie',
                'departments': [
                    'Agronomie',
                    'Développement rural',
                ],
            },
            {
                'name': 'Faculté des Sciences Sociales',
                'slug': 'sciences-sociales',
                'departments': [
                    'Sociologie',
                    'Communication sociale',
                    'Travail social',
                ],
            },
            {
                'name': 'Faculté de Théologie',
                'slug': 'theologie',
                'departments': [
                    'Théologie',
                    'Études religieuses',
                ],
            },
        ],
    },
    {
        'name': 'Université de Kananga',
        'slug': 'unikan',
        'city': 'Kananga',
        'sigle': 'UNIKAN',
        'faculties': [
            {
                'name': 'Faculté des Sciences',
                'slug': 'sciences',
                'departments': [
                    'Mathématiques-Informatique',
                    'Physique-Chimie',
                    'Biologie',
                ],
            },
            {
                'name': 'Faculté de Droit',
                'slug': 'droit',
                'departments': [
                    'Droit privé',
                    'Droit public',
                ],
            },
            {
                'name': 'Faculté des Sciences Économiques et de Gestion',
                'slug': 'economie',
                'departments': [
                    'Économie',
                    'Gestion',
                ],
            },
            {
                'name': 'Faculté des Lettres et Sciences Humaines',
                'slug': 'lettres',
                'departments': [
                    'Lettres',
                    'Histoire',
                    'Langues nationales',
                ],
            },
            {
                'name': 'Faculté des Sciences Sociales',
                'slug': 'sciences-sociales',
                'departments': [
                    'Sociologie',
                    'Anthropologie',
                    'Sciences politiques',
                ],
            },
            {
                'name': 'Faculté des Sciences Agronomiques',
                'slug': 'agronomie',
                'departments': [
                    'Agronomie',
                    'Environnement',
                ],
            },
        ],
    },
    {
        'name': 'Université officielle de Mbuji-Mayi',
        'slug': 'uom',
        'city': 'Mbuji-Mayi',
        'sigle': 'UOM',
        'faculties': [
            {
                'name': 'Faculté des Sciences',
                'slug': 'sciences',
                'departments': [
                    'Mathématiques-Informatique',
                    'Physique',
                    'Chimie',
                    'Géologie',
                ],
            },
            {
                'name': 'Faculté de Droit',
                'slug': 'droit',
                'departments': [
                    'Droit privé',
                    'Droit public',
                    'Droit minier',
                ],
            },
            {
                'name': 'Faculté des Sciences Économiques et de Gestion',
                'slug': 'economie',
                'departments': [
                    'Économie',
                    'Gestion',
                    'Économie diamantifère',
                ],
            },
            {
                'name': 'Faculté de Médecine',
                'slug': 'medecine',
                'departments': [
                    'Médecine',
                    'Sciences biomédicales',
                ],
            },
            {
                'name': 'Faculté des Lettres et Sciences Humaines',
                'slug': 'lettres',
                'departments': [
                    'Lettres',
                    'Histoire',
                ],
            },
            {
                'name': 'Faculté des Sciences Sociales',
                'slug': 'sciences-sociales',
                'departments': [
                    'Sociologie',
                    'Sciences politiques',
                ],
            },
        ],
    },
    {
        'name': 'Université Joseph Kasa-Vubu',
        'slug': 'ujkv',
        'city': 'Boma',
        'sigle': 'UKV',
        'faculties': [
            {
                'name': 'Faculté des Sciences',
                'slug': 'sciences',
                'departments': [
                    'Mathématiques-Informatique',
                    'Physique-Chimie',
                    'Biologie',
                ],
            },
            {
                'name': 'Faculté de Droit',
                'slug': 'droit',
                'departments': [
                    'Droit privé',
                    'Droit public',
                    'Droit maritime et portuaire',
                ],
            },
            {
                'name': 'Faculté des Sciences Économiques et de Gestion',
                'slug': 'economie',
                'departments': [
                    'Économie',
                    'Gestion',
                    'Commerce international',
                ],
            },
            {
                'name': 'Faculté des Lettres et Sciences Humaines',
                'slug': 'lettres',
                'departments': [
                    'Lettres',
                    'Histoire',
                    'Philosophie',
                ],
            },
            {
                'name': 'Faculté des Sciences Sociales',
                'slug': 'sciences-sociales',
                'departments': [
                    'Sociologie',
                    'Sciences politiques',
                ],
            },
            {
                'name': 'Faculté des Sciences Agronomiques',
                'slug': 'agronomie',
                'departments': [
                    'Agronomie',
                    'Environnement côtier',
                ],
            },
        ],
    },
    {
        'name': 'Université de Kindu',
        'slug': 'uniki',
        'city': 'Kindu',
        'sigle': 'UNIKI',
        'faculties': [
            {
                'name': 'Faculté des Sciences',
                'slug': 'sciences',
                'departments': [
                    'Mathématiques-Informatique',
                    'Physique-Chimie',
                    'Biologie',
                ],
            },
            {
                'name': 'Faculté de Droit',
                'slug': 'droit',
                'departments': [
                    'Droit privé',
                    'Droit public',
                ],
            },
            {
                'name': 'Faculté des Sciences Économiques et de Gestion',
                'slug': 'economie',
                'departments': [
                    'Économie',
                    'Gestion',
                ],
            },
            {
                'name': 'Faculté des Sciences Agronomiques et Environnement',
                'slug': 'agronomie',
                'departments': [
                    'Agronomie',
                    'Foresterie',
                    'Environnement',
                ],
            },
            {
                'name': 'Faculté des Sciences Sociales',
                'slug': 'sciences-sociales',
                'departments': [
                    'Sociologie',
                    'Développement communautaire',
                ],
            },
        ],
    },
    {
        'name': 'Université de Kolwezi',
        'slug': 'unikol',
        'city': 'Kolwezi',
        'sigle': 'UNIKOL',
        'faculties': [
            {
                'name': 'Faculté des Sciences',
                'slug': 'sciences',
                'departments': [
                    'Mathématiques-Informatique',
                    'Chimie',
                    'Géologie',
                ],
            },
            {
                'name': 'Faculté Polytechnique',
                'slug': 'polytechnique',
                'departments': [
                    'Génie minier',
                    'Génie métallurgique',
                    'Génie électrique',
                    'Génie civil',
                ],
            },
            {
                'name': 'Faculté de Droit',
                'slug': 'droit',
                'departments': [
                    'Droit privé',
                    'Droit minier et environnemental',
                ],
            },
            {
                'name': 'Faculté des Sciences Économiques et de Gestion',
                'slug': 'economie',
                'departments': [
                    'Économie',
                    'Gestion',
                    'Économie minière',
                ],
            },
            {
                'name': 'Faculté des Sciences Sociales',
                'slug': 'sciences-sociales',
                'departments': [
                    'Sociologie',
                    'Sciences politiques',
                ],
            },
        ],
    },
    {
        'name': 'Université de Bunia',
        'slug': 'unibu',
        'city': 'Bunia',
        'sigle': 'UNIBU',
        'faculties': [
            {
                'name': 'Faculté des Sciences',
                'slug': 'sciences',
                'departments': [
                    'Mathématiques-Informatique',
                    'Physique-Chimie',
                    'Biologie',
                ],
            },
            {
                'name': 'Faculté de Droit',
                'slug': 'droit',
                'departments': [
                    'Droit privé',
                    'Droit public',
                ],
            },
            {
                'name': 'Faculté des Sciences Économiques et de Gestion',
                'slug': 'economie',
                'departments': [
                    'Économie',
                    'Gestion',
                ],
            },
            {
                'name': 'Faculté des Sciences Agronomiques',
                'slug': 'agronomie',
                'departments': [
                    'Agronomie',
                    'Élevage',
                    'Environnement',
                ],
            },
            {
                'name': 'Faculté des Sciences Sociales',
                'slug': 'sciences-sociales',
                'departments': [
                    'Sociologie',
                    'Anthropologie',
                    'Développement',
                ],
            },
            {
                'name': 'Faculté de Médecine',
                'slug': 'medecine',
                'departments': [
                    'Médecine',
                    'Santé publique',
                ],
            },
        ],
    },
    {
        'name': 'Université de Mbandaka',
        'slug': 'unimba',
        'city': 'Mbandaka',
        'sigle': 'UNIMBA',
        'faculties': [
            {
                'name': 'Faculté des Sciences',
                'slug': 'sciences',
                'departments': [
                    'Mathématiques-Informatique',
                    'Physique-Chimie',
                    'Biologie',
                ],
            },
            {
                'name': 'Faculté de Droit',
                'slug': 'droit',
                'departments': [
                    'Droit privé',
                    'Droit public',
                ],
            },
            {
                'name': 'Faculté des Sciences Économiques et de Gestion',
                'slug': 'economie',
                'departments': [
                    'Économie',
                    'Gestion',
                ],
            },
            {
                'name': 'Faculté des Sciences Agronomiques et Forestières',
                'slug': 'agronomie',
                'departments': [
                    'Agronomie',
                    'Foresterie équatoriale',
                    'Environnement',
                ],
            },
            {
                'name': 'Faculté des Lettres et Sciences Humaines',
                'slug': 'lettres',
                'departments': [
                    'Lettres',
                    'Histoire',
                    'Langues',
                ],
            },
            {
                'name': 'Faculté des Sciences Sociales',
                'slug': 'sciences-sociales',
                'departments': [
                    'Sociologie',
                    'Anthropologie',
                    'Développement communautaire',
                ],
            },
        ],
    },
]
