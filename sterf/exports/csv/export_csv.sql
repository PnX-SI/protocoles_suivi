------- Export des observations STERF ----------
DROP VIEW  IF EXISTS gn_monitoring.v_export_sterf_standard;

CREATE OR REPLACE VIEW gn_monitoring.v_export_sterf_standard AS (
	SELECT
    -- identifiant unique
    o.uuid_observation AS uuid_observation,
    -- Site et variables associées
    s.base_site_name AS nom_site,
    st_x(s.geom_local) AS x_proj_locale,
    st_y(s.geom_local) AS y_proj_locale,
    alt.altitude_min AS altitude_min,
    alt.altitude_max AS altitude_max,
    --
    string_agg(distinct(com.area_name),', ') AS communes,
    -- Informations sur la visite
    v.id_dataset, 
    d.dataset_name AS jeu_de_donnees,
    v.uuid_base_visit AS uuid_visite,
    v.visit_date_min AS date_visite,
    json_extract_path(vc.data::json,'num_passage')::text AS visite,
    obs.observers,
    obs.organismes_rattaches,
    string_agg(distinct meth.methodes,' ; ') AS methodes_prospection,
    ref_nomenclatures.get_nomenclature_label(nullif(json_extract_path(vc.data::json,'pluviosite')::text,'null')::integer, 'fr') AS pluviosite,
    ref_nomenclatures.get_nomenclature_label(nullif(json_extract_path(vc.data::json,'couverture_nuageuse')::text,'null')::integer, 'fr') AS couverture_nuageuse,
    ref_nomenclatures.get_nomenclature_label(nullif(json_extract_path(vc.data::json,'vent')::text,'null')::integer, 'fr') AS vent,
    ref_nomenclatures.get_nomenclature_label(nullif(json_extract_path(vc.data::json,'turbidite')::text,'null')::integer, 'fr') AS turbidite,
    ref_nomenclatures.get_nomenclature_label(nullif(json_extract_path(vc.data::json,'vegetation_aquatique_principale')::text,'null')::integer, 'fr') AS vegetation_aquatique_principale,
    ref_nomenclatures.get_nomenclature_label(nullif(json_extract_path(vc.data::json,'rives')::text,'null')::integer, 'fr') AS rives,
    ref_nomenclatures.get_nomenclature_label(nullif(json_extract_path(vc.data::json,'habitat_terrestre_environnant')::text,'null')::integer, 'fr') AS habitat_terrestre_environnant,
    ref_nomenclatures.get_nomenclature_label(nullif(json_extract_path(vc.data::json,'activite_humaine')::text,'null')::integer, 'fr') AS activite_humaine,
    v.comments AS commentaire_visite,
    -- Informations sur l'observation
    o.cd_nom AS cd_nom,
    t.lb_nom AS nom_latin,
    t.nom_vern AS nom_francais,
    ref_nomenclatures.get_nomenclature_label(nullif(json_extract_path(oc.data::json,'id_nomenclature_typ_denbr')::text, 'null')::integer, 'fr') AS type_denombrement,
    nullif(((oc.data::json #> '{count_min}'::text[])::text),'null')::integer AS count_min,
    nullif(((oc.data::json #> '{count_max}'::text[])::text),'null')::integer AS count_max,
    ref_nomenclatures.get_nomenclature_label(nullif(json_extract_path(oc.data::json,'id_nomenclature_stade')::text,'null')::integer, 'fr') AS stade_vie,
    ref_nomenclatures.get_nomenclature_label(nullif(json_extract_path(oc.data::json,'id_nomenclature_sex')::text,'null')::integer, 'fr') AS sexe,
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
WHERE m.module_code = 'popamphibien'
GROUP BY o.uuid_observation, obs.organismes_rattaches, dep.area_name, dep.area_code, tsg.sites_group_name, o.cd_nom, t.lb_nom, t.nom_vern, o.comments, oc.data, v.visit_date_min, v.id_dataset, d.dataset_name, v.comments, v.uuid_base_visit,
s.base_site_name, sc.data, vc.data, alt.altitude_min, alt.altitude_max, obs.observers, com.area_name, s.geom_local;


);


---------- Export par transect STERF ----------
DROP VIEW  IF EXISTS gn_monitoring.v_export_sterf_analyse;

CREATE OR REPLACE VIEW gn_monitoring.v_export_sterf_analyse AS (
);
