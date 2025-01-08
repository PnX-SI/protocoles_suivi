
-------------------------------------------------final --POPReptile standard------------------------------------------
-- View: gn_monitoring.v_export_popreptile_standard

DROP VIEW IF EXISTS gn_monitoring.v_export_popreptile_standard;

CREATE OR REPLACE VIEW gn_monitoring.v_export_popreptile_standard AS
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
    string_agg(DISTINCT ((la.area_name::text || '(') ||bat.type_code::text) || ')', ', ') AS sites_proteges
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
    sites_proteges
FROM gn_monitoring.t_base_sites s
LEFT JOIN com USING (id_base_site)
LEFT JOIN dep USING (id_base_site)
LEFT JOIN zonages USING (id_base_site))
SELECT
    -- identifiant unique
    o.uuid_observation,
    -- Site et variables associées
    tsg.sites_group_name AS aire_etude,
    tsg.uuid_sites_group AS uuid_aire_etude,
    tsg.sites_group_description AS description_aire,
    NULLIF(REPLACE((tsg.data::json->'habitat_principal')::text,'"',''),'null') AS habitat_principal_aire,
    NULLIF(REPLACE((tsg.data::json->'expertise')::text,'"',''),'null') AS expertise_operateur,
    tsg.comments AS commentaire_aire,
    s.base_site_name AS nom_transect,
    st_astext(s.geom) AS wkt,
    st_x(st_centroid(s.geom_local)) AS x_centroid_l93,
    st_y(st_centroid(s.geom_local)) AS y_centroid_l93,
    s.altitude_min,
    s.altitude_max,
    i.departement AS departement,
    i.code_dep AS code_dep,
    i.commune AS commune,
    i.sites_proteges AS sites_proteges,
    NULLIF(REPLACE((sc.data::json->'methode_prospection')::text,'"',''),'null') AS methode_prospection,
    NULLIF(REPLACE((sc.data::json->'type_materiaux')::text,'"',''),'null') AS type_materiaux,
    NULLIF(REPLACE((sc.data::json->'nb_plaques')::text,'"',''),'null') AS nb_plaques,
    NULLIF(REPLACE((sc.data::json->'milieu_transect')::text,'"',''),'null') AS milieu_transect,
    NULLIF(REPLACE((sc.data::json->'milieu_bordier')::text,'"',''),'null') AS milieu_bordier,
    NULLIF(REPLACE((sc.data::json->'milieu_mosaique_vegetale')::text,'"',''),'null') AS milieu_mosaique,
    NULLIF(REPLACE((sc.data::json->'milieu_homogene')::text,'"',''),'null') AS milieu_homogene,
    NULLIF(REPLACE((sc.data::json->'milieu_anthropique')::text,'"',''),'null') AS milieu_anthropique,
    NULLIF(REPLACE((sc.data::json->'milieu_transect_autre')::text,'"',''),'null') AS milieu_anthropique_autre,
    NULLIF(REPLACE((sc.data::json->'microhabitat_favorable')::text,'"',''),'null') AS microhab_favorable,
    NULLIF(REPLACE((sc.data::json->'frequentation_humaine')::text,'"',''),'null') AS frequentation_humaine,
    NULLIF(REPLACE((sc.data::json->'comment')::text,'"',''),'null') AS commentaire_transect,
    -- Informations sur la visite
    v.id_dataset,
    d.dataset_name AS jeu_de_donnees,
    v.uuid_base_visit AS uuid_visite,
    v.visit_date_min AS date_visite,
    NULLIF(REPLACE((vc.data::json->'Heure_debut')::text,'"',''),'null') AS heure_debut,
    NULLIF(REPLACE((vc.data::json->'Heure_fin')::text,'"',''),'null') AS heure_fin,
    NULLIF(REPLACE((vc.data::json->'num_passage')::text,'"',''),'null') AS num_passage,
    obs.observers,
    obs.organismes_rattaches,
    NULLIF(REPLACE((vc.data::json->'meteo')::text,'"',''),'null') AS meteo,
    NULLIF(REPLACE((vc.data::json->'vent')::text,'"',''),'null') AS vent,
    v.comments AS commentaire_visite,
    -- Informations sur l'observation
    o.cd_nom,
    NULLIF(REPLACE((oc.data::json->'presence')::text,'"',''),'null') AS presence_reptile,
    t.lb_nom AS nom_latin,
    t.nom_vern AS nom_francais,
    NULLIF(REPLACE((oc.data::json->'abondance')::text,'"',''),'null') AS abondance,
    NULLIF(REPLACE((oc.data::json->'type_denombrement')::text,'"',''),'null') AS type_denbr,
    NULLIF(REPLACE((oc.data::json->'nombre_compte')::text,'"',''),'null') AS nombre_compte,
	NULLIF(REPLACE((oc.data::json->'nombre_estime_min')::text,'"',''),'null') AS nombre_estime_min,
	NULLIF(REPLACE((oc.data::json->'nombre_estime_max')::text,'"',''),'null') AS nombre_estime_max,
    NULLIF(REPLACE((oc.data::json->'stade_vie')::text,'"',''),'null') AS stade_vie,
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
WHERE m.module_code = 'popreptile';
        

--------------------------------------------------POPReptile analyses------------------------------------------
-- View: gn_monitoring.v_export_popreptile_analyse
DROP VIEW IF EXISTS gn_monitoring.v_export_popreptile_analyses;

CREATE OR REPLACE VIEW gn_monitoring.v_export_popreptile_analyses AS
WITH observations AS (
    SELECT
        o.id_base_visit,
        count(DISTINCT t.cd_ref) AS diversite,
        string_agg(DISTINCT t.lb_nom::text, ' ; '::text) AS taxons_latin,
        string_agg(DISTINCT t.nom_vern::text, ' ; '::text) AS taxons_fr,
        sum(NULLIF(REPLACE((oc.data::json->'nombre_compte')::text,'"',''),'null')::integer) + sum(NULLIF(REPLACE((oc.data::json->'nombre_estime_min')::text,'"',''),'null')::integer) AS count_min,
        sum(NULLIF(REPLACE((oc.data::json->'nombre_compte')::text,'"',''),'null')::integer) + sum(NULLIF(REPLACE((oc.data::json->'nombre_estime_max')::text,'"',''),'null')::integer) AS count_max
    FROM gn_monitoring.t_observations o
    LEFT JOIN taxonomie.taxref t ON o.cd_nom = t.cd_nom
    LEFT JOIN gn_monitoring.t_observation_complements oc ON oc.id_observation = o.id_observation
    GROUP BY o.id_base_visit
),
obs AS
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
    string_agg(DISTINCT ((la.area_name::text || '(') ||bat.type_code::text) || ')', ', ') AS sites_proteges
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
    sites_proteges
FROM gn_monitoring.t_base_sites s
LEFT JOIN com USING (id_base_site)
LEFT JOIN dep USING (id_base_site)
LEFT JOIN zonages USING (id_base_site))
SELECT
    -- Aire et site
    tsg.sites_group_name AS aire_etude,
    tsg.uuid_sites_group AS uuid_aire_etude,
    tsg.sites_group_description AS description_aire,
    NULLIF(REPLACE((tsg.data::json->'habitat_principal')::text,'"',''),'null') AS habitat_principal_aire,
    NULLIF(REPLACE((tsg.data::json->'expertise')::text,'"',''),'null') AS expertise_operateur,
    tsg.comments AS commentaire_aire,
    s.base_site_name AS nom_transect,
    st_astext(s.geom) AS wkt,
    st_x(st_centroid(s.geom_local)) AS x_centroid_l93,
    st_y(st_centroid(s.geom_local)) AS y_centroid_l93,
    s.altitude_min,
    s.altitude_max,
    i.departement AS departement,
    i.code_dep AS code_dep,
    i.commune AS commune,
    i.sites_proteges AS sites_proteges,
    NULLIF(REPLACE((sc.data::json->'methode_prospection')::text,'"',''),'null') AS methode_prospection,
    NULLIF(REPLACE((sc.data::json->'type_materiaux')::text,'"',''),'null') AS type_materiaux,
    NULLIF(REPLACE((sc.data::json->'nb_plaques')::text,'"',''),'null') AS nb_plaques,
    NULLIF(REPLACE((sc.data::json->'milieu_transect')::text,'"',''),'null') AS milieu_transect,
    NULLIF(REPLACE((sc.data::json->'milieu_bordier')::text,'"',''),'null') AS milieu_bordier,
    NULLIF(REPLACE((sc.data::json->'milieu_mosaique_vegetale')::text,'"',''),'null') AS milieu_mosaique,
    NULLIF(REPLACE((sc.data::json->'milieu_homogene')::text,'"',''),'null') AS milieu_homogene,
    NULLIF(REPLACE((sc.data::json->'milieu_anthropique')::text,'"',''),'null') AS milieu_anthropique,
    NULLIF(REPLACE((sc.data::json->'milieu_transect_autre')::text,'"',''),'null') AS milieu_anthropique_autre,
    NULLIF(REPLACE((sc.data::json->'microhabitat_favorable')::text,'"',''),'null') AS microhab_favorable,
    NULLIF(REPLACE((sc.data::json->'frequentation_humaine')::text,'"',''),'null') AS frequentation_humaine,
    NULLIF(REPLACE((sc.data::json->'comment')::text,'"',''),'null') AS commentaire_transect,
    -- Visite
    v.id_dataset,
    d.dataset_name AS jeu_de_donnees,
    v.uuid_base_visit AS uuid_visite,
    v.visit_date_min AS date_visite,
    NULLIF(REPLACE((vc.data::json->'Heure_debut')::text,'"',''),'null') AS heure_debut,
    NULLIF(REPLACE((vc.data::json->'Heure_fin')::text,'"',''),'null') AS heure_fin,
    NULLIF(REPLACE((vc.data::json->'num_passage')::text,'"',''),'null') AS num_passage,
    obs.observers,
    obs.organismes_rattaches,
    NULLIF(REPLACE((vc.data::json->'meteo')::text,'"',''),'null') AS meteo,
    NULLIF(REPLACE((vc.data::json->'vent')::text,'"',''),'null') AS vent,
    v.comments AS commentaire_visite,
    -- synthese observations
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
WHERE m.module_code = 'popreptile';
