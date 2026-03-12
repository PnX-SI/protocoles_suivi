DROP VIEW IF EXISTS gn_monitoring.v_hors_synthese_sterf;

CREATE OR REPLACE VIEW gn_monitoring.v_hors_synthese_sterf
 AS
 WITH source AS (
         SELECT sc.id_source,
            mo.id_module
           FROM gn_synthese.t_sources sc
             LEFT JOIN gn_commons.t_modules mo ON ('MONITORING_'::text || upper(mo.module_code::text)) = sc.name_source::text
          WHERE sc.name_source::text = 'MONITORING_STERF'::text
        ), ds AS (
         SELECT cds.id_dataset,
            cds.id_cor_dataset_site,
            cds.id_type,
            cds.area_code,
            cds.verif,
            d.unique_dataset_id,
            d.id_acquisition_framework,
            d.dataset_name,
            d.dataset_shortname,
            d.dataset_desc,
            d.id_nomenclature_data_type,
            d.keywords,
            d.marine_domain,
            d.terrestrial_domain,
            d.id_nomenclature_dataset_objectif,
            d.bbox_west,
            d.bbox_east,
            d.bbox_south,
            d.bbox_north,
            d.id_nomenclature_collecting_method,
            d.id_nomenclature_data_origin,
            d.id_nomenclature_source_status,
            d.id_nomenclature_resource_type,
            d.active,
            d.validable,
            d.id_digitizer,
            d.id_taxa_list,
            d.meta_create_date,
            d.meta_update_date
           FROM gn_meta.cor_dataset_site cds
             LEFT JOIN gn_meta.t_datasets d USING (id_dataset)
          WHERE NOT lower(d.dataset_name::text) ~~ '%flore%'::text AND NOT lower(d.dataset_name::text) ~~ '%fonge%'::text AND NOT lower(d.dataset_name::text) ~~ '%autre%'::text AND NOT lower(d.dataset_name::text) ~~ '%habitat%'::text
        ), sites AS (
         SELECT s_1.id_base_site,
            ds.id_dataset,
            tsg.sites_group_name,
            tsg.sites_group_description,
            s_1.base_site_name,
            s_1.base_site_code,
            s_1.altitude_min,
            s_1.altitude_max,
            tsg.data,
            s_1.geom AS the_geom_4326,
            st_centroid(s_1.geom) AS the_geom_point,
            s_1.geom_local
           FROM gn_monitoring.t_base_sites s_1
             LEFT JOIN gn_monitoring.t_site_complements tsc USING (id_base_site)
             LEFT JOIN gn_monitoring.t_sites_groups tsg USING (id_sites_group)
             LEFT JOIN ds ON tsg.sites_group_name::text = ds.area_code
             JOIN source source_1 ON tsc.id_module = source_1.id_module
        ), visits AS (
         SELECT v_1.id_base_visit,
            v_1.uuid_base_visit,
            v_1.id_module,
            v_1.id_base_site,
            v_1.id_dataset,
            v_1.id_digitiser,
            v_1.visit_date_min AS date_min,
            COALESCE(v_1.visit_date_max, v_1.visit_date_min) AS date_max,
            v_1.comments,
            v_1.id_nomenclature_tech_collect_campanule,
            v_1.id_nomenclature_grp_typ,
            tvc.data
           FROM gn_monitoring.t_base_visits v_1
             LEFT JOIN gn_monitoring.t_visit_complements tvc USING (id_base_visit)
             JOIN source source_1 USING (id_module)
        ), observers AS (
         SELECT array_agg(r.id_role) AS ids_observers,
            string_agg(concat(r.nom_role, ' ', r.prenom_role), ' ; '::text) AS observers,
            cvo.id_base_visit
           FROM gn_monitoring.cor_visit_observer cvo
             JOIN utilisateurs.t_roles r ON r.id_role = cvo.id_role
          GROUP BY cvo.id_base_visit
        )
 SELECT o.uuid_observation AS unique_id_sinp,
    v.uuid_base_visit AS unique_id_sinp_grp,
    source.id_source,
    o.id_observation AS entity_source_pk_value,
        CASE
            WHEN s.id_dataset IS NULL THEN 1342
            ELSE s.id_dataset
        END AS id_dataset,
    ref_nomenclatures.get_id_nomenclature('NAT_OBJ_GEO'::character varying, 'St'::character varying) AS id_nomenclature_geo_object_nature,
    v.id_nomenclature_grp_typ,
    v.id_nomenclature_tech_collect_campanule,
    ref_nomenclatures.get_id_nomenclature('METH_OBS'::character varying, '0'::character varying) AS id_nomenclature_obs_technique,
    (toc.data ->> 'id_nomenclature_obj_count'::text)::integer AS id_nomenclature_obj_count,
    (toc.data ->> 'id_nomenclature_type_count'::text)::integer AS id_nomenclature_type_count,
    ref_nomenclatures.get_id_nomenclature('STATUT_OBS'::character varying, 'Pr'::character varying) AS id_nomenclature_observation_status,
    ref_nomenclatures.get_id_nomenclature('STATUT_SOURCE'::character varying, 'Te'::character varying) AS id_nomenclature_source_status,
    ref_nomenclatures.get_id_nomenclature('TYP_INF_GEO'::character varying, '1'::character varying) AS id_nomenclature_info_geo_type,
    (toc.data ->> 'effectif'::text)::integer AS count_min,
    (toc.data ->> 'effectif'::text)::integer AS count_max,
    o.id_observation,
    o.cd_nom,
    t.nom_complet AS nom_cite,
    s.altitude_min,
    s.altitude_max,
    ((((((s.data ->> 'commune'::text) || ' - '::text) || s.sites_group_name::text) || ' - '::text) || s.sites_group_description) || ' - '::text) || s.base_site_code::text AS place_name,
    s.the_geom_4326,
    s.the_geom_point,
    s.geom_local AS the_geom_local,
    v.date_min,
    v.date_max,
    obs.observers,
    toc.data ->> 'determiner'::text AS determiner,
    v.id_digitiser,
    (toc.data ->> 'id_nomenclature_determination_method'::text)::integer AS id_nomenclature_determination_method,
    v.id_module,
    (((((((((((('num_passage : '::text || (v.data ->> 'num_passage'::text)) || ' | hab_1 : '::text) || (v.data ->> 'hab_1'::text)) || ' | hab_2 : '::text) || COALESCE(v.data ->> 'hab_2'::text, '/'::text)) || ' | occ_sol : '::text) || (v.data ->> 'occ_sol'::text)) || ' | vent : '::text) || ref_nomenclatures.get_nomenclature_label((v.data ->> 'id_nomenclature_vt'::text)::integer)::text) || ' | couverture_nuageuse : '::text) || ref_nomenclatures.get_nomenclature_label((v.data ->> 'id_nomenclature_cn'::text)::integer)::text) || ' | temperature : '::text) || ref_nomenclatures.get_nomenclature_label((v.data ->> 'id_nomenclature_tp'::text)::integer)::text AS comment_context,
        CASE
            WHEN v.comments IS NULL AND NOT o.comments IS NULL THEN o.comments
            WHEN NOT v.comments IS NULL AND o.comments IS NULL THEN v.comments
            ELSE (v.comments || ' '::text) || o.comments
        END AS comment_description,
    jsonb_strip_nulls(jsonb_build_object('année', (v.data ->> 'annee'::text)::integer, 'num_passage', (v.data ->> 'num_passage'::text)::integer, 'hab_1', v.data ->> 'hab_1'::text, 'hab_2', v.data ->> 'hab_2'::text, 'occ_sol', v.data ->> 'occ_sol'::text, 'vent', ref_nomenclatures.get_nomenclature_label((v.data ->> 'id_nomenclature_vt'::text)::integer), 'couverture_nuageuse', ref_nomenclatures.get_nomenclature_label((v.data ->> 'id_nomenclature_cn'::text)::integer), 'temperature', ref_nomenclatures.get_nomenclature_label((v.data ->> 'id_nomenclature_tp'::text)::integer))) AS additional_data,
    obs.ids_observers,
    v.id_base_site,
    v.id_base_visit
   FROM gn_monitoring.t_observations o
     LEFT JOIN gn_monitoring.t_observation_complements toc USING (id_observation)
     JOIN visits v ON v.id_base_visit = o.id_base_visit
     JOIN sites s ON s.id_base_site = v.id_base_site
     JOIN taxonomie.taxref t ON t.cd_nom = o.cd_nom
     LEFT JOIN source ON v.id_module = source.id_module
     LEFT JOIN observers obs ON obs.id_base_visit = v.id_base_visit
     LEFT JOIN gn_synthese.synthese synth ON o.uuid_observation = synth.unique_id_sinp
  WHERE date_part('year'::text, v.date_min) > 2023::double precision AND synth.id_synthese IS NULL
  ORDER BY v.date_min;


SELECT gn_synthese.import_row_from_table('id_module', '32', 'gn_monitoring.v_hors_synthese_sterf', 1000, 0);