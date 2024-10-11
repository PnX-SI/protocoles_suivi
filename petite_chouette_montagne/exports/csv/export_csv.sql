-------------------------------------------------final --petite_chouette_montagne standard------------------------------------------
-- View: gn_monitoring.v_export_petite_chouette_montagne_standard
-- DECLARE _v_export_ := v_export_:module_code;
-- DECLARE 

DROP VIEW IF EXISTS gn_monitoring.v_export_petite_chouette_montagne_standard;

CREATE OR REPLACE VIEW gn_monitoring.v_export_petite_chouette_montagne_standard AS

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
		sg.comments sites_group_comments,
		base_site_name,
		base_site_description,
		id_inventor,
		CONCAT(r.nom_role, ' ', prenom_role) inventor,
		COALESCE (t_base_sites.meta_update_date, first_use_date) AS date_site,
		altitude_min,
		geom_local,
		st_x(ST_Centroid(geom)) AS wgs84_x,
		st_y(ST_Centroid(geom))AS wgs84_y,
		st_x(ST_Centroid(geom_local)) AS l93_x,
		st_y(ST_Centroid(geom_local))AS l93_y,
		comments

        FROM gn_monitoring.t_base_sites
		JOIN gn_monitoring.t_site_complements sc USING (id_base_site)
		LEFT JOIN gn_monitoring.t_sites_groups sg USING (id_sites_group)
    	JOIN utilisateurs.t_roles r ON  id_inventor = r.id_role


), visits AS (
    
    SELECT
    
        id_dataset,
        id_base_visit,
        uuid_base_visit,
        id_module,
        id_base_site,
        id_digitiser,
        visit_date_min AS date_min,
	    COALESCE (visit_date_max, visit_date_min) AS date_visit,
        ref_nomenclatures.get_nomenclature_label((vc."data"::json#>>'{device_repasse}')::int) device_repasse,
		(vc."data"::json#>>'{fructif_fragus}')::text AS fructif_fragus,
		(vc."data"::json#>>'{time_sunset}')::text AS time_sunset,
		(vc."data"::json#>>'{etat_vent}')::text AS etat_vent,
		(vc."data"::json#>>'{etat_ciel}')::text AS etat_ciel,
		(vc."data"::json#>>'{neige}')::text AS neige,
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

		o.id_observation AS "Identifiant unique universel de l'observation",
		meta.dataset_name "Jeux de données",
		CASE WHEN t_roles.nom_role IS NULL AND t_roles.prenom_role IS NULL
			THEN b_orga.nom_organisme
		WHEN b_orga.nom_organisme IS NULL
			THEN CONCAT(t_roles.nom_role, ' ', t_roles.prenom_role)
			ELSE CONCAT(t_roles.nom_role, ' ', t_roles.prenom_role) || ' (' || b_orga.nom_organisme || ')' 
		END AS "Maitre d'ouvrage", 
		ref_nomenclatures.get_nomenclature_label(id_nomenclature_financing_type::int) "Statut juridique",
		'Protocole' "Méthode d'observation",
		s.sites_group_name "Nom de la zone",
		s.sites_group_code "Code de la zone",
		s.sites_group_description "Description de la zone",
		s.sites_group_comments "Commentaire de la zone",
		s.sites_group_name||'_'||s.base_site_name "nom du point",
		s.base_site_name "Numéro du point",
		s.base_site_description "Description du numéro",
		s.inventor "Créateur du point",
		s.date_site "date de création du point",
		s.altitude_min altitude,
		ST_AsText(geom_local) wkt_l93,
		s.l93_x x_l93,
		s.l93_y y_l93,
		s.wgs84_x x_wgs84,
		s.wgs84_y y_wgs84,
		s.comments "Commentaire localisation",
		v.date_min "date",
		v.device_repasse "Appareil de repasse utilisé",
		v.fructif_fragus "Fructifications du hêtre automne précédent",
		v.time_sunset "Heure de couché du soleil",
		v.etat_vent "Force du vent",
		v.etat_ciel "Etat du ciel",
		v.neige "Etat d'enneigement",
		v.comments AS "Commentaire de la visite",
		obs.observers "Observateurs",
		o.cd_nom,
		t.nom_complet AS "Taxon",
    	(oc."data"::json#>>'{listen_time}')::text AS "Heure début du point",
    	(oc."data"::json#>>'{duration_all}')::int AS "Temps total passé au point",
    	(oc."data"::json#>>'{duration_repasse}')::int AS "Durée de la repasse",
    	(oc."data"::json#>>'{nb_before_rep}')::int AS "Nb avant repasse",
    	(oc."data"::json#>>'{nb_repasse}')::int AS "Nb durant la repasse",
    	(oc."data"::json#>>'{nb_total}')::int AS "Nb jusqu'à la fin des 10 min",
    	(oc."data"::json#>>'{chev_chant}')::int AS "Nb total de chanteur Chevêchette",
    	ref_nomenclatures.get_nomenclature_label((oc."data"::json#>>'{chev_sexe}')::int) AS "Sexe",
    	(oc."data"::json#>>'{hulotte}')::text AS "Présence de Chouette Hulotte",
    	(oc."data"::json#>>'{nb_hulotte}')::text AS "Nombre d’individus Hulotte différents contactés (entendus/vu…)",
    	(oc."data"::json#>>'{nb_passereau}')::text AS "Nbre espèces de passereaux qui répondent à la repasse chevêchette dans un rayon de 10m",
		o.comments AS "Commentaire de l'observation"

    FROM gn_monitoring.t_observations o 
		JOIN gn_monitoring.t_observation_complements oc USING (id_observation)
    JOIN visits v
        ON v.id_base_visit = o.id_base_visit
    JOIN gn_meta.t_datasets meta
        ON v.id_dataset = meta.id_dataset
	LEFT JOIN gn_meta.t_acquisition_frameworks t_fram
		USING (id_acquisition_framework)
	LEFT JOIN gn_meta.cor_acquisition_framework_actor meta_actor
		ON t_fram.id_acquisition_framework = meta_actor.id_acquisition_framework  AND meta_actor.id_nomenclature_actor_role = ref_nomenclatures.get_id_nomenclature('ROLE_ACTEUR','3')
	LEFT JOIN utilisateurs.t_roles 
		USING (id_role)
	LEFT JOIN utilisateurs.bib_organismes b_orga
		ON meta_actor.id_organism = b_orga.id_organisme
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

-- View: gn_monitoring.v_export_petite_chouette_montagne_onf_lpo
DROP VIEW IF EXISTS gn_monitoring.v_export_petite_chouette_montagne_onf_lpo;

CREATE OR REPLACE VIEW gn_monitoring.v_export_petite_chouette_montagne_onf_lpo AS

WITH source AS (
	SELECT

        id_source

    FROM gn_synthese.t_sources
	WHERE name_source = CONCAT('MONITORING_', UPPER(:module_code))
	LIMIT 1

), sites AS (

    SELECT

        id_base_site,
		sg.sites_group_name,
		sg.sites_group_code,
		sg.sites_group_description,
		sg.comments sites_group_comments,
		base_site_name,
		base_site_description,
		id_inventor,
		CONCAT(r.nom_role, ' ', prenom_role) inventor,
		COALESCE (t_base_sites.meta_update_date, first_use_date) AS date_site,
		altitude_min,
		geom_local,
		st_x(ST_Centroid(geom)) AS wgs84_x,
		st_y(ST_Centroid(geom))AS wgs84_y,
		st_x(ST_Centroid(geom_local)) AS l93_x,
		st_y(ST_Centroid(geom_local))AS l93_y,
		comments

        FROM gn_monitoring.t_base_sites
		JOIN gn_monitoring.t_site_complements sc USING (id_base_site)
		LEFT JOIN gn_monitoring.t_sites_groups sg USING (id_sites_group)
    	JOIN utilisateurs.t_roles r ON  id_inventor = r.id_role


), visits AS (
    
    SELECT
    
        id_dataset,
        id_base_visit,
        uuid_base_visit,
        id_module,
        id_base_site,
        id_digitiser,
        visit_date_min AS date_min,
	    COALESCE (visit_date_max, visit_date_min) AS date_visit,
        ref_nomenclatures.get_nomenclature_label((vc."data"::json#>>'{device_repasse}')::int) device_repasse,
		(vc."data"::json#>>'{fructif_fragus}')::text AS fructif_fragus,
		(vc."data"::json#>>'{time_sunset}')::text AS time_sunset,
		(vc."data"::json#>>'{etat_vent}')::text AS etat_vent,
		(vc."data"::json#>>'{etat_ciel}')::text AS etat_ciel,
		(vc."data"::json#>>'{neige}')::text AS neige,
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

), chevechette AS (
	SELECT
		o.id_observation,
		t.nom_complet AS "Taxon 1",
    	(oc."data"::json#>>'{nb_before_rep}')::int AS "Nb Chevêchette avant repasse",
    	(oc."data"::json#>>'{nb_repasse}')::int AS "Nb Chevêchette durant la repasse",
    	(oc."data"::json#>>'{duration_repasse}')::int AS "durée de la repasse Chevêchette en minutes (3 min maxi)",
    	(oc."data"::json#>>'{nb_total}')::int AS "Nb Chevêchette jusqu'à la fin des 10 min",
    	(oc."data"::json#>>'{duration_all}')::int AS "temps total passé au point en minutes (10 min)",
    	(oc."data"::json#>>'{chev_chant}')::int AS "Nb total de chanteur Chevêchette",
    	ref_nomenclatures.get_nomenclature_label((oc."data"::json#>>'{chev_sexe}')::int) AS "Sexe",
    	(oc."data"::json#>>'{nb_passereau}')::text AS "Nbre espèces de passereaux qui répondent à la repasse chevêchette dans un rayon de 10m",
    	(oc."data"::json#>>'{hulotte}')::text AS "Présence de Chouette Hulotte",
    	(oc."data"::json#>>'{nb_hulotte}')::text AS "Nombre d’individus Hulotte différents contactés (entendus/vu…)"

    FROM gn_monitoring.t_observations o 
		JOIN gn_monitoring.t_observation_complements oc USING (id_observation)
		JOIN taxonomie.taxref t USING (cd_nom)
	WHERE unaccent(nom_vern) ilike '%chevechette%europe%' OR unaccent(nom_vern) ilike '%chouette chevechette%' OR nom_complet ilike '%glaucidium passerinum%'

), tengmalm AS (
	SELECT
		o.id_observation,
		t.nom_complet AS "Taxon 2",
    	(oc."data"::json#>>'{nb_before_rep}')::int AS "Nb Tengmalm avant repasse",
    	(oc."data"::json#>>'{nb_repasse}')::int AS "Nb Tengmalm durant la repasse",
    	(oc."data"::json#>>'{duration_repasse}')::int AS "durée de la repasse Tengmalm en minutes (3 min maxi)",
    	(oc."data"::json#>>'{nb_total}')::int AS "Nb Tengmalm jusqu'à la fin des 10 min",
    	(oc."data"::json#>>'{duration_all}')::int AS "temps total Tengmalm passé au point en minutes (10 min)",
    	(oc."data"::json#>>'{chev_chant}')::int AS "Nb total de Tengmalm"

    FROM gn_monitoring.t_observations o 
		JOIN gn_monitoring.t_observation_complements oc USING (id_observation)
		JOIN taxonomie.taxref t USING (cd_nom)
	WHERE nom_vern ilike '%tengmalm%' OR nom_complet ilike '%aegolius funereus%'
)

SELECT

		o.id_observation AS "Identifiant unique universel de l'observation",
		meta.dataset_name "Jeux de données",
		CASE WHEN t_roles.nom_role IS NULL AND t_roles.prenom_role IS NULL
			THEN b_orga.nom_organisme
		WHEN b_orga.nom_organisme IS NULL
			THEN CONCAT(t_roles.nom_role, ' ', t_roles.prenom_role)
			ELSE CONCAT(t_roles.nom_role, ' ', t_roles.prenom_role) || ' (' || b_orga.nom_organisme || ')' 
		END AS "Maitre d'ouvrage", 
		ref_nomenclatures.get_nomenclature_label(id_nomenclature_financing_type::int) "Statut juridique",
		'Protocole' "Méthode d'observation",
		s.sites_group_name "Nom de la zone",
		s.sites_group_code "Code de la zone",
		s.sites_group_description "Description de la zone",
		s.sites_group_comments "Commentaire de la zone",
		s.sites_group_name||'_'||s.base_site_name "nom du point",
		s.base_site_name "Numéro du point",
		s.base_site_description "Description du numéro",
		s.inventor "Créateur du point",
		s.date_site "date de création du point",
		s.altitude_min altitude,
		ST_AsText(geom_local) wkt_l93,
		s.l93_x x_l93,
		s.l93_y y_l93,
		s.wgs84_x x_wgs84,
		s.wgs84_y y_wgs84,
		s.comments "Commentaire localisation",
		v.date_min "date",
		v.comments AS "Commentaire de la visite",
		obs.observers "Observateurs",
		o.cd_nom,
		chev."Taxon 1",
		chev."Nb Chevêchette avant repasse",
		chev."Nb Chevêchette durant la repasse",
		chev."durée de la repasse Chevêchette en minutes (3 min maxi)",
		chev."Nb Chevêchette jusqu'à la fin des 10 min",
		chev."temps total passé au point en minutes (10 min)",
		chev."Nb total de chanteur Chevêchette",
		chev."Sexe",
		v.device_repasse "Appareil de repasse utilisé",
		chev."Nbre espèces de passereaux qui répondent à la repasse chevêchette dans un rayon de 10m",
		chev."Présence de Chouette Hulotte",
		chev."Nombre d’individus Hulotte différents contactés (entendus/vu…)",
		v.fructif_fragus "Fructifications du hêtre automne précédent",
		CONCAT_WS(', ','CS: '||v.time_sunset,v.etat_vent,v.etat_ciel,v.neige,o.comments) AS "Commentaire",
		teng."Taxon 2",
		teng."Nb Tengmalm avant repasse",
		teng."Nb Tengmalm durant la repasse",
		teng."durée de la repasse Tengmalm en minutes (3 min maxi)",
		teng."Nb Tengmalm jusqu'à la fin des 10 min",
		teng."temps total Tengmalm passé au point en minutes (10 min)",
		teng."Nb total de Tengmalm"

    FROM gn_monitoring.t_observations o 
		JOIN gn_monitoring.t_observation_complements oc USING (id_observation)
    LEFT JOIN tengmalm teng
		USING (id_observation)
    LEFT JOIN chevechette chev
		USING (id_observation)
    JOIN visits v
        ON v.id_base_visit = o.id_base_visit
    JOIN gn_meta.t_datasets meta
        ON v.id_dataset = meta.id_dataset
	LEFT JOIN gn_meta.t_acquisition_frameworks t_fram
		USING (id_acquisition_framework)
	LEFT JOIN gn_meta.cor_acquisition_framework_actor meta_actor
		ON t_fram.id_acquisition_framework = meta_actor.id_acquisition_framework  AND meta_actor.id_nomenclature_actor_role = ref_nomenclatures.get_id_nomenclature('ROLE_ACTEUR','3')
	LEFT JOIN utilisateurs.t_roles 
		USING (id_role)
	LEFT JOIN utilisateurs.bib_organismes b_orga
		ON meta_actor.id_organism = b_orga.id_organisme
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