-- #############################
-- 	Création d'une vue 
--		permettant la remonté des données 
--		test dans la synthèse
-- #############################
DROP VIEW IF EXISTS gn_monitoring.v_synthese_:module_code;
CREATE VIEW gn_monitoring.v_synthese_:module_code AS
WITH source AS (
	SELECT id_source 
	FROM gn_synthese.t_sources
	WHERE name_source = CONCAT('MONITORING_', UPPER(:'module_code'))
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
), determiner AS (
    SELECT
        array_agg(r.id_role) AS id_determiner,
        CONCAT(r.nom_role, ' ', prenom_role) AS determiner,
        id_observation
    FROM gn_monitoring.t_observation_complements oc
    JOIN utilisateurs.t_roles r
    ON r.id_role = (oc.data::json#>'{determiner}')::TEXT::integer
    GROUP BY id_observation, r.nom_role, prenom_role
)
SELECT
		o.uuid_observation AS unique_id_sinp, 
		v.uuid_base_visit AS unique_id_sinp_grp,
		(SELECT id_source FROM source) as id_source,
		o.id_observation AS entity_source_pk_value,
		v.id_dataset AS id_dataset,
		-- AS id_nomenclature_geo_object_nature,
		--v.id_nomenclature_grp_typ,
		(sc.data::json#>'{id_trap_type}')::text::int AS id_nomenclature_obs_meth,
		--id_nomenclature_bio_status, 
		--id_nomenclature_bio_condition,
		--id_nomenclature_naturalness,
		--id_nomenclature_exist_proof,-
		--id_nomenclature_valid_status,
		--id_nomenclature_diffusion_level,
		(oc.data::json#>'{id_nomenclature_life_stage}')::text::int AS id_nomenclature_life_stage,
		(oc.data::json#>'{id_nomenclature_sex}')::text::int AS id_nomenclature_sex,
 		ref_nomenclatures.get_id_nomenclature('OBJ_DENBR', 'IND') AS id_nomenclature_obj_count,
 		ref_nomenclatures.get_id_nomenclature('TYP_DENBR', 'Co') AS id_nomenclature_type_count,
 		-- id_nomenclature_sensitivity
 		ref_nomenclatures.get_id_nomenclature('STATUT_OBS', 'Pr') AS id_nomenclature_observation_status, 
		-- id_nomenclature_blurring
		ref_nomenclatures.get_id_nomenclature('STATUT_SOURCE', 'Te') AS id_nomenclature_source_status,
		ref_nomenclatures.get_id_nomenclature('TYP_INF_GEO', '1') AS id_nomenclature_info_geo_type,
		(oc.data::json#>'{nb_count}')::text::int AS count_min,
		(oc.data::json#>'{nb_count}')::text::int AS count_max,
		o.cd_nom::int AS cd_nom,
		t.nom_complet AS nom_cite,
		--meta_v_taxref
		--sample_number_proof
		--digital_proofvue
		alt.altitude_min,
		alt.altitude_max,
		s.geom AS the_geom_4326,
		ST_Centroid(s.geom) AS the_geom_point,
		s.geom_local as the_geom_local,
		v.visit_date_min AS date_min,
		v.visit_date_max AS date_max,
		--validator
		--validation_comment
		obs.observers,
		det.determiner AS determiner,
		v.id_digitiser,
		(oc.data::json#>'{id_nomenclature_determination_method}')::text::int AS id_nomenclature_determination_method,
		--meta_validation_date
		--meta_create_date,
		--meta_update_date,
		--last_action
		v.id_module,
		CONCAT('Commentaire site : ',(oc.data::json#>'{comment_site}')::text,' ; Commentaire visite : ', v.comments)  AS comment_context,
		o.comments AS comment_description,
		-- Colonnes complémentaires pouvant être utiles 
		s.id_base_site,
		v.id_base_visit
	FROM gn_monitoring.t_observations o
	JOIN gn_monitoring.t_observation_complements oc ON o.id_observation=oc.id_observation
	JOIN gn_monitoring.t_base_visits v ON o.id_base_visit=v.id_base_visit
	JOIN gn_monitoring.t_visit_complements vc ON v.id_base_visit=vc.id_base_visit
	JOIN gn_monitoring.t_base_sites s ON v.id_base_site=s.id_base_site
	JOIN gn_monitoring.t_site_complements sc ON s.id_base_site=sc.id_base_site
	JOIN taxonomie.taxref t ON o.cd_nom=t.cd_nom
	JOIN observers obs ON obs.id_base_visit = v.id_base_visit
	JOIN determiner det ON det.id_observation = o.id_observation
	JOIN gn_commons.t_modules m ON v.id_module=m.id_module
	LEFT JOIN LATERAL ref_geo.fct_get_altitude_intersection(s.geom_local) alt (altitude_min, altitude_max) ON true
 	WHERE m.module_code = :'module_code'