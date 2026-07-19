/// Base de connaissances LMD — RDC.
/// Sources principales :
/// - Décret n° 22/39 du 8 décembre 2022 (organisation / fonctionnement LMD)
/// - Loi-cadre n° 14/004 du 11 février 2014 de l’enseignement national
/// - Décret n° 24/23 du 15 mars 2024 (appellations des grades)
/// - Instructions académiques MESU (ex. 2023-2024)
library;

class LmdSource {
  const LmdSource({
    required this.title,
    required this.reference,
    this.url = '',
  });

  final String title;
  final String reference;
  final String url;
}

class LmdSection {
  const LmdSection({
    required this.id,
    required this.title,
    required this.iconName,
    required this.body,
    this.bullets = const [],
  });

  final String id;
  final String title;
  final String iconName;
  final String body;
  final List<String> bullets;
}

abstract final class LmdKnowledge {
  static const sources = <LmdSource>[
    LmdSource(
      title: 'Décret n° 22/39 du 8 décembre 2022',
      reference:
          'Organisation et fonctionnement du système Licence-Maîtrise-Doctorat (LMD) en RDC. '
          'Signé à Kinshasa — Premier ministre Jean-Michel Sama Lukonde ; '
          'Ministre MESU Muhindo Nzangi Butondo.',
      url:
          'https://www.droitcongolais.info/files/520.12.22-decret-du-8-decembre-2022_Systeme-LMD.pdf',
    ),
    LmdSource(
      title: 'Loi-cadre n° 14/004 du 11 février 2014',
      reference:
          'Loi-cadre de l’enseignement national — fondement légal du basculement LMD '
          '(notamment art. 98 et 100).',
    ),
    LmdSource(
      title: 'Décret n° 24/23 du 15 mars 2024',
      reference:
          'Appellations des grades académiques du système Licence-Maîtrise-Doctorat en RDC.',
      url:
          'https://www.taxenrdc.com/actualites/decret-n-24-23-du-15-mars-2024-portant-appelations-des-grades-academiques-du-systeme-licence-metrise-doctorat-en-republique-democratique-du-congo',
    ),
    LmdSource(
      title: 'Instructions académiques MESU',
      reference:
          'Directives ministérielles (ex. année 2023-2024) : application LMD dans tous les '
          'établissements publics et privés de l’ESU, maquettes et référentiels nationaux.',
    ),
  ];

  static const sections = <LmdSection>[
    LmdSection(
      id: 'intro',
      title: 'Qu’est-ce que le LMD en RDC ?',
      iconName: 'school',
      body:
          'Le système Licence–Maîtrise–Doctorat (LMD) réorganise l’enseignement supérieur '
          'et universitaire (ESU) congolais pour rendre les diplômes lisibles, comparables '
          'et reconnus aux niveaux national, régional et international.\n\n'
          'Le cadre légal repose notamment sur la loi-cadre n° 14/004 de 2014 et le '
          'décret n° 22/39 du 8 décembre 2022. Le basculement s’applique en principe aux '
          'étudiants inscrits en classes de recrutement à partir de l’année académique 2021-2022.',
      bullets: [
        'Trois cycles : Licence, Maîtrise, Doctorat',
        'Organisation en semestres, UE et crédits',
        'Objectif : qualité, mobilité, insertion professionnelle',
      ],
    ),
    LmdSection(
      id: 'objectifs',
      title: 'Objectifs officiels (décret 22/39)',
      iconName: 'flag',
      body:
          'Selon l’article 2 du décret n° 22/39, le LMD vise notamment :',
      bullets: [
        'Améliorer la qualité de la formation initiale et tout au long de la vie',
        'Diversifier les offres pour les rendre lisibles, compétitives et attractives',
        'Harmoniser les programmes au niveau national, régional et international',
        'Promouvoir le travail personnel de l’étudiant',
        'Favoriser l’insertion professionnelle et l’ouverture sur le monde extérieur',
        'Développer le partenariat local, national et international',
        'Autonomiser les apprenants dans leurs parcours',
        'Respecter les normes et standards internationaux',
        'Assainir le paysage universitaire (pôles d’excellence, viabilité des établissements)',
        'Introduire le tutorat et renforcer la gouvernance académique',
        'Promouvoir l’enseignement en ligne et l’intégration pédagogique des TIC',
      ],
    ),
    LmdSection(
      id: 'cycles',
      title: 'Les trois cycles',
      iconName: 'layers',
      body:
          'Article 4 du décret n° 22/39 — durée des cycles :',
      bullets: [
        'Licence : 3 ans = 6 semestres',
        'Maîtrise : 2 ans = 4 semestres',
        'Doctorat : 3 à 5 ans = 6 à 10 semestres selon le cheminement',
        'Formations à vocation recherche ou professionnelle',
        'Structuration : domaines → filières / mentions → parcours → semestres → UE → EC',
      ],
    ),
    LmdSection(
      id: 'semestres',
      title: 'Semestres (L1 → Doctorat)',
      iconName: 'calendar',
      body:
          'Une année académique compte en général deux semestres. '
          'Repères usuels du parcours LMD en RDC :',
      bullets: [
        'L1 : semestres S1–S2',
        'L2 : semestres S3–S4',
        'L3 : semestres S5–S6 → grade Licence',
        'M1 : semestres S7–S8',
        'M2 : semestres S9–S10 → grade Maîtrise',
        'Doctorat : à partir de S11 (durée variable selon le parcours)',
      ],
    ),
    LmdSection(
      id: 'credits',
      title: 'Crédits et charge de travail',
      iconName: 'credit',
      body:
          'Selon l’article 6 du décret n° 22/39 :',
      bullets: [
        '1 crédit = 25 heures de charge de travail',
        'Dont environ 1/3 consacré aux travaux personnels de l’étudiant (TPE)',
        '1 semestre = 30 crédits',
        'Le crédit mesure la quantité de travail, pas la « qualité » de l’étudiant',
        'Chaque UE reçoit une valeur en crédits ; les EC (CMI, TD, TP, TPE) la composent',
      ],
    ),
    LmdSection(
      id: 'ue',
      title: 'Unités d’enseignement (UE)',
      iconName: 'blocks',
      body:
          'L’UE est un bloc cohérent de formation. Une UE validée est en principe '
          'capitalisable (acquise). Types courants :',
      bullets: [
        'UE fondamentales : tronc commun de la filière',
        'UE optionnelles : approfondissement ou professionnalisation',
        'UE transversales : outils partagés (langues, informatique…)',
        'UE libres : choix de l’étudiant (culture, sport… selon l’offre)',
        'Éléments constitutifs (EC) : CMI, TD, TP, TPE',
      ],
    ),
    LmdSection(
      id: 'ancien',
      title: 'Ancien système vs LMD',
      iconName: 'compare',
      body:
          'Avant le LMD, l’ESU congolais s’organisait souvent autour de parcours '
          'type graduat / licence / etc. Le LMD remplace progressivement ce modèle '
          'pour les nouvelles promotions.\n\n'
          'Le décret 22/39 (art. 11–12) prévoit des dispositions transitoires : '
          'les classes montantes de l’ancien système peuvent terminer leur formation '
          'selon les règles antérieures ; des arrêtés fixent les correspondances '
          'et passerelles entre anciens et nouveaux diplômes.',
      bullets: [
        'Recrutement LMD : dès 2021-2022 (selon le décret)',
        'Ancien système : peut continuer pour promotions déjà engagées',
        'Passerelles et équivalences : arrêtés / cadre normatif MESU',
      ],
    ),
    LmdSection(
      id: 'pratique',
      title: 'Ce que ça change pour toi (étudiant)',
      iconName: 'student',
      body:
          'En pratique sur un campus congolais (UNIKIN, UPN, UPC, etc.) :',
      bullets: [
        'Tu progresses par semestres et crédits, pas seulement « année globale »',
        'Les maquettes de formation et référentiels sont nationaux (MESU)',
        'Stages et immersion professionnelle sont davantage mis en avant',
        'Le travail personnel (TPE) compte dans la charge de 25 h / crédit',
        'La mobilité et la lisibilité internationale des diplômes sont un objectif clé',
        'En cas de doute : secretariat académique, maquette officielle, instruction MESU',
      ],
    ),
  ];

  /// FAQ courte pour suggestions UI.
  static const suggestedQuestions = <String>[
    'Combien de semestres pour la licence ?',
    'Qu’est-ce qu’un crédit LMD en RDC ?',
    'Différence entre UE et EC ?',
    'Quand le LMD a-t-il commencé en RDC ?',
    'Que devient l’ancien système ?',
    'Combien d’heures pour 30 crédits ?',
  ];
}
