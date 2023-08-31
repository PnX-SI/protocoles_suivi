
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

DROP VIEW IF EXISTS gn_monitoring.v_synthese_:module_code;

CREATE OR REPLACE VIEW gn_monitoring.v_synthese_:module_code
AS WITH source AS (
         SELECT id_source
           FROM gn_synthese.t_sources
          WHERE name_source = CONCAT('MONITORING_', UPPER(:'module_code'))
        )
 SELECT 
 	o.uuid_observation AS unique_id_sinp,
    v.uuid_base_visit AS unique_id_sinp_grp,
    (SELECT id_source FROM source) AS id_source,
    o.id_observation AS entity_source_pk_value,
    v.id_dataset,
    ref_nomenclatures.get_id_nomenclature('METH_OBS'::character varying, '20'::character varying) AS id_nomenclature_obs_meth, 
    nullif(json_extract_path(oc.data::json,'id_nomenclature_stade')::text,'null')::integer AS id_nomenclature_life_stage,
    nullif(json_extract_path(oc.data::json,'id_nomenclature_sex')::text,'null')::integer AS id_nomenclature_sex,
    ref_nomenclatures.get_id_nomenclature('OBJ_DENBR'::character varying, 'IND'::character varying) AS id_nomenclature_obj_count,
    nullif(json_extract_path(oc.data::json,'id_nomenclature_typ_denbr')::text, 'null')::integer AS id_nomenclature_type_count,
    ref_nomenclatures.get_id_nomenclature('STATUT_OBS'::character varying, 'Pr'::character varying) AS id_nomenclature_observation_status,
    ref_nomenclatures.get_id_nomenclature('ETAT_BIO'::character varying, '1'::character varying) as id_nomenclature_bio_condition,
    ref_nomenclatures.get_id_nomenclature('STATUT_SOURCE'::character varying, 'Te'::character varying) AS id_nomenclature_source_status,
    ref_nomenclatures.get_id_nomenclature('TYP_INF_GEO'::character varying, '1'::character varying) AS id_nomenclature_info_geo_type,
    nullif(((oc.data::json #> '{count_min}'::text[])::text),'null')::integer AS count_min,
    nullif(((oc.data::json #> '{count_max}'::text[])::text),'null')::integer AS count_max,
    o.id_observation,
    o.cd_nom,
    t.nom_complet AS nom_cite,
    alt.altitude_min,
    alt.altitude_max,
    s.geom AS the_geom_4326,
    st_centroid(s.geom) AS the_geom_point,
    s.geom_local AS the_geom_local,
    v.visit_date_min AS date_min,
    v.visit_date_min AS date_max,
    obs.observers,
    v.id_digitiser,
    ref_nomenclatures.get_id_nomenclature('METH_DETERMIN'::character varying, '1'::character varying) AS id_nomenclature_determination_method,
    v.id_module as id_module,
    v.comments AS comment_context,
    o.comments AS comment_description,
    obs.ids_observers,
    v.id_base_site,
    v.id_base_visit, 
    json_build_object(
    	'aire_etude', tsg.sites_group_name,
        'nom_site', s.base_site_name,
        'milieu_aquatique', ref_nomenclatures.get_nomenclature_label(nullif(json_extract_path(sc.data::json,'milieu_aquatique')::text,'null')::integer, 'fr'),
        'variation_eau', ref_nomenclatures.get_nomenclature_label(nullif(json_extract_path(sc.data::json,'variation_eau')::text,'null')::integer, 'fr'),
        'courant',  ref_nomenclatures.get_nomenclature_label(nullif(json_extract_path(sc.data::json,'courant')::text,'null')::integer, 'fr'),
    	'num_passage', json_extract_path(vc.data::json,'num_passage')::text, 
    	'accessibilite', (vc.data::json #> '{accessibility}'::text[]),
    	'pluviosite', ref_nomenclatures.get_nomenclature_label(nullif(json_extract_path(vc.data::json,'pluviosite')::text,'null')::integer, 'fr'),
    	'couverture_nuageuse', ref_nomenclatures.get_nomenclature_label(nullif(json_extract_path(vc.data::json,'couverture_nuageuse')::text,'null')::integer, 'fr'),
    	'vent', ref_nomenclatures.get_nomenclature_label(nullif(json_extract_path(vc.data::json,'vent')::text,'null')::integer, 'fr'),
    	'turbidite', ref_nomenclatures.get_nomenclature_label(nullif(json_extract_path(vc.data::json,'turbidite')::text,'null')::integer, 'fr'),
    	'vegetation_aquatique_principale', ref_nomenclatures.get_nomenclature_label(nullif(json_extract_path(vc.data::json,'vegetation_aquatique_principale')::text,'null')::integer, 'fr'),
    	'rives', ref_nomenclatures.get_nomenclature_label(nullif(json_extract_path(vc.data::json,'rives')::text,'null')::integer, 'fr'),
    	'habitat_terrestre_environnant', ref_nomenclatures.get_nomenclature_label(nullif(json_extract_path(vc.data::json,'habitat_terrestre_environnant')::text,'null')::integer, 'fr'),
    	'activite_humaine', ref_nomenclatures.get_nomenclature_label(nullif(json_extract_path(vc.data::json,'activite_humaine')::text,'null')::integer, 'fr')
    	) as additional_data
   FROM gn_monitoring.t_base_visits v
   	 JOIN gn_monitoring.t_visit_complements vc on v.id_base_visit = vc.id_base_visit 
     JOIN gn_monitoring.t_base_sites s ON s.id_base_site = v.id_base_site
     JOIN gn_monitoring.t_site_complements sc on sc.id_base_site = s.id_base_site
     JOIN gn_monitoring.t_sites_groups tsg ON sc.id_sites_group = tsg.id_sites_group
     JOIN gn_commons.t_modules m ON m.id_module = v.id_module
     JOIN gn_monitoring.t_observations o ON o.id_base_visit = v.id_base_visit
     JOIN gn_monitoring.t_observation_complements oc ON oc.id_observation = o.id_observation
     JOIN taxonomie.taxref t ON t.cd_nom = o.cd_nom
     LEFT JOIN LATERAL ( SELECT array_agg(r.id_role) AS ids_observers,
            string_agg(concat(r.nom_role, ' ', r.prenom_role), ' ; '::text) AS observers
           FROM gn_monitoring.cor_visit_observer cvo
             JOIN utilisateurs.t_roles r ON r.id_role = cvo.id_role
          WHERE cvo.id_base_visit = v.id_base_visit) obs ON true
     LEFT JOIN LATERAL ref_geo.fct_get_altitude_intersection(s.geom_local) alt(altitude_min, altitude_max) ON true
    WHERE m.module_code = :'module_code';
