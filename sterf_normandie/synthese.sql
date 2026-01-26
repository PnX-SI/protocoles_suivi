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

CREATE VIEW gn_monitoring.v_synthese_:module_code AS

WITH 
	source AS (
		SELECT
			sc.id_source,
			mo.id_module
		FROM gn_synthese.t_sources sc
		LEFT JOIN gn_commons.t_modules mo ON 'MONITORING_' || UPPER(mo.module_code) = name_source
		WHERE name_source = CONCAT('MONITORING_', UPPER(:'module_code'))
	), 
	sites AS (
		SELECT
			s.id_base_site,
			(tsg.data ->> 'id_dataset')::integer as id_dataset,
			tsg.sites_group_name,
			tsg.sites_group_description,
			s.base_site_name,
			s.base_site_code,
			s.altitude_min,
			s.altitude_max,
			tsg.data,
			tsc.id_sites_group,
			s.geom AS the_geom_4326,
			ST_CENTROID(s.geom) AS the_geom_point,
			s.geom_local as geom_local
		FROM gn_monitoring.t_base_sites s
		LEFT JOIN gn_monitoring.t_site_complements tsc USING (id_base_site)
		LEFT JOIN gn_monitoring.t_sites_groups tsg USING (id_sites_group)
		INNER JOIN source ON tsc.id_module = source.id_module
	), 
	visits AS (
		SELECT
			v.id_base_visit,
			v.uuid_base_visit,
			v.id_module,
			v.id_base_site,
			v.id_dataset,
			v.id_digitiser,
			v.visit_date_min AS date_min,
			COALESCE (v.visit_date_max, v.visit_date_min) AS date_max,
			v.comments,
			v.id_nomenclature_tech_collect_campanule,
			v.id_nomenclature_grp_typ,
			tvc.data
		FROM gn_monitoring.t_base_visits v
		LEFT JOIN gn_monitoring.t_visit_complements tvc USING (id_base_visit)
		INNER JOIN source USING (id_module)
	), 
	observers AS (
		SELECT
			array_agg(r.id_role) AS ids_observers,
			STRING_AGG(CONCAT(r.nom_role, ' ', r.prenom_role), ' ; ') AS observers,
			cvo.id_base_visit
		FROM gn_monitoring.cor_visit_observer cvo
		JOIN utilisateurs.t_roles r
		ON r.id_role = cvo.id_role
		GROUP BY cvo.id_base_visit
	)
	SELECT
		o.uuid_observation AS unique_id_sinp, 
		v.uuid_base_visit AS unique_id_sinp_grp,
		source.id_source,
		o.id_observation AS entity_source_pk_value,
		CASE 
			WHEN s.id_dataset IS NULL THEN 1342 
			ELSE s.id_dataset
		END as id_dataset, -- v.id_dataset
		ref_nomenclatures.get_id_nomenclature('NAT_OBJ_GEO'::character varying, 'St'::character varying) AS id_nomenclature_geo_object_nature,
    	ref_nomenclatures.get_id_nomenclature('TYP_GRP'::character varying, 'PASS'::character varying) AS id_nomenclature_grp_typ,
    	ref_nomenclatures.get_id_nomenclature('TECHNIQUE_OBS'::character varying, '59'::character varying) AS id_nomenclature_tech_collect_campanule,
    	ref_nomenclatures.get_id_nomenclature('METH_OBS'::character varying, '0'::character varying) AS id_nomenclature_obs_technique,
    	ref_nomenclatures.get_id_nomenclature('OBJ_DENBR'::character varying, 'IND'::character varying) AS id_nomenclature_obj_count,
    	ref_nomenclatures.get_id_nomenclature('TYP_DENBR'::character varying, 'Co'::character varying) AS id_nomenclature_type_count,
   	 	ref_nomenclatures.get_id_nomenclature('STATUT_OBS'::character varying, 'Pr'::character varying) AS id_nomenclature_observation_status,
   	 	ref_nomenclatures.get_id_nomenclature('STATUT_SOURCE'::character varying, 'Te'::character varying) AS id_nomenclature_source_status,
    	ref_nomenclatures.get_id_nomenclature('TYP_INF_GEO'::character varying, '1'::character varying) AS id_nomenclature_info_geo_type,
    	(toc.data ->> 'effectif'):: integer AS count_min,
		(toc.data ->> 'effectif'):: integer AS count_max,
		id_observation,
		o.cd_nom,
		t.nom_complet AS nom_cite,
		--meta_v_taxref,
		--sample_number_proof,
		--digital_proofvue,
		s.altitude_min,
		s.altitude_max,
		 s.data ->> 'commune'|| ' - ' || s.sites_group_name || ' - ' || s.sites_group_description || ' - ' || s.base_site_code as place_name,
		s.the_geom_4326,
		s.the_geom_point,
		s.geom_local as the_geom_local,
		v.date_min,
		v.date_max,
		--validator,
		--validation_comment,
		obs.observers,
		(toc.data ->> 'determiner') as determiner,
		v.id_digitiser,
		(toc.data ->> 'id_nomenclature_determination_method')::integer AS id_nomenclature_determination_method,
		--meta_validation_date,
		--meta_create_date,
		--meta_update_date,
		--last_action
		v.id_module,
		(
			'num_passage : ' || (v.data ->> 'num_passage') || 
			' | hab_1 : ' ||  COALESCE((v.data ->> 'hab_1'), '/') || 
			' | hab_2 : ' || COALESCE((v.data ->> 'hab_2'), '/') || 
			' | occ_sol : ' ||  COALESCE((v.data ->> 'occ_sol'), '/') || 
			' | vent : ' || COALESCE(ref_nomenclatures.get_nomenclature_label((v.data ->> 'id_nomenclature_vt')::integer), 'Non renseigné') || 
			' | couverture_nuageuse : ' || COALESCE(ref_nomenclatures.get_nomenclature_label((v.data ->> 'id_nomenclature_cn')::integer), 'Non renseigné') || 
			' | temperature : ' || COALESCE(ref_nomenclatures.get_nomenclature_label((v.data ->> 'id_nomenclature_tp')::integer) , 'Non renseigné') 
		) AS comment_context,
		CASE 
			WHEN v.comments IS NULL AND NOT o.comments IS NULL THEN o.comments
			WHEN NOT v.comments IS NULL AND o.comments IS NULL THEN v.comments
			ELSE v.comments || ' ' || o.comments
		END AS comment_description,
		jsonb_strip_nulls( 
			jsonb_build_object(
				'année', (v.data ->> 'annee')::integer,
				'num_passage', (v.data ->> 'num_passage')::integer,
				'hab_1', (v.data ->> 'hab_1'),
				'hab_2', (v.data ->> 'hab_2'),
				'occ_sol', (v.data ->> 'occ_sol'),
				'id_nomenclature_vt', (v.data ->>'id_nomenclature_vt')::integer, 
				'id_nomenclature_cn', (v.data ->>'id_nomenclature_cn')::integer,
				'id_nomenclature_tp', (v.data ->>'id_nomenclature_tp')::integer
			)
		) as additional_data,
		obs.ids_observers,
		-- ## Colonnes complémentaires qui ont leur utilité dans la fonction synthese.import_row_from_table
		s.id_sites_group,
		v.id_base_site,
		v.id_base_visit
	FROM gn_monitoring.t_observations o
	LEFT JOIN gn_monitoring.t_observation_complements toc USING (id_observation)
	INNER JOIN visits v
		ON v.id_base_visit = o.id_base_visit
	INNER JOIN sites s 
		ON s.id_base_site = v.id_base_site
	JOIN taxonomie.taxref t 
		ON t.cd_nom = o.cd_nom
	LEFT JOIN source 
		ON v.id_module = source.id_module
	LEFT JOIN observers obs ON obs.id_base_visit = v.id_base_visit
	WHERE extract(year from v.date_min) > 2023 OR toc.data->>'id_obs_mysql' IS NULL
	ORDER BY v.date_min ASC
	;

SELECT * FROM gn_monitoring.v_synthese_:module_code
;