DROP VIEW IF EXISTS gn_monitoring.v_synthese_apollons;
CREATE VIEW gn_monitoring.v_synthese_apollons AS

WITH source AS (
    SELECT
        id_source
    FROM gn_synthese.t_sources
    WHERE name_source = CONCAT('MONITORING_', UPPER('apollons'))
    LIMIT 1
), observers AS (
    SELECT
        array_agg(r.id_role) AS ids_observers,
        STRING_AGG(CONCAT(r.nom_role, ' ', prenom_role), ' ; ') AS observers,
        id_base_visit
    FROM gn_monitoring.cor_visit_observer cvo
    JOIN utilisateurs.t_roles r
    ON r.id_role = cvo.id_role
    GROUP BY id_base_visit
)
 SELECT v.uuid_base_visit AS unique_id_sinp,
    v.uuid_base_visit AS unique_id_sinp_grp,
    source.id_source,
    v.id_base_visit AS entity_source_pk_value,
    v.id_dataset,
    ref_nomenclatures.get_id_nomenclature('NAT_OBJ_GEO'::character varying, 'St'::character varying) AS id_nomenclature_geo_object_nature,
    v.id_nomenclature_grp_typ,
    v.id_nomenclature_tech_collect_campanule,
    ref_nomenclatures.get_id_nomenclature('OBJ_DENBR'::character varying, 'IND'::character varying) AS id_nomenclature_obj_count,
    ref_nomenclatures.get_id_nomenclature('TYP_DENBR'::character varying, 'Es'::character varying) AS id_nomenclature_type_count,
    ref_nomenclatures.get_id_nomenclature('STATUT_OBS'::character varying, 'Pr'::character varying) AS id_nomenclature_observation_status,
    ref_nomenclatures.get_id_nomenclature('STATUT_SOURCE'::character varying, 'Te'::character varying) AS id_nomenclature_source_status,
    ref_nomenclatures.get_id_nomenclature('TYP_INF_GEO'::character varying, '1'::character varying) AS id_nomenclature_info_geo_type,
    ref_nomenclatures.get_id_nomenclature('STADE_VIE'::character varying, '7'::character varying) AS id_nomenclature_life_stage,
    COALESCE((vc.DATA->>'count_stade_l1')::int, 0) +
    COALESCE((vc.DATA->>'count_stade_l2')::int, 0) +
    COALESCE((vc.DATA->>'count_stade_l3')::int, 0) +
    COALESCE((vc.DATA->>'count_stade_l4')::int, 0) +
    COALESCE((vc.DATA->>'count_stade_l5')::int, 0)  AS count_min,
    COALESCE((vc.DATA->>'count_stade_l1')::int, 0) +
    COALESCE((vc.DATA->>'count_stade_l2')::int, 0) +
    COALESCE((vc.DATA->>'count_stade_l3')::int, 0) +
    COALESCE((vc.DATA->>'count_stade_l4')::int, 0) +
    COALESCE((vc.DATA->>'count_stade_l5')::int, 0)  AS count_max,
    t.cd_nom,
    t.nom_complet AS nom_cite,
    alt.altitude_min,
    alt.altitude_max,
    s.geom AS the_geom_4326,
    st_centroid(s.geom) AS the_geom_point,
    s.geom_local AS the_geom_local,
    v.visit_date_min AS date_min,
    COALESCE(v.visit_date_max, v.visit_date_min) AS date_max,
    obs.observers,
    v.id_digitiser,
    v.id_module,
    v.comments AS comment_description,
    obs.ids_observers,
    s.base_site_name AS place_name,
    v.id_base_site,
    v.id_base_visit
   FROM gn_monitoring.t_base_visits v
     JOIN gn_monitoring.t_base_sites s ON s.id_base_site = v.id_base_site
     JOIN gn_commons.t_modules m ON m.id_module = v.id_module
     JOIN gn_monitoring.t_visit_complements vc ON vc.id_base_visit = v.id_base_visit
     --JOIN ref_nomenclatures.t_nomenclatures n ON n.id_nomenclature = ((vc.data ->> 'id_nomenclature_statut_obs'::text)::integer) AND n.cd_nomenclature::text = 'Pr'::text
     JOIN taxonomie.taxref t ON t.cd_nom = ((vc.data ->> 'cd_nom'::text)::integer)
     LEFT JOIN observers obs ON obs.id_base_visit = v.id_base_visit
     JOIN source ON true
     LEFT JOIN LATERAL ref_geo.fct_get_altitude_intersection(s.geom_local) alt(altitude_min, altitude_max) ON true
  WHERE m.module_code::text = 'apollons'::TEXT
    AND COALESCE((vc.DATA->>'count_stade_l1')::int, 0) +
    COALESCE((vc.DATA->>'count_stade_l2')::int, 0) +
    COALESCE((vc.DATA->>'count_stade_l3')::int, 0) +
    COALESCE((vc.DATA->>'count_stade_l4')::int, 0) +
    COALESCE((vc.DATA->>'count_stade_l5')::int, 0)  > 0
  ;