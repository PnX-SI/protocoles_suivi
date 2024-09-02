CREATE OR REPLACE VIEW gn_monitoring.v_synthese_ligne_lecture
AS WITH source AS (
         SELECT t_sources.id_source
           FROM gn_synthese.t_sources
          WHERE t_sources.name_source::text = 'MONITORING_LIGNE_LECTURE'::text
         LIMIT 1
        ), observers AS (
         SELECT string_agg(concat(r.nom_role, ' ', r.prenom_role), ' ; '::text) AS observers,
            array_agg(r.id_role) AS ids_observers,
            v_1.id_base_visit
           FROM gn_monitoring.t_visit_complements v_1
             JOIN gn_monitoring.cor_visit_observer cvo ON cvo.id_base_visit = v_1.id_base_visit
             JOIN utilisateurs.t_roles r ON r.id_role = cvo.id_role
          GROUP BY v_1.id_base_visit
        )
 SELECT to2.id_observation,
    to2.uuid_observation AS unique_id_sinp,
    v.uuid_base_visit AS unique_id_sinp_grp,
    source.id_source,
    v.id_base_visit AS entity_source_pk_value,
    v.id_dataset,
    ref_nomenclatures.get_id_nomenclature('NAT_OBJ_GEO'::character varying, 'St'::character varying) AS id_nomenclature_geo_object_nature,
    v.id_nomenclature_tech_collect_campanule,
    ref_nomenclatures.get_id_nomenclature('ETA_BIO'::character varying, '2'::character varying) AS id_nomenclature_bio_condition,
    ref_nomenclatures.get_id_nomenclature('STAT_BIOGEO'::character varying, '1'::character varying) AS id_nomenclature_biogeo_status,
    ref_nomenclatures.get_id_nomenclature('OBJ_DENBR'::character varying, 'NSP'::character varying) AS id_nomenclature_obj_count,
    ref_nomenclatures.get_id_nomenclature('TYP_DENBR'::character varying, 'NSP'::character varying) AS id_nomenclature_type_count,
    ref_nomenclatures.get_id_nomenclature('STATUT_SOURCE'::character varying, 'Te'::character varying) AS id_nomenclature_source_status,
    ref_nomenclatures.get_id_nomenclature('TYP_INF_GEO'::character varying, '1'::character varying) AS id_nomenclature_info_geo_type,
    ref_nomenclatures.get_id_nomenclature('NATURALITE'::character varying, '1'::character varying) AS id_nomenclature_naturalness,
    ref_nomenclatures.get_id_nomenclature('STADE_VIE'::character varying, '0'::character varying) AS id_nomenclature_life_stage,
    ref_nomenclatures.get_id_nomenclature('TYP_GRP'::character varying, 'REL'::character varying) AS id_nomenclature_grp_typ,
    ref_nomenclatures.get_id_nomenclature('METH_OBS'::character varying, '0'::character varying) AS id_nomenclature_obs_technique, --vu
    t.cd_nom,
    t.nom_complet AS nom_cite,
    alt.altitude_min,
    alt.altitude_max,
    st_centroid(s.geom) AS the_geom_4326,
    st_centroid(s.geom) AS the_geom_point,
    st_centroid(s.geom_local) AS the_geom_local,
    v.visit_date_min AS date_min,
    COALESCE(v.visit_date_max, v.visit_date_min) AS date_max,
    obs.observers,
    v.id_digitiser,
    v.id_module,
    v.comments AS comment_description,
    obs.ids_observers,
    v.id_base_site,
    v.id_base_visit
   FROM gn_monitoring.t_base_visits v
     JOIN gn_monitoring.t_base_sites s ON s.id_base_site = v.id_base_site
     JOIN gn_commons.t_modules m ON m.id_module = v.id_module
     JOIN gn_monitoring.t_visit_complements vc ON vc.id_base_visit = v.id_base_visit
     JOIN gn_monitoring.t_observations to2 ON to2.id_base_visit = vc.id_base_visit
     JOIN gn_monitoring.t_observation_complements toc ON toc.id_observation = to2.id_observation
     JOIN taxonomie.taxref t ON t.cd_nom = to2.cd_nom
     LEFT JOIN observers obs ON obs.id_base_visit = v.id_base_visit
     JOIN source ON true
     LEFT JOIN LATERAL ref_geo.fct_get_altitude_intersection(s.geom_local) alt(altitude_min, altitude_max) ON true
  WHERE upper(m.module_code::text) = 'LIGNE_LECTURE'::text;
  