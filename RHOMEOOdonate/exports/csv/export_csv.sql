 
-------------------------------------------------final --rhomeoodonate standard------------------------------------------
-- View: gn_monitoring.v_export_rhomeoodonate_standard

DROP VIEW  IF EXISTS  gn_monitoring.v_export_rhomeoodonate_standard;

CREATE OR REPLACE VIEW gn_monitoring.v_export_rhomeoodonate_standard AS

WITH source AS (

	SELECT

        id_source

    FROM gn_synthese.t_sources
	WHERE name_source = CONCAT('MONITORING_', UPPER('RHOMEOOdonate'))
	LIMIT 1

), sites AS (

    SELECT

        id_base_site,
		base_site_name,
		base_site_code,
		base_site_description,
		id_inventor,
		COALESCE (t_base_sites.meta_update_date, first_use_date) AS date_site,
		altitude_min,
		altitude_max,
		geom_local,
		st_x(ST_Centroid(geom)) AS wgs84_x,
		st_y(ST_Centroid(geom))AS wgs84_y,
		st_x(ST_Centroid(geom_local)) AS l93_x,
		st_y(ST_Centroid(geom_local))AS l93_y,
		(sc.data::json#>>'{typ_geom}')::text AS typ_geom,
		(sc.data::json#>>'{surf_obs}')::text AS surf_obs,
		(sc.data::json#>>'{area_name}')::text AS area_name,
		n1.label_fr hab_odo,
		(sc.data::json#>>'{detail_hab_odo}')::text AS detail_hab_odo

        FROM gn_monitoring.t_base_sites
		JOIN gn_monitoring.t_site_complements sc USING (id_base_site)
		JOIN ref_nomenclatures.t_nomenclatures n1 ON n1.id_nomenclature::text = (sc.data->>'id_nomenclature_hab_odo')::text 



), visits AS (
    
    SELECT
    
        id_base_visit,
        uuid_base_visit,
        id_module,
        id_base_site,
        id_dataset,
        id_digitiser,
        visit_date_min AS date_min,
	    COALESCE (visit_date_max, visit_date_min) AS date_visit,
		((vc.data::json#>>'{heure_debut}')::text||'\:00')::time AS heure_debut,
		(vc.data::json#>>'{num_passage}')::int AS num_visit,
		(vc.data::json#>>'{visit_time}')::text AS visit_time,
		(vc.data::json#>>'{exuvie_exist}')::text AS exuvie_exist,
		(vc.data::json#>>'{temperature}')::text AS temperature,
		(vc.data::json#>>'{nebulosite}')::text AS nebulosite,
		(vc.data::json#>>'{vvent}')::text AS vvent,
        comments

	    --o.observers,
	    --o.ids_observers,

        FROM gn_monitoring.t_base_visits
		JOIN gn_monitoring.t_visit_complements vc USING (id_base_visit)

), observers AS (
    SELECT
        array_agg(r.id_role) AS ids_observers,
        STRING_AGG(CONCAT(r.nom_role, ' ', prenom_role), ' ; ') AS observers,
        id_base_visit
    FROM gn_monitoring.cor_visit_observer cvo
    JOIN utilisateurs.t_roles r
    ON r.id_role = cvo.id_role
    GROUP BY id_base_visit
), aggreg_obs AS (
	SELECT 
		oc.id_observation,
		array_agg(DISTINCT n2.label_default) AS stade_vie,
		array_agg(n1.label_default) AS occ_comportmt
	FROM gn_monitoring.t_observations o
		JOIN gn_monitoring.t_observation_complements oc USING (id_observation)
			left JOIN jsonb_array_elements_text((oc.data #> '{id_nomenclature_life_stage}')||'[]') pc2(child) ON TRUE
			Left JOIN ref_nomenclatures.t_nomenclatures n2 ON n2.id_nomenclature::text = pc2.child::text
			LEFT JOIN jsonb_array_elements_text((oc.data #> '{id_nomenclature_behaviour}')||'[]') pc1(child) ON TRUE
			left JOIN ref_nomenclatures.t_nomenclatures n1 ON n1.id_nomenclature::text = pc1.child::text
	GROUP BY 1
)

SELECT
		
        o.uuid_observation AS unique_id_sinp, 
		v.uuid_base_visit AS unique_id_sinp_grp,
		source.id_source,
		o.id_observation AS entity_source_pk_value,
		v.id_dataset,

		s.id_base_site,
		s.base_site_name,
		s.base_site_code,
		s.base_site_description,
		s.id_inventor,
		s.date_site,
		s.altitude_min,
		s.altitude_max,
		s.wgs84_x,
		s.wgs84_y,
		s.l93_x,
		s.l93_y,
		s.typ_geom,
		s.surf_obs,
		s.area_name,
		s.hab_odo,
		s.detail_hab_odo,
		v.date_min date_visit,
		v.date_visit date_visit_last,
		v.heure_debut,
		v.num_visit,
		v.visit_time,
		v.exuvie_exist,
		v.temperature,
		v.nebulosite,
		v.vvent,
		v.comments AS comment_visit,
		id_observation,
		o.cd_nom,
		t.nom_complet AS nom_cite,
		obs.observers,
		CASE WHEN (oc.data->>'nombre_compte') IS NULL THEN SPLIT_PART(REPLACE((oc.data->>'nombre')::text,'> ','')::text,' à ',1)::int
			ELSE (oc.data->>'nombre_compte')::int
		END AS count_min,
		CASE WHEN (oc.data->>'nombre_compte') IS NULL THEN 
			CASE WHEN SPLIT_PART(REPLACE((oc.data->>'nombre')::text,'> ','')::text,' à ',2) = '' THEN 9999
				ELSE SPLIT_PART(REPLACE((oc.data->>'nombre')::text,'> ','')::text,' à ',2)::int
			END
			ELSE (oc.data->>'nombre_compte')::int
		END AS count_max,
		(oc.data::json#>>'{nb_adulte}')::text AS nb_adulte,
		oa.stade_vie stade_vie,
		oa.occ_comportmt occ_comportmt,
		n3.label_default sexe,
		(oc.data::json#>>'{nb_exuvie}')::text AS nb_exuvie,
		CASE WHEN (oc."data"->>'num_tranche')::int = 0 THEN 6
			WHEN (oc."data"->>'num_tranche') IS NULL THEN NULL
			ELSE 6 + 2 * (oc."data"->>'num_tranche')::int END AS tranche,
		o.comments AS comment_obs

    FROM gn_monitoring.t_observations o 
		JOIN gn_monitoring.t_observation_complements oc USING (id_observation)
		JOIN aggreg_obs oa USING (id_observation)
		--JOIN ref_nomenclatures.t_nomenclatures n1 ON n1.id_nomenclature = (oc.data->>'id_nomenclature_life_stage')::int 
		--JOIN ref_nomenclatures.t_nomenclatures n2 ON n2.id_nomenclature = (oc.data->>'id_nomenclature_behaviour')::int 
		JOIN ref_nomenclatures.t_nomenclatures n3 ON n3.id_nomenclature = (oc.data->>'id_nomenclature_sex')::int 
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
    WHERE m.module_code = 'RHOMEOOdonate'
    ;








------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------
--					VERSION					xx/xx/2022
------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------

-- View: gn_monitoring.v_export_rhomeoodonate_calculette
DROP VIEW  IF EXISTS  gn_monitoring.v_export_rhomeoodonate_calculette;

CREATE OR REPLACE VIEW gn_monitoring.v_export_rhomeoodonate_calculette AS


WITH source AS (

	SELECT

        id_source

    FROM gn_synthese.t_sources
	WHERE name_source = CONCAT('MONITORING_', UPPER('RHOMEOOdonate'))
	LIMIT 1

), sites AS (

    SELECT

        id_base_site,
		base_site_name,
		base_site_code,
		id_inventor,
		n1.cd_nomenclature habitat

        FROM gn_monitoring.t_base_sites
		JOIN gn_monitoring.t_site_complements sc USING (id_base_site)
		JOIN ref_nomenclatures.t_nomenclatures n1 ON n1.id_nomenclature::text = (sc.data->>'id_nomenclature_hab_odo')::text 



), visits AS (
    
    SELECT
    
        id_base_visit,
        id_module,
        id_base_site,
        id_dataset,
        visit_date_min AS date_min,
	    COALESCE (visit_date_max, visit_date_min) AS date_visit,
        comments

	    --o.observers,
	    --o.ids_observers,

        FROM gn_monitoring.t_base_visits
		JOIN gn_monitoring.t_visit_complements vc USING (id_base_visit)

), aggreg_obs AS (
	WITH agg1 as (
		SELECT 
			oc.id_observation,
				replace(replace(replace(replace(replace(replace(replace(replace(replace(
						unnest(array[n3.label_default,n2.label_default,n1.label_default]),
					'Mixte','2'),
					'Tandem','3'),
					'Territorial','4'),
					'Accouplement','5'),
					'Pond','6'),
					'Immature','7'),
					'Emergent','8'),
					'Non renseigné','1'),
					'Indéterminé','1')::int
				 AS comportement
		FROM gn_monitoring.t_observations o
			JOIN gn_monitoring.t_observation_complements oc USING (id_observation)
				left JOIN jsonb_array_elements_text((oc.data #> '{id_nomenclature_life_stage}')||'[]') pc2(child) ON TRUE
				Left JOIN ref_nomenclatures.t_nomenclatures n2 ON n2.id_nomenclature::text = pc2.child::text
				LEFT JOIN jsonb_array_elements_text((oc.data #> '{id_nomenclature_behaviour}')||'[]') pc1(child) ON TRUE
				left JOIN ref_nomenclatures.t_nomenclatures n1 ON n1.id_nomenclature::text = pc1.child::text
				LEFT JOIN ref_nomenclatures.t_nomenclatures n3 ON n3.id_nomenclature = (oc.data->>'id_nomenclature_sex')::int 
		WHERE n3.label_default NOT IN ('Mâle','Femelle')-- AND n3.label_default <> 'Femelle'
		--GROUP BY 1
	)
	SELECT 
		id_observation, 
		CASE WHEN max(comportement) IS NULL THEN 1
		ELSE max(comportement) END comportement 
	FROM agg1 GROUP BY 1
)

SELECT
		--v.id_dataset,
		oa.comportement::varchar "behavior",
		CASE WHEN o.cd_nom = 653286 THEN 65169
			WHEN o.cd_nom = 653281 THEN 65088
		ELSE o.cd_nom END cd_nom,
		TO_CHAR(v.date_visit,'DD-MM-YYYY') "date",
		s.habitat,
		o.comments AS "remarks",
		COALESCE(s.base_site_code,s.base_site_name) "trackingPoint",
		--s.base_site_code,
		--o.id_observation AS trackingPoint,
		v.id_dataset

    FROM gn_monitoring.t_observations o 
		JOIN gn_monitoring.t_observation_complements oc USING (id_observation)
		JOIN aggreg_obs oa USING (id_observation)
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
    WHERE m.module_code = 'RHOMEOOdonate'
    ;