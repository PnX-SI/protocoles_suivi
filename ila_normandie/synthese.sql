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
			LEFT JOIN gn_commons.t_modules mo ON 'MONITORING_' || UPPER(mo.module_code) = sc.name_source
			WHERE sc.name_source = CONCAT('MONITORING_', UPPER(:'module_code'))
		), 
		sites AS (
			SELECT 
				tbs.id_base_site,
				(tsg.data ->> 'id_dataset'::text)::integer AS id_dataset,
				tsg.sites_group_code,
				tsg.sites_group_name,
				tsg.sites_group_description,
				tbs.base_site_name,
				tbs.base_site_code,
				tbs.altitude_min,
				tbs.altitude_max,
				tsg.data,
				tbs.geom AS the_geom_4326,
				st_centroid(tbs.geom) AS the_geom_point,
				tbs.geom_local
			FROM gn_monitoring.t_base_sites tbs
				LEFT JOIN gn_monitoring.t_site_complements tsc USING (id_base_site)
				LEFT JOIN gn_monitoring.t_sites_groups tsg USING (id_sites_group)
				JOIN source source_1 ON tsc.id_module = source_1.id_module
		), 
		visits AS (
			SELECT 
				tbv.id_base_visit,
				tbv.uuid_base_visit,
				tbv.id_module,
				tbv.id_base_site,
				tbv.id_dataset,
				tbv.id_digitiser,
				tbv.visit_date_min AS date_min,
				COALESCE(tbv.visit_date_max, tbv.visit_date_min) AS date_max,
				tbv.comments,
				tbv.id_nomenclature_tech_collect_campanule,
				tbv.id_nomenclature_grp_typ,
				tvc.data
			FROM gn_monitoring.t_base_visits tbv
				LEFT JOIN gn_monitoring.t_visit_complements tvc USING (id_base_visit)
				JOIN source srce USING (id_module)
		), 
		observers AS (
			SELECT 
				array_agg(r.id_role) AS ids_observers,
				string_agg(concat(r.nom_role, ' ', r.prenom_role), ' ; '::text) AS observers,
				cvo.id_base_visit
			FROM gn_monitoring.cor_visit_observer cvo
			JOIN utilisateurs.t_roles r ON r.id_role = cvo.id_role
			GROUP BY cvo.id_base_visit
		)
	SELECT 
		o.uuid_observation AS unique_id_sinp,
		v.uuid_base_visit AS unique_id_sinp_grp,
		source.id_source,
		o.id_observation AS entity_source_pk_value,
		CASE
			WHEN s.id_dataset IS NULL THEN 1343
			ELSE s.id_dataset
		END AS id_dataset,
		ref_nomenclatures.get_id_nomenclature('NAT_OBJ_GEO'::character varying, 'St'::character varying) AS id_nomenclature_geo_object_nature,
    	ref_nomenclatures.get_id_nomenclature('TYP_GRP'::character varying, 'PASS'::character varying) AS id_nomenclature_grp_typ,
    	ref_nomenclatures.get_id_nomenclature('TECHNIQUE_OBS'::character varying, '59'::character varying) AS id_nomenclature_tech_collect_campanule,
		ref_nomenclatures.get_id_nomenclature('METH_OBS'::character varying, '0'::character varying) AS id_nomenclature_obs_technique,
		ref_nomenclatures.get_id_nomenclature('OBJ_DENBR'::character varying, 'IND'::character varying) AS id_nomenclature_obj_count,
		ref_nomenclatures.get_id_nomenclature('TYP_DENBR'::character varying, 'Co'::character varying) AS id_nomenclature_type_count,
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
		((s.data ->> 'commune') || ' - ' || s.sites_group_code || ' - '|| s.sites_group_name || ' - ' || s.base_site_code ) AS place_name,
		s.the_geom_4326,
		s.the_geom_point,
		s.geom_local AS the_geom_local,
		v.date_min,
		v.date_max,
		obs.observers,
   		obs.observers AS determiner,
		v.id_digitiser,
		(toc.data ->> 'id_nomenclature_determination_method'::text)::integer AS id_nomenclature_determination_method,
		v.id_module,
		(
			'num_passage : ' || (v.data ->> 'num_passage'::text)
			|| ' | habitat : ' || COALESCE((v.data ->> 'habitat'), '/') 
			|| ' | gestion : '|| COALESCE((v.data ->> 'gestion'), '/') 
			|| ' | impact : ' || COALESCE((v.data ->> 'impact'), '/')
			|| ' | vent : ' || ref_nomenclatures.get_nomenclature_label((v.data ->> 'id_nomenclature_vt')::integer)
			|| ' | couverture_nuageuse : ' || ref_nomenclatures.get_nomenclature_label((v.data ->> 'id_nomenclature_cn')::integer) 
			|| ' | temperature : ' || ref_nomenclatures.get_nomenclature_label((v.data ->> 'id_nomenclature_tp')::integer)
		) AS comment_context,
		CASE
			WHEN v.comments IS NULL AND NOT o.comments IS NULL THEN o.comments
			WHEN NOT v.comments IS NULL AND o.comments IS NULL THEN v.comments
			ELSE v.comments || ' ' || o.comments
		END AS comment_description,
		jsonb_strip_nulls(
			jsonb_build_object(
				'annee', (v.data ->> 'annee'::text)::integer, 
				'num_passage', (v.data ->> 'num_passage'::text)::integer, 
				'habitat', v.data ->> 'habitat', 
				'gestion', v.data ->> 'gestion', 
				'impact', v.data ->> 'impact',
				'id_nomenclature_vt', (v.data ->>'id_nomenclature_vt')::integer, 
				'id_nomenclature_cn', (v.data ->>'id_nomenclature_cn')::integer,
				'id_nomenclature_tp', (v.data ->>'id_nomenclature_tp')::integer
			)
		) AS additional_data,
		obs.ids_observers,
		v.id_base_site,
		v.id_base_visit
	FROM gn_monitoring.t_observations o
		LEFT JOIN gn_monitoring.t_observation_complements toc USING (id_observation)
		INNER JOIN visits v ON v.id_base_visit = o.id_base_visit
		JOIN sites s ON s.id_base_site = v.id_base_site
		JOIN taxonomie.taxref t ON t.cd_nom = o.cd_nom
		JOIN source ON v.id_module = source.id_module
		LEFT JOIN observers obs ON obs.id_base_visit = v.id_base_visit
  WHERE date_part('year'::text, v.date_min) > 2023::double precision OR toc.data->>'id_obs_mysql' IS NULL
  ORDER BY v.date_min ASC
;

SELECT * FROM gn_monitoring.v_synthese_:module_code