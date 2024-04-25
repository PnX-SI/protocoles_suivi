-- TODO
CREATE
OR REPLACE VIEW gn_monitoring.v_synthese_ecrevisses_pattes_blanches AS WITH source AS (
  SELECT
    id_source
  FROM
    gn_synthese.t_sources
  WHERE
    name_source = CONCAT(
      'MONITORING_',
      UPPER('ECREVISSES_PATTES_BLANCHES')
    )
  LIMIT
    1
)
SELECT
  to2.uuid_observation AS unique_id_sinp,
  v.uuid_base_visit AS unique_id_sinp_grp,
  source.id_source,
  v.id_base_visit AS entity_source_pk_value,
  v.id_dataset,
  ref_nomenclatures.get_id_nomenclature(
    'NAT_OBJ_GEO' :: character varying,
    'St' :: character varying
  ) AS id_nomenclature_geo_object_nature,
  v.id_nomenclature_tech_collect_campanule,
  ref_nomenclatures.get_id_nomenclature(
    'OBJ_DENBR' :: character varying,
    'IND' :: character varying
  ) AS id_nomenclature_obj_count,
  ref_nomenclatures.get_id_nomenclature(
    'TYP_DENBR' :: character varying,
    'Co' :: character varying
  ) AS id_nomenclature_type_count,
  ref_nomenclatures.get_id_nomenclature(
    'STATUT_SOURCE' :: character varying,
    'Te' :: character varying
  ) AS id_nomenclature_source_status,
  ref_nomenclatures.get_id_nomenclature(
    'TYP_INF_GEO' :: character varying,
    '1' :: character varying
  ) AS id_nomenclature_info_geo_type,
  ref_nomenclatures.get_id_nomenclature('TYP_GRP', 'REL') as id_nomenclature_grp_typ,
  t.cd_nom,
  t.nom_complet AS nom_cite,
  alt.altitude_min,
  alt.altitude_max,
  s.geom AS the_geom_4326,
  st_centroid(s.geom) AS the_geom_point,
  s.geom_local AS the_geom_local,
  v.visit_date_min AS date_min,
  COALESCE(v.visit_date_max, v.visit_date_min) AS date_max,
  vc.data ->> 'participants_nom' AS observers,
  v.id_digitiser,
  v.id_module,
  v.comments AS comment_description,
  v.id_base_site,
  v.id_base_visit,
  to2.id_observation,
  tn.id_nomenclature as id_nomenclature_observation_status,
  1 AS count_min,
  1 AS count_max
FROM
  gn_monitoring.t_base_visits v
  JOIN gn_monitoring.t_base_sites s ON s.id_base_site = v.id_base_site
  JOIN gn_commons.t_modules m ON m.id_module = v.id_module
  JOIN gn_monitoring.t_visit_complements vc ON vc.id_base_visit = v.id_base_visit
  JOIN gn_monitoring.t_observations to2 ON to2.id_base_visit = vc.id_base_visit
  JOIN gn_monitoring.t_observation_complements toc ON toc.id_observation = to2.id_observation
  JOIN taxonomie.taxref t ON t.cd_nom = to2.cd_nom
  JOIN source ON true
  LEFT JOIN ref_nomenclatures.t_nomenclatures tn ON (
    (
      toc.data ->> 'id_nomenclature_statut_observation' :: text
    ) :: integer
  ) = tn.id_nomenclature
  LEFT JOIN LATERAL ref_geo.fct_get_altitude_intersection(s.geom_local) alt(altitude_min, altitude_max) ON true
WHERE
  m.module_code :: text = 'ecrevisses_pattes_blanches' :: TEXT
  AND tn.cd_nomenclature = 'Pr';