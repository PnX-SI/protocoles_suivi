alter table gn_monitoring.t_base_sites alter column id_nomenclature_type_site drop not null;

-------------------------------------------------final --rhomeoflore standard------------------------------------------
-- View: gn_monitoring.v_export_rhomeoflore_standard

DROP VIEW  IF EXISTS gn_monitoring.v_export_rhomeoflore_standard;

CREATE OR REPLACE VIEW gn_monitoring.v_export_rhomeoflore_standard AS

WITH source AS (

	SELECT

        id_source

    FROM gn_synthese.t_sources
	WHERE name_source = CONCAT('MONITORING_', UPPER('RHOMEOFlore'))
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
		(sc."data"::json#>>'{num_placette}')::text AS num_placette,
		(sc."data"::json#>>'{num_transect}')::text AS num_transect,
		(sc."data"::json#>>'{desc_pente}')::text AS desc_pente,
		(sc."data"::json#>>'{expo}')::text AS expo_terrain

        FROM gn_monitoring.t_base_sites
		JOIN gn_monitoring.t_site_complements sc USING (id_base_site)


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
		(vc."data"::json#>>'{num_passage}')::int AS num_passage,
		(vc."data"::json#>>'{visit_time}')::text AS visit_time,
		ref_nomenclatures.get_nomenclature_label((vc."data"::json#>>'{id_nomenclature_physio_veg}')::int) physio_veg,
		(vc."data"::json#>>'{heigth_arbore}')::text AS heigth_arbore,
		(vc."data"::json#>>'{rcvmt_arbore}')::text AS rcvmt_arbore,
		(vc."data"::json#>>'{heigth_arbust}')::text AS heigth_arbust,
		(vc."data"::json#>>'{rcvmt_arbust}')::text AS rcvmt_arbust,
		(vc."data"::json#>>'{heigth_ssarbust}')::text AS heigth_ssarbust,
		(vc."data"::json#>>'{rcvmt_ssarbust}')::text AS rcvmt_ssarbust,
		(vc."data"::json#>>'{heigth_herbace}')::text AS heigth_herbace,
		(vc."data"::json#>>'{rcvmt_herbace}')::text AS rcvmt_herbace,
		(vc."data"::json#>>'{heigth_musci}')::text AS heigth_musci,
		(vc."data"::json#>>'{rcvmt_musci}')::text AS rcvmt_musci,
		(vc."data"::json#>>'{meteo_comment}')::text AS meteo_comment,
		(vc."data"::json#>>'{milieu_comment}')::text AS milieu_comment,
        comments

	    --o.observers,
	    --o.ids_observers,

        FROM gn_monitoring.t_base_visits
		JOIN gn_monitoring.t_visit_complements vc USING (id_base_visit)
		--JOIN ref_nomenclatures.t_nomenclatures n1 ON n1.id_nomenclature::text = (vc."data"->>'id_nomenclature_physio_veg')::text 


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
		s.num_placette,
		s.num_transect,
		s.desc_pente,
		s.expo_terrain,
		v.date_min date_visit,
		v.date_visit date_visit_last,
		v.num_passage,
		v.visit_time,
		v.physio_veg,
		v.heigth_arbore,
		v.rcvmt_arbore,
		v.heigth_arbust,
		v.rcvmt_arbust,
		v.heigth_ssarbust,
		v.rcvmt_ssarbust,
		v.heigth_herbace,
		v.rcvmt_herbace,
		v.heigth_musci,
		v.rcvmt_musci,
		v.meteo_comment,
		v.milieu_comment,
		v.comments AS comment_visit,
		id_observation,
		obs.observers,
		ref_nomenclatures.get_nomenclature_label((oc."data"::json#>>'{id_nomenclature_strate_flore}')::int) strate_flore,
		ref_nomenclatures.get_nomenclature_label((oc."data"::json#>>'{id_nomenclature_braunblanq_abdom}')::int) abdom_braunblanq,
		o.cd_nom,
		t.nom_complet AS nom_cite,
		o.comments AS comment_obs

    FROM gn_monitoring.t_observations o 
		JOIN gn_monitoring.t_observation_complements oc USING (id_observation)
		--JOIN ref_nomenclatures.t_nomenclatures n1 ON n1.id_nomenclature = (oc."data"->>'id_nomenclature_strate_flore')::int
		--JOIN ref_nomenclatures.t_nomenclatures n2 ON n2.id_nomenclature = (oc."data"->>'id_nomenclature_braunblanq_abdom')::int 
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
    WHERE m.module_code = 'RHOMEOFlore'
    ;








------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------
--					VERSION					xx/xx/2022
------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------

-- View: gn_monitoring.v_export_:module_code:_calculette
DROP VIEW  IF EXISTS gn_monitoring.v_export_rhomeoflore_calculette;

CREATE OR REPLACE VIEW gn_monitoring.v_export_rhomeoflore_calculette AS

WITH source AS (

	SELECT

        id_source

    FROM gn_synthese.t_sources
	WHERE name_source = CONCAT('MONITORING_', UPPER('RHOMEOFlore'))
	LIMIT 1

), sites AS (

    SELECT

        id_base_site,
		base_site_name,
		base_site_code,
		base_site_description,
		id_inventor,
		COALESCE (t_base_sites.meta_update_date, first_use_date) AS date_site

        FROM gn_monitoring.t_base_sites
		JOIN gn_monitoring.t_site_complements sc USING (id_base_site)


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
		ref_nomenclatures.get_cd_nomenclature((vc."data"::json#>>'{id_nomenclature_physio_veg}')::int) physio_veg,
        comments


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
)

SELECT
		
		v.id_dataset,
		s.base_site_name "trackingPoint",
		v.date_min "date",
		v.physio_veg "physionomy",
		ref_nomenclatures.get_cd_nomenclature((oc."data"::json#>>'{id_nomenclature_braunblanq_abdom}')::int) "abundance",
		CASE WHEN o.cd_nom = 127191 THEN 3833
			WHEN o.cd_nom = 5494 THEN 5493
			WHEN o.cd_nom = 74349 THEN 53027
			WHEN o.cd_nom = 627578 THEN 74344
			WHEN o.cd_nom = 447951 THEN 80198
			WHEN o.cd_nom = 447347 THEN 81013
			WHEN o.cd_nom = 159690 THEN 100411
			WHEN o.cd_nom = 103917 THEN 103918
			WHEN o.cd_nom = 107440 THEN 107439
			WHEN o.cd_nom = 115694 THEN 115695
			WHEN o.cd_nom = 448412 THEN 125332
			WHEN o.cd_nom = 614193 THEN 127394
			WHEN o.cd_nom = 521655 THEN 127982
			WHEN o.cd_nom = 611902 THEN 130874
			WHEN o.cd_nom = 133646 THEN 145901
			WHEN o.cd_nom = 106346 THEN 160436
			WHEN o.cd_nom = 81023 THEN 445752
			WHEN o.cd_nom = 134362 THEN 718810
			WHEN o.cd_nom = 88489 THEN 784898
			WHEN o.cd_nom = 133108 THEN 446608
			WHEN o.cd_nom = 106748 THEN 447425
			WHEN o.cd_nom = 96746 THEN 452604
			WHEN o.cd_nom = 124261 THEN 455742
			WHEN o.cd_nom = 108996 THEN 521641
			WHEN o.cd_nom = 106220 THEN 521676
			WHEN o.cd_nom = 717630 THEN 1000001 -- Taraxacum officinale gr.
			WHEN o.cd_nom = 134346 THEN 97434 	-- Eupatorium cannabinum L.
			WHEN o.cd_nom = 197758 THEN 128042 	-- Tussilago farfara L.
		ELSE o.cd_nom END cd_nom,
		o.comments AS remarks

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
	JOIN observers obs ON obs.id_base_visit = v.id_base_visit
    
    WHERE m.module_code = 'RHOMEOFlore'
	AND ref_nomenclatures.get_cd_nomenclature((oc."data"::json#>>'{id_nomenclature_braunblanq_abdom}')::int) <> '0'
    ;