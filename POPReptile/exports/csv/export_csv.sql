---------------------------------------------------POPReptile standard------------------------------------------
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
com_dep AS (
SELECT
    csa.id_base_site,
    la_com.area_name AS commune,
    la_dep.area_name AS departement,
    la_dep.area_code AS code_dep,
    -- Permettra de filtrer pour n'avoir qu'un ensemble (commune - département) par observation
    ROW_NUMBER() OVER (PARTITION BY csa.id_base_site ORDER BY la_com.area_code) AS row_num
FROM gn_monitoring.cor_site_area csa
JOIN ref_geo.l_areas la_com ON csa.id_area = la_com.id_area
JOIN ref_geo.bib_areas_types bat_com ON bat_com.id_type = la_com.id_type
LEFT JOIN ref_geo.l_areas la_dep ON LEFT(la_com.area_code, 2) = la_dep.area_code
JOIN ref_geo.bib_areas_types bat_dep ON bat_dep.id_type = la_dep.id_type
WHERE bat_com.type_code = 'COM' AND bat_dep.type_code = 'DEP'),
zonages AS
(SELECT
    csa.id_base_site,
    string_agg(DISTINCT ((la.area_name::text || '(') ||bat.type_code::text) || ')', ', ') AS sites_proteges
FROM ref_geo.l_areas la
JOIN ref_geo.bib_areas_types bat ON la.id_type = bat.id_type
JOIN gn_monitoring.cor_site_area csa ON csa.id_area = la.id_area
WHERE bat.type_code = ANY (ARRAY['ZNIEFF1', 'ZNIEFF2', 'ZPS', 'ZCS', 'SIC', 'RNCFS', 'RNR', 'RNN', 'ZC']::text[]) -- A reprendre ultérieurement
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
LEFT JOIN com_dep USING (id_base_site)
LEFT JOIN zonages USING (id_base_site)
-- On s'assure de ne prendre qu'un ensemble (commune - département) par observation
WHERE row_num = 1),
num_passages_calc AS
(SELECT
    id_base_visit,
    row_number() OVER (PARTITION BY id_base_site, date_part('year', visit_date_min) ORDER BY visit_date_min ASC) as num_passage_calc
FROM gn_monitoring.t_base_visits
)
SELECT
    -- identifiant unique
    o.uuid_observation,
    -- Aire et variables associées (groupe de sites)
    REPLACE(trim(unaccent(tsg.sites_group_name)), ' ', '_') AS aire_etude, -- Uniformisation des noms
    tsg.uuid_sites_group AS uuid_aire_etude,
    tsg.sites_group_description AS description_aire,
    NULLIF(REPLACE((tsg.data::json->'habitat_principal')::text,'"',''),'null') AS habitat_principal_aire,
    tsg.comments AS commentaire_aire,
    -- Transect et variables associées (site)
    REPLACE(trim(unaccent(s.base_site_name)), ' ', '_') AS nom_transect, -- Uniformisation transect
    st_astext(s.geom) AS wkt_wgs,
    st_x(st_centroid(s.geom)) AS x_centroid_wgs,
    st_y(st_centroid(s.geom)) AS y_centroid_wgs,
    -- le cast en "geography" permet de s'assurer que le résultat sera en mètre
    round(ST_length(s.geom::geography)) AS longueur_transect,
    s.altitude_min,
    s.altitude_max,
    i.departement AS departement,
    i.code_dep AS code_dep,
    i.commune AS commune,
    i.sites_proteges AS sites_proteges,
    NULLIF(REPLACE((sc.DATA::json->'milieu_transect')::TEXT,'"', ''), 'null') AS milieu_transect,
    s.base_site_description AS commentaire_transect,
    -- Informations sur le passage (visite)
    v.id_dataset,
    d.dataset_name AS jeu_de_donnees,
    v.uuid_base_visit AS uuid_passage,
    v.visit_date_min AS date_passage,
    date_part('year', v.visit_date_min) AS annee_passage,
    date_part('month', v.visit_date_min) AS mois_passage,
    NULLIF(REPLACE((vc.data::json->'Heure_debut')::text,'"',''),'null') AS heure_debut,
    NULLIF(REPLACE((vc.data::json->'Heure_fin')::text,'"',''),'null') AS heure_fin,
    NULLIF(REPLACE((vc.data::json->'num_passage')::text,'"',''),'null') AS num_passage,
    npc.num_passage_calc,
    NULLIF(REPLACE((vc.data::json->'expertise')::text,'"',''),'null') AS expertise_operateur,
    NULLIF(REPLACE((vc.data::json->'methode_prospection')::text,'"',''),'null') AS methode_prospection,
    NULLIF(REPLACE((vc.data::json->'accessibility')::text, '"', ''), 'null') AS accessibilite,
    NULLIF(REPLACE((vc.data::json->'etat_site')::text, '"', ''), 'null') AS etat_site,
    NULLIF(REPLACE((vc.data::json->'date_changement_etat_site')::text, '"', ''), 'null') AS date_changement_etat_site,
    obs.observers,
    obs.organismes_rattaches,
    v.comments AS commentaire_passage,
    -- Informations sur l'observation
    o.cd_nom,
    NULLIF(REPLACE((oc.data::json->'presence')::text,'"',''),'null') AS presence_reptile,
    t.lb_nom AS nom_latin,
    t.nom_vern AS nom_francais,
    ref_nomenclatures.get_nomenclature_label(NULLIF(json_extract_path(oc.data::json,'id_nomenclature_typ_denbr')::text, 'null')::integer, 'fr') AS type_denombrement,
	NULLIF(REPLACE((oc.data::json->'count_min')::text,'"',''),'null') AS nombre_min,
	NULLIF(REPLACE((oc.data::json->'count_max')::text,'"',''),'null') AS nombre_max,
    ref_nomenclatures.get_nomenclature_label(NULLIF(json_extract_path(oc.data::json,'id_nomenclature_stade')::text,'null')::integer, 'fr') AS stade_vie,
    ref_nomenclatures.get_nomenclature_label(NULLIF(json_extract_path(oc.data::json,'id_nomenclature_sex')::text,'null')::integer, 'fr') AS sexe,
    o.comments AS commentaire_obs
FROM gn_monitoring.t_observations o
JOIN gn_monitoring.t_observation_complements oc USING (id_observation)
JOIN gn_monitoring.t_base_visits v USING (id_base_visit)
JOIN num_passages_calc npc USING (id_base_visit)
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
        -- Attention, comptabilise les 'Squamata' mais il le faut, car potentiellement, on peut avoir vu une observation de Squamata sans le déterminer
        count(DISTINCT t.cd_ref) AS diversite,
        string_agg(DISTINCT t.lb_nom::text, ' ; '::text) AS taxons_latin,
        string_agg(DISTINCT t.nom_vern::text, ' ; '::text) AS taxons_fr,
        sum(NULLIF(REPLACE((oc.data::json->'count_min')::text,'"',''),'null')::integer) AS count_min,
        sum(NULLIF(REPLACE((oc.data::json->'count_max')::text,'"',''),'null')::integer) AS count_max
    FROM gn_monitoring.t_observations o
    LEFT JOIN taxonomie.taxref t ON o.cd_nom = t.cd_nom
    LEFT JOIN gn_monitoring.t_observation_complements oc ON oc.id_observation = o.id_observation
    WHERE oc.data->>'presence' = 'Oui'
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
com_dep AS (
SELECT
    csa.id_base_site,
    la_com.area_name AS commune,
    la_dep.area_name AS departement,
    la_dep.area_code AS code_dep,
    -- Permettra de filtrer pour n'avoir qu'un ensemble (commune - département) par observation
    ROW_NUMBER() OVER (PARTITION BY csa.id_base_site ORDER BY la_com.area_code) AS row_num
FROM gn_monitoring.cor_site_area csa
JOIN ref_geo.l_areas la_com ON csa.id_area = la_com.id_area
JOIN ref_geo.bib_areas_types bat_com ON bat_com.id_type = la_com.id_type
LEFT JOIN ref_geo.l_areas la_dep ON LEFT(la_com.area_code, 2) = la_dep.area_code
JOIN ref_geo.bib_areas_types bat_dep ON bat_dep.id_type = la_dep.id_type
WHERE bat_com.type_code = 'COM' AND bat_dep.type_code = 'DEP'),
zonages AS
(SELECT
    csa.id_base_site,
    string_agg(DISTINCT ((la.area_name::text || '(') ||bat.type_code::text) || ')', ', ') AS sites_proteges
FROM ref_geo.l_areas la
JOIN ref_geo.bib_areas_types bat ON la.id_type = bat.id_type
JOIN gn_monitoring.cor_site_area csa ON csa.id_area = la.id_area
WHERE bat.type_code = ANY (ARRAY['ZNIEFF1', 'ZNIEFF2', 'ZPS', 'ZCS', 'SIC', 'RNCFS', 'RNR', 'RNN', 'ZC']::text[]) -- A reprendre ultérieurement
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
LEFT JOIN com_dep USING (id_base_site)
LEFT JOIN zonages USING (id_base_site)
-- On s'assure de ne prendre qu'un ensemble (commune - département) par observation
WHERE row_num = 1),
num_passages_calc AS
(SELECT
    id_base_visit,
    row_number() OVER (PARTITION BY id_base_site, date_part('year', visit_date_min) ORDER BY visit_date_min ASC) as num_passage_calc
FROM gn_monitoring.t_base_visits
)
SELECT
    -- Aire et site
    REPLACE(trim(unaccent(tsg.sites_group_name)), ' ', '_') AS aire_etude, -- Uniformisation des noms
    tsg.uuid_sites_group AS uuid_aire_etude,
    tsg.sites_group_description AS description_aire,
    NULLIF(REPLACE((tsg.data::json->'habitat_principal')::text,'"',''),'null') AS habitat_principal_aire,
    tsg.comments AS commentaire_aire,
    REPLACE(trim(unaccent(s.base_site_name)), ' ', '_') AS nom_transect, -- Uniformisation transect
    st_astext(s.geom) AS wkt_wgs,
    st_x(st_centroid(s.geom)) AS x_centroid_wgs,
    st_y(st_centroid(s.geom)) AS y_centroid_wgs,
    s.altitude_min,
    s.altitude_max,
    i.departement AS departement,
    i.code_dep AS code_dep,
    i.commune AS commune,
    i.sites_proteges AS sites_proteges,
    NULLIF(REPLACE((sc.DATA::json->'milieu_transect')::TEXT,'"', ''), 'null') AS milieu_transect,
    s.base_site_description AS commentaire_transect,
    -- Informations sur le passage (visite)
    v.id_dataset,
    d.dataset_name AS jeu_de_donnees,
    v.uuid_base_visit AS uuid_passage,
    v.visit_date_min AS date_passage,
    date_part('year', v.visit_date_min) AS annee_passage,
    date_part('month', v.visit_date_min) AS mois_passage,
    NULLIF(REPLACE((vc.data::json->'Heure_debut')::text,'"',''),'null') AS heure_debut,
    NULLIF(REPLACE((vc.data::json->'Heure_fin')::text,'"',''),'null') AS heure_fin,
    NULLIF(REPLACE((vc.data::json->'num_passage')::text,'"',''),'null') AS num_passage,
    npc.num_passage_calc,
    NULLIF(REPLACE((vc.data::json->'expertise')::text,'"',''),'null') AS expertise_operateur,
    NULLIF(REPLACE((vc.data::json->'methode_prospection')::text,'"',''),'null') AS methode_prospection,
    NULLIF(REPLACE((vc.data::json->'accessibility')::text, '"', ''), 'null') AS accessibilite,
    NULLIF(REPLACE((vc.data::json->'etat_site')::text, '"', ''), 'null') AS etat_site,
    NULLIF(REPLACE((vc.data::json->'date_changement_etat_site')::text, '"', ''), 'null') AS date_changement_etat_site,
    obs.observers,
    obs.organismes_rattaches,
    v.comments AS commentaire_passage,
    -- synthese observations
    observations.diversite::integer AS diversite,
    observations.taxons_latin,
    observations.taxons_fr,
    observations.count_min AS abondance_total_min,
    observations.count_max AS abondance_total_max
FROM gn_monitoring.t_base_visits v
JOIN num_passages_calc npc USING (id_base_visit)
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
