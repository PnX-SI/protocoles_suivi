
-------------------------------------------------final --POPReptile standard------------------------------------------
-- View: gn_monitoring.v_export_popreptile_standard

DROP  VIEW IF EXISTS gn_monitoring.v_export_popreptile_standard;

CREATE OR REPLACE VIEW gn_monitoring.v_export_popreptile_standard
 AS
SELECT
    -- identifiant unique
    o.uuid_observation AS uuid_observation,
    -- Aires et variables associées
    tsg.sites_group_name AS aire_etude,
    tsg.uuid_sites_group AS uuid_aire_etude,
    tsg.sites_group_description AS description_aire,
    json_extract_path(tsg.data::json,'habitat_principal')::text AS habitat_principal_aire,
    json_extract_path(tsg.data::json,'expertise')::text AS expertise_operateur,
	tsg.comments AS commentaire_aire,
    -- Site
    s.base_site_name AS nom_transect,
   	st_astext(s.geom) AS wkt,
    st_x(st_centroid(s.geom_local)) AS x_centroid_L93,
    st_y(st_centroid(s.geom_local)) AS y_centroid_L93,
    alt.altitude_min AS altitude_min,
    alt.altitude_max AS altitude_max,
    dep.area_name AS departement,
    dep.area_code AS code_dep,
    com.area_name AS commune,
    string_agg(distinct(sp.area_name)||'('||sp.type_code||')', ', ') AS site_protege,
    json_extract_path(sc.data::json,'methode_prospection')::text AS methode_prospection, 
    json_extract_path(sc.data::json,'type_materiaux')::text AS type_materiaux, 
    json_extract_path(sc.data::json,'nb_plaques')::text AS nb_plaques, 
    json_extract_path(sc.data::json,'milieu_transect')::text AS milieu_transect, 
    json_extract_path(sc.data::json,'milieu_bordier')::text AS milieu_bordier, 
    json_extract_path(sc.data::json,'milieu_mosaique_vegetale')::text AS milieu_mosaique, 
    json_extract_path(sc.data::json,'milieu_homogene')::text AS milieu_homogene, 
    json_extract_path(sc.data::json,'milieu_anthropique')::text AS milieu_anthropique, 
    json_extract_path(sc.data::json,'milieu_transect_autre')::text AS milieu_anthropique_autre, 
    json_extract_path(sc.data::json,'microhabitat_favorable')::text AS microhab_favorable, 
    json_extract_path(sc.data::json,'frequentation_humaine')::text AS frequentation_humaine, 
    json_extract_path(sc.data::json,'comment')::text AS commentaire_transect,
    -- Informations sur la visite
    v.id_dataset, 
    d.dataset_name AS jeu_de_donnees,
    v.uuid_base_visit AS uuid_visite,
    v.visit_date_min AS date_visite,
	json_extract_path(vc.data::json,'Heure_debut')::text AS heure_debut, 
    json_extract_path(vc.data::json,'Heure_fin')::text AS heure_fin, 
    json_extract_path(vc.data::json,'num_passage')::text AS num_passage,
    obs.observers,
    obs.organismes_rattaches,
    json_extract_path(vc.data::json,'meteo')::text AS meteo, 
    json_extract_path(vc.data::json,'vent')::text AS vent,
   	v.comments AS commentaire_visite,
    -- Informations sur l'observation
    o.cd_nom AS cd_nom,
    json_extract_path(oc.data::json,'presence')::text AS presence_reptile,
    t.lb_nom AS nom_latin,
    t.nom_vern AS nom_francais,
    json_extract_path(oc.data::json,'abondance')::text AS abondance,
    json_extract_path(oc.data::json,'type_denombrement')::text AS type_denbr,
    nullif(json_extract_path(oc.data::json,'nombre_compte')::text,null)::integer AS nombre_compte,
   	nullif(json_extract_path(oc.data::json,'nombre_estime_min')::text,null)::integer AS nombre_estime_min,
   	nullif(json_extract_path(oc.data::json,'nombre_estime_max')::text,null)::integer AS nombre_estime_max,
    json_extract_path(oc.data::json,'stade_vie')::text AS stade_vie,
    o.comments AS commentaire_obs
FROM gn_monitoring.t_observations o
JOIN gn_monitoring.t_observation_complements oc ON oc.id_observation = o.id_observation
JOIN gn_monitoring.t_base_visits v ON o.id_base_visit = v.id_base_visit
JOIN gn_monitoring.t_visit_complements vc ON v.id_base_visit = vc.id_base_visit
JOIN gn_monitoring.t_base_sites s ON s.id_base_site = v.id_base_site
JOIN gn_monitoring.t_site_complements sc ON sc.id_base_site = s.id_base_site
join gn_monitoring.t_sites_groups tsg ON sc.id_sites_group = tsg.id_sites_group
JOIN gn_commons.t_modules m ON m.id_module = v.id_module
JOIN taxonomie.taxref t ON t.cd_nom = o.cd_nom
LEFT JOIN gn_monitoring.cor_site_area csa ON csa.id_base_site = s.id_base_site
LEFT JOIN gn_meta.t_datasets d ON d.id_dataset=v.id_dataset
LEFT JOIN (select la.area_name, csa.id_base_site
	FROM ref_geo.l_areas la
	JOIN ref_geo.bib_areas_types bat ON la.id_type = bat.id_type
	JOIN gn_monitoring.cor_site_area csa ON csa.id_area = la.id_area
	WHERE bat.type_code='COM') com ON s.id_base_site = com.id_base_site
LEFT JOIN (select la.area_name, la.area_code, csa.id_base_site
	FROM ref_geo.l_areas la
	JOIN ref_geo.bib_areas_types bat ON la.id_type = bat.id_type
	JOIN gn_monitoring.cor_site_area csa ON csa.id_area = la.id_area
	WHERE bat.type_code='DEP') dep ON s.id_base_site = dep.id_base_site
LEFT JOIN (select la.area_name, csa.id_base_site, bat.type_code
	FROM ref_geo.l_areas la
	JOIN ref_geo.bib_areas_types bat ON la.id_type = bat.id_type
	JOIN gn_monitoring.cor_site_area csa ON csa.id_area = la.id_area
	WHERE bat.type_code IN ('ZNIEFF1','ZNIEFF2','ZPS','ZCS','SIC','RNCFS','RNR','RNN','ZC')) sp ON s.id_base_site = sp.id_base_site
LEFT JOIN LATERAL ( SELECT array_agg(r.id_role) AS ids_observers,
    string_agg(concat(r.nom_role, ' ', r.prenom_role), ' ; '::text) AS observers,
    string_agg(distinct org.nom_organisme, ', ')::text AS organismes_rattaches
    FROM gn_monitoring.cor_visit_observer cvo
    JOIN utilisateurs.t_roles r ON r.id_role = cvo.id_role
    LEFT JOIN utilisateurs.bib_organismes org ON org.id_organisme =r.id_organisme
    WHERE cvo.id_base_visit = v.id_base_visit) obs ON true
LEFT JOIN LATERAL ref_geo.fct_get_altitude_intersection(s.geom_local) alt(altitude_min, altitude_max) ON true
LEFT JOIN LATERAL (SELECT ref_nomenclatures.get_nomenclature_label(json_array_elements(vc.data::json #> '{methode_de_prospection}')::text::integer,'fr') AS methodes ) meth ON TRUE
WHERE m.module_code = 'popreptile'
GROUP BY 1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,18,19,20,21,22,23,24,25,26,27,28,29,30,31,32,33,34,35,36,37,38,39,40,41,42,43,44,45,46,47,48,49,50,51,52
;

		 
    
        
         
        
        

------------------------------------------------finale --POPReptile analyses------------------------------------------
-- View: gn_monitoring.v_export_popreptile_analyse
DROP VIEW IF EXISTS gn_monitoring.v_export_popreptile_analyses;

CREATE OR REPLACE VIEW gn_monitoring.v_export_popreptile_analyses
 AS
WITH observations AS (
    SELECT 
    	o.id_base_visit, 
    	COUNT(DISTINCT t.cd_ref) AS diversite, 
    	string_agg(DISTINCT t.lb_nom, ' ; ') AS taxons_latin, 
    	string_agg(DISTINCT t.nom_vern, ' ; ') AS taxons_fr, 
    	sum(nullif(json_extract_path(oc.data::json,'nombre_compte')::text,null)::integer)+sum(nullif(json_extract_path(oc.data::json,'nombre_estime_min')::text,null)::integer) AS count_min, 
    	sum(nullif(json_extract_path(oc.data::json,'nombre_compte')::text,null)::integer)+sum(nullif(json_extract_path(oc.data::json,'nombre_estime_max')::text,null)::integer) AS count_max 
    FROM gn_monitoring.t_observations o
    LEFT JOIN taxonomie.taxref t ON o.cd_nom=t.cd_nom
    LEFT JOIN gn_monitoring.t_observation_complements oc ON oc.id_observation=o.id_observation
    GROUP BY id_base_visit
    )
SELECT
    -- Aires et variables associées
    tsg.sites_group_name AS aire_etude,
    tsg.uuid_sites_group AS uuid_aire_etude,
    tsg.sites_group_description AS description_aire,
    json_extract_path(tsg.data::json,'habitat_principal')::text AS habitat_principal_aire,
    json_extract_path(tsg.data::json,'expertise')::text AS expertise_operateur,
	tsg.comments AS commentaire_aire,
    -- Site
    s.base_site_name AS nom_transect,
    st_astext(s.geom) AS wkt,
    st_x(st_centroid(s.geom_local)) AS x_centroid_L93,
    st_y(st_centroid(s.geom_local)) AS y_centroid_L93,
    alt.altitude_min AS altitude_min,
    alt.altitude_max AS altitude_max,
    dep.area_name AS departement,
    dep.area_code AS code_dep,
    com.area_name AS commune,
    string_agg(distinct(sp.area_name)||'('||sp.type_code||')', ', ') AS site_protege,
    json_extract_path(sc.data::json,'methode_prospection')::text AS methode_prospection, 
    json_extract_path(sc.data::json,'type_materiaux')::text AS type_materiaux, 
    json_extract_path(sc.data::json,'nb_plaques')::text AS nb_plaques, 
    json_extract_path(sc.data::json,'milieu_transect')::text AS milieu_transect, 
    json_extract_path(sc.data::json,'milieu_bordier')::text AS milieu_bordier, 
    json_extract_path(sc.data::json,'milieu_mosaique_vegetale')::text AS milieu_mosaique, 
    json_extract_path(sc.data::json,'milieu_homogene')::text AS milieu_homogene, 
    json_extract_path(sc.data::json,'milieu_anthropique')::text AS milieu_anthropique, 
    json_extract_path(sc.data::json,'milieu_transect_autre')::text AS milieu_anthropique_autre, 
    json_extract_path(sc.data::json,'microhabitat_favorable')::text AS microhab_favorable, 
    json_extract_path(sc.data::json,'frequentation_humaine')::text AS frequentation_humaine, 
    json_extract_path(sc.data::json,'comment')::text AS commentaire_transect,
    -- Informations sur la visite
    v.id_dataset, 
    d.dataset_name AS jeu_de_donnees,
    v.uuid_base_visit AS uuid_visite,
    v.visit_date_min AS date_visite,
	json_extract_path(vc.data::json,'Heure_debut')::text AS heure_debut, 
    json_extract_path(vc.data::json,'Heure_fin')::text AS heure_fin, 
    json_extract_path(vc.data::json,'num_passage')::text AS num_passage,
    obs.observers,
    obs.organismes_rattaches,
    json_extract_path(vc.data::json,'meteo')::text AS meteo, 
    json_extract_path(vc.data::json,'vent')::text AS vent,
   	v.comments AS commentaire_visite,
    -- Informations sur l'observation
    -- SYNTHESE OBSERVATIONS
    observations.diversite::integer as diversite,
    observations.taxons_latin as taxons_latin,
    observations.taxons_fr as taxons_fr,
    observations.count_min as abondance_total_min,
    observations.count_max as abondance_total_max
FROM gn_monitoring.t_base_visits v
JOIN gn_monitoring.t_visit_complements vc ON v.id_base_visit = vc.id_base_visit
JOIN gn_monitoring.t_base_sites s ON s.id_base_site = v.id_base_site
JOIN gn_monitoring.t_site_complements sc ON sc.id_base_site = s.id_base_site
JOIN gn_monitoring.t_sites_groups tsg ON sc.id_sites_group = tsg.id_sites_group
JOIN gn_commons.t_modules m ON m.id_module = v.id_module
LEFT JOIN gn_monitoring.cor_site_area csa ON csa.id_base_site = s.id_base_site
LEFT JOIN observations ON observations.id_base_visit=v.id_base_visit 
LEFT JOIN gn_meta.t_datasets d ON d.id_dataset=v.id_dataset
LEFT JOIN (SELECT la.area_name, csa.id_base_site
	FROM ref_geo.l_areas la
	JOIN ref_geo.bib_areas_types bat ON la.id_type = bat.id_type
	JOIN gn_monitoring.cor_site_area csa ON csa.id_area = la.id_area
	WHERE bat.type_code='COM') com ON s.id_base_site = com.id_base_site
LEFT JOIN (SELECT la.area_name, la.area_code, csa.id_base_site
	FROM ref_geo.l_areas la
	JOIN ref_geo.bib_areas_types bat ON la.id_type = bat.id_type
	JOIN gn_monitoring.cor_site_area csa ON csa.id_area = la.id_area
	WHERE bat.type_code='DEP') dep ON s.id_base_site = dep.id_base_site
LEFT JOIN (SELECT la.area_name, csa.id_base_site, bat.type_code
	FROM ref_geo.l_areas la
	JOIN ref_geo.bib_areas_types bat ON la.id_type = bat.id_type
	JOIN gn_monitoring.cor_site_area csa ON csa.id_area = la.id_area
	WHERE bat.type_code IN ('ZNIEFF1','ZNIEFF2','ZPS','ZCS','SIC','RNCFS','RNR','RNN','ZC')) sp ON s.id_base_site = sp.id_base_site
LEFT JOIN LATERAL ( SELECT array_agg(r.id_role) AS ids_observers,
    string_agg(concat(r.nom_role, ' ', r.prenom_role), ' ; '::text) AS observers,
    string_agg(distinct org.nom_organisme, ', ')::text AS organismes_rattaches
    FROM gn_monitoring.cor_visit_observer cvo
    JOIN utilisateurs.t_roles r ON r.id_role = cvo.id_role
    LEFT JOIN utilisateurs.bib_organismes org ON org.id_organisme =r.id_organisme
    WHERE cvo.id_base_visit = v.id_base_visit) obs ON true
LEFT JOIN LATERAL ref_geo.fct_get_altitude_intersection(s.geom_local) alt(altitude_min, altitude_max) ON true
LEFT JOIN lateral (SELECT ref_nomenclatures.get_nomenclature_label(json_array_elements(vc.data::json #> '{methode_de_prospection}')::text::integer,'fr') as methodes ) meth on true
WHERE m.module_code = 'popreptile'
GROUP BY 1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,17,18,19,20,21,22,23,24,25,26,27,28,29,30,31,32,33,34,35,36,37,38,39,40,41,42,43,44,45
;


-------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------
