 alter table gn_monitoring.t_base_sites alter column id_nomenclature_type_site drop not null;

-------------------------------------------------final --rhomeoamphibien standard------------------------------------------
-- View: gn_monitoring.v_export_rhomeoamphibien_standard

DROP VIEW  IF EXISTS  gn_monitoring.v_export_rhomeoamphibien_standard;

CREATE OR REPLACE VIEW gn_monitoring.v_export_rhomeoamphibien_standard AS

WITH source AS (

	SELECT

        id_source

    FROM gn_synthese.t_sources
	WHERE name_source = CONCAT('MONITORING_', UPPER('RHOMEOAmphibien'))
	LIMIT 1

), sites AS ( 
	WITH inventor AS (
		SELECT
			array_agg(r.id_role) AS ids_observers,
			STRING_AGG(CONCAT(r.nom_role, ' ', prenom_role), ' ; ') AS auteur_site,
			id_base_site
		FROM gn_monitoring.t_base_sites tbo
		JOIN utilisateurs.t_roles r ON r.id_role = tbo.id_inventor
		GROUP BY id_base_site
	)
    SELECT
		uuid_base_site,
        id_base_site,
		base_site_name,
		base_site_code,
		base_site_description,
		i.auteur_site,
		COALESCE (t_base_sites.meta_update_date, first_use_date) AS date_site,
		altitude_min,
		altitude_max,
		geom_local,
		st_x(ST_Centroid(geom)) AS wgs84_x,
		st_y(ST_Centroid(geom)) AS wgs84_y,
		st_x(ST_Centroid(geom_local)) AS l93_x,
		st_y(ST_Centroid(geom_local)) AS l93_y,
		(sc.data::json#>>'{ombrage}')::text AS ombrage,
		(SELECT 
		 	array_agg(ref_nomenclatures.get_nomenclature_label(sub2.val2::int))
			FROM (SELECT jsonb_array_elements(sb.val) val2 FROM (VALUES (sc."data"#>'{substrat}')) as sb(val)
		) as sub2) substrat,
		--STRING_AGG(n6.label_fr,' ; ') AS substrat,
		ref_nomenclatures.get_nomenclature_label((sc.data::json#>>'{fuite_eau}')::int) fuite_eau,
		ref_nomenclatures.get_nomenclature_label((sc.data::json#>>'{origine_eau}')::int) origine_eau,
		ref_nomenclatures.get_nomenclature_label((sc.data::json#>>'{context_pays}')::int) context_pays,
		ref_nomenclatures.get_nomenclature_label((sc.data::json#>>'{prospect_typo}')::int) prospect_typo,
		ref_nomenclatures.get_nomenclature_label((sc.data::json#>>'{prospect_form}')::int) prospect_form,
		(sc.data::json#>>'{type_pente}')::text AS type_pente,
		(sc.data::json#>>'{profondeur_maxi}')::text AS profondeur_maxi,
		(sc.data::json#>>'{esp_veget}')::text AS esp_veget,
		(sc.data::json#>>'{esp_poisson}')::text AS esp_poisson,
		(sc.data::json#>>'{esp_ecrevisse}')::text AS esp_ecrevisse

        FROM gn_monitoring.t_base_sites
		JOIN inventor i USING (id_base_site)
		JOIN gn_monitoring.t_site_complements sc USING (id_base_site)
		LEFT JOIN utilisateurs.t_roles r ON r.id_role = t_base_sites.id_inventor 

), visits AS (
    
    SELECT
    
        id_base_visit,
        uuid_base_visit,
        id_module,
        id_base_site,
        id_dataset,
        id_digitiser,
		vd.dataset_shortname,
        visit_date_min AS date_min,
	    COALESCE (visit_date_max, visit_date_min) AS date_visit,
		((vc.data::json#>>'{Heure_debut}')::text||'\:00')::time AS heure_debut,
		(vc.data::json#>>'{num_passage}')::int AS num_visit,
		(vc.data::json#>>'{surf_eau}')::text AS surf_eau_m2,
		(vc.data::json#>>'{color_eau}')::text AS color_eau,
		ref_nomenclatures.get_nomenclature_label((vc.data::json#>>'{transparence_eau}')::int )AS transparence_eau,
		--n1.label_fr transparence_eau,
        comments

	    --o.observers,
	    --o.ids_observers,

        FROM gn_monitoring.t_base_visits
		JOIN gn_monitoring.t_visit_complements vc USING (id_base_visit)
		JOIN gn_meta.t_datasets vd USING (id_dataset)
		--LEFT JOIN ref_nomenclatures.t_nomenclatures n1 ON n1.id_nomenclature::text = (vc.data->>'transparence_eau')::text 

), observers AS (
    SELECT
        array_agg(r.id_role) AS ids_observers,
        STRING_AGG(CONCAT(r.nom_role, ' ', prenom_role), ' ; ') AS observers,
        id_base_visit
    FROM gn_monitoring.cor_visit_observer cvo
    JOIN utilisateurs.t_roles r ON r.id_role = cvo.id_role
    GROUP BY id_base_visit

)

SELECT
		
        o.uuid_observation AS unique_id_sinp_value, 
		v.uuid_base_visit AS unique_id_sinp_visit,
		s.uuid_base_site AS unique_id_sinp_site,
		o.id_observation AS entity_source_pk_value,
		v.id_dataset,
		v.dataset_shortname,

		s.id_base_site,
		s.base_site_name,
		s.base_site_code,
		s.base_site_description,
		s.auteur_site,
		s.date_site,
		s.altitude_min,
		s.altitude_max,
		s.geom_local as the_geom_local,
		s.wgs84_x,
		s.wgs84_y,
		s.l93_x,
		s.l93_y,
		s.ombrage,
		s.substrat,
		s.fuite_eau,
		s.origine_eau,
		s.context_pays,
		s.prospect_typo,
		s.prospect_form,
		s.type_pente,
		s.profondeur_maxi,
		s.esp_veget,
		s.esp_poisson,
		s.esp_ecrevisse,
		v.id_base_visit,
		v.uuid_base_visit,
		v.date_min,
		v.date_visit,
		v.heure_debut,
		v.num_visit,
		v.surf_eau_m2,
		v.color_eau,
		v.transparence_eau,
		v.comments AS comment_visit,
		obs.observers,
		t.cd_nom,
		t.nom_complet AS nom_cite,
		CASE WHEN (oc.data->>'nombre_compte') IS NULL THEN SPLIT_PART(REPLACE((oc.data->>'nombre')::text,'> ','')::text,' à ',1)::int
			ELSE (oc.data->>'nombre_compte')::int
		END AS count_min,
		CASE WHEN (oc.data->>'nombre_compte') IS NULL THEN 
			CASE WHEN SPLIT_PART(REPLACE((oc.data->>'nombre')::text,'> ','')::text,' à ',2) = '' THEN 9999
				ELSE SPLIT_PART(REPLACE((oc.data->>'nombre')::text,'> ','')::text,' à ',2)::int
			END
			ELSE (oc.data->>'nombre_compte')::int
		END AS count_max,
		(oc.data::json#>>'{typ_detection}')::text AS detection,
		(oc.data::json#>>'{duree_peche}')::text AS duree_peche,
		ref_nomenclatures.get_nomenclature_label((oc.data ->> 'id_nomenclature_life_stage'::text)::int) stade_vie,
		o.comments AS comment_obs

    FROM gn_monitoring.t_observations o 
		JOIN gn_monitoring.t_observation_complements oc USING (id_observation)
		--LEFT JOIN ref_nomenclatures.t_nomenclatures n_stade ON n_stade.id_nomenclature = (oc.data->>'id_nomenclature_stade')::int 
    JOIN visits v
        ON v.id_base_visit = o.id_base_visit
    JOIN sites s 
        ON s.id_base_site = v.id_base_site
	JOIN gn_commons.t_modules m 
        ON m.id_module = v.id_module
	JOIN taxonomie.taxref t 
        ON t.cd_nom = o.cd_nom
	JOIN source 
        ON TRUE
	JOIN observers obs ON obs.id_base_visit = v.id_base_visit
    
 	LEFT JOIN LATERAL ref_geo.fct_get_altitude_intersection(s.geom_local) alt (altitude_min, altitude_max)
        ON TRUE
    WHERE m.module_code = 'RHOMEOAmphibien'
    ;








------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------
--					VERSION					xx/xx/2022
------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------

-- View: gn_monitoring.v_export_rhomeoamphibien_calculette

DROP VIEW  IF EXISTS  gn_monitoring.v_export_rhomeoamphibien_calculette;

CREATE OR REPLACE VIEW gn_monitoring.v_export_rhomeoamphibien_calculette AS

WITH source AS (

	SELECT

        id_source

    FROM gn_synthese.t_sources
	WHERE name_source = CONCAT('MONITORING_', UPPER('RHOMEOAmphibien'))
	LIMIT 1

), sites AS ( 
	WITH inventor AS (
		SELECT
			array_agg(r.id_role) AS ids_observers,
			STRING_AGG(CONCAT(r.nom_role, ' ', prenom_role), ' ; ') AS auteur_site,
			id_base_site
		FROM gn_monitoring.t_base_sites tbo
		JOIN utilisateurs.t_roles r ON r.id_role = tbo.id_inventor
		GROUP BY id_base_site
	)
    SELECT
		uuid_base_site,
        id_base_site,
		base_site_name,
		base_site_code
		--base_site_description,
		--i.auteur_site,
		--COALESCE (t_base_sites.meta_update_date, first_use_date) AS date_site,
		--altitude_min,
		--altitude_max,
		--geom_local,
		--st_x(ST_Centroid(geom)) AS wgs84_x,
		--st_y(ST_Centroid(geom)) AS wgs84_y,
		--st_x(ST_Centroid(geom_local)) AS l93_x,
		--st_y(ST_Centroid(geom_local)) AS l93_y,
		--(sc.data::json#>>'{ombrage}')::text AS ombrage,
		--(SELECT 
		-- 	array_agg(ref_nomenclatures.get_nomenclature_label(sub2.val2::int))
		--	FROM (SELECT jsonb_array_elements(sb.val) val2 FROM (VALUES (sc."data"#>'{substrat}')) as sb(val)
		--) as sub2) substrat,
		--STRING_AGG(n6.label_fr,' ; ') AS substrat,
		--ref_nomenclatures.get_nomenclature_label((sc.data::json#>>'{fuite_eau}')::int) fuite_eau,
		--ref_nomenclatures.get_nomenclature_label((sc.data::json#>>'{origine_eau}')::int) origine_eau,
		--ref_nomenclatures.get_nomenclature_label((sc.data::json#>>'{context_pays}')::int) context_pays,
		--ref_nomenclatures.get_nomenclature_label((sc.data::json#>>'{prospect_typo}')::int) prospect_typo,
		--ref_nomenclatures.get_nomenclature_label((sc.data::json#>>'{prospect_form}')::int) prospect_form,
		--(sc.data::json#>>'{type_pente}')::text AS type_pente,
		--(sc.data::json#>>'{profondeur_maxi}')::text AS profondeur_maxi,
		--(sc.data::json#>>'{esp_veget}')::text AS esp_veget,
		--(sc.data::json#>>'{esp_poisson}')::text AS esp_poisson,
		--(sc.data::json#>>'{esp_ecrevisse}')::text AS esp_ecrevisse

        FROM gn_monitoring.t_base_sites
		JOIN inventor i USING (id_base_site)
		JOIN gn_monitoring.t_site_complements sc USING (id_base_site)
		LEFT JOIN utilisateurs.t_roles r ON r.id_role = t_base_sites.id_inventor 

), visits AS (
    
    SELECT
    
        id_base_visit,
        --uuid_base_visit,
        id_module,
        id_base_site,
        id_dataset,
        --id_digitiser,
		--vd.dataset_shortname,
        visit_date_min AS date_min,
	    --COALESCE (visit_date_max, visit_date_min) AS date_visit,
		--((vc.data::json#>>'{Heure_debut}')::text||'\:00')::time AS heure_debut,
		--(vc.data::json#>>'{num_passage}')::int AS num_visit,
		--(vc.data::json#>>'{surf_eau}')::text AS surf_eau_m2,
		--(vc.data::json#>>'{color_eau}')::text AS color_eau,
		ref_nomenclatures.get_nomenclature_label((vc.data::json#>>'{transparence_eau}')::int )AS transparence_eau,
		--n1.label_fr transparence_eau,
        comments

	    --o.observers,
	    --o.ids_observers,

        FROM gn_monitoring.t_base_visits
		JOIN gn_monitoring.t_visit_complements vc USING (id_base_visit)
		JOIN gn_meta.t_datasets vd USING (id_dataset)
		--LEFT JOIN ref_nomenclatures.t_nomenclatures n1 ON n1.id_nomenclature::text = (vc.data->>'transparence_eau')::text 

), observers AS (
    SELECT
        array_agg(r.id_role) AS ids_observers,
        STRING_AGG(CONCAT(r.nom_role, ' ', prenom_role), ' ; ') AS observers,
        id_base_visit
    FROM gn_monitoring.cor_visit_observer cvo
    JOIN utilisateurs.t_roles r ON r.id_role = cvo.id_role
    GROUP BY id_base_visit

)

SELECT
		
        --o.uuid_observation AS unique_id_sinp_value, 
		--v.uuid_base_visit AS unique_id_sinp_visit,
		--s.uuid_base_site AS unique_id_sinp_site,
		--o.id_observation AS entity_source_pk_value,
		--v.id_dataset,
		--v.dataset_shortname,

		--s.id_base_site,
		COALESCE(s.base_site_code,s.base_site_name) "trackingPoint",
		
		--s.base_site_description,
		--s.auteur_site,
		--s.date_site,
		--s.altitude_min,
		--s.altitude_max,
		--s.geom_local as the_geom_local,
		--s.wgs84_x,
		--s.wgs84_y,
		--s.l93_x,
		--s.l93_y,
		--s.ombrage,
		--s.substrat,
		--s.fuite_eau,
		--s.origine_eau,
		--s.context_pays,
		--s.prospect_typo,
		--s.prospect_form,
		--s.type_pente,
		--s.profondeur_maxi,
		--s.esp_veget,
		--s.esp_poisson,
		--s.esp_ecrevisse,
		--v.id_base_visit,
		--v.uuid_base_visit,
		v.date_min "date",
		--v.date_visit,
		--v.heure_debut,
		--v.num_visit,
		--v.surf_eau_m2,
		--v.color_eau,
		--v.transparence_eau,
		--v.comments AS comment_visit,
		--obs.observers,
		CASE WHEN t.cd_nom = 92 THEN 99
			WHEN t.cd_nom = 351 THEN 301
		ELSE t.cd_nom END cd_nom,
		--t.nom_complet AS nom_cite,
		--CASE WHEN (oc.data->>'nombre_compte') IS NULL THEN SPLIT_PART(REPLACE((oc.data->>'nombre')::text,'> ','')::text,' à ',1)::int
		--	ELSE (oc.data->>'nombre_compte')::int
		--END AS count_min,
		CASE WHEN (oc.data->>'nombre_compte') IS NULL THEN 
			CASE WHEN (oc.data->>'nombre')::text = '11 à 50' THEN 25::int
				WHEN (oc.data->>'nombre')::text = '51 à 500' THEN 250::int
				WHEN (oc.data->>'nombre')::text = '> 500' THEN 500::int
			END
			ELSE (oc.data->>'nombre_compte')::int
		END AS "number",
		--(oc.data::json#>>'{typ_detection}')::text AS detection,
		--(oc.data::json#>>'{duree_peche}')::text AS duree_peche,
		--ref_nomenclatures.get_nomenclature_label((oc.data ->> 'id_nomenclature_life_stage'::text)::int) stade_vie,
		o.comments AS remarks,
		v.id_dataset

    FROM gn_monitoring.t_observations o 
		JOIN gn_monitoring.t_observation_complements oc USING (id_observation)
		--LEFT JOIN ref_nomenclatures.t_nomenclatures n_stade ON n_stade.id_nomenclature = (oc.data->>'id_nomenclature_stade')::int 
    JOIN visits v
        ON v.id_base_visit = o.id_base_visit
    JOIN sites s 
        ON s.id_base_site = v.id_base_site
	JOIN gn_commons.t_modules m 
        ON m.id_module = v.id_module
	JOIN taxonomie.taxref t 
        ON t.cd_nom = o.cd_nom
	JOIN source 
        ON TRUE
	--JOIN observers obs ON obs.id_base_visit = v.id_base_visit
    
 	-- LEFT JOIN LATERAL ref_geo.fct_get_altitude_intersection(s.geom_local) alt (altitude_min, altitude_max)
    --     ON TRUE
    WHERE m.module_code = 'RHOMEOAmphibien'
    ;
