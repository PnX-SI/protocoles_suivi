---------------------------------------------------POPAmphibien standard------------------------------------------
-- View: gn_monitoring.v_export_popamphibien_standard
-- Export avec une entrée observations, permettant de récupérer les occurrences d'observations avec l'ensemble
-- des attributs spécifiques du protocole. Ne renvoie pas les visites sans observations.
-- Version du 3 juin 2024

DROP VIEW IF EXISTS gn_monitoring.v_export_popamphibien_standard;

CREATE OR REPLACE VIEW gn_monitoring.v_export_popamphibien_standard AS
WITH obs AS
(SELECT
    id_base_visit,
    array_agg(r.id_role) AS ids_observers,
    string_agg(concat(r.nom_role, ' ', r.prenom_role), ' ; ') AS observers,
    string_agg(DISTINCT org.nom_organisme::text, ', ') AS organismes_rattaches
FROM gn_monitoring.cor_visit_observer cvo
JOIN utilisateurs.t_roles r USING (id_role)
JOIN utilisateurs.bib_organismes org USING (id_organisme)
GROUP BY id_base_visit),
com AS
(SELECT
    csa.id_base_site,
    la_com.area_name AS commune
FROM gn_monitoring.cor_site_area csa
JOIN ref_geo.l_areas la_com ON csa.id_area = la_com.id_area
JOIN ref_geo.bib_areas_types bat_com ON bat_com.id_type = la_com.id_type
WHERE bat_com.type_code = 'COM'
),
dep AS
(SELECT
    csa.id_base_site,
    la_dep.area_name AS departement,
    la_dep.area_code AS code_dep
FROM gn_monitoring.cor_site_area csa
JOIN ref_geo.l_areas la_dep ON csa.id_area = la_dep.id_area
LEFT JOIN ref_geo.bib_areas_types bat_dep ON bat_dep.id_type = la_dep.id_type
WHERE bat_dep.type_code = 'DEP'),
zonages AS
(SELECT
    csa.id_base_site,
    string_agg(DISTINCT ((la.area_name::text || '(') ||bat.type_code::text) || ')', ', ') AS site_protege
FROM ref_geo.l_areas la
JOIN ref_geo.bib_areas_types bat ON la.id_type = bat.id_type
JOIN gn_monitoring.cor_site_area csa ON csa.id_area = la.id_area
WHERE bat.type_code = ANY (ARRAY['ZNIEFF1', 'ZNIEFF2', 'ZPS', 'ZCS', 'SIC', 'RNCFS', 'RNR', 'RNN', 'ZC']::text[])
GROUP BY id_base_site
),
info_sites AS
(SELECT
    s.id_base_site,
    departement,
    code_dep,
    commune,
    site_protege
FROM gn_monitoring.t_base_sites s
LEFT JOIN com USING (id_base_site)
LEFT JOIN dep USING (id_base_site)
LEFT JOIN zonages USING (id_base_site)),
unnest_methods AS
(SELECT
    id_base_visit,
    ref_nomenclatures.get_nomenclature_label(unnest(string_to_array(REPLACE(REPLACE(vc.DATA ->> 'methode_de_prospection', '[', ''), ']', ''), ','))::integer, 'fr') AS meth
FROM gn_monitoring.t_visit_complements vc),
methods AS
(SELECT
    id_base_visit,
    string_agg(DISTINCT meth, ';') AS meth
FROM unnest_methods
GROUP BY id_base_visit)
SELECT
    -- identifiant unique
    o.uuid_observation AS uuid_observation,
    -- Site et variables associées
    tsg.sites_group_name AS aire_etude,
    s.base_site_name AS nom_site,
    st_x(s.geom_local) AS x_lambert93,
    st_y(s.geom_local) AS y_lambert93,
    s.altitude_min AS altitude_min,
    s.altitude_max AS altitude_max,
    ref_nomenclatures.get_nomenclature_label(NULLIF(json_extract_path(sc.data::json,'milieu_aquatique')::text,'null')::integer, 'fr') AS milieu_aquatique,
    ref_nomenclatures.get_nomenclature_label(NULLIF(json_extract_path(sc.data::json,'variation_eau')::text,'null')::integer, 'fr') AS variation_eau,
    ref_nomenclatures.get_nomenclature_label(NULLIF(json_extract_path(sc.data::json,'courant')::text,'null')::integer, 'fr') AS courant,
    i.departement AS departement,
    i.code_dep AS code_dep,
    i.commune AS commune,
    i.site_protege AS site_protege,
    -- Informations sur la visite
    v.id_dataset,
    d.dataset_name AS jeu_de_donnees,
    v.uuid_base_visit AS uuid_visite,
    v.visit_date_min AS date_visite,
    json_extract_path(vc.data::json,'num_passage')::text AS visite,
    obs.observers,
    obs.organismes_rattaches,
    methods.meth AS methodes_prospection,
    ref_nomenclatures.get_nomenclature_label(NULLIF(json_extract_path(vc.data::json,'pluviosite')::text,'null')::integer, 'fr') AS pluviosite,
    ref_nomenclatures.get_nomenclature_label(NULLIF(json_extract_path(vc.data::json,'couverture_nuageuse')::text,'null')::integer, 'fr') AS couverture_nuageuse,
    ref_nomenclatures.get_nomenclature_label(NULLIF(json_extract_path(vc.data::json,'vent')::text,'null')::integer, 'fr') AS vent,
    ref_nomenclatures.get_nomenclature_label(NULLIF(json_extract_path(vc.data::json,'turbidite')::text,'null')::integer, 'fr') AS turbidite,
    ref_nomenclatures.get_nomenclature_label(NULLIF(json_extract_path(vc.data::json,'vegetation_aquatique_principale')::text,'null')::integer, 'fr') AS vegetation_aquatique_principale,
    ref_nomenclatures.get_nomenclature_label(NULLIF(json_extract_path(vc.data::json,'rives')::text,'null')::integer, 'fr') AS rives,
    ref_nomenclatures.get_nomenclature_label(NULLIF(json_extract_path(vc.data::json,'habitat_terrestre_environnant')::text,'null')::integer, 'fr') AS habitat_terrestre_environnant,
    ref_nomenclatures.get_nomenclature_label(NULLIF(json_extract_path(vc.data::json,'activite_humaine')::text,'null')::integer, 'fr') AS activite_humaine,
    v.comments AS commentaire_visite,
    -- Informations sur l'observation
    o.cd_nom AS cd_nom,
    t.lb_nom AS nom_latin,
    t.nom_vern AS nom_francais,
    ref_nomenclatures.get_nomenclature_label(NULLIF(json_extract_path(oc.data::json,'id_nomenclature_typ_denbr')::text, 'null')::integer, 'fr') AS type_denombrement,
    NULLIF(((oc.data::json #> '{count_min}'::text[])::text),'null')::integer AS count_min,
    NULLIF(((oc.data::json #> '{count_max}'::text[])::text),'null')::integer AS count_max,
    ref_nomenclatures.get_nomenclature_label(NULLIF(json_extract_path(oc.data::json,'id_nomenclature_stade')::text,'null')::integer, 'fr') AS stade_vie,
    ref_nomenclatures.get_nomenclature_label(NULLIF(json_extract_path(oc.data::json,'id_nomenclature_sex')::text,'null')::integer, 'fr') AS sexe,
    o.comments AS commentaire_obs
FROM gn_monitoring.t_observations o
JOIN gn_monitoring.t_observation_complements oc USING (id_observation)
JOIN gn_monitoring.t_base_visits v USING (id_base_visit)
JOIN gn_monitoring.t_visit_complements vc USING (id_base_visit)
JOIN gn_monitoring.t_base_sites s USING (id_base_site)
JOIN gn_monitoring.t_site_complements sc USING (id_base_site)
JOIN gn_monitoring.t_sites_groups tsg USING (id_sites_group)
JOIN gn_commons.t_modules m ON m.id_module = v.id_module
JOIN taxonomie.taxref t USING (cd_nom)
LEFT JOIN gn_meta.t_datasets d USING (id_dataset)
LEFT JOIN info_sites i USING (id_base_site)
LEFT JOIN obs USING (id_base_visit)
LEFT JOIN methods USING (id_base_visit)
WHERE m.module_code = 'popamphibien';

---------------------------------------------------POPAmphibien analyses------------------------------------------
-- View: gn_monitoring.v_export_popamphibien_analyses
-- Export avec une entrée visites, permettant d'analyser les données de protocole en listant les visites et les 
-- observations associées, y compris visite sans occurrences.
-- Version du 3 juin 2024

-- View: gn_monitoring.v_export_popamphibien_analyses

DROP VIEW IF EXISTS gn_monitoring.v_export_popamphibien_analyses;

CREATE OR REPLACE VIEW gn_monitoring.v_export_popamphibien_analyses AS
WITH obs AS
(SELECT
    id_base_visit,
    array_agg(r.id_role) AS ids_observers,
    string_agg(concat(r.nom_role, ' ', r.prenom_role), ' ; ') AS observers,
    string_agg(DISTINCT org.nom_organisme::text, ', ') AS organismes_rattaches
FROM gn_monitoring.cor_visit_observer cvo
JOIN utilisateurs.t_roles r USING (id_role)
JOIN utilisateurs.bib_organismes org USING (id_organisme)
GROUP BY id_base_visit),
observations AS (
    SELECT
        o.id_base_visit,
        count(DISTINCT t.cd_ref) AS diversite,
        string_agg(DISTINCT t.lb_nom::text, ' ; ') AS taxons_latin,
        string_agg(DISTINCT t.nom_vern::text, ' ; ') AS taxons_fr,
        sum(NULLIF(replace((oc.data::json -> 'count_min')::text, '"', ''), 'null')::integer) AS count_min,
        sum(NULLIF(replace((oc.data::json -> 'count_max')::text, '"', ''), 'null')::integer) AS count_max
    FROM gn_monitoring.t_observations o
    LEFT JOIN taxonomie.taxref t ON o.cd_nom = t.cd_nom
    LEFT JOIN gn_monitoring.t_observation_complements oc ON oc.id_observation = o.id_observation
    GROUP BY o.id_base_visit
),
com AS
(SELECT
    csa.id_base_site,
    la_com.area_name AS commune
FROM gn_monitoring.cor_site_area csa
JOIN ref_geo.l_areas la_com ON csa.id_area = la_com.id_area
JOIN ref_geo.bib_areas_types bat_com ON bat_com.id_type = la_com.id_type
WHERE bat_com.type_code = 'COM'
),
dep AS
(SELECT
    csa.id_base_site,
    la_dep.area_name AS departement,
    la_dep.area_code AS code_dep
FROM gn_monitoring.cor_site_area csa
JOIN ref_geo.l_areas la_dep ON csa.id_area = la_dep.id_area
LEFT JOIN ref_geo.bib_areas_types bat_dep ON bat_dep.id_type = la_dep.id_type
WHERE bat_dep.type_code = 'DEP'),
zonages AS
(SELECT
    csa.id_base_site,
    string_agg(DISTINCT ((la.area_name::text || '(') ||bat.type_code::text) || ')', ', ') AS site_protege
FROM ref_geo.l_areas la
JOIN ref_geo.bib_areas_types bat ON la.id_type = bat.id_type
JOIN gn_monitoring.cor_site_area csa ON csa.id_area = la.id_area
WHERE bat.type_code = ANY (ARRAY['ZNIEFF1', 'ZNIEFF2', 'ZPS', 'ZCS', 'SIC', 'RNCFS', 'RNR', 'RNN', 'ZC']::text[])
GROUP BY id_base_site
),
info_sites AS
(SELECT
    s.id_base_site,
    departement,
    code_dep,
    commune,
    site_protege
FROM gn_monitoring.t_base_sites s
LEFT JOIN com USING (id_base_site)
LEFT JOIN dep USING (id_base_site)
LEFT JOIN zonages USING (id_base_site)),
unnest_methods AS
(SELECT id_base_visit,
	ref_nomenclatures.get_nomenclature_label(unnest(string_to_array(REPLACE(REPLACE(vc.DATA ->> 'methode_de_prospection', '[', ''), ']', ''), ','))::integer, 'fr') AS meth
FROM gn_monitoring.t_visit_complements vc),
methods AS
(SELECT id_base_visit, string_agg(DISTINCT meth, ';') AS meth FROM unnest_methods
GROUP BY id_base_visit)
SELECT
    -- Aire et site
    tsg.sites_group_name AS aire_etude,
    s.base_site_name AS nom_site,
    st_x(s.geom_local) AS x_lambert93,
    st_y(s.geom_local) AS y_lambert93,
    s.altitude_min AS altitude_min,
    s.altitude_max AS altitude_max,
    ref_nomenclatures.get_nomenclature_label(NULLIF(replace((sc.data::json -> 'milieu_aquatique')::text, '"', ''), 'null')::integer, 'fr') AS milieu_aquatique,
    ref_nomenclatures.get_nomenclature_label(NULLIF(replace((sc.data::json -> 'variation_eau')::text, '"', ''), 'null')::integer, 'fr') AS variation_eau,
    ref_nomenclatures.get_nomenclature_label(NULLIF(replace((sc.data::json -> 'courant')::text, '"', ''), 'null')::integer, 'fr') AS courant,
    i.departement AS departement,
    i.code_dep AS code_dep,
    i.commune AS commune,
    i.site_protege AS site_protege,
    -- VISITE
    v.uuid_base_visit AS uuid_visite,
    v.visit_date_min AS date_visite,
    v.id_dataset,
    d.dataset_name AS jeu_de_donnees,
    date_part('year', v.visit_date_min) AS annee,
    NULLIF(replace((vc.data::json -> 'num_passage')::text, '"', ''), 'null') AS visite,
    obs.observers,
    obs.organismes_rattaches,
    NULLIF(replace((vc.data::json -> 'accessibility')::text, '"', ''), 'null') AS accessibilite,
    methods.meth AS methodes_prospection,
    ref_nomenclatures.get_nomenclature_label(NULLIF(replace((vc.data::json -> 'pluviosite')::text, '"', ''), 'null')::integer, 'fr') AS pluviosite,
    ref_nomenclatures.get_nomenclature_label(NULLIF(replace((vc.data::json -> 'couverture_nuageuse')::text, '"', ''), 'null')::integer, 'fr') AS couverture_nuageuse,
    ref_nomenclatures.get_nomenclature_label(NULLIF(replace((vc.data::json -> 'vent')::text, '"', ''), 'null')::integer, 'fr') AS vent,
    ref_nomenclatures.get_nomenclature_label(NULLIF(replace((vc.data::json -> 'turbidite')::text, '"', ''), 'null')::integer, 'fr') AS turbidite,
    ref_nomenclatures.get_nomenclature_label(NULLIF(replace((vc.data::json -> 'vegetation_aquatique_principale')::text, '"', ''), 'null')::integer, 'fr') AS vegetation_aquatique_principale,
    ref_nomenclatures.get_nomenclature_label(NULLIF(replace((vc.data::json -> 'rives')::text, '"', ''), 'null')::integer, 'fr') AS rives,
    ref_nomenclatures.get_nomenclature_label(NULLIF(replace((vc.data::json -> 'habitat_terrestre_environnant')::text, '"', ''), 'null')::integer, 'fr') AS habitat_terrestre_environnant,
    ref_nomenclatures.get_nomenclature_label(NULLIF(replace((vc.data::json -> 'activite_humaine')::text, '"', ''), 'null')::integer, 'fr') AS activite_humaine,
    NULLIF(replace((vc.data::json -> 'presence_amphibien')::text, '"', ''), 'null') AS presence_amphibien,
    v.comments AS commentaire_visite,
    -- SYNTHESE OBSERVATIONS
    observations.diversite::integer AS diversite,
    observations.taxons_latin,
    observations.taxons_fr,
    observations.count_min AS abondance_total_min,
    observations.count_max AS abondance_total_max
FROM gn_monitoring.t_base_visits v
JOIN gn_monitoring.t_visit_complements vc USING (id_base_visit)
JOIN gn_monitoring.t_base_sites s USING (id_base_site)
JOIN gn_monitoring.t_site_complements sc USING (id_base_site)
JOIN gn_monitoring.t_sites_groups tsg USING (id_sites_group)
JOIN gn_commons.t_modules m ON m.id_module = v.id_module
LEFT JOIN observations USING (id_base_visit)
LEFT JOIN gn_meta.t_datasets d ON d.id_dataset = v.id_dataset
LEFT JOIN info_sites i USING (id_base_site)
LEFT JOIN obs USING (id_base_visit)
LEFT JOIN methods USING (id_base_visit)
WHERE m.module_code::text = 'popamphibien';
