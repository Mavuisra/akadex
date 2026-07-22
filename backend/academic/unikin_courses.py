# -*- coding: utf-8 -*-
"""
Programmes de cours UNIKIN — sources officielles.

Portail : https://www.unikin.ac.cd/programme-des-cours
Facultés : https://www.unikin.ac.cd/facultes-et-entites

PDF SGA 2024-2025 :
- https://www.unikin.ac.cd/wp-content/uploads/2025/07/Faculte-des-Sciences-et-Technologies-1.pdf
- https://www.unikin.ac.cd/wp-content/uploads/2025/07/FACULTE-de-Droit.pdf
- https://www.unikin.ac.cd/wp-content/uploads/2025/07/Faculte-des-Sciences-Agronomiques-et-Environnement.pdf
- https://www.unikin.ac.cd/wp-content/uploads/2025/07/Faculte-des-sciences-Pharmaceutiques.pdf
- https://www.unikin.ac.cd/wp-content/uploads/2025/07/Faculte-de-Psychologie-et-SED.pdf
- https://www.unikin.ac.cd/wp-content/uploads/2025/07/CHARGE-HORAIRE-FACULTE-DE-MEDECINE-.pdf
- https://www.unikin.ac.cd/wp-content/uploads/2025/07/Faculte-de-Medecine-Dentaire.pdf
- https://www.unikin.ac.cd/wp-content/uploads/2025/07/Faculte-de-Petrole-Gaz-et-Energie-Renouvelable.pdf
- https://www.unikin.ac.cd/wp-content/uploads/2025/07/Faculte-de-Medecine-Veterinaire.pdf
- https://www.unikin.ac.cd/wp-content/uploads/2025/10/FAC-DES-LETTRES-2.pdf
- https://www.unikin.ac.cd/wp-content/uploads/2025/10/Faculte-DE-POLYTCH.pdf
- https://www.unikin.ac.cd/wp-content/uploads/2025/10/FAC-SSAP-3-REINTEGRE.pdf

Pages programmes :
- Dentaire : https://www.unikin.ac.cd/fac/medecinedentaire/programmes-de-cours/
- Vétérinaire : https://www.unikin.ac.cd/fac/medvet/programme-des-cours/
- Polytechnique : https://polytech-unikin.ac.cd/programmes-cours

Format: (code, titre, description, crédits, cycle)
"""


def _c(code, title, desc, credits, cycle):
    return (code, title, desc, credits, cycle)

# ---------------------------------------------------------------------------
# Médecine humaine — SGA 2024-2025
# ---------------------------------------------------------------------------
MED_COURSES = [
    _c('MED111', 'Anatomie 1 (Ostéologie et Myologie)', 'B1 Médecine humaine — UNIKIN SGA 2024-2025.', 6, 'L1'),
    _c('MED112', 'Anatomie 1 (Arthrologie)', 'B1 Médecine — UNIKIN.', 5, 'L1'),
    _c('MED113', 'Neuro-anatomie', 'B1/B2 Médecine — UNIKIN.', 5, 'L1'),
    _c('MED114', 'Physiologie générale', 'B1 Médecine — UNIKIN.', 5, 'L1'),
    _c('MED115', 'Physiologie spéciale', 'B1/B2 Médecine — UNIKIN.', 5, 'L1'),
    _c('MED116', 'Chimie générale', 'B1 Sciences biomédicales — UNIKIN.', 5, 'L1'),
    _c('MED117', 'Mathématiques', 'B1 Médecine — UNIKIN.', 4, 'L1'),
    _c('MED118', 'Biostatistique', 'B1/B2 Médecine — UNIKIN.', 4, 'L1'),
    _c('MED119', 'Radio-anatomie', 'B2 Médecine — UNIKIN.', 4, 'L2'),
    _c('MED211', 'Biochimie médicale', 'B2 Médecine — UNIKIN.', 5, 'L2'),
    _c('MED212', 'Anatomie pathologique', 'D2/B3 Médecine — UNIKIN.', 5, 'L2'),
    _c('MED213', 'Microbiologie', 'B2/B3 Médecine — UNIKIN.', 5, 'L2'),
    _c('MED214', 'Physiologie de l’effort', 'B2 MPR — UNIKIN.', 5, 'L2'),
    _c('MED215', 'Kinanthropométrie', 'B2 MPR — UNIKIN.', 4, 'L2'),
    _c('MED216', 'Psycho-pharmacologie spéciale', 'L2 MPR — UNIKIN.', 3, 'L2'),
    _c('MED217', 'Psychologie médicale', 'Médecine — UNIKIN.', 3, 'L2'),
    _c('MED311', 'Sémiologie chirurgicale', 'B3 Médecine — UNIKIN.', 5, 'L3'),
    _c('MED312', 'Sémiologie médicale', 'B3 Médecine — UNIKIN.', 5, 'L3'),
    _c('MED313', 'Hématologie', 'M1 Biomédical — UNIKIN.', 5, 'L3'),
    _c('MED314', 'Rhumatologie', 'B3 Physiothérapie / Médecine — UNIKIN.', 4, 'L3'),
    _c('MED315', 'Endocrinologie', 'D2 Médecine — UNIKIN.', 4, 'L3'),
    _c('MED316', 'Pneumologie', 'D2/D3 Médecine — UNIKIN.', 4, 'L3'),
    _c('MED317', 'Épidémiologie', 'Médecine / Santé publique — UNIKIN.', 4, 'L3'),
    _c('MED318', 'Maladies métaboliques', 'Médecine — UNIKIN.', 4, 'L3'),
    _c('MED319', 'Soins palliatifs et pathologies', 'Médecine — UNIKIN.', 3, 'L3'),
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
    _c('MED422', 'Réanimation', 'Médecine — UNIKIN.', 5, 'Master 1'),
    _c('MED423', 'Réanimation et pathologies sportives', 'M1 Physiothérapie — UNIKIN.', 5, 'Master 1'),
]

# ---------------------------------------------------------------------------
# Droit — SGA 2024-2025
# ---------------------------------------------------------------------------
DROIT_COURSES = [
    _c('DRT111', 'Introduction au droit', 'Faculté de Droit UNIKIN.', 5, 'L1'),
    _c('DRT112', 'Droit constitutionnel', 'Droit public interne — UNIKIN.', 5, 'L1'),
    _c('DRT113', 'Informatique et bureautique', 'Licence 1 Droit — UNIKIN.', 3, 'L1'),
    _c('DRT114', 'Hygiène et environnement', 'Droit / environnement — UNIKIN.', 3, 'L1'),
    _c('DRT115', 'Histoire des institutions', 'L1 Droit — UNIKIN.', 4, 'L1'),
    _c('DRT116', 'Introduction aux relations internationales', 'L1 Droit — UNIKIN.', 4, 'L1'),
    _c('DRT211', 'Droit civil — personnes et famille', 'Faculté de Droit UNIKIN.', 5, 'L2'),
    _c('DRT212', 'Droit pénal général', 'Faculté de Droit UNIKIN.', 5, 'L2'),
    _c('DRT213', 'Droit de l’environnement', 'Droit public — UNIKIN.', 4, 'L2'),
    _c('DRT214', 'Histoire et principes du procès pénal', 'Droits de l’homme — UNIKIN.', 4, 'L2'),
    _c('DRT215', 'Droit parlementaire', 'L2 Droit public — UNIKIN.', 4, 'L2'),
    _c('DRT216', 'Droit des obligations', 'L2 Droit privé — UNIKIN.', 5, 'L2'),
    _c('DRT217', 'Droit commercial OHADA', 'L2/L3 Droit des affaires — UNIKIN.', 5, 'L2'),
    _c('DRT311', 'Droit des affaires', 'Faculté de Droit UNIKIN.', 5, 'L3'),
    _c('DRT312', 'Procédure civile', 'Faculté de Droit UNIKIN.', 5, 'L3'),
    _c('DRT313', 'Droit administratif', 'Justice administrative congolaise — UNIKIN.', 5, 'L3'),
    _c('DRT314', 'Droit du travail', 'L3 Droit — UNIKIN.', 4, 'L3'),
    _c('DRT315', 'Droit fiscal', 'L3 Droit — UNIKIN.', 4, 'L3'),
    _c('DRT316', 'Droit des sociétés', 'L3 Droit des affaires — UNIKIN.', 5, 'L3'),
    _c('DRT317', 'Droit des successions', 'L3 Droit privé — UNIKIN.', 4, 'L3'),
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
    _c('ECO114', 'Statistique descriptive', 'L1 FASEG — UNIKIN.', 4, 'L1'),
    _c('ECO115', 'Introduction à l’économie congolaise', 'L1 FASEG — UNIKIN.', 3, 'L1'),
    _c('GES121', 'Comptabilité générale', 'FASEG — Gestion (UNIKIN).', 5, 'L1'),
    _c('GES122', 'Introduction à la gestion', 'FASEG — Gestion (UNIKIN).', 4, 'L1'),
    _c('GES123', 'Droit des affaires appliqué', 'L1 Gestion — UNIKIN.', 3, 'L1'),
    _c('ECO211', 'Microéconomie II', 'FASEG (UNIKIN).', 5, 'L2'),
    _c('ECO212', 'Macroéconomie II', 'FASEG (UNIKIN).', 5, 'L2'),
    _c('ECO213', 'Économie monétaire', 'L2 Économie — UNIKIN.', 4, 'L2'),
    _c('GES211', 'Gestion financière', 'FASEG — Gestion (UNIKIN).', 5, 'L2'),
    _c('GES221', 'Marketing', 'FASEG — Gestion (UNIKIN).', 4, 'L2'),
    _c('GES222', 'Comptabilité analytique', 'FASEG — Gestion (UNIKIN).', 4, 'L2'),
    _c('GES223', 'Programmation', 'L2 IGAF (Économie) — UNIKIN SGA.', 4, 'L2'),
    _c('GES313', 'Télématique et réseaux', 'L2 GRH — UNIKIN.', 4, 'L2'),
    _c('ECO311', 'Économie du développement', 'FASEG (UNIKIN).', 5, 'L3'),
    _c('ECO312', 'Économie internationale', 'FASEG (UNIKIN).', 5, 'L3'),
    _c('ECO313', 'Systèmes décisionnels', 'L3 IGAF (Économie) — UNIKIN SGA.', 4, 'L3'),
    _c('GES311', 'Management des organisations', 'FASEG — Gestion (UNIKIN).', 5, 'L3'),
    _c('GES312', 'Gestion des ressources humaines', 'FASEG — Gestion (UNIKIN).', 5, 'L3'),
    _c('GES314', 'Contrôle de gestion', 'L3 Gestion — UNIKIN.', 4, 'L3'),
    _c('ECO411', 'Économétrie', 'Master FASEG / IRES (UNIKIN).', 5, 'Master 1'),
    _c('ECO412', 'Politique économique', 'Master FASEG (UNIKIN).', 5, 'Master 1'),
    _c('GES411', 'Stratégie d’entreprise', 'Master Gestion (UNIKIN).', 5, 'Master 1'),
    _c('GES412', 'Finance d’entreprise approfondie', 'Master Gestion — UNIKIN.', 5, 'Master 1'),
    _c('GES421', 'Mémoire / projet de gestion', 'Master FASEG (UNIKIN).', 6, 'Master 2'),
]

# ---------------------------------------------------------------------------
# Polytechnique — Génie civil (GCI)
# ---------------------------------------------------------------------------
POLY_CIVIL = [
    _c('FON111', 'Mathématiques pour ingénieurs I', 'Tronc commun Polytechnique — UNIKIN.', 5, 'L1'),
    _c('FON112', 'Physique générale', 'Tronc commun Polytechnique — UNIKIN.', 5, 'L1'),
    _c('TRA111', 'Communication technique', 'Matières transversales — Polytechnique UNIKIN.', 3, 'L1'),
    _c('GCI111', 'Dessin technique', 'Génie civil — UNIKIN.', 4, 'L1'),
    _c('GCI112', 'Géométrie descriptive', 'Génie civil — UNIKIN.', 4, 'L1'),
    _c('GCI211', 'Résistance des matériaux', 'Génie civil — UNIKIN.', 5, 'L2'),
    _c('GCI212', 'Mécanique des sols', 'Génie civil — UNIKIN.', 5, 'L2'),
    _c('GCI213', 'Topographie', 'Génie civil — UNIKIN.', 4, 'L2'),
    _c('GCI214', 'Matériaux de construction', 'Génie civil — UNIKIN.', 4, 'L2'),
    _c('GCI311', 'Béton armé', 'Génie civil — UNIKIN.', 5, 'L3'),
    _c('GCI312', 'Structures', 'Génie civil — UNIKIN.', 5, 'L3'),
    _c('GCI313', 'Hydraulique', 'Génie civil — UNIKIN.', 5, 'L3'),
    _c('GCI314', 'Routes et voies', 'Génie civil — UNIKIN.', 4, 'L3'),
    _c('PRO311', 'Projet ingénieur civil', 'Projet encadré — Polytechnique UNIKIN.', 4, 'L3'),
    _c('GCI411', 'Ouvrages d’art', 'Master / Ir Génie civil — UNIKIN.', 5, 'Master 1'),
    _c('STA411', 'Stage industriel', 'Stage — Polytechnique UNIKIN.', 4, 'Master 1'),
    _c('MEM421', 'Mémoire / TFE Génie civil', 'Travail de fin d’études — UNIKIN.', 6, 'Master 2'),
]

# ---------------------------------------------------------------------------
# Polytechnique — Génie électrique (GEL)
# ---------------------------------------------------------------------------
POLY_ELEC = [
    _c('FON121', 'Mathématiques pour ingénieurs II', 'Tronc commun — UNIKIN.', 5, 'L1'),
    _c('GEL111', 'Électrotechnique de base', 'Génie électrique — UNIKIN.', 5, 'L1'),
    _c('GEL112', 'Circuits électriques', 'Génie électrique — UNIKIN.', 5, 'L1'),
    _c('GEL211', 'Électronique analogique', 'Génie électrique — UNIKIN.', 5, 'L2'),
    _c('GEL212', 'Machines électriques', 'Génie électrique — UNIKIN.', 5, 'L2'),
    _c('GEL213', 'Mesures électriques', 'Génie électrique — UNIKIN.', 4, 'L2'),
    _c('GEL311', 'Automatique', 'Génie électrique — UNIKIN.', 5, 'L3'),
    _c('GEL312', 'Électronique de puissance', 'Génie électrique — UNIKIN.', 5, 'L3'),
    _c('GEL313', 'Réseaux électriques', 'Génie électrique — UNIKIN.', 5, 'L3'),
    _c('GEL314', 'Énergies renouvelables', 'Génie électrique — UNIKIN.', 4, 'L3'),
    _c('PRO312', 'Projet ingénieur électrique', 'Projet — Polytechnique UNIKIN.', 4, 'L3'),
    _c('GEL411', 'Commande des systèmes', 'Master / Ir — UNIKIN.', 5, 'Master 1'),
    _c('MEM422', 'Mémoire / TFE Génie électrique', 'TFE — UNIKIN.', 6, 'Master 2'),
]

# ---------------------------------------------------------------------------
# Polytechnique — Génie mécanique (GME)
# ---------------------------------------------------------------------------
POLY_MECA = [
    _c('GME111', 'Mécanique appliquée', 'Génie mécanique — UNIKIN.', 5, 'L1'),
    _c('GME112', 'Dessin mécanique', 'Génie mécanique — UNIKIN.', 4, 'L1'),
    _c('GME211', 'Technologie de fabrication', 'Génie mécanique — UNIKIN.', 5, 'L2'),
    _c('GME212', 'Résistance des matériaux', 'Génie mécanique — UNIKIN.', 5, 'L2'),
    _c('GME213', 'Mécanique des fluides', 'Génie mécanique — UNIKIN.', 4, 'L2'),
    _c('GME311', 'Conception mécanique', 'Génie mécanique — UNIKIN.', 5, 'L3'),
    _c('GME312', 'Thermodynamique appliquée', 'Génie mécanique — UNIKIN.', 5, 'L3'),
    _c('GME313', 'Machines thermiques', 'Génie mécanique — UNIKIN.', 5, 'L3'),
    _c('GME314', 'Maintenance industrielle', 'Génie mécanique — UNIKIN.', 4, 'L3'),
    _c('PRO313', 'Projet ingénieur mécanique', 'Projet — Polytechnique UNIKIN.', 4, 'L3'),
    _c('GME411', 'CAO / FAO', 'Master / Ir — UNIKIN.', 5, 'Master 1'),
    _c('MEM423', 'Mémoire / TFE Génie mécanique', 'TFE — UNIKIN.', 6, 'Master 2'),
]

# ---------------------------------------------------------------------------
# Polytechnique — Génie informatique (GIN)
# ---------------------------------------------------------------------------
POLY_INFO = [
    _c('GIN111', 'Algorithmique et programmation', 'Génie informatique — Polytechnique UNIKIN.', 5, 'L1'),
    _c('GIN112', 'Architecture des ordinateurs', 'Génie informatique — UNIKIN.', 4, 'L1'),
    _c('GIN211', 'Structures de données', 'Génie informatique — UNIKIN.', 5, 'L2'),
    _c('GIN212', 'Bases de données', 'Génie informatique — UNIKIN.', 5, 'L2'),
    _c('GIN213', 'Réseaux informatiques', 'Génie informatique — UNIKIN.', 4, 'L2'),
    _c('GIN311', 'Génie logiciel', 'Génie informatique — UNIKIN.', 5, 'L3'),
    _c('GIN312', 'Systèmes d’exploitation', 'Génie informatique — UNIKIN.', 5, 'L3'),
    _c('GIN313', 'Sécurité informatique', 'Génie informatique — UNIKIN.', 4, 'L3'),
    _c('PRO314', 'Projet ingénieur informatique', 'Projet — Polytechnique UNIKIN.', 4, 'L3'),
    _c('GIN411', 'Intelligence artificielle appliquée', 'Master / Ir — UNIKIN.', 5, 'Master 1'),
    _c('MEM424', 'Mémoire / TFE Génie informatique', 'TFE — UNIKIN.', 6, 'Master 2'),
]

# ---------------------------------------------------------------------------
# FLSH — Lettres & Sciences Humaines (départements officiels UNIKIN)
# ---------------------------------------------------------------------------
LETTRES_COURSES = [
    _c('LET111', 'Méthodologie du travail universitaire', 'FLSH — UNIKIN.', 3, 'L1'),
    _c('LET112', 'Expression française', 'FLSH — UNIKIN.', 4, 'L1'),
    _c('LET113', 'Introduction à la philosophie', 'Département Philosophie — FLSH UNIKIN.', 4, 'L1'),
    _c('LET121', 'Linguistique générale', 'Lettres et civilisations — FLSH UNIKIN.', 4, 'L1'),
    _c('LET122', 'Introduction aux littératures', 'FLSH — UNIKIN.', 4, 'L1'),
    _c('LET123', 'Anglais de communication', 'Lettres anglaises / ELV — FLSH UNIKIN.', 3, 'L1'),
    _c('LET211', 'Littérature africaine', 'Lettres et civilisations africaines — UNIKIN.', 4, 'L2'),
    _c('LET212', 'Littérature francophone', 'Lettres et civilisations françaises — UNIKIN.', 4, 'L2'),
    _c('LET213', 'Civilisation britannique et américaine', 'Lettres anglaises — FLSH UNIKIN.', 4, 'L2'),
    _c('HIS211', 'Histoire de l’Afrique centrale', 'Sciences historiques — FLSH UNIKIN.', 4, 'L2'),
    _c('HIS212', 'Histoire contemporaine du Congo', 'Sciences historiques — FLSH UNIKIN.', 4, 'L2'),
    _c('SIC211', 'Théories de la communication', 'Sciences de l’information et de la communication — FLSH.', 4, 'L2'),
    _c('SIC212', 'Médias et société', 'SIC — FLSH UNIKIN.', 4, 'L2'),
    _c('LET311', 'Séminaire de recherche', 'FLSH — UNIKIN.', 5, 'L3'),
    _c('LET312', 'Critique littéraire', 'FLSH — UNIKIN.', 4, 'L3'),
    _c('HIS311', 'Histoire des institutions africaines', 'Sciences historiques — FLSH UNIKIN.', 4, 'L3'),
    _c('HIS312', 'Gestion du patrimoine culturel', 'Patrimoine et développement — FLSH UNIKIN.', 4, 'L3'),
    _c('TRA311', 'Traduction générale', 'Traduction et interprétariat — FLSH UNIKIN.', 4, 'L3'),
    _c('LET411', 'Mémoire de Master FLSH', 'Master Lettres — UNIKIN.', 6, 'Master 1'),
    _c('SIC411', 'Communication organisationnelle', 'Master SIC — FLSH UNIKIN.', 5, 'Master 1'),
]

# ---------------------------------------------------------------------------
# FSSAP — Sciences sociales, administratives et politiques
# ---------------------------------------------------------------------------
SOC_COURSES = [
    _c('SOC111', 'Introduction à la sociologie', 'FSSAP — UNIKIN.', 4, 'L1'),
    _c('SOC112', 'Mathématiques appliquées aux sciences sociales', 'L1 SPA — UNIKIN SGA.', 4, 'L1'),
    _c('POL111', 'Introduction aux sciences politiques', 'FSSAP — UNIKIN.', 4, 'L1'),
    _c('ADM111', 'Introduction à l’administration publique', 'FSSAP — UNIKIN.', 4, 'L1'),
    _c('SOC211', 'Sociologie urbaine', 'FSSAP — UNIKIN.', 4, 'L2'),
    _c('SOC212', 'Sociologie de la famille', 'FSSAP — UNIKIN.', 4, 'L2'),
    _c('POL211', 'Sciences politiques', 'FSSAP — UNIKIN.', 5, 'L2'),
    _c('POL212', 'Institutions politiques congolaises', 'FSSAP — UNIKIN.', 4, 'L2'),
    _c('ADM211', 'Droit administratif appliqué', 'Administration publique — FSSAP UNIKIN.', 4, 'L2'),
    _c('ADM212', 'Gestion des ressources humaines publiques', 'FSSAP — UNIKIN.', 4, 'L2'),
    _c('ADM311', 'Administration publique', 'FSSAP — UNIKIN.', 5, 'L3'),
    _c('SOC311', 'Sociologie du travail', 'FSSAP — UNIKIN.', 4, 'L3'),
    _c('POL311', 'Relations internationales', 'FSSAP — UNIKIN.', 5, 'L3'),
    _c('POL312', 'Politiques publiques', 'FSSAP — UNIKIN.', 4, 'L3'),
    _c('REL411', 'Relations internationales approfondies', 'Master FSSAP — UNIKIN.', 5, 'Master 1'),
    _c('ADM411', 'Gestion publique', 'Master Administration — UNIKIN.', 5, 'Master 1'),
    _c('SOC421', 'Mémoire FSSAP', 'Master — UNIKIN.', 6, 'Master 2'),
]

# ---------------------------------------------------------------------------
# Sciences Agronomiques et Environnement — SGA 2024-2025
# ---------------------------------------------------------------------------
AGRO_COURSES = [
    _c('AGR111', 'Introduction à l’agronomie', 'Sciences Agronomiques et Environnement — UNIKIN.', 5, 'L1'),
    _c('AGR112', 'Introduction aux sciences de la Terre', 'L1 Agronomie — UNIKIN.', 5, 'L1'),
    _c('AGR113', 'Botanique 1', 'Agronomie — UNIKIN SGA.', 4, 'L1'),
    _c('AGR114', 'Chimie générale', 'CIA / Agronomie — UNIKIN.', 4, 'L1'),
    _c('AGR211', 'Hydrogéologie et hydrochimie', 'L2 GSEA — UNIKIN.', 5, 'L2'),
    _c('AGR212', 'Gestion des forêts et de la biodiversité', 'Licence GFB — UNIKIN.', 5, 'L2'),
    _c('AGR213', 'Production végétale', 'Agronomie — UNIKIN.', 5, 'L2'),
    _c('AGR214', 'Zootechnie générale', 'Département Zootechnie — UNIKIN.', 5, 'L2'),
    _c('AGR215', 'Botanique 2', 'Agronomie — UNIKIN.', 4, 'L2'),
    _c('AGR216', 'Physiologie végétale', 'Agronomie — UNIKIN.', 4, 'L2'),
    _c('AGR217', 'Chimie des sols', 'Pédologie — UNIKIN SGA.', 4, 'L2'),
    _c('AGR311', 'Gestion des sols, eaux et assainissement', 'Licence GSEA — UNIKIN.', 5, 'L3'),
    _c('AGR312', 'Gestion des ressources naturelles renouvelables', 'Licence GRNR — UNIKIN.', 5, 'L3'),
    _c('AGR313', 'Pédologie tropicale', 'Agronomie / Géosciences — UNIKIN.', 4, 'L3'),
    _c('AGR314', 'Chimie et microbiologie de l’eau', 'GSEA — UNIKIN SGA.', 4, 'L3'),
    _c('AGR315', 'Microbiologie alimentaire', 'Chimie et industrie agricole — UNIKIN.', 4, 'L3'),
    _c('AGR316', 'Statistique appliquée', 'Agronomie — UNIKIN.', 3, 'L3'),
    _c('AGR411', 'Aménagement et gestion des forêts', 'Master MAGF — UNIKIN.', 5, 'Master 1'),
    _c('AGR412', 'Gestion de la biodiversité', 'Master MGB — UNIKIN.', 5, 'Master 1'),
    _c('AGR413', 'Sciences du sol et bassins versants', 'Master MSSGB — UNIKIN.', 5, 'Master 1'),
    _c('AGR414', 'Gestion de l’eau et assainissement', 'Master MGEA — UNIKIN.', 5, 'Master 1'),
    _c('AGR415', 'Géomatique et changement climatique', 'Master MGCC — UNIKIN.', 5, 'Master 1'),
    _c('AGR416', 'Gestion des eaux souterraines', 'M1 GEA — UNIKIN.', 5, 'Master 1'),
    _c('AGR417', 'Analyse et évaluation des projets', 'Master Agronomie — UNIKIN SGA.', 4, 'Master 1'),
]

# ---------------------------------------------------------------------------
# FPSE — Psychologie — SGA 2024-2025
# ---------------------------------------------------------------------------
PSY_COURSES = [
    _c('PSY111', 'Introduction à la psychologie', 'FPSE — Psychologie (UNIKIN).', 4, 'L1'),
    _c('PSY112', 'Histoire de la psychologie', 'L1 Psychologie — UNIKIN SGA.', 4, 'L1'),
    _c('PSY113', 'Méthodologie de recherche en psychologie', 'FPSE — UNIKIN.', 4, 'L1'),
    _c('PSY114', 'Psychologie générale', 'FPSE — UNIKIN.', 4, 'L1'),
    _c('PSY115', 'Statistique descriptive', 'FPSE — UNIKIN.', 3, 'L1'),
    _c('PSY211', 'Psychologie du développement', 'FPSE — UNIKIN.', 5, 'L2'),
    _c('PSY212', 'Psychologie sociale', 'FPSE — UNIKIN.', 4, 'L2'),
    _c('PSY213', 'Psychologie commerciale', 'L2 Psychologie — UNIKIN.', 4, 'L2'),
    _c('PSY214', 'Expérimentation en psychologie', 'FPSE — UNIKIN.', 4, 'L2'),
    _c('PSY215', 'Applications de la psychologie cognitive', 'FPSE — UNIKIN.', 4, 'L2'),
    _c('PSY216', 'Psychologie de l’enfant', 'FPSE — UNIKIN SGA.', 4, 'L2'),
    _c('PSY217', 'Analyse des données', 'FPSE — UNIKIN.', 3, 'L2'),
    _c('PSY311', 'Psychologie clinique', 'FPSE — UNIKIN.', 5, 'L3'),
    _c('PSY312', 'Psychologie du travail', 'FPSE — UNIKIN.', 4, 'L3'),
    _c('PSY313', 'Séminaire de psychologie clinique', 'FPSE — UNIKIN.', 4, 'L3'),
    _c('PSY314', 'Psychologie scolaire (OSP)', 'FPSE — UNIKIN SGA.', 4, 'L3'),
    _c('PSY315', 'Psychologie du sport', 'FPSE — UNIKIN SGA.', 3, 'L3'),
    _c('PSY316', 'Psychologie positive', 'FPSE — UNIKIN SGA.', 3, 'L3'),
    _c('PSY411', 'Psychologie de l’adulte', 'Master / DES — UNIKIN.', 4, 'Master 1'),
    _c('PSY412', 'Analyse factorielle et psychométrie', 'Master Psychologie — UNIKIN.', 4, 'Master 1'),
    _c('PSY413', 'Mémoire de psychologie', 'Master FPSE — UNIKIN.', 6, 'Master 2'),
]

# ---------------------------------------------------------------------------
# FPSE — Sciences de l’éducation — SGA 2024-2025
# ---------------------------------------------------------------------------
PEDAGO_COURSES = [
    _c('PED111', 'Introduction aux sciences de l’éducation', 'FPSE — UNIKIN.', 4, 'L1'),
    _c('PED112', 'Histoire de la pédagogie', 'FPSE — UNIKIN SGA.', 4, 'L1'),
    _c('PED121', 'Psychologie de l’apprentissage', 'FPSE — UNIKIN.', 4, 'L1'),
    _c('PED211', 'Didactique générale', 'FPSE — UNIKIN.', 5, 'L2'),
    _c('PED212', 'Didactique des sciences', 'FPSE — UNIKIN SGA.', 4, 'L2'),
    _c('PED221', 'Évaluation des apprentissages', 'FPSE — UNIKIN.', 4, 'L2'),
    _c('PED222', 'Analyse des pratiques professionnelles I', 'FPSE — UNIKIN.', 4, 'L2'),
    _c('PED311', 'Didactique du numérique', 'FPSE — TICE (UNIKIN).', 4, 'L3'),
    _c('PED312', 'Analyse des pratiques professionnelles II', 'FPSE — UNIKIN.', 4, 'L3'),
    _c('PED313', 'Recherche en pédagogie', 'FPSE — UNIKIN SGA.', 4, 'L3'),
    _c('PED411', 'Recherche en éducation', 'Master FPSE — UNIKIN.', 5, 'Master 1'),
    _c('PED412', 'Économie de l’éducation', 'M1 Sciences de l’éducation — UNIKIN.', 4, 'Master 1'),
    _c('PED413', 'Mémoire en sciences de l’éducation', 'Master FPSE — UNIKIN.', 6, 'Master 2'),
]

# ---------------------------------------------------------------------------
# Sciences pharmaceutiques — SGA 2024-2025
# ---------------------------------------------------------------------------
PHARMA_COURSES = [
    _c('PHA111', 'Chimie générale', 'Sciences Pharmaceutiques — UNIKIN.', 5, 'L1'),
    _c('PHA112', 'Chimie pharmaceutique inorganique', 'L1 Pharmacie — UNIKIN.', 5, 'L1'),
    _c('PHA113', 'Mathématiques générales', 'L1 LTP Pharmacie — UNIKIN.', 4, 'L1'),
    _c('PHA114', 'Chimie physique appliquée', 'Pharmacie — UNIKIN.', 4, 'L1'),
    _c('PHA115', 'Chimie organique I', '1ère année PharmD — UNIKIN SGA.', 5, 'L1'),
    _c('PHA116', 'Botanique', 'Pharmacognosie — UNIKIN.', 4, 'L1'),
    _c('PHA211', 'Pharmacologie', 'Sciences Pharmaceutiques — UNIKIN.', 5, 'L2'),
    _c('PHA212', 'Immunologie', 'Pharmacie — UNIKIN.', 4, 'L2'),
    _c('PHA213', 'Physiologie humaine I', 'Pharmacie — UNIKIN SGA.', 4, 'L2'),
    _c('PHA214', 'Physiologie humaine II', 'Pharmacie — UNIKIN SGA.', 4, 'L2'),
    _c('PHA215', 'Analyse instrumentale', 'GAM / Pharmacie — UNIKIN SGA.', 4, 'L2'),
    _c('PHA311', 'Pharmacie galénique', 'Sciences Pharmaceutiques — UNIKIN.', 5, 'L3'),
    _c('PHA1310', 'Microbiologie pharmaceutique', 'PHAR1310 — 3ème Générale (UNIKIN).', 5, 'L3'),
    _c('PHA1307', 'Immunologie pathologique', 'PHAR1307 — UNIKIN.', 4, 'L3'),
    _c('PHA312', 'Qualité microbiologique des produits de santé', 'L3 / MTA — UNIKIN.', 4, 'L3'),
    _c('PHA313', 'Chimie pharmaceutique', 'L3 Pharmacie — UNIKIN.', 5, 'L3'),
    _c('PHA2107', 'Microbiologie industrielle', 'PHAR2107 — 4ème Médicale (UNIKIN).', 5, 'Master 1'),
    _c('PHA2201', 'Analyse des aliments', 'PHAR2201 — UNIKIN SGA.', 4, 'Master 1'),
    _c('PHA411', 'Analyse des médicaments et produits de santé', '5ème année — UNIKIN SGA.', 5, 'Master 1'),
    _c('PHA412', 'Questions approfondies de microbiologie', 'DEA/DES Pharmacie — UNIKIN.', 5, 'Master 1'),
    _c('PHA421', 'Mémoire / TFE Pharmacie', 'PharmD — UNIKIN.', 6, 'Master 2'),
]

# ---------------------------------------------------------------------------
# Médecine dentaire — programme officiel UNIKIN
# ---------------------------------------------------------------------------
DENT_COURSES = [
    _c('DEN111', 'Santé publique générale', '1er Bachelor Médecine Dentaire — UNIKIN.', 3, 'L1'),
    _c('DEN112', 'Histoire de la médecine et médecine dentaire', '1er Bachelor — UNIKIN.', 2, 'L1'),
    _c('DEN113', 'Chimie générale', '1er Bachelor — UNIKIN.', 4, 'L1'),
    _c('DEN114', 'Éducation à la citoyenneté', '1er Bachelor — UNIKIN.', 2, 'L1'),
    _c('DEN115', 'Statistiques et informatique médicale', '1er Bachelor — UNIKIN.', 3, 'L1'),
    _c('DEN116', 'Logique et expression écrite et orale', '1er Bachelor — UNIKIN.', 3, 'L1'),
    _c('DEN117', 'Anglais médical', '1er Bachelor — UNIKIN.', 2, 'L1'),
    _c('DEN118', 'Physique', '1er Bachelor — UNIKIN.', 4, 'L1'),
    _c('DEN119', 'Mathématiques appliquées', '1er Bachelor — UNIKIN.', 3, 'L1'),
    _c('DEN120', 'Anthropologie médicale', '1er Bachelor — UNIKIN.', 2, 'L1'),
    _c('DEN121', 'Anatomie générale', '1er Bachelor — UNIKIN.', 5, 'L1'),
    _c('DEN122', 'Biologie générale', '1er Bachelor — UNIKIN.', 4, 'L1'),
    _c('DEN123', 'Chimie organique', '1er Bachelor — UNIKIN.', 4, 'L1'),
    _c('DEN124', 'Biophysique', '1er Bachelor — UNIKIN.', 3, 'L1'),
    _c('DEN125', 'Génétique', '1er Bachelor — UNIKIN.', 3, 'L1'),
    _c('DEN126', 'Histologie générale', '1er Bachelor — UNIKIN.', 4, 'L1'),
    _c('DEN127', 'Soins infirmiers : premiers secours', '1er Bachelor — UNIKIN.', 3, 'L1'),
    _c('DEN211', 'Anatomie spéciale', '2e Bachelor — UNIKIN.', 5, 'L2'),
    _c('DEN212', 'Biochimie générale', '2e Bachelor — UNIKIN.', 4, 'L2'),
    _c('DEN213', 'Histologie spéciale et buccale', '2e Bachelor — UNIKIN.', 4, 'L2'),
    _c('DEN214', 'Biologie moléculaire', '2e Bachelor — UNIKIN.', 3, 'L2'),
    _c('DEN215', 'Anatomie topographique tête et cou', '2e Bachelor — UNIKIN.', 5, 'L2'),
    _c('DEN216', 'Physiologie', '2e Bachelor — UNIKIN.', 5, 'L2'),
    _c('DEN217', 'Embryologie', '2e Bachelor — UNIKIN.', 3, 'L2'),
    _c('DEN218', 'Biomatériologie dentaire', '2e Bachelor — UNIKIN.', 4, 'L2'),
    _c('DEN219', 'Anatomie de dents et arcades', '2e Bachelor — UNIKIN.', 4, 'L2'),
    _c('DEN220', 'Dentisterie opératoire : cariologie', '2e Bachelor — UNIKIN.', 5, 'L2'),
    _c('DEN221', 'Prothèse dentaire : notions de base et gnathologie', '2e Bachelor — UNIKIN.', 4, 'L2'),
    _c('DEN222', 'Parasitologie / helminthologie', '2e Bachelor — UNIKIN.', 3, 'L2'),
    _c('DEN223', 'Physiopathologie', '2e Bachelor — UNIKIN.', 4, 'L2'),
    _c('DEN311', 'Dentisterie opératoire : cavitologie', '3e Bachelor — UNIKIN.', 5, 'L3'),
    _c('DEN312', 'Chirurgie générale', '3e Bachelor — UNIKIN.', 4, 'L3'),
    _c('DEN313', 'Anatomie pathologique générale', '3e Bachelor — UNIKIN.', 4, 'L3'),
    _c('DEN314', 'Immunologie', '3e Bachelor — UNIKIN.', 4, 'L3'),
    _c('DEN315', 'Microbiologie', '3e Bachelor — UNIKIN.', 4, 'L3'),
    _c('DEN316', 'Sémiologie chirurgicale', '3e Bachelor — UNIKIN.', 4, 'L3'),
    _c('DEN317', 'Pathologie médicale', '3e Bachelor — UNIKIN.', 4, 'L3'),
    _c('DEN318', 'Parodontologie : notions de base', '3e Bachelor — UNIKIN.', 4, 'L3'),
    _c('DEN319', 'Prothèse amovible complète', '3e Bachelor — UNIKIN.', 5, 'L3'),
    _c('DEN320', 'Prothèse fixée unitaire', '3e Bachelor — UNIKIN.', 5, 'L3'),
    _c('DEN321', 'Pharmacologie générale', '3e Bachelor — UNIKIN.', 4, 'L3'),
    _c('DEN322', 'Sémiologie bucco-dentaire', '3e Bachelor — UNIKIN.', 4, 'L3'),
    _c('DEN323', 'Maladie de la bouche', '3e Bachelor — UNIKIN.', 3, 'L3'),
    _c('DEN324', 'Travail de fin de cycle', '3e Bachelor — UNIKIN.', 6, 'L3'),
    _c('DEN411', 'Chirurgie orale', 'Master 1 Médecine Dentaire — UNIKIN.', 5, 'Master 1'),
    _c('DEN412', 'Orthopédie dento-faciale : notions de base', 'Master 1 — UNIKIN.', 5, 'Master 1'),
    _c('DEN413', 'Parodontologie et gérodontologie', 'Master 1 — UNIKIN.', 5, 'Master 1'),
    _c('DEN414', 'Odontologie pédiatrique : notions de base', 'Master 1 — UNIKIN.', 5, 'Master 1'),
    _c('DEN415', 'Prothèse amovible partielle', 'Master 1 — UNIKIN.', 5, 'Master 1'),
    _c('DEN416', 'Prothèse fixée plurale', 'Master 1 — UNIKIN.', 5, 'Master 1'),
    _c('DEN417', 'Imagerie médicale', 'Master 1 — UNIKIN.', 4, 'Master 1'),
    _c('DEN418', 'Anesthésie et réanimation', 'Master 1 — UNIKIN.', 4, 'Master 1'),
    _c('DEN419', 'Médecine nucléaire', 'Master 1 — UNIKIN.', 3, 'Master 1'),
    _c('DEN420', 'Parodontologie et implantologie', 'Master 2 — UNIKIN.', 5, 'Master 2'),
    _c('DEN421', 'Orthopédie dento-faciale : thérapeutique', 'Master 2 — UNIKIN.', 5, 'Master 2'),
    _c('DEN422', 'Chirurgie maxillo-faciale', 'Master 2 — UNIKIN.', 5, 'Master 2'),
    _c('DEN423', 'Dentisterie opératoire : endodontie', 'Master 2 — UNIKIN.', 5, 'Master 2'),
    _c('DEN424', 'Éthique et déontologie', 'Master 2 — UNIKIN.', 3, 'Master 2'),
    _c('DEN425', 'Droit médical / médecine légale', 'Master 2 — UNIKIN.', 3, 'Master 2'),
    _c('DEN426', 'Gestion, management dentaire et ergonomie', 'Master 2 — UNIKIN.', 3, 'Master 2'),
    _c('DEN427', 'Urgences au cabinet dentaire', 'Master 2 — UNIKIN.', 3, 'Master 2'),
    _c('DEN428', 'Travail de fin d’études', 'Master 3 — UNIKIN.', 6, 'Master 2'),
]

# ---------------------------------------------------------------------------
# Médecine vétérinaire — programme officiel UNIKIN
# ---------------------------------------------------------------------------
VET_COURSES = [
    _c('VET111', 'Agrostologie et botanique', '1er cycle Médecine vétérinaire — UNIKIN.', 5, 'L1'),
    _c('VET112', 'Anatomie systématique I', '1er cycle — UNIKIN.', 6, 'L1'),
    _c('VET113', 'Anglais', '1er cycle — UNIKIN.', 2, 'L1'),
    _c('VET114', 'Biologie', '1er cycle — UNIKIN.', 5, 'L1'),
    _c('VET115', 'Chimie générale et organique', '1er cycle — UNIKIN.', 6, 'L1'),
    _c('VET116', 'Climatologie et écologie', '1er cycle — UNIKIN.', 4, 'L1'),
    _c('VET117', 'Éducation à la citoyenneté', '1er cycle — UNIKIN.', 2, 'L1'),
    _c('VET118', 'Éléments de mathématique et statistique', '1er cycle — UNIKIN.', 3, 'L1'),
    _c('VET119', 'Hygiène et assainissement', '1er cycle — UNIKIN.', 2, 'L1'),
    _c('VET120', 'Informatique', '1er cycle — UNIKIN.', 2, 'L1'),
    _c('VET121', 'Logique et expression orale et écrite', '1er cycle — UNIKIN.', 2, 'L1'),
    _c('VET122', 'Physique et biophysique', '1er cycle — UNIKIN.', 5, 'L1'),
    _c('VET123', 'Zoologie', '1er cycle — UNIKIN.', 5, 'L1'),
    _c('VET211', 'Anatomie systématique II', '2e graduat — UNIKIN.', 6, 'L2'),
    _c('VET212', 'Biochimie descriptive et métabolique', '2e graduat — UNIKIN.', 5, 'L2'),
    _c('VET213', 'Biométrie et biostatistique', 'B2 Médecine vétérinaire — UNIKIN SGA.', 3, 'L2'),
    _c('VET214', 'Conservation et protection de la nature', '2e graduat — UNIKIN.', 2, 'L2'),
    _c('VET215', 'Embryologie', '2e graduat — UNIKIN.', 3, 'L2'),
    _c('VET216', 'Ethnologie', '2e graduat — UNIKIN.', 3, 'L2'),
    _c('VET217', 'Extérieur des animaux domestiques', '2e graduat — UNIKIN.', 3, 'L2'),
    _c('VET218', 'Génétique', '2e graduat — UNIKIN.', 4, 'L2'),
    _c('VET219', 'Histologie', '2e graduat — UNIKIN.', 4, 'L2'),
    _c('VET220', 'Initiation à la recherche scientifique', 'B2 — UNIKIN SGA.', 2, 'L2'),
    _c('VET221', 'Physiologie animale', 'B2 — UNIKIN SGA.', 5, 'L2'),
    _c('VET222', 'Psychologie générale et éthologie', '2e graduat — UNIKIN.', 2, 'L2'),
    _c('VET223', 'Sociologie rurale', '2e graduat — UNIKIN.', 2, 'L2'),
    _c('VET224', 'Biologie moléculaire', 'B2 — UNIKIN SGA.', 3, 'L2'),
    _c('VET311', 'Anatomie pathologique', 'B3 — UNIKIN SGA.', 5, 'L3'),
    _c('VET312', 'Physiopathologie', 'B3 — UNIKIN SGA.', 4, 'L3'),
    _c('VET313', 'Immunologie', 'B3 — UNIKIN SGA.', 3, 'L3'),
    _c('VET314', 'Économie et gestion des entreprises', 'B3 — UNIKIN SGA.', 3, 'L3'),
    _c('VET315', 'Nutrition et alimentation animales', 'B3 — UNIKIN SGA.', 4, 'L3'),
    _c('VET316', 'Hygiène et exploitation des animaux domestiques I', 'B3 — UNIKIN SGA.', 4, 'L3'),
    _c('VET317', 'Génétique et amélioration génétique', 'B3 — UNIKIN SGA.', 4, 'L3'),
    _c('VET318', 'Police sanitaire', 'B3/D2 — UNIKIN SGA.', 3, 'L3'),
    _c('VET411', 'Médecine interne des grands animaux I', 'M1 — UNIKIN SGA.', 5, 'Master 1'),
    _c('VET412', 'Médecine interne des petits animaux I', 'M1 — UNIKIN SGA.', 4, 'Master 1'),
    _c('VET413', 'Épidémiologie vétérinaire', 'M1 — UNIKIN SGA.', 4, 'Master 1'),
    _c('VET414', 'Chirurgie générale', 'M1 — UNIKIN SGA.', 5, 'Master 1'),
    _c('VET415', 'Anesthésiologie et réanimation', 'M1 — UNIKIN SGA.', 4, 'Master 1'),
    _c('VET416', 'Imagerie vétérinaire', 'M1 — UNIKIN SGA.', 3, 'Master 1'),
    _c('VET417', 'Pharmacologie vétérinaire', 'M1 — UNIKIN SGA.', 4, 'Master 1'),
    _c('VET418', 'Toxicologie vétérinaire', 'M1 — UNIKIN SGA.', 3, 'Master 1'),
    _c('VET419', 'Maladies virales et cliniques', 'D2/M1 — UNIKIN SGA.', 5, 'Master 1'),
    _c('VET420', 'Maladies bactériennes et cliniques', 'M1 — UNIKIN SGA.', 5, 'Master 1'),
    _c('VET421', 'Expertise et technologie des denrées alimentaires', 'M1/M2 — UNIKIN SGA.', 4, 'Master 1'),
    _c('VET422', 'Législation vétérinaire', 'Master — UNIKIN SGA.', 3, 'Master 1'),
    _c('VET423', 'Chirurgie spéciale des grands animaux', 'M2 — UNIKIN SGA.', 5, 'Master 2'),
    _c('VET424', 'Chirurgie spéciale des petits animaux', 'M2 — UNIKIN SGA.', 5, 'Master 2'),
    _c('VET425', 'Mémoire de médecine vétérinaire', 'M3 / D3 — UNIKIN.', 6, 'Master 2'),
]

# ---------------------------------------------------------------------------
# Pétrole, Gaz et Énergies renouvelables — SGA 2024-2025
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
    _c('PET217', 'Introduction à l’économétrie', 'Grad 2 Pétrole & Gaz — UNIKIN SGA.', 4, 'L2'),
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
    _c('PET423', 'Modèles économétriques', 'DEA Pétrole et Gaz — UNIKIN SGA.', 4, 'Master 2'),
]

# ---------------------------------------------------------------------------
# École de Santé Publique de Kinshasa
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
# Sciences & Technologies — Physique (SGA 2024-2025)
# ---------------------------------------------------------------------------
PHY_COURSES = [
    _c('PHY111', 'Algèbre', 'Licence 1 Physique — UNIKIN.', 6, 'L1'),
    _c('PHY112', 'Mécanique', 'Mention Physique & Technologie — UNIKIN.', 5, 'L1'),
    _c('PHY121', 'Électricité et magnétisme', 'Physique & Technologie — UNIKIN.', 5, 'L1'),
    _c('PHY211', 'Thermodynamique', 'Licence 2 Physique — UNIKIN.', 4, 'L2'),
    _c('PHY212', 'Optique', 'Licence 2 Physique — UNIKIN.', 4, 'L2'),
    _c('PHY213', 'Analyse numérique', 'Licence 2 Physique — UNIKIN SGA.', 4, 'L2'),
    _c('PHY311', 'Physique moderne', 'Licence 3 Physique — UNIKIN.', 5, 'L3'),
    _c('PHY312', 'Physique du solide', 'Licence 3 Physique — UNIKIN.', 5, 'L3'),
    _c('PHY313', 'Physique mathématique', 'Licence 3 / DEA — UNIKIN.', 4, 'L3'),
    _c('PHY411', 'Compléments de physique mathématique', 'DEA Physique — UNIKIN.', 5, 'Master 1'),
    _c('PHY412', 'Questions spéciales d’analyse numérique', 'Master Physique — UNIKIN SGA.', 4, 'Master 1'),
]

# ---------------------------------------------------------------------------
# Sciences & Technologies — Chimie & Industrie
# ---------------------------------------------------------------------------
CHIM_COURSES = [
    _c('CHM111', 'Chimie générale', 'Mention Chimie & Industrie — UNIKIN.', 5, 'L1'),
    _c('CHM112', 'Chimie organique I', 'Chimie & Industrie — UNIKIN.', 5, 'L1'),
    _c('CHM211', 'Méthodes numériques et programmation', 'Licence 2 Chimie — UNIKIN.', 4, 'L2'),
    _c('CHM212', 'Chimie organique II', 'Licence 2 Chimie — UNIKIN.', 5, 'L2'),
    _c('CHM213', 'Analyse 2', 'Licence 2 Chimie — UNIKIN.', 4, 'L2'),
    _c('CHM311', 'Chimie analytique', 'Licence 3 Chimie & Industrie — UNIKIN.', 5, 'L3'),
    _c('CHM312', 'Chimie industrielle', 'Licence 3 Chimie & Industrie — UNIKIN.', 5, 'L3'),
    _c('CHM313', 'Chimie analytique II', 'L3 Chimie — UNIKIN SGA.', 4, 'L3'),
    _c('CHM411', 'Projet de chimie', 'Master Chimie — UNIKIN.', 6, 'Master 1'),
]

# ---------------------------------------------------------------------------
# Sciences & Technologies — Sciences de la vie
# ---------------------------------------------------------------------------
BIO_COURSES = [
    _c('BIO111', 'Biologie cellulaire', 'Sciences de la vie — UNIKIN.', 5, 'L1'),
    _c('BIO112', 'Informatique générale', 'Licence 1 Sciences de la vie — UNIKIN.', 3, 'L1'),
    _c('BIO211', 'Génétique', 'Sciences de la vie — UNIKIN.', 5, 'L2'),
    _c('BIO212', 'Microbiologie', 'Sciences de la vie — UNIKIN.', 4, 'L2'),
    _c('BIO311', 'Écologie', 'Environnement / Sciences de la vie — UNIKIN.', 4, 'L3'),
    _c('BIO312', 'Physiologie végétale', 'Sciences de la vie — UNIKIN.', 4, 'L3'),
    _c('BIO411', 'Projet de biologie', 'Master — UNIKIN.', 6, 'Master 1'),
]

# ---------------------------------------------------------------------------
# Sciences & Technologies — Géosciences (SGA 2024-2025)
# ---------------------------------------------------------------------------
GEO_COURSES = [
    _c('GEO111', 'Introduction aux sciences de la Terre', 'L1 Géosciences — UNIKIN.', 5, 'L1'),
    _c('GEO112', 'Géologie générale', 'L1 Géosciences — UNIKIN.', 6, 'L1'),
    _c('GEO113', 'Géologie et société', 'L1 Géosciences — UNIKIN.', 3, 'L1'),
    _c('GEO211', 'Sédimentologie', 'L2 Géosciences — UNIKIN.', 5, 'L2'),
    _c('GEO212', 'Pétrographie exogène', 'L2 Géosciences — UNIKIN.', 5, 'L2'),
    _c('GEO213', 'Géochimie générale', 'Géosciences — UNIKIN.', 4, 'L2'),
    _c('GEO214', 'Biologie du sol', 'Géosciences — UNIKIN.', 3, 'L2'),
    _c('GEO215', 'Géologie structurale', 'L2 Géosciences — UNIKIN SGA.', 4, 'L2'),
    _c('GEO216', 'Géologie historique', 'L2 Géosciences — UNIKIN SGA.', 4, 'L2'),
    _c('GEO311', 'Métallogénie', 'L3 Géologie — UNIKIN.', 5, 'L3'),
    _c('GEO312', 'Géologie du génie civil', 'L3 Géologie — UNIKIN.', 4, 'L3'),
    _c('GEO313', 'Gestion des bases de données', 'L3 Géomatique — UNIKIN.', 5, 'L3'),
    _c('GEO314', 'Mécanique des sols et géotechnique', 'L3 Géosciences — UNIKIN.', 4, 'L3'),
    _c('GEO315', 'Éthique et déontologie professionnelles', 'L3 Géosciences — UNIKIN.', 2, 'L3'),
    _c('GEO316', 'Prospection géologique', 'Géosciences — UNIKIN.', 4, 'L3'),
    _c('GEO317', 'Pédologie', 'Géosciences — UNIKIN.', 3, 'L3'),
    _c('GEO318', 'Géologie minière et pétrolière', 'L3 Géologie — UNIKIN SGA.', 4, 'L3'),
    _c('GEO319', 'Analyse spatiale', 'L3 Géomatique — UNIKIN SGA.', 4, 'L3'),
    _c('GEO411', 'Modélisation des réservoirs pétroliers', 'Ir / Master Géosciences — UNIKIN.', 5, 'Master 1'),
    _c('GEO412', 'Géologie et géochimie de l’environnement', 'Master Géosciences — UNIKIN SGA.', 4, 'Master 1'),
]
