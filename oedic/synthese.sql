

-- #############################
-- 	Création d'une vue
--		permettant la remonté des données
--		oedicnèmes dans la synthèse
-- #############################
DROP VIEW IF EXISTS gn_monitoring.v_synthese_oedicnemes;
CREATE VIEW gn_monitoring.v_synthese_oedicnemes AS

WITH source AS (
	SELECT id_source
	FROM gn_synthese.t_sources
	WHERE name_source = CONCAT('MONITORING_', UPPER(:'module_code')) -- ici 'MONITORING_<module_code>.upper()'
	LIMIT 1
)SELECT
		o.uuid_observation AS unique_id_sinp,
		v.uuid_base_visit AS unique_id_sinp_grp,
		 (SELECT id_source FROM source) AS id_source,
		o.id_observation AS entity_source_pk_value,
		v.id_dataset,
		ref_nomenclatures.get_id_nomenclature('NAT_OBJ_GEO', 'St') AS id_nomenclature_geo_object_nature,
		v.id_nomenclature_grp_typ,
		ref_nomenclatures.get_id_nomenclature('METH_OBS', n.cd_nomenclature) AS id_nomenclature_obs_meth,
		--v.id_nomenclature_obs_technique,
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
 		ref_nomenclatures.get_id_nomenclature('STATUT_OBS', 'Pr')  AS id_nomenclature_observation_status,
		-- id_nomenclature_blurring
		ref_nomenclatures.get_id_nomenclature('STATUT_SOURCE', 'Te') AS id_nomenclature_source_status,
		ref_nomenclatures.get_id_nomenclature('TYP_INF_GEO', '1') AS id_nomenclature_info_geo_type,
		oc.data->>'nb_oiseaux' AS  count_min,
		oc.data->>'nb_oiseaux' AS count_max,
		o.cd_nom AS cd_nom,
		t.nom_complet AS nom_cite,
		--meta_v_taxref
		--sample_number_proof
		--digital_proofvue
	    alt.altitude_max,
		s.geom AS the_geom_4326,
		ST_CENTROID(s.geom) AS the_geom_point,
		s.geom_local AS the_geom_local,
		v.visit_date_min AS date_min,
		v.visit_date_max AS date_max,
		--validator
		--validation_comment
		obs.observers,
		--determiner
		v.id_digitiser,
		--id_nomenclature_determination_method
		--meta_validation_date
		--meta_create_date,
		--meta_update_date,
		--last_action
		v.id_module,
		v.comments AS comment_context,
		o.comments AS comment_description,
		ids_observers,

		-- ## Colonnes complémentaires pouvant être utile
		v.id_base_site,
		v.id_base_visit,
		o.id_observation
FROM gn_monitoring.t_base_visits v
JOIN gn_monitoring.t_base_sites s
ON v.id_base_site = s.id_base_site 
JOIN gn_commons.t_modules m ON m.id_module = v.id_module
JOIN gn_monitoring.t_visit_complements vc ON vc.id_base_visit = v.id_base_visit
JOIN gn_monitoring.t_observations o ON vc.id_base_visit = o.id_base_visit
JOIN gn_monitoring.t_observation_complements oc ON oc.id_observation = o.id_observation
JOIN ref_nomenclatures.t_nomenclatures   n
ON n.id_nomenclature = (oc.data->>'id_nomenclature_nature_observation')::int
JOIN taxonomie.taxref t ON t.cd_nom = o.cd_nom
LEFT JOIN LATERAL ref_geo.fct_get_altitude_intersection(s.geom_local) alt (altitude_min, altitude_max) ON true
LEFT JOIN LATERAL (
	SELECT
		array_agg(r.id_role) AS ids_observers,
		STRING_AGG(CONCAT(r.nom_role, ' ', prenom_role), ' ; ') AS observers
	FROM gn_monitoring.cor_visit_observer cvo
	JOIN utilisateurs.t_roles r
	ON r.id_role = cvo.id_role
	WHERE cvo.id_base_visit = v.id_base_visit
) obs ON true
WHERE m.module_code = :'module_code';
