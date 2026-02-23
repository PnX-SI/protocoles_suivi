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

-- gn_monitoring.v_synthese_chiro source



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
SELECT to2.uuid_observation AS unique_id_sinp,
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
    to2.comments AS comment_description,
    obs.ids_observers,
    v.id_base_site,
    v.id_base_visit,
    CASE WHEN m.field_target = 'id_nomenclature_behaviour' THEN m.id_nomenclature_coresp
         ELSE ref_nomenclatures.get_id_nomenclature('OCC_COMPORTEMENT', '0') -- default : inconnu
    END AS id_nomenclature_behaviour,
    ref_nomenclatures.get_id_nomenclature('ETA_BIO', ' 2')AS id_nomenclature_bio_condition, -- default: 2 = vivant
    CASE WHEN m.field_target = 'id_nomenclature_bio_status' THEN m.id_nomenclature_coresp
         ELSE ref_nomenclatures.get_id_nomenclature('STATUT_BIO', '0') -- inconnu
    END AS id_nomenclature_bio_status,
    CASE WHEN m.field_target = 'id_nomenclature_life_stage' THEN m.id_nomenclature_coresp
         ELSE ref_nomenclatures.get_id_nomenclature('STADE_VIE', '0') -- inconnu
    END AS id_nomenclature_life_stage,
    ref_nomenclatures.get_id_nomenclature('SEXE', '0') AS id_nomenclature_sex, -- sexe = inconnu
    ref_nomenclatures.get_id_nomenclature('METH_OBS', '0') AS id_nomenclature_obs_technique, --METH_OBS = vue
    COALESCE(m.count_min, 1 AS count_min,
    COALESCE(m.count_max, 1 AS count_max
   FROM gn_monitoring.t_base_visits v
     JOIN gn_monitoring.t_base_sites s ON s.id_base_site = v.id_base_site
     JOIN gn_commons.t_modules m_mod ON m_mod.id_module = v.id_module
     JOIN gn_monitoring.t_visit_complements vc ON vc.id_base_visit = v.id_base_visit
     JOIN taxonomie.taxref t ON t.cd_nom = to2.cd_nom
     JOIN observers obs ON obs.id_base_visit = v.id_base_visit
     LEFT JOIN gn_monitoring.t_nomenclature_mapping_aigle m ON m.id_nomenclature_aigle = (toc.data ->> 'id_nomenclature_behaviour_home_range'::text)::integer
     JOIN source ON true
  WHERE m_mod.module_code::text = 'aigle'::text
  ORDER BY unique_id_sinp;