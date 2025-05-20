-- #############################
-- 	Création d'une vue 
--		permettant la remonté des données 
--		STERF dans la synthèse
-- #############################
DROP VIEW IF EXISTS gn_monitoring.v_synthese_sterf;

-- gn_monitoring.v_synthese_sterf 
CREATE OR REPLACE VIEW gn_monitoring.v_synthese_sterf
AS WITH source AS (SELECT t_sources.id_source
                FROM gn_synthese.t_sources
                WHERE t_sources.name_source::text = concat('MONITORING_', upper('sterf'::text))
                LIMIT 1)
SELECT o.uuid_observation                                                                                 AS unique_id_sinp,
       v.uuid_base_visit                                                                                  AS unique_id_sinp_grp,
       (SELECT source.id_source FROM source)                                                              AS id_source,
       o.id_observation                                                                                   AS entity_source_pk_value,
       v.id_dataset,
       ref_nomenclatures.get_id_nomenclature('METH_OBS'::character varying,
                                             '0'::character varying)                                      AS id_nomenclature_obs_meth,
       ref_nomenclatures.get_id_nomenclature('STADE_VIE'::character varying,
                                             '15'::character varying)                                     AS id_nomenclature_life_stage,
       ref_nomenclatures.get_id_nomenclature('SEXE'::character varying,
                                             '6'::character varying)                                      AS id_nomenclature_sex,
       ref_nomenclatures.get_id_nomenclature('OBJ_DENBR'::character varying,
                                             'IND'::character varying)                                    AS id_nomenclature_obj_count,
       ref_nomenclatures.get_id_nomenclature('TYP_DENBR'::character varying,
                                             'Co'::character varying)                                     AS id_nomenclature_type_count,
       ref_nomenclatures.get_id_nomenclature('STATUT_OBS'::character varying,
                                             'Pr'::character varying)                                     AS id_nomenclature_observation_status,
       ref_nomenclatures.get_id_nomenclature('STATUT_SOURCE'::character varying,
                                             'Te'::character varying)                                     AS id_nomenclature_source_status,
       ref_nomenclatures.get_id_nomenclature('TYP_INF_GEO'::character varying,
                                             '1'::character varying)                                      AS id_nomenclature_info_geo_type,
       ref_nomenclatures.get_id_nomenclature('ETA_BIO'::character varying,
                                             '2'::character varying)                                      AS id_nomenclature_bio_condition,
       NULLIF(oc.data::json ->> 'count_min'::text, 'null'::text)::integer                                 AS count_min,
       COALESCE(NULLIF(oc.data::json ->> 'count_max'::text, 'null'::text)::integer,
                NULLIF(oc.data::json ->> 'count_min'::text, 'null'::text)::integer)                       AS count_max,
       o.id_observation,
       o.cd_nom,
       t.nom_complet                                                                                      AS nom_cite,
       alt.altitude_min,
       alt.altitude_max,
       s.geom                                                                                             AS the_geom_4326,
       st_centroid(s.geom)                                                                                AS the_geom_point,
       s.geom_local                                                                                       AS the_geom_local,
       v.visit_date_min                                                                                   AS date_min,
       v.visit_date_max                                                                                   AS date_max,
       obs.observers,
       s.id_digitiser,
       coalesce(
               NULLIF( replace(oc.data::json #>> '{id_nomenclature_determination_method}'::text[], '"'::text, ''::text),
                       'null'::text)::text,
               gn_synthese.get_default_nomenclature_value('METH_DETERMIN'::CHARACTER VARYING)::text) ::int            AS id_nomenclature_determination_method, -- on récupère l'id par défaut en cas de null
       v.id_module,
       v.comments                                                                                         AS comment_context,
       o.comments                                                                                         AS comment_description,
       obs.ids_observers,
       v.id_base_site,
       v.id_base_visit,
       jsonb_build_object('nom_site', s.base_site_name, 'code_site', s.base_site_code, 'habitat_1',
                          NULLIF(replace((sc.data::json -> 'habitat_1'::text)::text, '"'::text, ''::text),
                                 'null'::text), 'habitat_2',
                          NULLIF(replace((sc.data::json -> 'habitat_2'::text)::text, '"'::text, ''::text),
                                 'null'::text), 'habitat_3',
                          NULLIF(replace((sc.data::json -> 'habitat_3'::text)::text, '"'::text, ''::text),
                                 'null'::text), 'habitat_4',
                          NULLIF(replace((sc.data::json -> 'habitat_4'::text)::text, '"'::text, ''::text),
                                 'null'::text), 'vent',
                          NULLIF(replace((vc.data::json -> 'vent'::text)::text, '"'::text, ''::text), 'null'::text),
                          'ennuagement',
                          NULLIF(replace((vc.data::json -> 'ennuagement'::text)::text, '"'::text, ''::text),
                                 'null'::text), 'temperature',
                          NULLIF(replace((vc.data::json -> 'temperature'::text)::text, '"'::text, ''::text),
                                 'null'::text), 'meteo_favorable',
                          NULLIF(replace((vc.data::json -> 'meteo_cond'::text)::text, '"'::text, ''::text),
                                 'null'::text), 'duree_transect',
                          NULLIF(replace((vc.data::json -> 'duration'::text)::text, '"'::text, ''::text), 'null'::text),
                          'heure_debut',
                          NULLIF(replace((vc.data::json -> 'start_time'::text)::text, '"'::text, ''::text),
                                 'null'::text))                                                           AS additional_data
FROM gn_monitoring.t_base_visits v
         JOIN gn_monitoring.t_visit_complements vc ON v.id_base_visit = vc.id_base_visit
         JOIN gn_monitoring.t_base_sites s ON s.id_base_site = v.id_base_site
         JOIN gn_monitoring.t_site_complements sc ON s.id_base_site = sc.id_base_site
         JOIN gn_commons.t_modules m ON m.id_module = v.id_module
         JOIN gn_monitoring.t_observations o ON o.id_base_visit = v.id_base_visit
         JOIN gn_monitoring.t_observation_complements oc ON oc.id_observation = o.id_observation
         JOIN taxonomie.taxref t ON t.cd_nom = o.cd_nom
         LEFT JOIN LATERAL ( SELECT array_agg(r.id_role)                                            AS ids_observers,
                                    string_agg(concat(r.nom_role, ' ', r.prenom_role), ' ; '::text) AS observers
                             FROM gn_monitoring.cor_visit_observer cvo
                                      JOIN utilisateurs.t_roles r ON r.id_role = cvo.id_role
                             WHERE cvo.id_base_visit = v.id_base_visit) obs ON true
         LEFT JOIN LATERAL ref_geo.fct_get_altitude_intersection(s.geom_local) alt(altitude_min, altitude_max) ON true
WHERE m.module_code::text = 'sterf'::text
  AND o.cd_nom IS NOT NULL
  AND o.uuid_observation IS NOT NULL; -- on viens peupler la synthèse seulement si on a une espèces saisies.
  
