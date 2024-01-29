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

DROP VIEW IF EXISTS gn_monitoring.v_synthese_POPReptile;

CREATE OR REPLACE VIEW gn_monitoring.v_synthese_POPReptile
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
    ref_nomenclatures.get_id_nomenclature('METH_OBS'::character varying, '0'::character varying) AS id_nomenclature_obs_meth, 
    CASE 
        WHEN json_extract_path(oc.data::json,'stade_vie')::text = 'Adultes' THEN ref_nomenclatures.get_id_nomenclature('STADE_VIE'::character varying, '2'::character varying)
        WHEN json_extract_path(oc.data::json,'stade_vie')::text IN ('Nouveaux-nés','Juvéniles') THEN ref_nomenclatures.get_id_nomenclature('STADE_VIE'::character varying, '3'::character varying)
        ELSE ref_nomenclatures.get_id_nomenclature('STADE_VIE'::character varying, '1'::character varying)
    END AS id_nomenclature_life_stage,
    ref_nomenclatures.get_id_nomenclature('SEXE'::character varying, '6'::character varying) AS id_nomenclature_sex,
    ref_nomenclatures.get_id_nomenclature('OBJ_DENBR'::character varying, 'IND'::character varying) AS id_nomenclature_obj_count,
    CASE
        WHEN json_extract_path(oc.data::json,'type_denombrement')::text = 'Compté' THEN ref_nomenclatures.get_id_nomenclature('TYP_DENBR'::character varying, 'Co'::character varying)
        WHEN json_extract_path(oc.data::json,'type_denombrement')::text = 'Estimé' THEN ref_nomenclatures.get_id_nomenclature('TYP_DENBR'::character varying, 'Es'::character varying)
        ELSE ref_nomenclatures.get_id_nomenclature('TYP_DENBR'::character varying, 'NSP'::character varying)
    END AS id_nomenclature_type_count,
    CASE 
         WHEN json_extract_path(oc.data::json,'presence')::text = 'Oui' THEN ref_nomenclatures.get_id_nomenclature('STATUT_OBS'::character varying, 'Pr'::character varying) 
         ELSE ref_nomenclatures.get_id_nomenclature('STATUT_OBS'::character varying, 'No'::character varying)
    END AS id_nomenclature_observation_status,
    ref_nomenclatures.get_id_nomenclature('ETAT_BIO'::character varying, '1'::character varying) as id_nomenclature_bio_condition,
    ref_nomenclatures.get_id_nomenclature('STATUT_SOURCE'::character varying, 'Te'::character varying) AS id_nomenclature_source_status,
    ref_nomenclatures.get_id_nomenclature('TYP_INF_GEO'::character varying, '1'::character varying) AS id_nomenclature_info_geo_type,
    CASE
        WHEN json_extract_path(oc.data::json,'type_denombrement')::text = 'Compté' AND nullif(json_extract_path(oc.data::json,'nombre_compte')::text,null)::integer IS NOT NULL THEN nullif(json_extract_path(oc.data::json,'nombre_compte')::text,null)::integer
        WHEN json_extract_path(oc.data::json,'type_denombrement')::text = 'Estimé' AND nullif(json_extract_path(oc.data::json,'nombre_estime_min')::text,null)::integer IS NOT NULL THEN nullif(json_extract_path(oc.data::json,'nombre_estime_min')::text,null)::integer
        ELSE 1
    END AS count_min,
    CASE
        WHEN json_extract_path(oc.data::json,'type_denombrement')::text = 'Compté' AND nullif(json_extract_path(oc.data::json,'nombre_compte')::text,null)::integer IS NOT NULL THEN nullif(json_extract_path(oc.data::json,'nombre_compte')::text,null)::integer
        WHEN json_extract_path(oc.data::json,'type_denombrement')::text = 'Estimé' AND nullif(json_extract_path(oc.data::json,'nombre_estime_max')::text,null)::integer IS NOT NULL THEN nullif(json_extract_path(oc.data::json,'nombre_estime_max')::text,null)::integer
        ELSE 1
    END AS count_max,
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
    ref_nomenclatures.get_id_nomenclature('METH_DETERMIN'::character varying, '0'::character varying) AS id_nomenclature_determination_method,
    v.id_module as id_module,
    v.comments AS comment_context,
    o.comments AS comment_description,
    obs.ids_observers,
    v.id_base_site,
    v.id_base_visit, 
    json_build_object(
        'expertise_operateur', json_extract_path(tsg.data::json,'expertise')::text, 
        'nom_aire', tsg.sites_group_name, 
        'description_aire', tsg.sites_group_description, 
        'habitat_principal_aire', json_extract_path(tsg.data::json,'habitat_principal')::text, 
        'commentaire_aire', tsg.comments, 
        'nom_transect', s.base_site_name, 
        'methode_prospection', json_extract_path(sc.data::json,'methode_prospection')::text, 
        'materiaux_plaques', json_extract_path(sc.data::json,'type_materiaux')::text, 
        'nombre_plaques', json_extract_path(sc.data::json,'nb_plaques')::text, 
        'milieu_transect', json_extract_path(sc.data::json,'milieu_transect')::text, 
        'milieu_bordier', json_extract_path(sc.data::json,'milieu_bordier')::text, 
        'milieu_mosaique', json_extract_path(sc.data::json,'milieu_mosaique_vegetale')::text, 
        'milieu_homogene', json_extract_path(sc.data::json,'milieu_homogene')::text, 
        'milieu_anthropique', json_extract_path(sc.data::json,'milieu_anthropique')::text, 
        'precision_milieu_anthropique', json_extract_path(sc.data::json,'milieu_transect_autre')::text, 
        'microhab_favorable', json_extract_path(sc.data::json,'microhabitat_favorable')::text, 
        'frequentation_humaine_transect', json_extract_path(sc.data::json,'frequentation_humaine')::text, 
        'commentaire_transect', json_extract_path(sc.data::json,'comment')::text, 
        'num_passage', json_extract_path(vc.data::json,'num_passage')::text, 
        'heure_debut', json_extract_path(vc.data::json,'Heure_debut')::text, 
        'heure_fin', json_extract_path(vc.data::json,'Heure_fin')::text, 
        'meteo_visite', json_extract_path(vc.data::json,'meteo')::text, 
        'vent_visite', json_extract_path(vc.data::json,'vent')::text, 
        'abondance', json_extract_path(oc.data::json,'abondance')::text
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

