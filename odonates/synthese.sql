-- Vue générique pour alimenter la synthèse dans le cadre d'un protocole site-visite-observation
-- 
-- Ce fichier peut être copié dans le dossier du sous-module et renommé en synthese.sql (et au besoin personnalisé)
-- le fichier sera joué à l'installation avec la valeur de module_code qui sera attribué automatiquement
--
--
-- Personalisations possibles
--
--  - ajouter des champs specifiques qui peuvent alimenter la synthese
--      jointure avec les table de complement
--
--  - choisir les valeurs de champs de nomenclatures qui seront propres au modules
-- ce fichier contient une variable :module_code (ou :'module_code')
-- utiliser psql avec l'option -v module_code=<module_code
-- ne pas remplacer cette variable, elle est indispensable pour les scripts d'installations
-- le module pouvant être installé avec un code différent de l'original
DROP VIEW IF EXISTS gn_monitoring.v_synthese_odonates;
CREATE OR REPLACE VIEW gn_monitoring.v_synthese_odonates AS WITH source AS (
    SELECT id_source
    FROM gn_synthese.t_sources
    WHERE name_source = CONCAT('MONITORING_', UPPER('odonates'))
  ), determiner AS (
    SELECT
        array_agg(r.id_role) AS id_determiner,
        CONCAT(r.nom_role, ' ', prenom_role) AS determiner,
        id_base_visit
    FROM gn_monitoring.t_base_visits tbv
    JOIN utilisateurs.t_roles r
    ON r.id_role = tbv.id_digitiser
    GROUP BY id_base_visit, r.nom_role, prenom_role
)
SELECT o.uuid_observation AS unique_id_sinp,
  v.uuid_base_visit AS unique_id_sinp_grp,
  (
    SELECT id_source
    FROM source
  ) AS id_source,
  o.id_observation AS entity_source_pk_value,
  v.id_dataset,
  nullif(
    json_extract_path(oc.data::json, 'id_nomenclature_stade')::text,
    'null'
  )::integer AS id_nomenclature_life_stage,
  nullif(
    json_extract_path(oc.data::json, 'id_nomenclature_sex')::text,
    'null'
  )::integer AS id_nomenclature_sex,
  nullif(
    json_extract_path(oc.data::json, 'id_nomenclature_etat_bio')::text,
    'null'
  )::integer AS id_nomenclature_bio_condition,
  nullif(
    json_extract_path(oc.data::json, 'id_nomenclature_behaviour')::text,
    'null'
  )::integer AS id_nomenclature_behaviour,
  nullif(
    ((oc.data::json#>'{count_min}'::text [])::text),
    'null'
  )::integer AS count_min,
  nullif(
    ((oc.data::json#>'{count_max}'::text [])::text),
    'null'
  )::integer AS count_max,
  o.id_observation,
  o.cd_nom,
  t.nom_complet AS nom_cite,
  alt.altitude_min,
  alt.altitude_max,
  s.geom AS the_geom_4326,
  st_centroid(s.geom) AS the_geom_point,
  s.geom_local AS the_geom_local,
  v.visit_date_min AS date_min,
  v.visit_date_max AS date_max,
  obs.observers,
  v.id_digitiser,
  det.determiner AS determiner,
  v.id_module as id_module,
  v.comments AS comment_context,
  o.comments AS comment_description,
  obs.ids_observers,
  v.id_base_site,
  v.id_base_visit,
  json_build_object(
    'nom_site',
    s.base_site_name,
    'owner_site',
    (sc.data::json#>'{owner}'::text []),
    'proprietepzh',
    (sc.data::json#>'{proprietepzh}'::text []),
    'id_nomenclature_type_site',
    ref_nomenclatures.get_nomenclature_label(
      nullif(s.id_nomenclature_type_site::text, 'null')::integer,
      'fr'
    ),
    'id_nomenclature_prospection',
    ref_nomenclatures.get_nomenclature_label(
      nullif(
        json_extract_path(sc.data::json, 'id_nomenclature_prospection')::text,
        'null'
      )::integer,
      'fr'
    ),
    'passage',
    (vc.data::json#>'{passage}'::text []),
    'periode',
    (vc.data::json#>'{periode}'::text []),
    'tempAir',
    json_extract_path(vc.data::json, 'tempAir')::text,
    'humidite',
    json_extract_path(vc.data::json, 'humidite')::text,
    'pluviosite',
    (vc.data::json#>'{pluviosite}'::text []),
    'couvertureNuageuse',
    (vc.data::json#>'{couvertureNuageuse}'::text []),
    'vent',
    (vc.data::json#>'{vent}'::text []),
    'pertubations',
    (vc.data::json#>'{pertubations}'::text []),
    'comment_visit',
    json_extract_path(vc.data::json, 'comment_visit')::text,
    'count_tranche',
    (oc.data::json#>'{count_tranche}'::text []),
    'count_exact',
    json_extract_path(oc.data::json, 'count_exact')::text,
    'count_average',
    json_extract_path(oc.data::json, 'count_average')::text,
    'comment_obs',
    json_extract_path(oc.data::json, 'comments')::text
  ) as additional_data
FROM gn_monitoring.t_base_visits v
  JOIN gn_monitoring.t_visit_complements vc on v.id_base_visit = vc.id_base_visit
  JOIN gn_monitoring.t_base_sites s ON s.id_base_site = v.id_base_site
  JOIN gn_monitoring.t_site_complements sc on sc.id_base_site = s.id_base_site
  JOIN gn_commons.t_modules m ON m.id_module = v.id_module
  JOIN gn_monitoring.t_observations o ON o.id_base_visit = v.id_base_visit
  JOIN determiner det ON det.id_base_visit = v.id_base_visit
  JOIN gn_monitoring.t_observation_complements oc ON oc.id_observation = o.id_observation
  JOIN taxonomie.taxref t ON t.cd_nom = o.cd_nom
  LEFT JOIN LATERAL (
    SELECT array_agg(r.id_role) AS ids_observers,
      string_agg(
        concat(r.nom_role, ' ', r.prenom_role),
        ' ; '::text
      ) AS observers
    FROM gn_monitoring.cor_visit_observer cvo
      JOIN utilisateurs.t_roles r ON r.id_role = cvo.id_role
    WHERE cvo.id_base_visit = v.id_base_visit
  ) obs ON true
  LEFT JOIN LATERAL ref_geo.fct_get_altitude_intersection(s.geom_local) alt(altitude_min, altitude_max) ON true
WHERE m.module_code = 'odonates';