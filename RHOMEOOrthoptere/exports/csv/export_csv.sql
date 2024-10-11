 alter table gn_monitoring.t_base_sites alter column id_nomenclature_type_site drop not null;

-------------------------------------------------final --rhomeoothoptere standard------------------------------------------
-- View: gn_monitoring.v_export_rhomeoothoptere_standard

DROP VIEW  IF EXISTS  gn_monitoring.v_export_rhomeoothoptere_standard;

CREATE OR REPLACE VIEW gn_monitoring.v_export_rhomeoothoptere_standard AS

WITH source AS (

	SELECT

        id_source,
		name_source

    FROM gn_synthese.t_sources
	WHERE name_source = CONCAT('MONITORING_', UPPER(:module_code))
	LIMIT 1

), sites AS (

    SELECT

        id_base_site,
		sg.sites_group_name,
		sg.sites_group_description,
		sg.comments sites_group_comments,
		base_site_name,
		base_site_description,
		id_inventor,
		CONCAT(tr.nom_role, ' ', tr.prenom_role) AS inventor,
		COALESCE (t_base_sites.meta_update_date, first_use_date) AS date_site,
		altitude_min,
		altitude_max,
		geom_local,
		st_x(ST_Centroid(geom)) AS wgs84_x,
		st_y(ST_Centroid(geom)) AS wgs84_y,
		st_x(ST_Centroid(geom_local)) AS l93_x,
		st_y(ST_Centroid(geom_local)) AS l93_y,
		(sc.data::json#>>'{size_maille}')::text AS site_size_maille

        FROM gn_monitoring.t_base_sites
		JOIN gn_monitoring.t_site_complements sc USING (id_base_site)
		JOIN gn_monitoring.t_sites_groups sg USING (id_sites_group)
		JOIN utilisateurs.t_roles tr ON tr.id_role = t_base_sites.id_inventor

), visits AS (
    
    SELECT
    
        id_base_visit,
        uuid_base_visit,
        id_module,
        id_base_site,
        id_dataset,
		ds.dataset_shortname,
        id_digitiser,
		CONCAT(tr.nom_role, ' ', tr.prenom_role) AS digitiser,
        visit_date_min AS date_min,
	    COALESCE (visit_date_max, visit_date_min) AS date_visit,
		((vc.data::json#>>'{heure_debut}')::text||'\:00')::time AS heure_debut,
		(vc.data::json#>>'{num_passage}')::int AS num_visit,
		(vc.data::json#>>'{temperature}')::text AS temperature,
		(vc.data::json#>>'{nebulosite}')::text AS nebulosite,
		(vc.data::json#>>'{vvent}')::text AS vvent,
        comments

	    --o.observers,
	    --o.ids_observers,

        FROM gn_monitoring.t_base_visits
		JOIN gn_monitoring.t_visit_complements vc USING (id_base_visit)
		JOIN gn_meta.t_datasets ds USING (id_dataset)
		JOIN utilisateurs.t_roles tr ON tr.id_role = t_base_visits.id_digitiser

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
		array_agg(DISTINCT n2.label_default) AS stade_vie
	FROM gn_monitoring.t_observations o
		JOIN gn_monitoring.t_observation_complements oc USING (id_observation)
			left JOIN jsonb_array_elements_text((oc.data #> '{id_nomenclature_life_stage}')||'[]') pc2(child) ON TRUE
			Left JOIN ref_nomenclatures.t_nomenclatures n2 ON n2.id_nomenclature::text = pc2.child::text
	GROUP BY 1
)

SELECT
		
        o.uuid_observation AS unique_id_sinp_obs, 
		v.uuid_base_visit AS unique_id_sinp_grp,
		o.id_observation AS entity_source_pk_value,
		source.name_source,
		v.id_dataset,
		v.dataset_shortname,
		s.sites_group_name,
		s.sites_group_description,
		s.sites_group_comments,
		s.base_site_name,
		s.base_site_description,
		s.inventor,
		s.date_site,
		s.altitude_min,
		s.altitude_max,
		s.wgs84_x,
		s.wgs84_y,
		s.l93_x,
		s.l93_y,
		s.site_size_maille,
		v.date_min date_visit,
		v.date_visit date_visit_last,
		v.heure_debut,
		v.num_visit,
		v.temperature,
		v.nebulosite,
		v.vvent,
		v.comments AS comment_visit,
		id_observation,
		obs.observers,
		o.cd_nom,
		t.nom_complet AS nom_cite,
		(oc.data::json#>>'{abondance}')::text AS abondance,
		oa.stade_vie stade_vie,
		n2.label_default occ_comportmt,
		o.comments AS comment_obs

    FROM gn_monitoring.t_observations o 
		JOIN gn_monitoring.t_observation_complements oc USING (id_observation)
		JOIN aggreg_obs oa USING (id_observation)
		--JOIN ref_nomenclatures.t_nomenclatures n1 ON n1.id_nomenclature = (oc.data->>'id_nomenclature_life_stage')::int 
		LEFT JOIN ref_nomenclatures.t_nomenclatures n2 ON n2.id_nomenclature::text = (oc.data->>'id_nomenclature_behaviour')::text
		--JOIN ref_nomenclatures.t_nomenclatures n3 ON n3.id_nomenclature = (oc.data->>'id_nomenclature_sex')::int 
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
    WHERE m.module_code = :module_code
    ;








------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------
--					VERSION					xx/xx/2022
------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------

-- View: gn_monitoring.v_export_rhomeoothoptere_calculette
DROP VIEW  IF EXISTS  gn_monitoring.v_export_rhomeoothoptere_calculette;

CREATE OR REPLACE VIEW gn_monitoring.v_export_rhomeoothoptere_calculette AS


WITH source AS (

	SELECT

        id_source

    FROM gn_synthese.t_sources
	WHERE name_source = CONCAT('MONITORING_', UPPER(:module_code))
	LIMIT 1

), sites AS (

    SELECT

        id_base_site,
		base_site_name,
		base_site_code,
		id_inventor

        FROM gn_monitoring.t_base_sites
		JOIN gn_monitoring.t_site_complements sc USING (id_base_site)



), visits AS (
    
    SELECT
    
        id_base_visit,
        id_module,
        id_base_site,
        id_dataset,
		ds.dataset_shortname,
        visit_date_min AS date_min,
	    COALESCE (visit_date_max, visit_date_min) AS date_visit,
        comments

	    --o.observers,
	    --o.ids_observers,

        FROM gn_monitoring.t_base_visits
		JOIN gn_monitoring.t_visit_complements vc USING (id_base_visit)
		JOIN gn_meta.t_datasets ds USING (id_dataset)

)

SELECT
		--v.id_dataset,
		o.cd_nom,
		TO_CHAR(v.date_visit,'DD-MM-YYYY') "date",
		o.comments AS "remarks",
		COALESCE(s.base_site_code,s.base_site_name) "trackingPoint",
		--s.base_site_code,
		--o.id_observation AS trackingPoint,
		v.id_dataset,
		v.dataset_shortname

    FROM gn_monitoring.t_observations o 
		JOIN gn_monitoring.t_observation_complements oc USING (id_observation)
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
    WHERE m.module_code = :module_code
    ;