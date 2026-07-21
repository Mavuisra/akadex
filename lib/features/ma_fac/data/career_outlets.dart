import '../../../domain/models/models.dart';

/// Fiche d’orientation professionnelle adaptée à une filière.
class CareerOutlet {
  const CareerOutlet({
    required this.domainKey,
    required this.title,
    required this.jobs,
    required this.skills,
    required this.sectors,
    required this.opportunities,
    required this.furtherStudies,
    required this.certifications,
    required this.testimonials,
    required this.internshipsHint,
  });

  final String domainKey;
  final String title;
  final List<String> jobs;
  final List<String> skills;
  final List<String> sectors;
  final List<String> opportunities;
  final List<String> furtherStudies;
  final List<String> certifications;
  final List<String> testimonials;
  final String internshipsHint;
}

abstract final class CareerOutlets {
  static const _default = CareerOutlet(
    domainKey: 'general',
    title: 'Perspectives professionnelles',
    jobs: [
      'Cadre junior en entreprise',
      'Consultant débutant',
      'Chargé de projet',
      'Enseignant / formateur',
    ],
    skills: [
      'Analyse et synthèse',
      'Travail en équipe',
      'Communication écrite et orale',
      'Résolution de problèmes',
    ],
    sectors: [
      'Secteur public',
      'Secteur privé',
      'ONG et coopération',
      'Entrepreneuriat',
    ],
    opportunities: [
      'Stages en entreprise locale',
      'Programmes jeunes talents',
      'Création de startup',
    ],
    furtherStudies: [
      'Master professionnel',
      'Master recherche',
      'Certifications sectorielles',
    ],
    certifications: [
      'Certifications numériques de base',
      'Langues (anglais, français pro)',
    ],
    testimonials: [
      '« Mon diplôme m’a ouvert des portes en entreprise et en freelance. » — Alumni Unikin',
    ],
    internshipsHint:
        'Consulte les offres Alumni et les annonces de ta faculté pour les stages.',
  );

  static const _catalog = <CareerOutlet>[
    CareerOutlet(
      domainKey: 'informatique',
      title: 'Informatique & numérique',
      jobs: [
        'Développeur logiciel',
        'Analyste systèmes',
        'Administrateur réseaux',
        'Data analyst junior',
        'Chef de projet digital',
      ],
      skills: [
        'Programmation',
        'Bases de données',
        'Cybersécurité de base',
        'Gestion de projet Agile',
      ],
      sectors: [
        'Éditeurs de logiciels',
        'Banques & fintech',
        'Télécoms',
        'Administration publique numérique',
      ],
      opportunities: [
        'Stages DevOps / web',
        'Freelance apps mobiles',
        'Hackathons et incubateurs',
      ],
      furtherStudies: [
        'Master Génie logiciel',
        'Master Data / IA',
        'Spécialisation cybersécurité',
      ],
      certifications: [
        'AWS Cloud Practitioner',
        'Cisco CCNA',
        'Google Data Analytics',
      ],
      testimonials: [
        '« Après L3 Info, j’ai rejoint une fintech à Kinshasa en stage puis CDI. » — Alumni FASI',
      ],
      internshipsHint:
          'Cible les cabinets IT, banques et startups tech de ta ville.',
    ),
    CareerOutlet(
      domainKey: 'droit',
      title: 'Droit & sciences juridiques',
      jobs: [
        'Assistant juridique',
        'Clerc de notaire',
        'Conseiller compliance',
        'Juriste d’entreprise junior',
      ],
      skills: [
        'Rédaction juridique',
        'Analyse de dossiers',
        'Procédure civile / pénale',
        'Négociation',
      ],
      sectors: [
        'Cabinets d’avocats',
        'Notariat',
        'Administration judiciaire',
        'ONG droits humains',
      ],
      opportunities: [
        'Stages en cabinet',
        'Cliniques juridiques universitaires',
      ],
      furtherStudies: [
        'Master Droit des affaires',
        'École de magistrature',
        'Spécialisation droit international',
      ],
      certifications: [
        'Certificat en droit OHADA',
        'Langue juridique anglaise',
      ],
      testimonials: [
        '« Le TFC m’a servi de carte de visite pour mon premier stage en cabinet. » — Alumni Droit',
      ],
      internshipsHint:
          'Contacte les cabinets partenaires via le secrétariat de ta faculté.',
    ),
    CareerOutlet(
      domainKey: 'medecine',
      title: 'Santé & médecine',
      jobs: [
        'Médecin généraliste (après parcours complet)',
        'Assistant de recherche clinique',
        'Technicien de laboratoire',
        'Agent de santé publique',
      ],
      skills: [
        'Raisonnement clinique',
        'Éthique médicale',
        'Travail pluridisciplinaire',
        'Communication patient',
      ],
      sectors: [
        'Hôpitaux publics',
        'Cliniques privées',
        'ONG santé',
        'Recherche biomédicale',
      ],
      opportunities: [
        'Stages hospitaliers',
        'Campagnes de vaccination / sensibilisation',
      ],
      furtherStudies: [
        'Spécialisation médicale',
        'Master Santé publique',
        'Doctorat sciences médicales',
      ],
      certifications: [
        'Gestes d’urgence',
        'Bonnes pratiques cliniques (GCP)',
      ],
      testimonials: [
        '« Les stages cliniques m’ont confirmé ma vocation en pédiatrie. » — Alumni Médecine',
      ],
      internshipsHint:
          'Les stages sont souvent gérés par le doyenné — suis le calendrier officiel.',
    ),
    CareerOutlet(
      domainKey: 'economie',
      title: 'Économie & gestion',
      jobs: [
        'Analyste financier junior',
        'Assistant comptable',
        'Chargé de clientèle banque',
        'Assistant RH',
        'Entrepreneur',
      ],
      skills: [
        'Comptabilité',
        'Analyse financière',
        'Excel / reporting',
        'Négociation commerciale',
      ],
      sectors: [
        'Banques & microfinance',
        'Audit & conseil',
        'Commerce & distribution',
        'Administration fiscale',
      ],
      opportunities: [
        'Stages banque / cabinet',
        'Programmes jeunes entrepreneurs',
      ],
      furtherStudies: [
        'Master Finance',
        'Master Management',
        'MBA',
      ],
      certifications: [
        'Comptabilité OHADA',
        'Excel avancé',
        'Certification en audit interne',
      ],
      testimonials: [
        '« Mon mémoire sur la microfinance m’a aidé à entrer en banque. » — Alumni Éco',
      ],
      internshipsHint:
          'Prépare un CV ciblé banques, cabinets et ONG de développement.',
    ),
    CareerOutlet(
      domainKey: 'ingenierie',
      title: 'Ingénierie & polytechnique',
      jobs: [
        'Ingénieur civil junior',
        'Technicien de chantier',
        'Dessinateur-projeteur',
        'Responsable maintenance',
      ],
      skills: [
        'Calcul de structures',
        'Lecture de plans',
        'Gestion de chantier',
        'Normes de sécurité',
      ],
      sectors: [
        'BTP',
        'Énergie',
        'Industries extractives',
        'Collectivités territoriales',
      ],
      opportunities: [
        'Stages chantier',
        'Projets tuteurés avec entreprises',
      ],
      furtherStudies: [
        'Master Génie civil',
        'Spécialisation énergies renouvelables',
      ],
      certifications: [
        'AutoCAD / Revit',
        'HSE chantier',
      ],
      testimonials: [
        '« Mon projet tuteuré BTP m’a ouvert un stage chez un grand promoteur. » — Alumni Polytech',
      ],
      internshipsHint:
          'Les bureaux d’études et entreprises BTP recrutent souvent via les professeurs.',
    ),
    CareerOutlet(
      domainKey: 'sciences',
      title: 'Sciences fondamentales',
      jobs: [
        'Technicien de laboratoire',
        'Assistant de recherche',
        'Enseignant de sciences',
        'Contrôle qualité',
      ],
      skills: [
        'Méthode scientifique',
        'Analyse de données',
        'Rédaction de rapports',
        'Manipulation en labo',
      ],
      sectors: [
        'Recherche universitaire',
        'Industrie pharmaceutique',
        'Environnement',
        'Éducation',
      ],
      opportunities: [
        'Stages labo',
        'Projets de recherche encadrés',
      ],
      furtherStudies: [
        'Master recherche',
        'Doctorat',
        'Agrégation / pédagogie',
      ],
      certifications: [
        'Bonnes pratiques de laboratoire',
        'Statistiques appliquées',
      ],
      testimonials: [
        '« Le master recherche m’a mené vers un doctorat en chimie. » — Alumni Sciences',
      ],
      internshipsHint:
          'Parle à tes enseignants de labo pour les stages et thèses.',
    ),
  ];

  /// Choisit la fiche la plus proche du profil (fac / département).
  static CareerOutlet forProfile(UserProfile? user) {
    if (user == null) return _default;
    final hay = [
      user.faculty,
      user.department,
      user.professionalDomain,
      user.promotion,
    ].join(' ').toLowerCase();

    bool hit(String key, List<String> words) =>
        words.any((w) => hay.contains(w));

    if (hit('informatique', ['info', 'fasi', 'logiciel', 'digital', 'computer'])) {
      return _catalog.firstWhere((c) => c.domainKey == 'informatique');
    }
    if (hit('droit', ['droit', 'juridique', 'loi'])) {
      return _catalog.firstWhere((c) => c.domainKey == 'droit');
    }
    if (hit('medecine', ['méd', 'med', 'santé', 'sante', 'pharmacie'])) {
      return _catalog.firstWhere((c) => c.domainKey == 'medecine');
    }
    if (hit('economie', ['éco', 'eco', 'gestion', 'commerce', 'finance'])) {
      return _catalog.firstWhere((c) => c.domainKey == 'economie');
    }
    if (hit('ingenierie', [
      'ingénieur',
      'ingenieur',
      'polytech',
      'civil',
      'électri',
      'electri',
      'mécan',
    ])) {
      return _catalog.firstWhere((c) => c.domainKey == 'ingenierie');
    }
    if (hit('sciences', ['science', 'physique', 'chimie', 'math', 'bio'])) {
      return _catalog.firstWhere((c) => c.domainKey == 'sciences');
    }
    return _default;
  }
}
