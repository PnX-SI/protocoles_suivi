
DROP VIEW IF EXISTS gn_monitoring.vs_visits CASCADE;
CREATE VIEW gn_monitoring.vs_visits AS
SELECT 
	v.id_module,
	v.uuid_base_visit,
	s.uuid_base_site,
	s.id_base_site,
	v.id_base_visit,
	v.id_dataset,
	id_nomenclature_obs_technique,
	id_nomenclature_grp_typ,
	ref_nomenclatures.get_id_nomenclature('NAT_OBJ_GEO', 'St') AS id_nomenclature_geo_object_nature,
	v.visit_date_min AS date_min,
	COALESCE (v.visit_date_max, v.visit_date_min) AS date_max,
	v.comments AS comment_description,
	s.geom AS the_geom_4326,
	ST_CENTROID(s.geom) AS the_geom_point, 
	s.geom_local as geom_local,
	o.ids_observers,    
	o.observers,    
	v.id_digitiser 
	FROM gn_monitoring.t_base_visits v
	JOIN gn_monitoring.t_base_sites s ON v.id_base_site = s.id_base_site
	LEFT JOIN LATERAL (
		SELECT array_agg(r.id_role) AS ids_observers,
        STRING_AGG(CONCAT(r.nom_role, ' ', prenom_role), ' ; ') AS observers 
		FROM gn_monitoring.cor_visit_observer cvo
		JOIN utilisateurs.t_roles r
		ON r.id_role = cvo.id_role  
		WHERE cvo.id_base_visit = v.id_base_visit
	) o ON true 
;


DROP VIEW IF EXISTS gn_monitoring.vs_cheveches;
CREATE VIEW gn_monitoring.vs_cheveches AS
SELECT
		v.uuid_base_visit AS unique_id_sinp, 
		v.uuid_base_site AS unique_id_sinp_grp,
		-- idsource OBLIGATOIRE POUR QUE LA données remonte dans la synthese
		v.id_base_visit AS entity_source_pk_value,
		v.id_dataset,
		v.id_nomenclature_geo_object_nature,
		v.id_nomenclature_grp_typ,
		--id_nomenclature_obs_meth,
		v.id_nomenclature_obs_technique,
		--id_nomenclature_bio_status, 
		--id_nomenclature_bio_condition,
		--id_nomenclature_naturalness,
		--id_nomenclature_exist_proof,-
		--id_nomenclature_valid_status,
		--id_nomenclature_diffusion_level,
		--id_nomenclature_life_stage,
		--id_nomenclature_sex,
 		ref_nomenclatures.get_id_nomenclature('IND', 'OBJ_DENBR') AS id_nomenclature_obj_count,
 		ref_nomenclatures.get_id_nomenclature('TYP_DENBR', 'Es') AS id_nomenclature_type_count,
 		-- id_nomenclature_sensitivity
 		
         --CASE 
		--	WHEN n.cd_nomenclature = 'Pr' THEN ref_nomenclatures.get_id_nomenclature('STATUT_OBS', 'Pr')
		--	ELSE  ref_nomenclatures.get_id_nomenclature('STATUT_OBS', 'No')  
		--END AS id_nomenclature_observation_status, 
        (vc.data->>'id_nomenclature_statut_obs')::int AS id_nomenclature_observation_status,
		-- id_nomenclature_blurring
		ref_nomenclatures.get_id_nomenclature('STATUT_SOURCE', 'Te') AS id_nomenclature_source_status,
		ref_nomenclatures.get_id_nomenclature('TYP_INF_GEO', '1') AS id_nomenclature_info_geo_type,
		CASE 
			WHEN n.cd_nomenclature = 'Pr' THEN 1
			ELSE 0 
		END AS count_min,
		CASE 
			WHEN n.cd_nomenclature = 'Pr' THEN 1
			ELSE 0 
		END AS count_max,
		(vc.data->>'cd_nom')::int AS cd_nom,
		t.nom_complet AS nom_cite,
		--meta_v_taxref
		--sample_number_proof
		--digital_proof
		--non_digital_proof
	    alt.altitude_min,
	    alt.altitude_max,
		v.the_geom_4326,
		v.the_geom_point,
		v.geom_local as the_geom_local,
		v.date_min,
		v.date_max,
		--validator
		--validation_comment
		observers,
		--determiner
		v.id_digitiser,
		--id_nomenclature_determination_method
		--meta_validation_date
		--meta_create_date,
		--meta_update_date,
		--last_action
		v.id_module,
		--comment_context
		v.comment_description,
		ids_observers,
		
		-- ## Colonnes complémentaires pouvant être utile
		v.id_base_site,
		v.id_base_visit
	FROM gn_monitoring.vs_visits v
	JOIN gn_commons.t_modules m ON m.id_module = v.id_module
	JOIN gn_monitoring.t_visit_complements vc ON vc.id_base_visit = v.id_base_visit 
	JOIN ref_nomenclatures.t_nomenclatures n ON n.id_nomenclature = (vc.data->>'id_nomenclature_statut_obs')::int
	JOIN taxonomie.taxref t ON cd_nom = (vc.data->>'cd_nom')::int
 	LEFT JOIN LATERAL ref_geo.fct_get_altitude_intersection(v.geom_local) alt (altitude_min, altitude_max) ON true
	WHERE m.module_path = 'cheveches';
