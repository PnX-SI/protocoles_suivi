-- #############################
-- 	Création d'une vue 
--		permettant la remonté des données 
--		test dans la synthèse
-- #############################
DROP VIEW IF EXISTS gn_monitoring.vs_chronocapture;
CREATE VIEW gn_monitoring.vs_chronocapture AS
WITH source AS (
	SELECT id_source 
	FROM gn_synthese.t_sources
	WHERE name_source = CONCAT('MONITORING_', UPPER(:'module_code')) -- ici 'MONITORING_<module_code>.upper()'
	LIMIT 1
)
SELECT
		o.uuid_observation AS unique_id_sinp, 
		v.uuid_base_visit AS unique_id_sinp_grp,
		(SELECT id_source FROM source) as id_source,
		o.id_observation AS entity_source_pk_value,
		v.id_dataset,
		v.id_nomenclature_geo_object_nature,
		--v.id_nomenclature_grp_typ,
		ref_nomenclatures.get_id_nomenclature('METH_OBS', '50') AS id_nomenclature_obs_meth,
		--v.id_nomenclature_obs_technique,
		--id_nomenclature_bio_status, 
		--id_nomenclature_bio_condition,
		--id_nomenclature_naturalness,
		--id_nomenclature_exist_proof,-
		--id_nomenclature_valid_status,
		--id_nomenclature_diffusion_level,
		ref_nomenclatures.get_id_nomenclature('STADE_VIE', '15')AS id_nomenclature_life_stage,
		ref_nomenclatures.get_id_nomenclature('SEXE', '6') AS id_nomenclature_sex,
 		ref_nomenclatures.get_id_nomenclature('OBJ_DENBR', 'IND') AS id_nomenclature_obj_count,
 		ref_nomenclatures.get_id_nomenclature('TYP_DENBR', 'Co') AS id_nomenclature_type_count,
 		-- id_nomenclature_sensitivity
 		ref_nomenclatures.get_id_nomenclature('STATUT_OBS', 'Pr') AS id_nomenclature_observation_status, 
		-- id_nomenclature_blurring
		ref_nomenclatures.get_id_nomenclature('STATUT_SOURCE', 'Te') AS id_nomenclature_source_status,
		ref_nomenclatures.get_id_nomenclature('TYP_INF_GEO', '1') AS id_nomenclature_info_geo_type,
		(oc.data::json#>'{nb_count}')::text::int AS count_min,
		(oc.data::json#>'{nb_count}')::text::int AS count_max,
		o.id_observation,
		o.cd_nom::int AS cd_nom,
		t.nom_complet AS nom_cite,
		--meta_v_taxref
		--sample_number_proof
		--digital_proofvue
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
		(oc.data::json#>'{id_nomenclature_determination_method}')::text::int AS id_nomenclature_determination_method,
		--meta_validation_date
		--meta_create_date,
		--meta_update_date,
		--last_action
		v.id_module,
		v.comment_context AS comment_context,
		o.comments AS comment_description,
		ids_observers,
		-- ## Colonnes complémentaires pouvant être utile
		v.id_base_site,
		v.id_base_visit
	FROM gn_monitoring.vs_visits v
	JOIN gn_commons.t_modules m ON m.id_module = v.id_module
	JOIN gn_monitoring.t_observations o ON o.id_base_visit = v.id_base_visit 
	JOIN gn_monitoring.t_observation_complements oc ON oc.id_observation=o.id_observation
	JOIN taxonomie.taxref t ON t.cd_nom = o.cd_nom
 	LEFT JOIN LATERAL ref_geo.fct_get_altitude_intersection(v.geom_local) alt (altitude_min, altitude_max) ON true
    WHERE m.module_code = :'module_code';
