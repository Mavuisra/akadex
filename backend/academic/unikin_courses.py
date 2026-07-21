# -*- coding: utf-8 -*-
"""
Cours UNIKIN enrichis — sources SGA 2024-2025 (PDF officiels).

https://www.unikin.ac.cd/facultes-et-entites
https://www.unikin.ac.cd/wp-content/uploads/2025/07/
"""

# Format: (code, titre, description, crédits, cycle)


def _c(code, title, desc, credits, cycle):
    return (code, title, desc, credits, cycle)


# ---------------------------------------------------------------------------
# Médecine humaine
# ---------------------------------------------------------------------------
MED_COURSES = [
    _c('MED111', 'Anatomie 1 (Ostéologie et Myologie)', 'B1 Médecine — UNIKIN.', 6, 'L1'),
    _c('MED112', 'Physiologie I', 'B1/B2 Médecine humaine — UNIKIN.', 5, 'L1'),
    _c('MED113', 'Chimie générale', 'B1 Médecine / MPR — UNIKIN.', 5, 'L1'),
    _c('MED114', 'Mathématiques', 'B1 Sciences biomédicales — UNIKIN.', 4, 'L1'),
    _c('MED211', 'Biochimie médicale', 'B2 Médecine — UNIKIN.', 5, 'L2'),
    _c('MED212', 'Anatomie pathologique', 'D2 Médecine — UNIKIN.', 5, 'L2'),
    _c('MED213', 'Physiologie de l’effort', 'B2 Médecine physique et réadaptation — UNIKIN.', 5, 'L2'),
    _c('MED214', 'Kinanthropométrie', 'B2 MPR — UNIKIN.', 4, 'L2'),
    _c('MED215', 'Psycho-pharmacologie spéciale', 'L2 MPR — UNIKIN.', 3, 'L2'),
    _c('MED311', 'Sémiologie chirurgicale', 'B3 Médecine — UNIKIN.', 5, 'L3'),
    _c('MED312', 'Hématologie', 'M1 Biomédical — UNIKIN.', 5, 'L3'),
    _c('MED313', 'Rhumatologie', 'B3 Physiothérapie — UNIKIN.', 4, 'L3'),
    _c('MED314', 'Endocrinologie', 'D2 Médecine — UNIKIN.', 4, 'L3'),
    _c('MED411', 'Pédiatrie I', 'M1 / D2 Médecine — UNIKIN.', 5, 'Master 1'),
    _c('MED412', 'Pédiatrie néonatale', 'D2/D3 Médecine — UNIKIN.', 4, 'Master 1'),
    _c('MED413', 'Pédiatrie pneumologie', 'D3 Médecine — UNIKIN.', 4, 'Master 1'),
    _c('MED414', 'Pédiatrie néphrologie', 'D3 Médecine — UNIKIN.', 4, 'Master 1'),
    _c('MED415', 'Pédiatrie génétique', 'D2 Médecine — UNIKIN.', 4, 'Master 1'),
    _c('MED416', 'Pédiatrie toxicologie', 'D3 Médecine — UNIKIN.', 3, 'Master 1'),
    _c('MED417', 'Urgence pédiatrique et PCIMNE', 'D2 Médecine — UNIKIN.', 4, 'Master 1'),
    _c('MED418', 'Croissance et développement', 'M1 Médecine — UNIKIN.', 4, 'Master 1'),
    _c('MED419', 'Médecine nucléaire', 'D3 Médecine — UNIKIN.', 4, 'Master 1'),
    _c('MED420', 'Médecine aéronautique', 'D2 Médecine — UNIKIN.', 3, 'Master 1'),
    _c('MED421', 'Pathologies gravidiques', 'M1 Médecine — UNIKIN.', 5, 'Master 1'),
    _c('MED422', 'Réanimation et pathologies sportives', 'M1 Physiothérapie — UNIKIN.', 5, 'Master 1'),
]

# ---------------------------------------------------------------------------
# Droit
# ---------------------------------------------------------------------------
DROIT_COURSES = [
    _c('DRT111', 'Introduction au droit', 'Faculté de Droit UNIKIN.', 5, 'L1'),
    _c('DRT112', 'Droit constitutionnel', 'Droit public interne — UNIKIN.', 5, 'L1'),
    _c('DRT113', 'Informatique et bureautique', 'Licence 1 Droit — UNIKIN.', 3, 'L1'),
    _c('DRT114', 'Hygiène et environnement', 'Droit / environnement — UNIKIN.', 3, 'L1'),
    _c('DRT211', 'Droit civil — personnes et famille', 'Faculté de Droit UNIKIN.', 5, 'L2'),
    _c('DRT212', 'Droit pénal général', 'Faculté de Droit UNIKIN.', 5, 'L2'),
    _c('DRT213', 'Droit de l’environnement', 'Droit public — UNIKIN.', 4, 'L2'),
    _c('DRT214', 'Histoire et principes du procès pénal', 'Droits de l’homme — UNIKIN.', 4, 'L2'),
    _c('DRT311', 'Droit des affaires', 'Faculté de Droit UNIKIN.', 5, 'L3'),
    _c('DRT312', 'Procédure civile', 'Faculté de Droit UNIKIN.', 5, 'L3'),
    _c('DRT313', 'Droit administratif', 'Justice administrative congolaise — UNIKIN.', 5, 'L3'),
    _c('DRT411', 'Droit international public', 'DIP & Relations internationales — UNIKIN.', 5, 'Master 1'),
    _c('DRT412', 'Droits de l’homme', 'Département DH — UNIKIN.', 5, 'Master 1'),
    _c('DRT413', 'Droit international des réfugiés', 'Master 1 DH — UNIKIN.', 4, 'Master 1'),
    _c('DRT414', 'Droit de la Cour pénale internationale', 'Master DH — UNIKIN.', 4, 'Master 1'),
    _c('DRT415', 'Histoire des droits de l’homme', 'Master DH — UNIKIN.', 4, 'Master 1'),
    _c('DRT416', 'Droit international humanitaire', 'Master DH — UNIKIN.', 4, 'Master 1'),
    _c('DRT417', 'Droit constitutionnel des droits de l’homme', 'Master DH — UNIKIN.', 4, 'Master 1'),
    _c('DRT418', 'Droits des personnes vulnérables (enfants)', 'Master DH — UNIKIN.', 3, 'Master 1'),
    _c('DRT419', 'Droits des personnes vulnérables (femmes)', 'Master DH — UNIKIN.', 3, 'Master 1'),
    _c('DRT420', 'Droit onusien des droits de l’homme', 'Master DH — UNIKIN.', 4, 'Master 1'),
    _c('DRT421', 'Mémoire de Master en droit', 'Recherche juridique — UNIKIN.', 6, 'Master 2'),
]

# ---------------------------------------------------------------------------
# FASEG — Économie & Gestion
# ---------------------------------------------------------------------------
ECO_COURSES = [
    _c('ECO111', 'Microéconomie I', 'FASEG — Sciences économiques (UNIKIN).', 5, 'L1'),
    _c('ECO112', 'Macroéconomie I', 'FASEG — Sciences économiques (UNIKIN).', 5, 'L1'),
    _c('ECO113', 'Mathématiques générales', 'L1 IGAF / Économie — UNIKIN.', 4, 'L1'),
    _c('GES121', 'Comptabilité générale', 'FASEG — Gestion (UNIKIN).', 5, 'L1'),
    _c('GES122', 'Introduction à la gestion', 'FASEG — Gestion (UNIKIN).', 4, 'L1'),
    _c('ECO211', 'Microéconomie II', 'FASEG (UNIKIN).', 5, 'L2'),
    _c('ECO212', 'Macroéconomie II', 'FASEG (UNIKIN).', 5, 'L2'),
    _c('GES211', 'Gestion financière', 'FASEG — Gestion (UNIKIN).', 5, 'L2'),
    _c('GES221', 'Marketing', 'FASEG — Gestion (UNIKIN).', 4, 'L2'),
    _c('GES222', 'Comptabilité analytique', 'FASEG — Gestion (UNIKIN).', 4, 'L2'),
    _c('ECO311', 'Économie du développement', 'FASEG (UNIKIN).', 5, 'L3'),
    _c('ECO312', 'Économie internationale', 'FASEG (UNIKIN).', 5, 'L3'),
    _c('GES311', 'Management des organisations', 'FASEG — Gestion (UNIKIN).', 5, 'L3'),
    _c('GES312', 'Gestion des ressources humaines', 'FASEG — Gestion (UNIKIN).', 5, 'L3'),
    _c('GES313', 'Télématique et réseaux', 'L2 GRH — UNIKIN.', 4, 'L2'),
    _c('ECO411', 'Économétrie', 'Master FASEG / IRES (UNIKIN).', 5, 'Master 1'),
    _c('ECO412', 'Politique économique', 'Master FASEG (UNIKIN).', 5, 'Master 1'),
    _c('GES411', 'Stratégie d’entreprise', 'Master Gestion (UNIKIN).', 5, 'Master 1'),
    _c('GES421', 'Mémoire / projet de gestion', 'Master FASEG (UNIKIN).', 6, 'Master 2'),
]

# ---------------------------------------------------------------------------
# Polytechnique
# ---------------------------------------------------------------------------
POLY_CIVIL = [
    _c('GC111', 'Dessin technique', 'Faculté Polytechnique — Génie civil (UNIKIN).', 4, 'L1'),
    _c('GC112', 'Géométrie descriptive', 'Génie civil — UNIKIN.', 4, 'L1'),
    _c('GC113', 'Algèbre et analyse', 'Tronc commun Polytechnique — UNIKIN.', 5, 'L1'),
    _c('GC211', 'Résistance des matériaux', 'Génie civil — UNIKIN.', 5, 'L2'),
    _c('GC212', 'Mécanique des sols', 'Génie civil — UNIKIN.', 5, 'L2'),
    _c('GC213', 'Topographie', 'Génie civil — UNIKIN.', 4, 'L2'),
    _c('GC311', 'Béton armé', 'Génie civil — UNIKIN.', 5, 'L3'),
    _c('GC312', 'Génie civil et structures', 'Génie civil — UNIKIN.', 5, 'L3'),
    _c('GC313', 'Hydraulique', 'Génie civil — UNIKIN.', 5, 'L3'),
    _c('GC411', 'Projet de génie civil', 'Master / Ir — UNIKIN.', 6, 'Master 1'),
]

POLY_ELEC = [
    _c('GE111', 'Électrotechnique de base', 'Génie électrique — UNIKIN.', 5, 'L1'),
    _c('GE112', 'Circuits électriques', 'Génie électrique — UNIKIN.', 5, 'L1'),
    _c('GE211', 'Électronique', 'Génie électrique — UNIKIN.', 5, 'L2'),
    _c('GE212', 'Machines électriques', 'Génie électrique — UNIKIN.', 5, 'L2'),
    _c('GE311', 'Automatique', 'Génie électrique — UNIKIN.', 5, 'L3'),
    _c('GE312', 'Électronique de puissance', 'Génie électrique — UNIKIN.', 5, 'L3'),
    _c('GE313', 'Réseaux électriques', 'Génie électrique — UNIKIN.', 5, 'L3'),
    _c('GE411', 'Projet de génie électrique', 'Master / Ir — UNIKIN.', 6, 'Master 1'),
]

POLY_MECA = [
    _c('GM111', 'Mécanique appliquée', 'Génie mécanique — UNIKIN.', 5, 'L1'),
    _c('GM112', 'Dessin mécanique', 'Génie mécanique — UNIKIN.', 4, 'L1'),
    _c('GM211', 'Technologie de fabrication', 'Génie mécanique — UNIKIN.', 5, 'L2'),
    _c('GM212', 'Résistance des matériaux', 'Génie mécanique — UNIKIN.', 5, 'L2'),
    _c('GM311', 'Conception mécanique', 'Génie mécanique — UNIKIN.', 5, 'L3'),
    _c('GM312', 'Thermodynamique appliquée', 'Génie mécanique — UNIKIN.', 5, 'L3'),
    _c('GM313', 'Machines thermiques', 'Génie mécanique — UNIKIN.', 5, 'L3'),
    _c('GM411', 'Projet de génie mécanique', 'Master / Ir — UNIKIN.', 6, 'Master 1'),
]

# ---------------------------------------------------------------------------
# Lettres & Sciences Humaines
# ---------------------------------------------------------------------------
LETTRES_COURSES = [
    _c('LET111', 'Méthodologie du travail universitaire', 'FLSH — UNIKIN.', 3, 'L1'),
    _c('LET112', 'Expression française', 'FLSH — UNIKIN.', 4, 'L1'),
    _c('LET121', 'Linguistique générale', 'FLSH — UNIKIN.', 4, 'L1'),
    _c('LET122', 'Introduction aux littératures', 'FLSH — UNIKIN.', 4, 'L1'),
    _c('LET211', 'Littérature africaine', 'FLSH — UNIKIN.', 4, 'L2'),
    _c('LET212', 'Littérature francophone', 'FLSH — UNIKIN.', 4, 'L2'),
    _c('HIS211', 'Histoire de l’Afrique centrale', 'FLSH — Histoire — UNIKIN.', 4, 'L2'),
    _c('HIS212', 'Histoire contemporaine du Congo', 'FLSH — Histoire — UNIKIN.', 4, 'L2'),
    _c('LET311', 'Séminaire de recherche', 'FLSH — UNIKIN.', 5, 'L3'),
    _c('LET312', 'Critique littéraire', 'FLSH — UNIKIN.', 4, 'L3'),
    _c('HIS311', 'Histoire des institutions africaines', 'FLSH — UNIKIN.', 4, 'L3'),
    _c('LET411', 'Mémoire de Master FLSH', 'Master Lettres — UNIKIN.', 6, 'Master 1'),
]

# ---------------------------------------------------------------------------
# FSSAP
# ---------------------------------------------------------------------------
SOC_COURSES = [
    _c('SOC111', 'Introduction à la sociologie', 'FSSAP — UNIKIN.', 4, 'L1'),
    _c('SOC112', 'Mathématiques appliquées aux sciences sociales', 'L1 SPA — UNIKIN.', 4, 'L1'),
    _c('POL111', 'Introduction aux sciences politiques', 'FSSAP — UNIKIN.', 4, 'L1'),
    _c('SOC211', 'Sociologie urbaine', 'FSSAP — UNIKIN.', 4, 'L2'),
    _c('POL211', 'Sciences politiques', 'FSSAP — UNIKIN.', 5, 'L2'),
    _c('POL212', 'Institutions politiques congolaises', 'FSSAP — UNIKIN.', 4, 'L2'),
    _c('ADM211', 'Introduction à l’administration publique', 'FSSAP — UNIKIN.', 4, 'L2'),
    _c('ADM311', 'Administration publique', 'FSSAP — UNIKIN.', 5, 'L3'),
    _c('SOC311', 'Sociologie du travail', 'FSSAP — UNIKIN.', 4, 'L3'),
    _c('POL311', 'Relations internationales', 'FSSAP — UNIKIN.', 5, 'L3'),
    _c('REL411', 'Relations internationales approfondies', 'Master FSSAP — UNIKIN.', 5, 'Master 1'),
    _c('ADM411', 'Gestion publique', 'Master Administration — UNIKIN.', 5, 'Master 1'),
    _c('SOC421', 'Mémoire FSSAP', 'Master — UNIKIN.', 6, 'Master 2'),
]

# ---------------------------------------------------------------------------
# Agronomie & Environnement
# ---------------------------------------------------------------------------
AGRO_COURSES = [
    _c('AGR111', 'Introduction à l’agronomie', 'Sciences Agronomiques et Environnement — UNIKIN.', 5, 'L1'),
    _c('AGR112', 'Introduction aux sciences de la Terre', 'L1 Agronomie — UNIKIN.', 5, 'L1'),
    _c('AGR113', 'Botanique générale', 'Agronomie — UNIKIN.', 4, 'L1'),
    _c('AGR211', 'Hydrogéologie et hydrochimie', 'L2 GSEA — UNIKIN.', 5, 'L2'),
    _c('AGR212', 'Gestion des forêts et de la biodiversité', 'Licence GFB — UNIKIN.', 5, 'L2'),
    _c('AGR213', 'Production végétale', 'Agronomie — UNIKIN.', 5, 'L2'),
    _c('AGR214', 'Zootechnie générale', 'Département Zootechnie — UNIKIN.', 5, 'L2'),
    _c('AGR311', 'Gestion des sols, eaux et assainissement', 'Licence GSEA — UNIKIN.', 5, 'L3'),
    _c('AGR312', 'Gestion des ressources naturelles renouvelables', 'Licence GRNR — UNIKIN.', 5, 'L3'),
    _c('AGR313', 'Pédologie', 'Agronomie / Géosciences — UNIKIN.', 4, 'L3'),
    _c('AGR411', 'Aménagement et gestion des forêts', 'Master MAGF — UNIKIN.', 5, 'Master 1'),
    _c('AGR412', 'Gestion de la biodiversité', 'Master MGB — UNIKIN.', 5, 'Master 1'),
    _c('AGR413', 'Sciences du sol et bassins versants', 'Master MSSGB — UNIKIN.', 5, 'Master 1'),
    _c('AGR414', 'Gestion de l’eau et assainissement', 'Master MGEA — UNIKIN.', 5, 'Master 1'),
    _c('AGR415', 'Géomatique et changement climatique', 'Master MGCC — UNIKIN.', 5, 'Master 1'),
    _c('AGR416', 'Gestion des eaux souterraines', 'M1 GEA — UNIKIN.', 5, 'Master 1'),
]

# ---------------------------------------------------------------------------
# Psychologie & Sciences de l’éducation
# ---------------------------------------------------------------------------
PSY_COURSES = [
    _c('PSY111', 'Introduction à la psychologie', 'FPSE — Psychologie (UNIKIN).', 4, 'L1'),
    _c('PSY112', 'Théories et méthodes de la psychologie sociale', 'L1 Psychologie — UNIKIN.', 4, 'L1'),
    _c('PSY113', 'Méthodologie de recherche en psychologie', 'FPSE — UNIKIN.', 4, 'L1'),
    _c('PSY211', 'Psychologie du développement', 'FPSE — UNIKIN.', 5, 'L2'),
    _c('PSY212', 'Psychologie sociale', 'FPSE — UNIKIN.', 4, 'L2'),
    _c('PSY213', 'Psychologie commerciale', 'L2 Psychologie — UNIKIN.', 4, 'L2'),
    _c('PSY214', 'Expérimentation en psychologie', 'FPSE — UNIKIN.', 4, 'L2'),
    _c('PSY215', 'Applications de la psychologie cognitive', 'FPSE — UNIKIN.', 4, 'L2'),
    _c('PSY311', 'Psychologie clinique', 'FPSE — UNIKIN.', 5, 'L3'),
    _c('PSY312', 'Psychologie du travail', 'FPSE — UNIKIN.', 4, 'L3'),
    _c('PSY313', 'Séminaire de psychologie clinique', 'FPSE — UNIKIN.', 4, 'L3'),
    _c('PSY411', 'Psychologie de l’adulte', 'Master / DES — UNIKIN.', 4, 'Master 1'),
    _c('PSY412', 'Mémoire de psychologie', 'Master FPSE — UNIKIN.', 6, 'Master 2'),
]

PEDAGO_COURSES = [
    _c('PED111', 'Introduction aux sciences de l’éducation', 'FPSE — UNIKIN.', 4, 'L1'),
    _c('PED121', 'Psychologie de l’apprentissage', 'FPSE — UNIKIN.', 4, 'L1'),
    _c('PED211', 'Didactique générale', 'FPSE — UNIKIN.', 5, 'L2'),
    _c('PED221', 'Évaluation des apprentissages', 'FPSE — UNIKIN.', 4, 'L2'),
    _c('PED311', 'Didactique du numérique', 'FPSE — TICE (UNIKIN).', 4, 'L3'),
    _c('PED312', 'Analyse des pratiques professionnelles', 'FPSE — UNIKIN.', 4, 'L3'),
    _c('PED411', 'Recherche en éducation', 'Master FPSE — UNIKIN.', 5, 'Master 1'),
    _c('PED412', 'Économie de l’éducation', 'M1 Sciences de l’éducation — UNIKIN.', 4, 'Master 1'),
    _c('PED413', 'Mémoire en sciences de l’éducation', 'Master FPSE — UNIKIN.', 6, 'Master 2'),
]

# ---------------------------------------------------------------------------
# Pharmacie
# ---------------------------------------------------------------------------
PHARMA_COURSES = [
    _c('PHA111', 'Chimie pharmaceutique', 'Sciences Pharmaceutiques — UNIKIN.', 5, 'L1'),
    _c('PHA112', 'Chimie pharmaceutique inorganique', 'L1/L3 Pharmacie — UNIKIN.', 5, 'L1'),
    _c('PHA113', 'Mathématiques générales', 'L1 LTP Pharmacie — UNIKIN.', 4, 'L1'),
    _c('PHA114', 'Chimie physique appliquée', 'Pharmacie — UNIKIN.', 4, 'L1'),
    _c('PHA211', 'Pharmacologie', 'Sciences Pharmaceutiques — UNIKIN.', 5, 'L2'),
    _c('PHA212', 'Immunologie', 'Pharmacie — UNIKIN.', 4, 'L2'),
    _c('PHA311', 'Pharmacie galénique', 'Sciences Pharmaceutiques — UNIKIN.', 5, 'L3'),
    _c('PHA1310', 'Microbiologie pharmaceutique', 'PHAR1310 — 3ème Générale (UNIKIN).', 5, 'L3'),
    _c('PHA1307', 'Immunologie pathologique', 'PHAR1307 — UNIKIN.', 4, 'L3'),
    _c('PHA312', 'Qualité microbiologique des produits de santé', 'L3 / MTA — UNIKIN.', 4, 'L3'),
    _c('PHA2107', 'Microbiologie industrielle', 'PHAR2107 — 4ème Médicale (UNIKIN).', 5, 'Master 1'),
    _c('PHA411', 'Questions approfondies de microbiologie', 'DEA/DES Pharmacie — UNIKIN.', 5, 'Master 1'),
    _c('PHA421', 'Mémoire / TFE Pharmacie', 'PharmD — UNIKIN.', 6, 'Master 2'),
]

# ---------------------------------------------------------------------------
# Médecine dentaire
# ---------------------------------------------------------------------------
DENT_COURSES = [
    _c('DEN111', 'Anatomie dentaire', 'Médecine Dentaire — UNIKIN.', 5, 'L1'),
    _c('DEN112', 'Anatomie topographique tête et cou', 'G2 Médecine Dentaire — UNIKIN.', 5, 'L1'),
    _c('DEN211', 'Matériaux dentaires', 'B2 Médecine Dentaire — UNIKIN.', 4, 'L2'),
    _c('DEN212', 'Biomatériologie', 'B2 Médecine Dentaire — UNIKIN.', 4, 'L2'),
    _c('DEN213', 'Dentisterie opératoire II', 'B2 Médecine Dentaire — UNIKIN.', 5, 'L2'),
    _c('DEN214', 'Sémiologie bucco-dentaire', 'B3 Médecine Dentaire — UNIKIN.', 4, 'L2'),
    _c('DEN311', 'Parodontologie', 'B3 Médecine Dentaire — UNIKIN.', 5, 'L3'),
    _c('DEN312', 'Prothèse dentaire', 'Médecine Dentaire — UNIKIN.', 5, 'L3'),
    _c('DEN313', 'Pathologie dentaire', 'G3 Médecine Dentaire — UNIKIN.', 4, 'L3'),
    _c('DEN314', 'Biologie clinique', 'B3 Médecine Dentaire — UNIKIN.', 3, 'L3'),
    _c('DEN315', 'Immunologie', 'B3 Médecine Dentaire — UNIKIN.', 4, 'L3'),
    _c('DEN411', 'Pédodontie', 'M1 Médecine Dentaire — UNIKIN.', 5, 'Master 1'),
    _c('DEN412', 'Prothèse amovible complète', 'M1 Médecine Dentaire — UNIKIN.', 5, 'Master 1'),
    _c('DEN413', 'Gnathologie', 'M1 Médecine Dentaire — UNIKIN.', 4, 'Master 1'),
    _c('DEN414', 'Chirurgie orale', 'M1 Médecine Dentaire — UNIKIN.', 5, 'Master 1'),
    _c('DEN415', 'Orthopédie dento-faciale I', 'M1 Médecine Dentaire — UNIKIN.', 5, 'Master 1'),
    _c('DEN416', 'Stomatologie', 'M1 Médecine Dentaire — UNIKIN.', 4, 'Master 1'),
    _c('DEN417', 'Principes d’oncologie médicale', 'M1 Médecine Dentaire — UNIKIN.', 4, 'Master 1'),
    _c('DEN418', 'Santé publique dentaire', 'Médecine Dentaire — UNIKIN.', 4, 'Master 1'),
    _c('DEN419', 'Éthique et déontologie', 'D2 Médecine Dentaire — UNIKIN.', 3, 'Master 1'),
    _c('DEN420', 'Parodontologie / Implantologie', 'M2 Médecine Dentaire — UNIKIN.', 5, 'Master 2'),
    _c('DEN421', 'Orthopédie dento-faciale II', 'M2 Médecine Dentaire — UNIKIN.', 5, 'Master 2'),
    _c('DEN422', 'Chirurgie maxillo-faciale', 'D2 Médecine Dentaire — UNIKIN.', 5, 'Master 2'),
]

# ---------------------------------------------------------------------------
# Médecine vétérinaire
# ---------------------------------------------------------------------------
VET_COURSES = [
    _c('VET111', 'Anatomie animale', 'Médecine Vétérinaire — UNIKIN.', 5, 'L1'),
    _c('VET112', 'Biologie animale', 'Médecine Vétérinaire — UNIKIN.', 4, 'L1'),
    _c('VET113', 'Chimie et biochimie vétérinaire', 'Médecine Vétérinaire — UNIKIN.', 4, 'L1'),
    _c('VET211', 'Physiologie animale', 'Médecine Vétérinaire — UNIKIN.', 5, 'L2'),
    _c('VET212', 'Pathologie vétérinaire', 'Médecine Vétérinaire — UNIKIN.', 5, 'L2'),
    _c('VET213', 'Microbiologie vétérinaire', 'Médecine Vétérinaire — UNIKIN.', 4, 'L2'),
    _c('VET214', 'Parasitologie', 'Médecine Vétérinaire — UNIKIN.', 4, 'L2'),
    _c('VET311', 'Santé publique vétérinaire', 'One Health — UNIKIN.', 5, 'L3'),
    _c('VET312', 'Clinique des animaux de rente', 'Médecine Vétérinaire — UNIKIN.', 5, 'L3'),
    _c('VET313', 'Clinique des animaux de compagnie', 'Médecine Vétérinaire — UNIKIN.', 5, 'L3'),
    _c('VET314', 'Hygiène des denrées alimentaires', 'Médecine Vétérinaire — UNIKIN.', 4, 'L3'),
    _c('VET411', 'Épidémiologie vétérinaire', 'Master — UNIKIN.', 5, 'Master 1'),
    _c('VET421', 'Mémoire de médecine vétérinaire', 'Master — UNIKIN.', 6, 'Master 2'),
]

# ---------------------------------------------------------------------------
# Pétrole, Gaz et Énergies renouvelables
# ---------------------------------------------------------------------------
PETROLE_COURSES = [
    _c('PET111', 'Géologie générale', 'G1 PGER — UNIKIN.', 6, 'L1'),
    _c('PET112', 'Dessin technique', 'G1 / Préparatoire PGER — UNIKIN.', 4, 'L1'),
    _c('PET113', 'Statique appliquée', 'G1 PGER — UNIKIN.', 4, 'L1'),
    _c('PET114', 'Algèbre linéaire', 'G1 PGER — UNIKIN.', 4, 'L1'),
    _c('PET115', 'Notions de géographie physique', 'G1 PGER — UNIKIN.', 3, 'L1'),
    _c('PET116', 'Introduction aux sciences de l’environnement', 'Préparatoire PGER — UNIKIN.', 5, 'L1'),
    _c('PET211', 'Résistance des matériaux', 'G2 PGER — UNIKIN.', 4, 'L2'),
    _c('PET212', 'Cristallographie', 'G2 PGER — UNIKIN.', 4, 'L2'),
    _c('PET213', 'Pétrographie', 'G2 PGER — UNIKIN.', 5, 'L2'),
    _c('PET214', 'Topographie', 'G2 PGER — UNIKIN.', 4, 'L2'),
    _c('PET215', 'Programmation', 'G2 PGER — UNIKIN.', 4, 'L2'),
    _c('PET216', 'Initiation à la recherche scientifique', 'G2 PGER — UNIKIN.', 3, 'L2'),
    _c('PET311', 'Forage pétrolier', 'G3 Sciences de base — UNIKIN.', 5, 'L3'),
    _c('PET312', 'Géologie pétrolière de la RDC', 'Exploration / Production — UNIKIN.', 5, 'L3'),
    _c('PET313', 'Diagraphie pétrolière I', 'Grade 1 Exploration/Production — UNIKIN.', 5, 'L3'),
    _c('PET314', 'Gisement pétrolier', 'Grade 1 Exploration/Production — UNIKIN.', 5, 'L3'),
    _c('PET315', 'Mécanique des roches', 'G3 PGER — UNIKIN.', 4, 'L3'),
    _c('PET316', 'Mécanique des sols', 'G3 PGER — UNIKIN.', 4, 'L3'),
    _c('PET317', 'Éléments d’équipements pétroliers', 'G3 PGER — UNIKIN.', 4, 'L3'),
    _c('PET318', 'Notions de climatologie', 'G3 Sciences de base — UNIKIN.', 3, 'L3'),
    _c('PET319', 'Levé géologique', 'G3 PGER — UNIKIN.', 4, 'L3'),
    _c('PET411', 'Diagraphie pétrolière II', 'Grade 2 Exploration/Production — UNIKIN.', 5, 'Master 1'),
    _c('PET412', 'Forage d’exploration / Gestion des opérations', 'Grade 2 — UNIKIN.', 5, 'Master 1'),
    _c('PET413', 'Technologie d’exploitation gazière', 'Ir1 Production / Raffinage — UNIKIN.', 5, 'Master 1'),
    _c('PET414', 'Procédés de raffinage', 'Ir1 Raffinage & Pétrochimie — UNIKIN.', 6, 'Master 1'),
    _c('PET415', 'Pétrochimie approfondie', 'Ir1 Raffinage & Pétrochimie — UNIKIN.', 6, 'Master 1'),
    _c('PET416', 'Pétrologie exogène et sédimentaire', 'Ir1 Exploration/Production — UNIKIN.', 5, 'Master 1'),
    _c('PET417', 'Fondements du changement climatique', 'Ir1 PGER — UNIKIN.', 3, 'Master 1'),
    _c('PET418', 'Environnement économique', 'Ir1 Gestion et Économie pétrolière — UNIKIN.', 4, 'Master 1'),
    _c('PET419', 'SIG et télédétection', 'Bac 3 PGER — UNIKIN.', 5, 'Master 1'),
    _c('PET420', 'Énergie géothermique', 'Bac 2 Génie environnemental — UNIKIN.', 4, 'Master 1'),
    _c('PET421', 'Récupération secondaire et tertiaire', 'Bac 3 Production — UNIKIN.', 4, 'Master 2'),
    _c('PET422', 'Gestion des opérations de raffinage', 'Ir2 Raffinage — UNIKIN.', 5, 'Master 2'),
]

# ---------------------------------------------------------------------------
# Santé publique
# ---------------------------------------------------------------------------
SANTE_PUB = [
    _c('SP111', 'Introduction à la santé publique', 'École de Santé Publique de Kinshasa.', 4, 'L1'),
    _c('SP112', 'Biostatistique', 'ESP Kinshasa — UNIKIN.', 4, 'L1'),
    _c('SP211', 'Épidémiologie', 'ESP Kinshasa — UNIKIN.', 5, 'L2'),
    _c('SP212', 'Démographie et santé', 'ESP Kinshasa — UNIKIN.', 4, 'L2'),
    _c('SP213', 'Santé communautaire', 'ESP Kinshasa — UNIKIN.', 4, 'L2'),
    _c('SP311', 'Politiques de santé', 'ESP Kinshasa — UNIKIN.', 5, 'L3'),
    _c('SP312', 'Gestion des systèmes de santé', 'ESP Kinshasa — UNIKIN.', 5, 'L3'),
    _c('SP313', 'Nutrition et santé publique', 'ESP Kinshasa — UNIKIN.', 4, 'L3'),
    _c('SP411', 'Épidémiologie avancée', 'Master ESP — UNIKIN.', 5, 'Master 1'),
    _c('SP421', 'Mémoire de santé publique', 'Master ESP — UNIKIN.', 6, 'Master 2'),
]

# ---------------------------------------------------------------------------
# Physique / Chimie / Bio / Geo (compléments Sciences & Technologies)
# ---------------------------------------------------------------------------
PHY_COURSES = [
    _c('PHY111', 'Algèbre', 'Licence 1 Physique — UNIKIN.', 6, 'L1'),
    _c('PHY112', 'Mécanique', 'Mention Physique & Technologie — UNIKIN.', 5, 'L1'),
    _c('PHY121', 'Électricité et magnétisme', 'Physique & Technologie — UNIKIN.', 5, 'L1'),
    _c('PHY211', 'Thermodynamique', 'Licence 2 Physique — UNIKIN.', 4, 'L2'),
    _c('PHY212', 'Optique', 'Licence 2 Physique — UNIKIN.', 4, 'L2'),
    _c('PHY311', 'Physique moderne', 'Licence 3 Physique — UNIKIN.', 5, 'L3'),
    _c('PHY312', 'Physique du solide', 'Licence 3 Physique — UNIKIN.', 5, 'L3'),
    _c('PHY411', 'Compléments de physique mathématique', 'DEA Physique — UNIKIN.', 5, 'Master 1'),
]

CHIM_COURSES = [
    _c('CHM111', 'Chimie générale', 'Mention Chimie & Industrie — UNIKIN.', 5, 'L1'),
    _c('CHM112', 'Chimie organique I', 'Chimie & Industrie — UNIKIN.', 5, 'L1'),
    _c('CHM211', 'Méthodes numériques et programmation', 'Licence 2 Chimie — UNIKIN.', 4, 'L2'),
    _c('CHM212', 'Chimie organique II', 'Licence 2 Chimie — UNIKIN.', 5, 'L2'),
    _c('CHM213', 'Analyse 2', 'Licence 2 Chimie — UNIKIN.', 4, 'L2'),
    _c('CHM311', 'Chimie analytique', 'Licence 3 Chimie & Industrie — UNIKIN.', 5, 'L3'),
    _c('CHM312', 'Chimie industrielle', 'Licence 3 Chimie & Industrie — UNIKIN.', 5, 'L3'),
    _c('CHM411', 'Projet de chimie', 'Master Chimie — UNIKIN.', 6, 'Master 1'),
]

BIO_COURSES = [
    _c('BIO111', 'Biologie cellulaire', 'Sciences de la vie — UNIKIN.', 5, 'L1'),
    _c('BIO112', 'Informatique générale', 'Licence 1 Sciences de la vie — UNIKIN.', 3, 'L1'),
    _c('BIO211', 'Génétique', 'Sciences de la vie — UNIKIN.', 5, 'L2'),
    _c('BIO212', 'Microbiologie', 'Sciences de la vie — UNIKIN.', 4, 'L2'),
    _c('BIO311', 'Écologie', 'Environnement / Sciences de la vie — UNIKIN.', 4, 'L3'),
    _c('BIO312', 'Physiologie végétale', 'Sciences de la vie — UNIKIN.', 4, 'L3'),
    _c('BIO411', 'Projet de biologie', 'Master — UNIKIN.', 6, 'Master 1'),
]

GEO_COURSES = [
    _c('GEO111', 'Introduction aux sciences de la Terre', 'L1 Géosciences — UNIKIN.', 5, 'L1'),
    _c('GEO112', 'Géologie générale', 'L1 Géosciences — UNIKIN.', 6, 'L1'),
    _c('GEO113', 'Géologie et société', 'L1 Géosciences — UNIKIN.', 3, 'L1'),
    _c('GEO211', 'Sédimentologie', 'L2 Géosciences — UNIKIN.', 5, 'L2'),
    _c('GEO212', 'Pétrographie exogène', 'L2 Géosciences — UNIKIN.', 5, 'L2'),
    _c('GEO213', 'Géochimie générale', 'Géosciences — UNIKIN.', 4, 'L2'),
    _c('GEO214', 'Biologie du sol', 'Géosciences — UNIKIN.', 3, 'L2'),
    _c('GEO311', 'Métallogénie', 'L3 Géologie — UNIKIN.', 5, 'L3'),
    _c('GEO312', 'Géologie du génie civil', 'L3 Géologie — UNIKIN.', 4, 'L3'),
    _c('GEO313', 'Gestion des bases de données', 'L3 Géomatique — UNIKIN.', 5, 'L3'),
    _c('GEO314', 'Mécanique des sols et géotechnique', 'L3 Géosciences — UNIKIN.', 4, 'L3'),
    _c('GEO315', 'Éthique et déontologie professionnelles', 'L3 Géosciences — UNIKIN.', 2, 'L3'),
    _c('GEO316', 'Prospection géologique', 'Géosciences — UNIKIN.', 4, 'L3'),
    _c('GEO317', 'Pédologie', 'Géosciences — UNIKIN.', 3, 'L3'),
    _c('GEO411', 'Modélisation des réservoirs pétroliers', 'Ir / Master Géosciences — UNIKIN.', 5, 'Master 1'),
]
