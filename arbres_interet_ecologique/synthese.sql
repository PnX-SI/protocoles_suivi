CREATE OR REPLACE VIEW gn_monitoring.v_synthese_arbres_interet_ecologique
AS WITH source AS (
         SELECT t_sources.id_source
           FROM gn_synthese.t_sources
          WHERE t_sources.name_source::text = concat('MONITORING_', upper('arbres_interet_ecologique'::text))
         LIMIT 1
        ), observers AS (
         SELECT array_agg(r.id_role) AS ids_observers,
            string_agg(concat(r.nom_role, ' ', r.prenom_role), ' ; '::text) AS observers,
            cvo.id_base_visit
           FROM gn_monitoring.cor_visit_observer cvo
             JOIN utilisateurs.t_roles r ON r.id_role = cvo.id_role
          GROUP BY cvo.id_base_visit
        ), selected_type_site AS (
         SELECT cst.id_base_site,
            string_agg(DISTINCT tn.label_default::text, ', '::text) AS type
           FROM gn_monitoring.bib_type_site ts
             JOIN ref_nomenclatures.t_nomenclatures tn ON tn.id_nomenclature = ts.id_nomenclature_type_site
             JOIN gn_monitoring.cor_site_type cst ON cst.id_type_site = ts.id_nomenclature_type_site
          WHERE tn.cd_nomenclature::text = ANY (ARRAY['ARBRES_AIE'::character varying::text, 'ARBRES_LOGES'::character varying::text, 'ARBRES_CHIRO'::character varying::text])
          GROUP BY cst.id_base_site
        ), dataset AS (
         SELECT t_datasets.id_dataset
           FROM gn_meta.t_datasets
          WHERE t_datasets.dataset_shortname::text = 'Arbres d''interet écologique'::text
         LIMIT 1
        ), id_module AS (
         SELECT t_modules.id_module
           FROM gn_commons.t_modules
          WHERE t_modules.module_code::text = 'arbres_interet_ecologique'::text
        )
 SELECT o.uuid_observation AS unique_id_sinp,
    v.uuid_base_visit AS unique_id_sinp_grp,
    source.id_source,
    o.id_observation AS entity_source_pk_value,
    v.id_dataset,
    ref_nomenclatures.get_id_nomenclature('NAT_OBJ_GEO'::character varying, 'St'::character varying) AS id_nomenclature_geo_object_nature,
    v.id_nomenclature_grp_typ,
    ref_nomenclatures.get_id_nomenclature('OBJ_DENBR'::character varying, 'IND'::character varying) AS id_nomenclature_obj_count,
    ref_nomenclatures.get_id_nomenclature('TYP_DENBR'::character varying, 'Es'::character varying) AS id_nomenclature_type_count,
    ref_nomenclatures.get_id_nomenclature('STATUT_OBS'::character varying, 'Pr'::character varying) AS id_nomenclature_observation_status,
    ref_nomenclatures.get_id_nomenclature('STATUT_SOURCE'::character varying, 'Te'::character varying) AS id_nomenclature_source_status,
    ref_nomenclatures.get_id_nomenclature('TYP_INF_GEO'::character varying, '1'::character varying) AS id_nomenclature_info_geo_type,
    COALESCE((toc.data ->> 'count_min'::text)::integer, 1) AS count_min,
    COALESCE((toc.data ->> 'count_min'::text)::integer, 1) AS count_max,
    (toc.data ->> 'id_nomenclature_sex'::text)::integer AS id_nomenclature_sex,
    (toc.data ->> 'id_nomenclature_behaviour'::text)::integer AS id_nomenclature_behaviour,
    (toc.data ->> 'id_nomenclature_bio_status'::text)::integer AS id_nomenclature_bio_status,
    COALESCE((toc.data ->> 'id_nomenclature_life_stage'::text)::integer, ref_nomenclatures.get_id_nomenclature('STADE_VIE'::character varying, '1'::character varying)) AS id_nomenclature_life_stage,
    COALESCE((toc.data ->> 'id_nomenclature_bio_condition'::text)::integer, ref_nomenclatures.get_id_nomenclature('ETA_BIO'::character varying, '1'::character varying)) AS id_nomenclature_bio_condition,
    COALESCE((toc.data ->> 'id_nomenclature_obs_technique'::text)::integer, ref_nomenclatures.get_id_nomenclature('METH_OBS'::character varying, '0'::character varying)) AS id_nomenclature_obs_technique,
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
    o.comments AS comment_description,
    obs.ids_observers,
    s.base_site_name AS place_name,
    NULL::jsonb AS additional_data,
    v.id_base_site,
    v.id_base_visit,
    toc.id_observation
   FROM gn_monitoring.t_base_visits v
     JOIN gn_monitoring.t_base_sites s ON s.id_base_site = v.id_base_site
     JOIN gn_monitoring.t_observations o ON o.id_base_visit = v.id_base_visit
     JOIN gn_monitoring.t_observation_complements toc ON o.id_observation = toc.id_observation
     JOIN gn_commons.t_modules m ON m.id_module = v.id_module
     JOIN gn_monitoring.t_visit_complements vc ON vc.id_base_visit = v.id_base_visit
     JOIN taxonomie.taxref t ON t.cd_nom = o.cd_nom
     JOIN observers obs ON obs.id_base_visit = v.id_base_visit
     JOIN source ON true
  WHERE m.module_code::text = 'arbres_interet_ecologique'::text
UNION
 SELECT s.uuid_base_site AS unique_id_sinp,
    NULL::uuid AS unique_id_sinp_grp,
    source.id_source,
    s.id_base_site AS entity_source_pk_value,
    ( SELECT dataset.id_dataset
           FROM dataset) AS id_dataset,
    ref_nomenclatures.get_id_nomenclature('NAT_OBJ_GEO'::character varying, 'St'::character varying) AS id_nomenclature_geo_object_nature,
    ref_nomenclatures.get_id_nomenclature('TYP_GRP'::character varying, 'REL'::character varying) AS id_nomenclature_grp_typ,
    ref_nomenclatures.get_id_nomenclature('OBJ_DENBR'::character varying, 'IND'::character varying) AS id_nomenclature_obj_count,
    ref_nomenclatures.get_id_nomenclature('TYP_DENBR'::character varying, 'Es'::character varying) AS id_nomenclature_type_count,
    ref_nomenclatures.get_id_nomenclature('STATUT_OBS'::character varying, 'Pr'::character varying) AS id_nomenclature_observation_status,
    ref_nomenclatures.get_id_nomenclature('STATUT_SOURCE'::character varying, 'Te'::character varying) AS id_nomenclature_source_status,
    ref_nomenclatures.get_id_nomenclature('TYP_INF_GEO'::character varying, '1'::character varying) AS id_nomenclature_info_geo_type,
    1 AS count_min,
    1 AS count_max,
    NULL::integer AS id_nomenclature_sex,
    NULL::integer AS id_nomenclature_behaviour,
    NULL::integer AS id_nomenclature_bio_status,
    ref_nomenclatures.get_id_nomenclature('STADE_VIE'::character varying, '1'::character varying) AS id_nomenclature_life_stage,
    NULL::integer AS id_nomenclature_bio_condition,
    NULL::integer AS id_nomenclature_obs_technique,
    t.cd_nom,
    t.nom_complet AS nom_cite,
    s.altitude_min,
    s.altitude_max,
    s.geom AS the_geom_4326,
    st_centroid(s.geom) AS the_geom_point,
    s.geom_local AS the_geom_local,
    s.first_use_date AS date_min,
    s.first_use_date AS date_max,
    concat(upper(tr.nom_role::text), ' ', tr.prenom_role) AS observers,
    s.id_digitiser,
    ( SELECT id_module.id_module
           FROM id_module) AS id_module,
    s.base_site_description AS comment_description,
    ARRAY[tr.id_role] AS ids_observers,
    s.base_site_name AS place_name,
    jsonb_build_object('type_site', st.type, 'diametre', sc.data ->> 'diametre'::text, 'diametre_estime', sc.data ->> 'diametre_estime'::text, 'espece_loges', sc.data ->> 'espece_loges'::text, 'etat_sanitaire', sc.data ->> 'etat_sanitaire'::text, 'code_dmh', i.code_dmh, 'code_marquage', marquage.code_marquage, 'nb_ebauches', sc.data ->> 'nb_ebauches'::text, 'nb_loges', sc.data ->> 'nb_loges'::text, 'num_plaquette', sc.data ->> 'num_plaquette'::text) AS additional_data,
    s.id_base_site,
    NULL::integer AS id_base_visit,
    NULL::integer AS id_observation
   FROM gn_monitoring.t_base_sites s
     JOIN selected_type_site st ON st.id_base_site = s.id_base_site
     JOIN utilisateurs.t_roles tr ON tr.id_role = s.id_inventor
     JOIN gn_monitoring.t_site_complements sc ON sc.id_base_site = s.id_base_site
     JOIN taxonomie.taxref t ON t.cd_nom = ((sc.data ->> 'cd_nom_essence'::text)::integer)
     LEFT JOIN LATERAL ( SELECT string_agg(DISTINCT tn.cd_nomenclature::text, ', '::text) AS code_marquage
           FROM ref_nomenclatures.t_nomenclatures tn,
            jsonb_array_elements_text(sc.data -> 'id_nomenclature_marquage'::text) id(value)
          WHERE tn.id_nomenclature = id.value::integer AND NOT (sc.data ->> 'id_nomenclature_marquage'::text) IS NULL
          GROUP BY s.id_base_site) marquage ON true
     LEFT JOIN LATERAL ( SELECT string_agg(DISTINCT tn.cd_nomenclature::text, ', '::text) AS code_dmh
           FROM ref_nomenclatures.t_nomenclatures tn,
            jsonb_array_elements_text(sc.data -> 'id_nomenclature_dmh'::text) id(value)
          WHERE tn.id_nomenclature = id.value::integer AND NOT (sc.data ->> 'id_nomenclature_dmh'::text) IS NULL
          GROUP BY s.id_base_site) i ON true
     JOIN source ON true;