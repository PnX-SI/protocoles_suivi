-- gn_monitoring.t_nomenclature_mapping_aigle

DROP TABLE IF EXISTS gn_monitoring.t_nomenclature_mapping_aigle CASCADE;

CREATE TABLE gn_monitoring.t_nomenclature_mapping_aigle (
  id_mapping SERIAL PRIMARY KEY,
  id_nomenclature_aigle INTEGER NOT NULL REFERENCES ref_nomenclatures.t_nomenclatures(id_nomenclature),
  id_type_nomenclature_aigle INTEGER NOT NULL REFERENCES ref_nomenclatures.bib_nomenclatures_types(id_type),
  id_nomenclature_coresp INTEGER NOT NULL REFERENCES ref_nomenclatures.t_nomenclatures(id_nomenclature),
  field_target VARCHAR(50),
  count_min INTEGER,
  count_max INTEGER
);

-- INSERT data mapping for AIGLE_COMPORTEMENT_DOMAINE_VITAL
-- 2_JEUNES_SEULS -> juvenile life_stage, count_min=2
INSERT INTO gn_monitoring.t_nomenclature_mapping_aigle
  (id_nomenclature_aigle, id_type_nomenclature_aigle, id_nomenclature_coresp, field_target, count_min)
SELECT
  n.id_nomenclature,
  nt.id_type,
  (SELECT id_nomenclature FROM ref_nomenclatures.t_nomenclatures WHERE mnemonique = 'Juvénile' AND id_type = (SELECT id_type FROM ref_nomenclatures.bib_nomenclatures_types WHERE mnemonique = 'STADE_VIE')),
  'id_nomenclature_life_stage',
  2
FROM ref_nomenclatures.t_nomenclatures n
JOIN ref_nomenclatures.bib_nomenclatures_types nt ON n.id_type = nt.id_type
WHERE n.cd_nomenclature = '2_JEUNES_SEULS' AND nt.mnemonique = 'AIGLE_COMPORTEMENT_DOMAINE_VITAL';

-- 1_JEUNE_SEUL -> juvenile life_stage, count_min=1
INSERT INTO gn_monitoring.t_nomenclature_mapping_aigle
  (id_nomenclature_aigle, id_type_nomenclature_aigle, id_nomenclature_coresp, field_target, count_min)
SELECT
  n.id_nomenclature,
  nt.id_type,
  (SELECT id_nomenclature FROM ref_nomenclatures.t_nomenclatures WHERE mnemonique = 'Juvénile' AND id_type = (SELECT id_type FROM ref_nomenclatures.bib_nomenclatures_types WHERE mnemonique = 'STADE_VIE')),
  'id_nomenclature_life_stage',
  1
FROM ref_nomenclatures.t_nomenclatures n
JOIN ref_nomenclatures.bib_nomenclatures_types nt ON n.id_type = nt.id_type
WHERE n.cd_nomenclature = '1_JEUNE_SEUL' AND nt.mnemonique = 'AIGLE_COMPORTEMENT_DOMAINE_VITAL';

-- 1_JEUNE_AVEC_LES_ADULTES -> Line 1: juvenile, count_min=1
INSERT INTO gn_monitoring.t_nomenclature_mapping_aigle
  (id_nomenclature_aigle, id_type_nomenclature_aigle, id_nomenclature_coresp, field_target, count_min)
SELECT
  n.id_nomenclature,
  nt.id_type,
  (SELECT id_nomenclature FROM ref_nomenclatures.t_nomenclatures WHERE mnemonique = 'Juvénile' AND id_type = (SELECT id_type FROM ref_nomenclatures.bib_nomenclatures_types WHERE mnemonique = 'STADE_VIE')),
  'id_nomenclature_life_stage',
  1
FROM ref_nomenclatures.t_nomenclatures n
JOIN ref_nomenclatures.bib_nomenclatures_types nt ON n.id_type = nt.id_type
WHERE n.cd_nomenclature = '1_JEUNE_AVEC_LES_ADULTES' AND nt.mnemonique = 'AIGLE_COMPORTEMENT_DOMAINE_VITAL';

-- 1_JEUNE_AVEC_LES_ADULTES -> Line 2: adulte, count_min=2
INSERT INTO gn_monitoring.t_nomenclature_mapping_aigle
  (id_nomenclature_aigle, id_type_nomenclature_aigle, id_nomenclature_coresp, field_target, count_min)
SELECT
  n.id_nomenclature,
  nt.id_type,
  (SELECT id_nomenclature FROM ref_nomenclatures.t_nomenclatures WHERE mnemonique = 'Adulte' AND id_type = (SELECT id_type FROM ref_nomenclatures.bib_nomenclatures_types WHERE mnemonique = 'STADE_VIE')),
  'id_nomenclature_life_stage',
  2
FROM ref_nomenclatures.t_nomenclatures n
JOIN ref_nomenclatures.bib_nomenclatures_types nt ON n.id_type = nt.id_type
WHERE n.cd_nomenclature = '1_JEUNE_AVEC_LES_ADULTES' AND nt.mnemonique = 'AIGLE_COMPORTEMENT_DOMAINE_VITAL';

-- 2_JEUNES_AVEC_LES_ADULTES -> Line 1: juvenile, count_min=2
INSERT INTO gn_monitoring.t_nomenclature_mapping_aigle
  (id_nomenclature_aigle, id_type_nomenclature_aigle, id_nomenclature_coresp, field_target, count_min)
SELECT
  n.id_nomenclature,
  nt.id_type,
  (SELECT id_nomenclature FROM ref_nomenclatures.t_nomenclatures WHERE mnemonique = 'Juvénile' AND id_type = (SELECT id_type FROM ref_nomenclatures.bib_nomenclatures_types WHERE mnemonique = 'STADE_VIE')),
  'id_nomenclature_life_stage',
  2
FROM ref_nomenclatures.t_nomenclatures n
JOIN ref_nomenclatures.bib_nomenclatures_types nt ON n.id_type = nt.id_type
WHERE n.cd_nomenclature = '2_JEUNES_AVEC_LES_ADULTES' AND nt.mnemonique = 'AIGLE_COMPORTEMENT_DOMAINE_VITAL';

-- 2_JEUNES_AVEC_LES_ADULTES -> Line 2: adulte, count_min=1
INSERT INTO gn_monitoring.t_nomenclature_mapping_aigle
  (id_nomenclature_aigle, id_type_nomenclature_aigle, id_nomenclature_coresp, field_target, count_min)
SELECT
  n.id_nomenclature,
  nt.id_type,
  (SELECT id_nomenclature FROM ref_nomenclatures.t_nomenclatures WHERE mnemonique = 'Adulte' AND id_type = (SELECT id_type FROM ref_nomenclatures.bib_nomenclatures_types WHERE mnemonique = 'STADE_VIE')),
  'id_nomenclature_life_stage',
  1
FROM ref_nomenclatures.t_nomenclatures n
JOIN ref_nomenclatures.bib_nomenclatures_types nt ON n.id_type = nt.id_type
WHERE n.cd_nomenclature = '2_JEUNES_AVEC_LES_ADULTES' AND nt.mnemonique = 'AIGLE_COMPORTEMENT_DOMAINE_VITAL';

-- ACCOUPLEMENT -> bio_status = reproduction
INSERT INTO gn_monitoring.t_nomenclature_mapping_aigle
  (id_nomenclature_aigle, id_type_nomenclature_aigle, id_nomenclature_coresp, field_target)
SELECT
  n.id_nomenclature,
  nt.id_type,
  (SELECT id_nomenclature FROM ref_nomenclatures.t_nomenclatures WHERE mnemonique ILIKE '%repro%' AND id_type = (SELECT id_type FROM ref_nomenclatures.bib_nomenclatures_types WHERE mnemonique = 'STATUT_BIO') LIMIT 1),
  'id_nomenclature_bio_status'
FROM ref_nomenclatures.t_nomenclatures n
JOIN ref_nomenclatures.bib_nomenclatures_types nt ON n.id_type = nt.id_type
WHERE n.cd_nomenclature = 'ACCOUPLEMENT' AND nt.mnemonique = 'AIGLE_COMPORTEMENT_DOMAINE_VITAL';

-- TRANSPORT_DE_PROIE -> behaviour = nourrissage des jeunes
INSERT INTO gn_monitoring.t_nomenclature_mapping_aigle
  (id_nomenclature_aigle, id_type_nomenclature_aigle, id_nomenclature_coresp, field_target)
SELECT
  n.id_nomenclature,
  nt.id_type,
  (SELECT id_nomenclature FROM ref_nomenclatures.t_nomenclatures WHERE label_default ILIKE '%nourrissage%jeunes%' AND id_type = (SELECT id_type FROM ref_nomenclatures.bib_nomenclatures_types WHERE mnemonique = 'OCC_COMPORTEMENT') LIMIT 1),
  'id_nomenclature_behaviour'
FROM ref_nomenclatures.t_nomenclatures n
JOIN ref_nomenclatures.bib_nomenclatures_types nt ON n.id_type = nt.id_type
WHERE n.cd_nomenclature = 'TRANSPORT_DE_PROIE' AND nt.mnemonique = 'AIGLE_COMPORTEMENT_DOMAINE_VITAL';

-- AIGLE_STATUT_REPRODUCTION mappings

-- REPRODUCTION_EN_COURS -> bio_status = Reproduction
INSERT INTO gn_monitoring.t_nomenclature_mapping_aigle
  (id_nomenclature_aigle, id_type_nomenclature_aigle, id_nomenclature_coresp, field_target)
SELECT
  n.id_nomenclature,
  nt.id_type,
  (SELECT id_nomenclature FROM ref_nomenclatures.t_nomenclatures WHERE mnemonique = 'Reproduction' AND id_type = (SELECT id_type FROM ref_nomenclatures.bib_nomenclatures_types WHERE mnemonique = 'STATUT_BIO') LIMIT 1),
  'id_nomenclature_bio_status'
FROM ref_nomenclatures.t_nomenclatures n
JOIN ref_nomenclatures.bib_nomenclatures_types nt ON n.id_type = nt.id_type
WHERE n.cd_nomenclature = 'REPRODUCTION_EN_COURS' AND nt.mnemonique = 'AIGLE_STATUT_REPRODUCTION';

-- 1_JEUNE_ENVOLÉ -> bio_status = Reproduction (succès)
INSERT INTO gn_monitoring.t_nomenclature_mapping_aigle
  (id_nomenclature_aigle, id_type_nomenclature_aigle, id_nomenclature_coresp, field_target)
SELECT
  n.id_nomenclature,
  nt.id_type,
  (SELECT id_nomenclature FROM ref_nomenclatures.t_nomenclatures WHERE mnemonique = 'Reproduction' AND id_type = (SELECT id_type FROM ref_nomenclatures.bib_nomenclatures_types WHERE mnemonique = 'STATUT_BIO') LIMIT 1),
  'id_nomenclature_bio_status'
FROM ref_nomenclatures.t_nomenclatures n
JOIN ref_nomenclatures.bib_nomenclatures_types nt ON n.id_type = nt.id_type
WHERE n.cd_nomenclature = '1_JEUNE_ENVOLÉ' AND nt.mnemonique = 'AIGLE_STATUT_REPRODUCTION';

-- 2_JEUNES_ENVOLÉS -> bio_status = Reproduction (succès)
INSERT INTO gn_monitoring.t_nomenclature_mapping_aigle
  (id_nomenclature_aigle, id_type_nomenclature_aigle, id_nomenclature_coresp, field_target)
SELECT
  n.id_nomenclature,
  nt.id_type,
  (SELECT id_nomenclature FROM ref_nomenclatures.t_nomenclatures WHERE mnemonique = 'Reproduction' AND id_type = (SELECT id_type FROM ref_nomenclatures.bib_nomenclatures_types WHERE mnemonique = 'STATUT_BIO') LIMIT 1),
  'id_nomenclature_bio_status'
FROM ref_nomenclatures.t_nomenclatures n
JOIN ref_nomenclatures.bib_nomenclatures_types nt ON n.id_type = nt.id_type
WHERE n.cd_nomenclature = '2_JEUNES_ENVOLÉS' AND nt.mnemonique = 'AIGLE_STATUT_REPRODUCTION';

-- ÉCHEC -> bio_status = Pas de reproduction
INSERT INTO gn_monitoring.t_nomenclature_mapping_aigle
  (id_nomenclature_aigle, id_type_nomenclature_aigle, id_nomenclature_coresp, field_target)
SELECT
  n.id_nomenclature,
  nt.id_type,
  (SELECT id_nomenclature FROM ref_nomenclatures.t_nomenclatures WHERE mnemonique = 'Pas de reproduction' AND id_type = (SELECT id_type FROM ref_nomenclatures.bib_nomenclatures_types WHERE mnemonique = 'STATUT_BIO') LIMIT 1),
  'id_nomenclature_bio_status'
FROM ref_nomenclatures.t_nomenclatures n
JOIN ref_nomenclatures.bib_nomenclatures_types nt ON n.id_type = nt.id_type
WHERE n.cd_nomenclature = 'ÉCHEC' AND nt.mnemonique = 'AIGLE_STATUT_REPRODUCTION';

-- PAS_DE_REPRODUCTION_CONSTATÉE -> bio_status = Pas de reproduction
INSERT INTO gn_monitoring.t_nomenclature_mapping_aigle
  (id_nomenclature_aigle, id_type_nomenclature_aigle, id_nomenclature_coresp, field_target)
SELECT
  n.id_nomenclature,
  nt.id_type,
  (SELECT id_nomenclature FROM ref_nomenclatures.t_nomenclatures WHERE mnemonique = 'Pas de reproduction' AND id_type = (SELECT id_type FROM ref_nomenclatures.bib_nomenclatures_types WHERE mnemonique = 'STATUT_BIO') LIMIT 1),
  'id_nomenclature_bio_status'
FROM ref_nomenclatures.t_nomenclatures n
JOIN ref_nomenclatures.bib_nomenclatures_types nt ON n.id_type = nt.id_type
WHERE n.cd_nomenclature = 'PAS_DE_REPRODUCTION_CONSTATÉE' AND nt.mnemonique = 'AIGLE_STATUT_REPRODUCTION';

-- PAS_DE_CONCLUSION_POSSIBLE -> bio_status = Non Déterminé
INSERT INTO gn_monitoring.t_nomenclature_mapping_aigle
  (id_nomenclature_aigle, id_type_nomenclature_aigle, id_nomenclature_coresp, field_target)
SELECT
  n.id_nomenclature,
  nt.id_type,
  (SELECT id_nomenclature FROM ref_nomenclatures.t_nomenclatures WHERE mnemonique = 'Non Déterminé' AND id_type = (SELECT id_type FROM ref_nomenclatures.bib_nomenclatures_types WHERE mnemonique = 'STATUT_BIO') LIMIT 1),
  'id_nomenclature_bio_status'
FROM ref_nomenclatures.t_nomenclatures n
JOIN ref_nomenclatures.bib_nomenclatures_types nt ON n.id_type = nt.id_type
WHERE n.cd_nomenclature = 'PAS_DE_CONCLUSION_POSSIBLE' AND nt.mnemonique = 'AIGLE_STATUT_REPRODUCTION';

-- NON_SUIVI -> pas de mapping (données insuffisantes)

-- AIGLE_ACTIVITE_AIRE mappings

-- 1_ADULTE_SUR_L'AIRE -> life_stage = adulte, count_min = 1
INSERT INTO gn_monitoring.t_nomenclature_mapping_aigle
  (id_nomenclature_aigle, id_type_nomenclature_aigle, id_nomenclature_coresp, field_target, count_min)
SELECT
  n.id_nomenclature,
  nt.id_type,
  (SELECT id_nomenclature FROM ref_nomenclatures.t_nomenclatures WHERE mnemonique = 'Adulte' AND id_type = (SELECT id_type FROM ref_nomenclatures.bib_nomenclatures_types WHERE mnemonique = 'STADE_VIE')),
  'id_nomenclature_life_stage',
  1
FROM ref_nomenclatures.t_nomenclatures n
JOIN ref_nomenclatures.bib_nomenclatures_types nt ON n.id_type = nt.id_type
WHERE n.cd_nomenclature = '1_ADULTE_SUR_L''AIRE' AND nt.mnemonique = 'AIGLE_ACTIVITE_AIRE';

-- 2_ADULTES_SUR_L'AIRE -> life_stage = adulte, count_min = 2
INSERT INTO gn_monitoring.t_nomenclature_mapping_aigle
  (id_nomenclature_aigle, id_type_nomenclature_aigle, id_nomenclature_coresp, field_target, count_min)
SELECT
  n.id_nomenclature,
  nt.id_type,
  (SELECT id_nomenclature FROM ref_nomenclatures.t_nomenclatures WHERE mnemonique = 'Adulte' AND id_type = (SELECT id_type FROM ref_nomenclatures.bib_nomenclatures_types WHERE mnemonique = 'STADE_VIE')),
  'id_nomenclature_life_stage',
  2
FROM ref_nomenclatures.t_nomenclatures n
JOIN ref_nomenclatures.bib_nomenclatures_types nt ON n.id_type = nt.id_type
WHERE n.cd_nomenclature = '2_ADULTES_SUR_L''AIRE' AND nt.mnemonique = 'AIGLE_ACTIVITE_AIRE';

-- ACCOUPLEMENT_SUR_L'AIRE -> life_stage = adulte, count_min = 2 (Line 1)
INSERT INTO gn_monitoring.t_nomenclature_mapping_aigle
  (id_nomenclature_aigle, id_type_nomenclature_aigle, id_nomenclature_coresp, field_target, count_min)
SELECT
  n.id_nomenclature,
  nt.id_type,
  (SELECT id_nomenclature FROM ref_nomenclatures.t_nomenclatures WHERE mnemonique = 'Adulte' AND id_type = (SELECT id_type FROM ref_nomenclatures.bib_nomenclatures_types WHERE mnemonique = 'STADE_VIE')),
  'id_nomenclature_life_stage',
  2
FROM ref_nomenclatures.t_nomenclatures n
JOIN ref_nomenclatures.bib_nomenclatures_types nt ON n.id_type = nt.id_type
WHERE n.cd_nomenclature = 'ACCOUPLEMENT_SUR_L''AIRE' AND nt.mnemonique = 'AIGLE_ACTIVITE_AIRE';

-- ACCOUPLEMENT_SUR_L'AIRE -> bio_status = Reproduction (Line 2)
INSERT INTO gn_monitoring.t_nomenclature_mapping_aigle
  (id_nomenclature_aigle, id_type_nomenclature_aigle, id_nomenclature_coresp, field_target, count_min)
SELECT
  n.id_nomenclature,
  nt.id_type,
  (SELECT id_nomenclature FROM ref_nomenclatures.t_nomenclatures WHERE mnemonique = 'Reproduction' AND id_type = (SELECT id_type FROM ref_nomenclatures.bib_nomenclatures_types WHERE mnemonique = 'STATUT_BIO')),
  'id_nomenclature_bio_status',
  2
FROM ref_nomenclatures.t_nomenclatures n
JOIN ref_nomenclatures.bib_nomenclatures_types nt ON n.id_type = nt.id_type
WHERE n.cd_nomenclature = 'ACCOUPLEMENT_SUR_L''AIRE' AND nt.mnemonique = 'AIGLE_ACTIVITE_AIRE';

-- 1_JEUNE_BLANC_VU -> life_stage = jeune, count_min = 1
INSERT INTO gn_monitoring.t_nomenclature_mapping_aigle
  (id_nomenclature_aigle, id_type_nomenclature_aigle, id_nomenclature_coresp, field_target, count_min)
SELECT
  n.id_nomenclature,
  nt.id_type,
  (SELECT id_nomenclature FROM ref_nomenclatures.t_nomenclatures WHERE mnemonique = 'Juvénile' AND id_type = (SELECT id_type FROM ref_nomenclatures.bib_nomenclatures_types WHERE mnemonique = 'STADE_VIE')),
  'id_nomenclature_life_stage',
  1
FROM ref_nomenclatures.t_nomenclatures n
JOIN ref_nomenclatures.bib_nomenclatures_types nt ON n.id_type = nt.id_type
WHERE n.cd_nomenclature = '1_JEUNE_BLANC_VU' AND nt.mnemonique = 'AIGLE_ACTIVITE_AIRE';

-- 1_JEUNES_NOIR_VU -> life_stage = jeune, count_min = 1
INSERT INTO gn_monitoring.t_nomenclature_mapping_aigle
  (id_nomenclature_aigle, id_type_nomenclature_aigle, id_nomenclature_coresp, field_target, count_min)
SELECT
  n.id_nomenclature,
  nt.id_type,
  (SELECT id_nomenclature FROM ref_nomenclatures.t_nomenclatures WHERE mnemonique = 'Juvénile' AND id_type = (SELECT id_type FROM ref_nomenclatures.bib_nomenclatures_types WHERE mnemonique = 'STADE_VIE')),
  'id_nomenclature_life_stage',
  1
FROM ref_nomenclatures.t_nomenclatures n
JOIN ref_nomenclatures.bib_nomenclatures_types nt ON n.id_type = nt.id_type
WHERE n.cd_nomenclature = '1_JEUNES_NOIR_VU' AND nt.mnemonique = 'AIGLE_ACTIVITE_AIRE';

-- 2_JEUNES_BLANCS_VUS -> life_stage = jeune, count_min = 2
INSERT INTO gn_monitoring.t_nomenclature_mapping_aigle
  (id_nomenclature_aigle, id_type_nomenclature_aigle, id_nomenclature_coresp, field_target, count_min)
SELECT
  n.id_nomenclature,
  nt.id_type,
  (SELECT id_nomenclature FROM ref_nomenclatures.t_nomenclatures WHERE mnemonique = 'Juvénile' AND id_type = (SELECT id_type FROM ref_nomenclatures.bib_nomenclatures_types WHERE mnemonique = 'STADE_VIE')),
  'id_nomenclature_life_stage',
  2
FROM ref_nomenclatures.t_nomenclatures n
JOIN ref_nomenclatures.bib_nomenclatures_types nt ON n.id_type = nt.id_type
WHERE n.cd_nomenclature = '2_JEUNES_BLANCS_VUS' AND nt.mnemonique = 'AIGLE_ACTIVITE_AIRE';

-- 2_JEUNES_NOIRS_VUS -> life_stage = jeune, count_min = 2
INSERT INTO gn_monitoring.t_nomenclature_mapping_aigle
  (id_nomenclature_aigle, id_type_nomenclature_aigle, id_nomenclature_coresp, field_target, count_min)
SELECT
  n.id_nomenclature,
  nt.id_type,
  (SELECT id_nomenclature FROM ref_nomenclatures.t_nomenclatures WHERE mnemonique = 'Juvénile' AND id_type = (SELECT id_type FROM ref_nomenclatures.bib_nomenclatures_types WHERE mnemonique = 'STADE_VIE')),
  'id_nomenclature_life_stage',
  2
FROM ref_nomenclatures.t_nomenclatures n
JOIN ref_nomenclatures.bib_nomenclatures_types nt ON n.id_type = nt.id_type
WHERE n.cd_nomenclature = '2_JEUNES_NOIRS_VUS' AND nt.mnemonique = 'AIGLE_ACTIVITE_AIRE';

-- 1_JEUNE_ENVOLÉ -> life_stage = jeune, count_min = 1 (Line 1)
INSERT INTO gn_monitoring.t_nomenclature_mapping_aigle
  (id_nomenclature_aigle, id_type_nomenclature_aigle, id_nomenclature_coresp, field_target, count_min)
SELECT
  n.id_nomenclature,
  nt.id_type,
  (SELECT id_nomenclature FROM ref_nomenclatures.t_nomenclatures WHERE mnemonique = 'Juvénile' AND id_type = (SELECT id_type FROM ref_nomenclatures.bib_nomenclatures_types WHERE mnemonique = 'STADE_VIE')),
  'id_nomenclature_life_stage',
  1
FROM ref_nomenclatures.t_nomenclatures n
JOIN ref_nomenclatures.bib_nomenclatures_types nt ON n.id_type = nt.id_type
WHERE n.cd_nomenclature = '1_JEUNE_ENVOLÉ' AND nt.mnemonique = 'AIGLE_ACTIVITE_AIRE';

-- 1_JEUNE_ENVOLÉ -> bio_status = Reproduction (Line 2)
INSERT INTO gn_monitoring.t_nomenclature_mapping_aigle
  (id_nomenclature_aigle, id_type_nomenclature_aigle, id_nomenclature_coresp, field_target, count_min)
SELECT
  n.id_nomenclature,
  nt.id_type,
  (SELECT id_nomenclature FROM ref_nomenclatures.t_nomenclatures WHERE mnemonique = 'Reproduction' AND id_type = (SELECT id_type FROM ref_nomenclatures.bib_nomenclatures_types WHERE mnemonique = 'STATUT_BIO')),
  'id_nomenclature_bio_status',
  1
FROM ref_nomenclatures.t_nomenclatures n
JOIN ref_nomenclatures.bib_nomenclatures_types nt ON n.id_type = nt.id_type
WHERE n.cd_nomenclature = '1_JEUNE_ENVOLÉ' AND nt.mnemonique = 'AIGLE_ACTIVITE_AIRE';

-- 2_JEUNES_ENVOLÉS -> life_stage = jeune, count_min = 2 (Line 1)
INSERT INTO gn_monitoring.t_nomenclature_mapping_aigle
  (id_nomenclature_aigle, id_type_nomenclature_aigle, id_nomenclature_coresp, field_target, count_min)
SELECT
  n.id_nomenclature,
  nt.id_type,
  (SELECT id_nomenclature FROM ref_nomenclatures.t_nomenclatures WHERE mnemonique = 'Juvénile' AND id_type = (SELECT id_type FROM ref_nomenclatures.bib_nomenclatures_types WHERE mnemonique = 'STADE_VIE')),
  'id_nomenclature_life_stage',
  2
FROM ref_nomenclatures.t_nomenclatures n
JOIN ref_nomenclatures.bib_nomenclatures_types nt ON n.id_type = nt.id_type
WHERE n.cd_nomenclature = '2_JEUNES_ENVOLÉS' AND nt.mnemonique = 'AIGLE_ACTIVITE_AIRE';

-- 2_JEUNES_ENVOLÉS -> bio_status = Reproduction (Line 2)
INSERT INTO gn_monitoring.t_nomenclature_mapping_aigle
  (id_nomenclature_aigle, id_type_nomenclature_aigle, id_nomenclature_coresp, field_target, count_min)
SELECT
  n.id_nomenclature,
  nt.id_type,
  (SELECT id_nomenclature FROM ref_nomenclatures.t_nomenclatures WHERE mnemonique = 'Reproduction' AND id_type = (SELECT id_type FROM ref_nomenclatures.bib_nomenclatures_types WHERE mnemonique = 'STATUT_BIO')),
  'id_nomenclature_bio_status',
  2
FROM ref_nomenclatures.t_nomenclatures n
JOIN ref_nomenclatures.bib_nomenclatures_types nt ON n.id_type = nt.id_type
WHERE n.cd_nomenclature = '2_JEUNES_ENVOLÉS' AND nt.mnemonique = 'AIGLE_ACTIVITE_AIRE';

-- COUVAISON -> life_stage = adulte, count_min = 1 (Line 1)
INSERT INTO gn_monitoring.t_nomenclature_mapping_aigle
  (id_nomenclature_aigle, id_type_nomenclature_aigle, id_nomenclature_coresp, field_target, count_min)
SELECT
  n.id_nomenclature,
  nt.id_type,
  (SELECT id_nomenclature FROM ref_nomenclatures.t_nomenclatures WHERE mnemonique = 'Adulte' AND id_type = (SELECT id_type FROM ref_nomenclatures.bib_nomenclatures_types WHERE mnemonique = 'STADE_VIE')),
  'id_nomenclature_life_stage',
  1
FROM ref_nomenclatures.t_nomenclatures n
JOIN ref_nomenclatures.bib_nomenclatures_types nt ON n.id_type = nt.id_type
WHERE n.cd_nomenclature = 'COUVAISON' AND nt.mnemonique = 'AIGLE_ACTIVITE_AIRE';

-- COUVAISON -> bio_status = Reproduction (Line 2)
INSERT INTO gn_monitoring.t_nomenclature_mapping_aigle
  (id_nomenclature_aigle, id_type_nomenclature_aigle, id_nomenclature_coresp, field_target, count_min)
SELECT
  n.id_nomenclature,
  nt.id_type,
  (SELECT id_nomenclature FROM ref_nomenclatures.t_nomenclatures WHERE mnemonique = 'Reproduction' AND id_type = (SELECT id_type FROM ref_nomenclatures.bib_nomenclatures_types WHERE mnemonique = 'STATUT_BIO')),
  'id_nomenclature_bio_status',
  1
FROM ref_nomenclatures.t_nomenclatures n
JOIN ref_nomenclatures.bib_nomenclatures_types nt ON n.id_type = nt.id_type
WHERE n.cd_nomenclature = 'COUVAISON' AND nt.mnemonique = 'AIGLE_ACTIVITE_AIRE';

-- NOURRISSAGE -> life_stage = jeune, count_min = 1 (default, no specific count)
INSERT INTO gn_monitoring.t_nomenclature_mapping_aigle
  (id_nomenclature_aigle, id_type_nomenclature_aigle, id_nomenclature_coresp, field_target, count_min)
SELECT
  n.id_nomenclature,
  nt.id_type,
  (SELECT id_nomenclature FROM ref_nomenclatures.t_nomenclatures WHERE mnemonique = 'Juvénile' AND id_type = (SELECT id_type FROM ref_nomenclatures.bib_nomenclatures_types WHERE mnemonique = 'STADE_VIE')),
  'id_nomenclature_life_stage',
  1
FROM ref_nomenclatures.t_nomenclatures n
JOIN ref_nomenclatures.bib_nomenclatures_types nt ON n.id_type = nt.id_type
WHERE n.cd_nomenclature = 'NOURRISSAGE' AND nt.mnemonique = 'AIGLE_ACTIVITE_AIRE';

-- APPORT_DE_PROIE_SUR_L'AIRE -> life_stage = jeune, count_min = 1 (default, no specific count)
INSERT INTO gn_monitoring.t_nomenclature_mapping_aigle
  (id_nomenclature_aigle, id_type_nomenclature_aigle, id_nomenclature_coresp, field_target, count_min)
SELECT
  n.id_nomenclature,
  nt.id_type,
  (SELECT id_nomenclature FROM ref_nomenclatures.t_nomenclatures WHERE mnemonique = 'Juvénile' AND id_type = (SELECT id_type FROM ref_nomenclatures.bib_nomenclatures_types WHERE mnemonique = 'STADE_VIE')),
  'id_nomenclature_life_stage',
  1
FROM ref_nomenclatures.t_nomenclatures n
JOIN ref_nomenclatures.bib_nomenclatures_types nt ON n.id_type = nt.id_type
WHERE n.cd_nomenclature = 'APPORT_DE_PROIE_SUR_L''AIRE' AND nt.mnemonique = 'AIGLE_ACTIVITE_AIRE';

-- RELÈVE_À_L'AIRE -> life_stage = adulte
INSERT INTO gn_monitoring.t_nomenclature_mapping_aigle
  (id_nomenclature_aigle, id_type_nomenclature_aigle, id_nomenclature_coresp, field_target)
SELECT
  n.id_nomenclature,
  nt.id_type,
  (SELECT id_nomenclature FROM ref_nomenclatures.t_nomenclatures WHERE mnemonique = 'Adulte' AND id_type = (SELECT id_type FROM ref_nomenclatures.bib_nomenclatures_types WHERE mnemonique = 'STADE_VIE')),
  'id_nomenclature_life_stage'
FROM ref_nomenclatures.t_nomenclatures n
JOIN ref_nomenclatures.bib_nomenclatures_types nt ON n.id_type = nt.id_type
WHERE n.cd_nomenclature = 'RELÈVE_À_L''AIRE' AND nt.mnemonique = 'AIGLE_ACTIVITE_AIRE';

-- DÉPOT_DE_BRANCHE -> life_stage = adulte
INSERT INTO gn_monitoring.t_nomenclature_mapping_aigle
  (id_nomenclature_aigle, id_type_nomenclature_aigle, id_nomenclature_coresp, field_target)
SELECT
  n.id_nomenclature,
  nt.id_type,
  (SELECT id_nomenclature FROM ref_nomenclatures.t_nomenclatures WHERE mnemonique = 'Adulte' AND id_type = (SELECT id_type FROM ref_nomenclatures.bib_nomenclatures_types WHERE mnemonique = 'STADE_VIE')),
  'id_nomenclature_life_stage'
FROM ref_nomenclatures.t_nomenclatures n
JOIN ref_nomenclatures.bib_nomenclatures_types nt ON n.id_type = nt.id_type
WHERE n.cd_nomenclature = 'DÉPOT_DE_BRANCHE' AND nt.mnemonique = 'AIGLE_ACTIVITE_AIRE';

-- ŒUF(S)_ABANDONNÉ(S) -> bio_status = Pas de reproduction
INSERT INTO gn_monitoring.t_nomenclature_mapping_aigle
  (id_nomenclature_aigle, id_type_nomenclature_aigle, id_nomenclature_coresp, field_target)
SELECT
  n.id_nomenclature,
  nt.id_type,
  (SELECT id_nomenclature FROM ref_nomenclatures.t_nomenclatures WHERE mnemonique = 'Pas de reproduction' AND id_type = (SELECT id_type FROM ref_nomenclatures.bib_nomenclatures_types WHERE mnemonique = 'STATUT_BIO')),
  'id_nomenclature_bio_status'
FROM ref_nomenclatures.t_nomenclatures n
JOIN ref_nomenclatures.bib_nomenclatures_types nt ON n.id_type = nt.id_type
WHERE n.cd_nomenclature = 'ŒUF(S)_ABANDONNÉ(S)' AND nt.mnemonique = 'AIGLE_ACTIVITE_AIRE';

-- JEUNE(S)_MORT(S) -> bio_status = Pas de reproduction
INSERT INTO gn_monitoring.t_nomenclature_mapping_aigle
  (id_nomenclature_aigle, id_type_nomenclature_aigle, id_nomenclature_coresp, field_target)
SELECT
  n.id_nomenclature,
  nt.id_type,
  (SELECT id_nomenclature FROM ref_nomenclatures.t_nomenclatures WHERE mnemonique = 'Pas de reproduction' AND id_type = (SELECT id_type FROM ref_nomenclatures.bib_nomenclatures_types WHERE mnemonique = 'STATUT_BIO')),
  'id_nomenclature_bio_status'
FROM ref_nomenclatures.t_nomenclatures n
JOIN ref_nomenclatures.bib_nomenclatures_types nt ON n.id_type = nt.id_type
WHERE n.cd_nomenclature = 'JEUNE(S)_MORT(S)' AND nt.mnemonique = 'AIGLE_ACTIVITE_AIRE';


-- gn_monitoring.v_synthese_aigle source (Simplified version)

CREATE OR REPLACE VIEW gn_monitoring.v_synthese_aigle
AS WITH source AS (
         SELECT t_sources.id_source
           FROM gn_synthese.t_sources
          WHERE t_sources.name_source::text = 'MONITORING_AIGLE'::text
         LIMIT 1
        ), observers AS (
         SELECT
                CASE
                    WHEN array_agg(r.id_role) IS NULL THEN v_1.data ->> 'observers_txt'::text
                    ELSE string_agg(concat(r.nom_role, ' ', r.prenom_role), ' ; '::text)
                END AS observers,
            array_remove(array_agg(r.id_role), NULL::integer) AS ids_observers,
            v_1.id_base_visit
           FROM gn_monitoring.t_visit_complements v_1
             LEFT JOIN gn_monitoring.cor_visit_observer cvo ON cvo.id_base_visit = v_1.id_base_visit
             LEFT JOIN utilisateurs.t_roles r ON r.id_role = cvo.id_role
          GROUP BY v_1.id_base_visit
        )
-- gn_monitoring.v_synthese_aigle_mapping_consolidated
-- Intermediate view that consolidates all mappings from a single visit
-- Takes multi-select JSON fields and returns one line with consolidated nomenclatures

CREATE OR REPLACE VIEW gn_monitoring.v_synthese_aigle_mapping_consolidated AS
WITH behaviour_unnest AS (
  -- Unnest id_nomenclature_behaviour_home_range array
  SELECT
    vc.id_base_visit,
    (jsonb_array_elements(COALESCE(vc.data->'id_nomenclature_behaviour_home_range', '[]'::jsonb))::text)::integer AS id_nomenclature
  FROM gn_monitoring.t_visit_complements vc
  WHERE vc.id_module = (SELECT id_module FROM gn_commons.t_modules WHERE module_code = 'aigle')
),
aire_unnest AS (
  -- Unnest id_nomenclature_aire_activity array
  SELECT
    vc.id_base_visit,
    (jsonb_array_elements(COALESCE(vc.data->'id_nomenclature_aire_activity', '[]'::jsonb))::text)::integer AS id_nomenclature
  FROM gn_monitoring.t_visit_complements vc
  WHERE vc.id_module = (SELECT id_module FROM gn_commons.t_modules WHERE module_code = 'aigle')
),
all_mappings AS (
  -- Collect all mappings from all sources (behaviour, status, aire)
  SELECT
    vc.id_base_visit,
    COALESCE(
      m_behaviour.id_nomenclature_coresp,
      m_status.id_nomenclature_coresp,
      m_aire.id_nomenclature_coresp
    ) AS id_nomenclature_coresp,
    COALESCE(
      m_behaviour.field_target,
      m_status.field_target,
      m_aire.field_target
    ) AS field_target,
    COALESCE(
      m_behaviour.count_min,
      m_status.count_min,
      m_aire.count_min
    ) AS count_min,
    COALESCE(
      m_behaviour.count_max,
      m_status.count_max,
      m_aire.count_max
    ) AS count_max
  FROM gn_monitoring.t_visit_complements vc
  LEFT JOIN behaviour_unnest bu ON bu.id_base_visit = vc.id_base_visit
  LEFT JOIN gn_monitoring.t_nomenclature_mapping_aigle m_behaviour ON m_behaviour.id_nomenclature_aigle = bu.id_nomenclature
  LEFT JOIN aire_unnest au ON au.id_base_visit = vc.id_base_visit
  LEFT JOIN gn_monitoring.t_nomenclature_mapping_aigle m_aire ON m_aire.id_nomenclature_aigle = au.id_nomenclature
  LEFT JOIN gn_monitoring.t_nomenclature_mapping_aigle m_status ON m_status.id_nomenclature_aigle = ((vc.data ->> 'id_nomenclature_statut_reproduction'::text)::integer) AND m_status.field_target IS NOT NULL
  WHERE vc.id_module = (SELECT id_module FROM gn_commons.t_modules WHERE module_code = 'aigle')
    AND (bu.id_nomenclature IS NOT NULL OR au.id_nomenclature IS NOT NULL OR (vc.data ->> 'id_nomenclature_statut_reproduction'::text) IS NOT NULL)
)
SELECT
  vc.id_base_visit,
  COALESCE((SELECT count_min FROM all_mappings WHERE id_base_visit = vc.id_base_visit AND field_target = 'id_nomenclature_life_stage'), 1) AS count_min,
  COALESCE((SELECT count_max FROM all_mappings WHERE id_base_visit = vc.id_base_visit AND field_target = 'id_nomenclature_life_stage'), 1) AS count_max,
  (SELECT id_nomenclature_coresp FROM all_mappings WHERE id_base_visit = vc.id_base_visit AND field_target = 'id_nomenclature_life_stage' LIMIT 1) AS id_nomenclature_life_stage,
  (SELECT id_nomenclature_coresp FROM all_mappings WHERE id_base_visit = vc.id_base_visit AND field_target = 'id_nomenclature_bio_status' LIMIT 1) AS id_nomenclature_bio_status,
  (SELECT id_nomenclature_coresp FROM all_mappings WHERE id_base_visit = vc.id_base_visit AND field_target = 'id_nomenclature_behaviour' LIMIT 1) AS id_nomenclature_behaviour
FROM gn_monitoring.t_visit_complements vc
WHERE vc.id_module = (SELECT id_module FROM gn_commons.t_modules WHERE module_code = 'aigle')
GROUP BY vc.id_base_visit;


-- gn_monitoring.v_synthese_aigle source

CREATE OR REPLACE VIEW gn_monitoring.v_synthese_aigle
AS WITH source AS (
         SELECT t_sources.id_source
           FROM gn_synthese.t_sources
          WHERE t_sources.name_source::text = 'MONITORING_AIGLE'::text
         LIMIT 1
        ), observers AS (
         SELECT
                CASE
                    WHEN array_agg(r.id_role) IS NULL THEN vc_1.data ->> 'observers_txt'::text
                    ELSE string_agg(concat(r.nom_role, ' ', r.prenom_role), ' ; '::text)
                END AS observers,
            array_remove(array_agg(r.id_role), NULL::integer) AS ids_observers,
            vc_1.id_base_visit
           FROM gn_monitoring.t_visit_complements vc_1
             LEFT JOIN gn_monitoring.cor_visit_observer cvo ON cvo.id_base_visit = vc_1.id_base_visit
             LEFT JOIN utilisateurs.t_roles r ON r.id_role = cvo.id_role
          GROUP BY vc_1.id_base_visit
        )
SELECT
    uuid_in(md5(concat_ws(':', v.id_base_visit, v.cd_nom))::cstring)::text AS unique_id_sinp,
    v.uuid_base_visit AS unique_id_sinp_grp,
    source.id_source,
    v.id_base_visit AS entity_source_pk_value,
    v.id_dataset,
    ref_nomenclatures.get_id_nomenclature('NAT_OBJ_GEO'::character varying, 'St'::character varying) AS id_nomenclature_geo_object_nature,
    v.id_nomenclature_tech_collect_campanule,
    ref_nomenclatures.get_id_nomenclature('OBJ_DENBR'::character varying, 'IND'::character varying) AS id_nomenclature_obj_count,
    ref_nomenclatures.get_id_nomenclature('TYP_DENBR'::character varying, 'Co'::character varying) AS id_nomenclature_type_count,
    ref_nomenclatures.get_id_nomenclature('STATUT_SOURCE'::character varying, 'Te'::character varying) AS id_nomenclature_source_status,
    ref_nomenclatures.get_id_nomenclature('TYP_INF_GEO'::character varying, '1'::character varying) AS id_nomenclature_info_geo_type,
    ref_nomenclatures.get_id_nomenclature('NIV_PRECIS'::character varying, '4'::character varying) AS id_nomenclature_diffusion_level,
    ref_nomenclatures.get_id_nomenclature('NATURALITE'::character varying, '1'::character varying) AS id_nomenclature_naturalness,
    ref_nomenclatures.get_id_nomenclature('TYP_GRP'::character varying, 'REL'::character varying) AS id_nomenclature_grp_typ,
    t.cd_nom,
    t.nom_complet AS nom_cite,
    s.altitude_min,
    s.altitude_max,
    s.geom AS the_geom_4326,
    st_centroid(s.geom) AS the_geom_point,
    s.geom_local AS the_geom_local,
    v.visit_date_min AS date_min,
    COALESCE(v.visit_date_max, v.visit_date_min) AS date_max,
    obs.observers,
    v.id_digitiser,
    v.id_module,
    v.comments AS comment_context,
    vc.data ->> 'comments'::text AS comment_description,
    obs.ids_observers,
    v.id_base_site,
    v.id_base_visit,
    COALESCE(am.id_nomenclature_behaviour, ref_nomenclatures.get_id_nomenclature('OCC_COMPORTEMENT', '0')) AS id_nomenclature_behaviour,
    ref_nomenclatures.get_id_nomenclature('ETA_BIO', ' 2') AS id_nomenclature_bio_condition,
    COALESCE(am.id_nomenclature_bio_status, ref_nomenclatures.get_id_nomenclature('STATUT_BIO', '0')) AS id_nomenclature_bio_status,
    COALESCE(am.id_nomenclature_life_stage, ref_nomenclatures.get_id_nomenclature('STADE_VIE', '0')) AS id_nomenclature_life_stage,
    ref_nomenclatures.get_id_nomenclature('SEXE', '0') AS id_nomenclature_sex,
    ref_nomenclatures.get_id_nomenclature('METH_OBS', '0') AS id_nomenclature_obs_technique,
    COALESCE(am.count_min, 1) AS count_min,
    COALESCE(am.count_max, 1) AS count_max
   FROM gn_monitoring.t_base_visits v
     JOIN gn_monitoring.t_base_sites s ON s.id_base_site = v.id_base_site
     JOIN gn_commons.t_modules m_mod ON m_mod.id_module = v.id_module
     JOIN gn_monitoring.t_visit_complements vc ON vc.id_base_visit = v.id_base_visit
     JOIN taxonomie.taxref t ON t.cd_nom = (vc.data ->> 'cd_nom'::text)::integer
     JOIN observers obs ON obs.id_base_visit = v.id_base_visit
     LEFT JOIN gn_monitoring.v_synthese_aigle_mapping_consolidated am ON am.id_base_visit = v.id_base_visit
     JOIN source ON true
  WHERE m_mod.module_code::text = 'aigle'::text
  ORDER BY unique_id_sinp;