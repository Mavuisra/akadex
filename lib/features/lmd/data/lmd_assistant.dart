import 'lmd_knowledge.dart';

class LmdAnswer {
  const LmdAnswer({
    required this.text,
    this.relatedSectionId,
  });

  final String text;
  final String? relatedSectionId;
}

/// Assistant local : répond à partir de la base LMD RDC (pas d’API externe).
abstract final class LmdAssistant {
  static LmdAnswer answer(String rawQuestion) {
    final q = _normalize(rawQuestion);
    if (q.isEmpty) {
      return const LmdAnswer(
        text: 'Pose une question sur le LMD en RDC (crédits, semestres, licence…).',
      );
    }

    if (_match(q, ['bonjour', 'salut', 'hello', 'merci'])) {
      return const LmdAnswer(
        text:
            'Bonjour ! Je suis l’assistant LMD Akadex. Je m’appuie sur le décret '
            'n° 22/39 (2022), la loi-cadre 14/004 et les directives MESU pour expliquer '
            'le système en RDC. Que veux-tu clarifier ?',
      );
    }

    if (_match(q, ['credit', 'crédits', '30 credit', 'charge', 'heure', '25 h', '25h'])) {
      return LmdAnswer(
        text:
            'En RDC, selon le décret n° 22/39 (art. 6) :\n\n'
            '• 1 crédit = 25 heures de charge de travail\n'
            '• Environ 1/3 de ces heures = travaux personnels de l’étudiant (TPE)\n'
            '• 1 semestre = 30 crédits\n'
            '• Donc un semestre ≈ 30 × 25 = 750 heures de charge totale\n\n'
            'Le crédit mesure la quantité de travail prévue, pas ta « note ».',
        relatedSectionId: 'credits',
      );
    }

    if (_match(q, ['licence', 'l1', 'l2', 'l3', '6 semestre', 'trois ans', '3 ans'])) {
      return LmdAnswer(
        text:
            'La Licence (1er cycle) dure 3 ans = 6 semestres :\n\n'
            '• L1 : S1 et S2\n'
            '• L2 : S3 et S4\n'
            '• L3 : S5 et S6\n\n'
            'À la fin de L3, tu obtiens le grade / diplôme de Licence '
            '(nomenclature précisée notamment par le décret n° 24/23 de 2024).',
        relatedSectionId: 'cycles',
      );
    }

    if (_match(q, ['maitrise', 'maîtrise', 'master', 'm1', 'm2', '2 ans'])) {
      return LmdAnswer(
        text:
            'La Maîtrise (2e cycle) dure 2 ans = 4 semestres :\n\n'
            '• M1 : S7 et S8\n'
            '• M2 : S9 et S10\n\n'
            'Le décret 22/39 parle de « maîtrise » ; dans le langage campus on dit '
            'souvent aussi « Master ». Vérifie l’appellation exacte sur ton diplôme '
            'et le décret n° 24/23 (2024) sur les grades.',
        relatedSectionId: 'semestres',
      );
    }

    if (_match(q, ['doctorat', 'these', 'thèse', 'phd', 'd1', 'troisieme cycle'])) {
      return LmdAnswer(
        text:
            'Le Doctorat (3e cycle) dure 3 à 5 ans, soit 6 à 10 semestres '
            'selon le cheminement (art. 4 du décret 22/39).\n\n'
            'Il s’inscrit dans une logique de recherche (et parfois professionnelle '
            'selon les filières autorisées). Les modalités précises sont dans le '
            'cadre normatif / arrêtés MESU.',
        relatedSectionId: 'cycles',
      );
    }

    if (_match(q, ['ue', 'unite', 'unité', 'ec', 'element', 'élément', 'cmi', 'td', 'tp', 'tpe'])) {
      return LmdAnswer(
        text:
            '• UE (unité d’enseignement) : bloc cohérent du semestre. '
            'Une UE validée est en principe capitalisable.\n\n'
            'Types d’UE : fondamentales, optionnelles, transversales, libres.\n\n'
            '• EC (éléments constitutifs) à l’intérieur d’une UE :\n'
            '  – CMI : cours magistral interactif\n'
            '  – TD : travaux dirigés\n'
            '  – TP : travaux pratiques\n'
            '  – TPE : travaux personnels de l’étudiant\n\n'
            'Chaque UE a une valeur en crédits (décret 22/39 art. 6).',
        relatedSectionId: 'ue',
      );
    }

    if (_match(q, ['ancien', 'graduat', 'avant', 'passerelle', 'equivalence', 'équivalence'])) {
      return LmdAnswer(
        text:
            'Le LMD remplace progressivement l’ancien organisation de l’ESU '
            'pour les nouvelles promotions.\n\n'
            'Selon le décret 22/39 :\n'
            '• Recrutements concernés : dès 2021-2022\n'
            '• Classes montantes de l’ancien système : peuvent terminer sous les '
            'anciennes règles\n'
            '• Correspondances / passerelles : arrêtés du ministre MESU\n\n'
            'Pour ton cas personnel : demande la table d’équivalence à ton '
            'secrétariat académique.',
        relatedSectionId: 'ancien',
      );
    }

    if (_match(q, ['quand', '2021', 'debut', 'début', 'basculement', 'applique', 'histoire'])) {
      return LmdAnswer(
        text:
            '• Loi-cadre 14/004 (2014) : socle légal\n'
            '• Basculement effectif pour beaucoup d’établissements : autour de 2021\n'
            '• Décret 22/39 (8 déc. 2022) : organisation officielle du LMD\n'
            '• Décret 24/23 (15 mars 2024) : appellations des grades\n'
            '• Instructions MESU : précisent l’application année par année '
            '(ex. 2023-2024 : LMD dans tous les établissements ESU)\n\n'
            'Le décret indique que la régularisation concerne les inscrits en '
            'recrutement à partir de 2021-2022.',
        relatedSectionId: 'intro',
      );
    }

    if (_match(q, ['objectif', 'pourquoi', 'utilite', 'utilité', 'avantage'])) {
      return const LmdAnswer(
        text:
            'Objectifs clés du décret 22/39 : qualité de formation, diplômes '
            'lisibles et compétitifs, harmonisation nationale/internationale, '
            'travail personnel, insertion professionnelle, partenariats, '
            'gouvernance, tutorat, enseignement en ligne et TIC.\n\n'
            'Pour la RDC, un enjeu majeur est la reconnaissance et la mobilité '
            'des diplômes congolais.',
        relatedSectionId: 'objectifs',
      );
    }

    if (_match(q, ['semestre', 'semestr', 'année', 'annee', 'session'])) {
      return LmdAnswer(
        text:
            'Dans le LMD, l’année est découpée en semestres (souvent 2). '
            'Chaque semestre vaut 30 crédits.\n\n'
            'Tu valides des UE / crédits semestre par semestre. '
            'C’est différent d’une logique uniquement « année globale » '
            'de l’ancien modèle.',
        relatedSectionId: 'semestres',
      );
    }

    if (_match(q, ['maquette', 'referentiel', 'référentiel', 'programme', 'mesu', 'ministere', 'ministère'])) {
      return const LmdAnswer(
        text:
            'Les programmes sont nationaux : référentiels de compétences et '
            'maquettes de formation par domaine, publiés / validés sous l’autorité '
            'du Ministère de l’Enseignement Supérieur et Universitaire (MESU).\n\n'
            'Les établissements publics et privés de l’ESU doivent les appliquer '
            '(instructions académiques). Sur Akadex, tes niveaux L1–M2 suivent '
            'cette nomenclature campus RDC.',
        relatedSectionId: 'pratique',
      );
    }

    // Fallback : résumé + invite
    final section = LmdKnowledge.sections.first;
    return LmdAnswer(
      text:
          'Je n’ai pas une fiche exacte pour « $rawQuestion », mais voici l’essentiel :\n\n'
          '${section.body}\n\n'
          'Essaie une question plus précise, par exemple :\n'
          '• « Combien de crédits par semestre ? »\n'
          '• « Différence UE et EC ? »\n'
          '• « Que devient l’ancien graduat ? »\n\n'
          'Sources : décret 22/39, loi-cadre 14/004, décret 24/23, instructions MESU.',
      relatedSectionId: section.id,
    );
  }

  static String _normalize(String s) {
    return s
        .toLowerCase()
        .replaceAll(RegExp(r'[àáâãä]'), 'a')
        .replaceAll(RegExp(r'[èéêë]'), 'e')
        .replaceAll(RegExp(r'[ìíîï]'), 'i')
        .replaceAll(RegExp(r'[òóôõö]'), 'o')
        .replaceAll(RegExp(r'[ùúûü]'), 'u')
        .replaceAll(RegExp(r'[ç]'), 'c')
        .trim();
  }

  static bool _match(String q, List<String> keys) {
    for (final k in keys) {
      if (q.contains(_normalize(k))) return true;
    }
    return false;
  }
}
