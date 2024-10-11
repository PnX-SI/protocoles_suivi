alter table gn_monitoring.t_base_sites alter column id_nomenclature_type_site drop not null;

-------------------------------------------------final --phytosociologique standard------------------------------------------
-- View: gn_monitoring.v_export_phytosociologique_standard

DROP VIEW  IF EXISTS gn_monitoring.v_export_suivi_phytosocio_standard;

CREATE OR REPLACE VIEW gn_monitoring.v_export_suivi_phytosocio_standard AS

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
		sg.sites_group_code,
		sg.sites_group_description,
		base_site_name,
		base_site_description,
		id_inventor,
		CONCAT(r.nom_role, ' ', prenom_role) inventor,
		COALESCE (t_base_sites.meta_update_date, first_use_date) AS date_site,
		altitude_min,
		altitude_max,
		geom_local,
		st_x(ST_Centroid(geom)) AS wgs84_x,
		st_y(ST_Centroid(geom))AS wgs84_y,
		st_x(ST_Centroid(geom_local)) AS l93_x,
		st_y(ST_Centroid(geom_local))AS l93_y,
		(sc."data"::json#>>'{num_placette}')::text AS num_placette,
		(sc."data"::json#>>'{num_transect}')::text AS num_transect

        FROM gn_monitoring.t_base_sites
		JOIN gn_monitoring.t_site_complements sc USING (id_base_site)
		LEFT JOIN gn_monitoring.t_sites_groups sg USING (id_sites_group)
    	JOIN utilisateurs.t_roles r ON  id_inventor = r.id_role


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
		(vc."data"::json#>>'{type_placette}')::text AS type_placette,
		(vc."data"::json#>>'{surf_releve}')::text AS surf_releve,
		ref_nomenclatures.get_nomenclature_label((vc."data"::json#>>'{id_nomenclature_physio_veg}')::int) physio_veg,
		(vc."data"::json#>>'{rcvmt_arbore}')::text AS rcvmt_arbore,
		(vc."data"::json#>>'{rcvmt_arbust}')::text AS rcvmt_arbust,
		(vc."data"::json#>>'{rcvmt_ssarbust}')::text AS rcvmt_ssarbust,
		(vc."data"::json#>>'{rcvmt_herbace}')::text AS rcvmt_herbace,
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
		o.id_observation AS entity_source_pk_value,
		source.name_source,
		t_fram.acquisition_framework_name,
		meta.dataset_name,
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
		s.num_placette,
		s.num_transect,
		v.date_min date_visit,
		v.date_visit date_visit_last,
		v.num_passage,
		v.visit_time,
		v.type_placette,
		v.surf_releve,
		v.physio_veg,
		v.rcvmt_arbore,
		v.rcvmt_arbust,
		v.rcvmt_ssarbust,
		v.rcvmt_herbace,
		v.rcvmt_musci,
		v.meteo_comment,
		v.milieu_comment,
		v.comments AS comment_visit,
		o.cd_nom,
		t.nom_complet AS nom_cite,
		obs.observers,
		ref_nomenclatures.get_nomenclature_label((oc."data"::json#>>'{id_nomenclature_strate_flore}')::int) strate_flore,
		ref_nomenclatures.get_nomenclature_label((oc."data"::json#>>'{id_nomenclature_stade_pheno}')::int) phenologie,
		(oc."data"::json#>>'{nb_pieds}')::int nb_pieds,
		ref_nomenclatures.get_nomenclature_label((oc."data"::json#>>'{id_nomenclature_braunblanq_abdom}')::int) abdom_braunblanq,
		o.comments AS comment_obs

    FROM gn_monitoring.t_observations o 
		JOIN gn_monitoring.t_observation_complements oc USING (id_observation)
    JOIN visits v
        ON v.id_base_visit = o.id_base_visit
    JOIN gn_meta.t_datasets meta
        ON v.id_dataset = meta.id_dataset
	JOIN gn_meta.t_acquisition_frameworks t_fram
		USING (id_acquisition_framework)
    JOIN sites s 
        ON s.id_base_site = v.id_base_site
	JOIN gn_commons.t_modules m 
        ON m.id_module = v.id_module
	JOIN taxonomie.taxref t 
        ON t.cd_nom = o.cd_nom
	JOIN source 
        ON TRUE
	JOIN observers obs ON obs.id_base_visit = v.id_base_visit
    
    WHERE m.module_code = :module_code
    ;








------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------
--					VERSION					xx/xx/2022
------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------
