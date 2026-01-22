DROP VIEW IF EXISTS gn_monitoring.v_synthese_craves;
CREATE VIEW gn_monitoring.v_synthese_craves AS
WITH source AS (
	SELECT
        id_source
    FROM gn_synthese.t_sources
	WHERE name_source = CONCAT('MONITORING_', UPPER( :module_code))
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
SELECT
		v.uuid_base_visit AS unique_id_sinp,
		v.uuid_base_visit AS unique_id_sinp_grp,
		source.id_source,
		v.id_base_visit AS entity_source_pk_value,
		v.id_dataset,
        ref_nomenclatures.get_id_nomenclature('NAT_OBJ_GEO', 'St') AS id_nomenclature_geo_object_nature,
		ref_nomenclatures.get_id_nomenclature('TYP_GRP', 'REL') AS id_nomenclature_grp_typ, -- TYP_GRP
		--id_nomen clature_obs_technique, -- METH_OBS
		--id_nomenclature_bio_status, -- STATUT_BIO
		--id_nomenclature_bio_condition, -- ETA_BIO
		--id_nomenclature_naturalness, -- NATURALITE
		--id_nomenclature_exist_proof, -- PREUVE_EXIST
		--id_nomenclature_valid_status,  --STATUT_VALID
		--id_nomenclature_diffusion_level, -- NIV_PRECIS
		--id_nomenclature_life_stage, -- STADE_VIE
		--id_nomenclature_sex, -- SEXE
 		ref_nomenclatures.get_id_nomenclature('OBJ_DENBR', 'IND') AS id_nomenclature_obj_count,
 		ref_nomenclatures.get_id_nomenclature('TYP_DENBR', 'Es') AS id_nomenclature_type_count,
 		-- id_nomenclature_sensitivity, --SENSIBILITE
 		ref_nomenclatures.get_id_nomenclature('STATUT_OBS', 'Pr') AS id_nomenclature_observation_status,
		-- id_nomenclature_blurring, -- DEE_FLOU
        -- id_nomenclature_behaviour, -- OCC_COMPORTEMENT
		ref_nomenclatures.get_id_nomenclature('STATUT_SOURCE', 'Te') AS id_nomenclature_source_status,
		ref_nomenclatures.get_id_nomenclature('TYP_INF_GEO', '1') AS id_nomenclature_info_geo_type,
		(vc.data->>'count')::int AS count_min,
		(vc.data->>'count')::int AS count_max,
		t.cd_nom,
		t.nom_complet AS nom_cite,
		--meta_v_taxref
		--sample_number_proof
		--digital_proofvue
		s.altitude_min,
		s.altitude_max,
		s.geom AS the_geom_4326,
		ST_CENTROID(s.geom) AS the_geom_point,
		s.geom_local AS the_geom_local,
		v.visit_date_min AS date_min,
		COALESCE (v.visit_date_max, v.visit_date_min) AS date_max,
		--validator
		--validation_comment
		CONCAT_WS(' ; ', obs.observers, observers_txt) as observers,
		--determiner
		--v.v.id_digitiser,
		--id_nomenclature_determination_method
		--meta_validation_date
		--meta_create_date,
		--meta_update_date,
		--last_action
		v.id_module,
		v.comments AS comment_description, 
    	s.base_site_name AS place_name,
		-- ## Colonnes complémentaires qui ont leur utilité dans la fonction synthese.import_row_from_table
		v.id_base_site,
		v.id_base_visit
    FROM gn_monitoring.t_base_visits v
    LEFT JOIN gn_monitoring.t_base_sites s
        ON s.id_base_site = v.id_base_site
	JOIN gn_commons.t_modules m
        ON m.id_module = v.id_module
	JOIN gn_monitoring.t_visit_complements vc ON vc.id_base_visit = v.id_base_visit
	JOIN taxonomie.taxref t ON cd_nom = (vc.data->>'cd_nom')::int
	LEFT OUTER JOIN observers obs ON obs.id_base_visit = v.id_base_visit
	JOIN source ON TRUE
    WHERE m.module_code =  :module_code and (vc.data->>'count')::int > 0
    ;
