-- Création de vue pour certaine visualisation des données personnalisés

DROP VIEW IF EXISTS gn_monitoring.v_qgis_nichoirs;
CREATE OR REPLACE VIEW gn_monitoring.v_qgis_nichoirs
AS WITH t_source AS (
         SELECT t_sources.id_source
           FROM gn_synthese.t_sources
          WHERE t_sources.name_source::text = concat('MONITORING_', upper('NICHOIRS'::text))
        ), observers AS (
         SELECT array_agg(r.id_role) AS ids_observers,
            string_agg(concat(r.nom_role, ' ', r.prenom_role), ' ; '::text) AS observers,
            cvo.id_base_visit
           FROM gn_monitoring.cor_visit_observer cvo
             JOIN utilisateurs.t_roles r ON r.id_role = cvo.id_role
          GROUP BY cvo.id_base_visit
        )
 SELECT tbs.uuid_base_site AS unique_id_sinp_grp,
    tbs.base_site_name,
    tbs.base_site_description,
    tsc.data #>> '{nichoir_type}'::text[] AS nichoir_type,
    tsc.data #>> '{pose_localisation}'::text[] AS pose_localisation,
    tsc.data #>> '{nichoir_referent}'::text[] AS nichoir_referent,
    tsc.data #>> '{localite_precision}'::text[] AS localite_precision,
    tvc.data #>> '{etat_nichoir}'::text[] AS etat_nichoir,
    tvc.data #>> '{nidification}'::text[] AS nidification,
    tbs.geom_local AS the_geom_local,
    tbv.visit_date_min AS date_min,
    COALESCE(tbv.visit_date_max, tbv.visit_date_min) AS date_max,
    concat(tr.nom_role, ' ', tr.prenom_role) AS observers,
    tbv.comments AS comment_context,
    count(DISTINCT toc.id_observation) AS nb_observation,
    max(
        CASE
            WHEN (toc.data #>> '{adulte}'::text[]) ~~* ''::text OR (toc.data #>> '{adulte}'::text[]) IS NULL THEN 0
            ELSE (toc.data #>> '{adulte}'::text[])::integer
        END) AS max_adulte,
    max(
        CASE
            WHEN (toc.data #>> '{oeuf}'::text[]) ~~* ''::text OR (toc.data #>> '{oeuf}'::text[]) IS NULL THEN 0
            ELSE (toc.data #>> '{oeuf}'::text[])::integer
        END) AS max_oeuf,
    max(
        CASE
            WHEN (toc.data #>> '{jeune_vivant}'::text[]) ~~* ''::text OR (toc.data #>> '{jeune_vivant}'::text[]) IS NULL THEN 0
            ELSE (toc.data #>> '{jeune_vivant}'::text[])::integer
        END) AS max_jeune_vivant,
    max(
        CASE
            WHEN (toc.data #>> '{jeune_mort}'::text[]) ~~* ''::text OR (toc.data #>> '{jeune_mort}'::text[]) IS NULL THEN 0
            ELSE (toc.data #>> '{jeune_mort}'::text[])::integer
        END) AS max_jeune_mort
   FROM gn_monitoring.t_base_sites tbs
     LEFT JOIN gn_monitoring.t_site_complements tsc ON tsc.id_base_site = tbs.id_base_site
     LEFT JOIN gn_monitoring.t_base_visits tbv ON tbs.id_base_site = tbv.id_base_site
     LEFT JOIN gn_monitoring.t_visit_complements tvc ON tbv.id_base_visit = tvc.id_base_visit
     LEFT JOIN observers obs ON obs.id_base_visit = tbv.id_base_visit
     LEFT JOIN gn_monitoring.t_observations to2 ON to2.id_base_visit = tbv.id_base_visit
     LEFT JOIN gn_monitoring.t_observation_complements toc ON toc.id_observation = to2.id_observation
     LEFT JOIN utilisateurs.t_roles tr ON tr.id_role = obs.ids_observers[1]
     LEFT JOIN taxonomie.taxref t ON to2.cd_nom = t.cd_nom
     LEFT JOIN t_source ON true
     LEFT JOIN LATERAL ref_geo.fct_get_altitude_intersection(tbs.geom_local) alt(altitude_min, altitude_max) ON true
     LEFT JOIN gn_commons.t_modules tm ON tm.id_module = tsc.id_module
  WHERE tm.module_label::text ~~* 'Nichoirs'::text
  GROUP BY tbs.uuid_base_site, tbs.base_site_name, tbs.base_site_description, (tsc.data #>> '{nichoir_type}'::text[]), (tsc.data #>> '{pose_localisation}'::text[]), (tsc.data #>> '{nichoir_referent}'::text[]), (tsc.data #>> '{localite_precision}'::text[]), (tvc.data #>> '{etat_nichoir}'::text[]), (tvc.data #>> '{nidification}'::text[]), tbs.geom_local, tbv.visit_date_min, (COALESCE(tbv.visit_date_max, tbv.visit_date_min)), (concat(tr.nom_role, ' ', tr.prenom_role)), tbv.comments;

DROP VIEW IF EXISTS gn_monitoring.v_qgis_nichoirs_obs;  
CREATE OR REPLACE VIEW gn_monitoring.v_qgis_nichoirs_obs
AS WITH t_source AS (
         SELECT t_sources.id_source
           FROM gn_synthese.t_sources
          WHERE t_sources.name_source::text = concat('MONITORING_', upper('NICHOIRS'::text))
        ), observers AS (
         SELECT array_agg(r.id_role) AS ids_observers,
            string_agg(concat(r.nom_role, ' ', r.prenom_role), ' ; '::text) AS observers,
            cvo.id_base_visit
           FROM gn_monitoring.cor_visit_observer cvo
             JOIN utilisateurs.t_roles r ON r.id_role = cvo.id_role
          GROUP BY cvo.id_base_visit
        )
 SELECT to2.uuid_observation AS unique_id_sinp,
    tbs.uuid_base_site AS unique_id_sinp_grp,
    tsc.id_module,
    to2.id_observation AS entity_source_pk_value,
        CASE
            WHEN (toc.data #>> '{adulte}'::text[]) ~~* ''::text OR (toc.data #>> '{adulte}'::text[]) IS NULL THEN 0
            ELSE (toc.data #>> '{adulte}'::text[])::integer
        END +
        CASE
            WHEN (toc.data #>> '{oeuf}'::text[]) ~~* ''::text OR (toc.data #>> '{oeuf}'::text[]) IS NULL THEN 0
            ELSE (toc.data #>> '{oeuf}'::text[])::integer
        END +
        CASE
            WHEN (toc.data #>> '{jeune_vivant}'::text[]) ~~* ''::text OR (toc.data #>> '{jeune_vivant}'::text[]) IS NULL THEN 0
            ELSE (toc.data #>> '{jeune_vivant}'::text[])::integer
        END +
        CASE
            WHEN (toc.data #>> '{jeune_mort}'::text[]) ~~* ''::text OR (toc.data #>> '{jeune_mort}'::text[]) IS NULL THEN 0
            ELSE (toc.data #>> '{jeune_mort}'::text[])::integer
        END AS count_min,
        CASE
            WHEN (toc.data #>> '{adulte}'::text[]) ~~* ''::text OR (toc.data #>> '{adulte}'::text[]) IS NULL THEN 0
            ELSE (toc.data #>> '{adulte}'::text[])::integer
        END +
        CASE
            WHEN (toc.data #>> '{oeuf}'::text[]) ~~* ''::text OR (toc.data #>> '{oeuf}'::text[]) IS NULL THEN 0
            ELSE (toc.data #>> '{oeuf}'::text[])::integer
        END +
        CASE
            WHEN (toc.data #>> '{jeune_vivant}'::text[]) ~~* ''::text OR (toc.data #>> '{jeune_vivant}'::text[]) IS NULL THEN 0
            ELSE (toc.data #>> '{jeune_vivant}'::text[])::integer
        END +
        CASE
            WHEN (toc.data #>> '{jeune_mort}'::text[]) ~~* ''::text OR (toc.data #>> '{jeune_mort}'::text[]) IS NULL THEN 0
            ELSE (toc.data #>> '{jeune_mort}'::text[])::integer
        END AS count_max,
    to2.cd_nom,
    t.nom_complet AS nom_cite,
    alt.altitude_min,
    alt.altitude_max,
    tbs.geom_local AS the_geom_local,
    tbv.visit_date_min AS date_min,
    COALESCE(tbv.visit_date_max, tbv.visit_date_min) AS date_max,
    concat(tr.nom_role, ' ', tr.prenom_role) AS observers,
    tbv.comments AS comment_context,
    to2.comments AS comment_description
   FROM gn_monitoring.t_base_sites tbs
     LEFT JOIN gn_monitoring.t_site_complements tsc ON tsc.id_base_site = tbs.id_base_site
     LEFT JOIN gn_monitoring.t_base_visits tbv ON tbs.id_base_site = tbv.id_base_site
     LEFT JOIN observers obs ON obs.id_base_visit = tbv.id_base_visit
     LEFT JOIN gn_monitoring.t_observations to2 ON to2.id_base_visit = tbv.id_base_visit
     LEFT JOIN gn_monitoring.t_observation_complements toc ON toc.id_observation = to2.id_observation
     LEFT JOIN utilisateurs.t_roles tr ON tr.id_role = obs.ids_observers[1]
     LEFT JOIN taxonomie.taxref t ON to2.cd_nom = t.cd_nom
     LEFT JOIN t_source ON true
     LEFT JOIN LATERAL ref_geo.fct_get_altitude_intersection(tbs.geom_local) alt(altitude_min, altitude_max) ON true
     LEFT JOIN gn_commons.t_modules tm ON tm.id_module = tsc.id_module
  WHERE tm.module_label::text ~~* 'Nichoirs'::text AND to2.cd_nom IS NOT NULL AND to2.uuid_observation IS NOT NULL;
