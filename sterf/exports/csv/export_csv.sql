------- Export des observations STERF ----------
 DROP VIEW  IF EXISTS gn_monitoring.v_export_sterf_standard;

CREATE OR REPLACE VIEW gn_monitoring.v_export_sterf_standard AS (
    SELECT
    -- identifiant unique
    o.uuid_observation AS uuid_observation,
    -- Site et variables associées
    s.base_site_name AS nom_transect,
    st_astext(s.geom) AS wkt_transect,
    st_x(st_centroid(s.geom_local)) AS x_centroid_local,
    st_y(st_centroid(s.geom_local)) AS y_centroid_local,
    alt.altitude_min AS altitude_min,
    alt.altitude_max AS altitude_max,
    string_agg(distinct(com.area_name),', ') AS communes,
    nullif(sc.data::json ->> 'tirage_site', 'null') AS tirage_site,
    nullif(sc.data::json ->> 'habitat_1', 'null') AS habitat_1,
    nullif(sc.data::json ->> 'habitat_2', 'null') AS habitat_2,
    nullif(sc.data::json ->> 'habitat_3', 'null') AS habitat_3,    
    nullif(sc.data::json ->> 'habitat_4', 'null') AS habitat_4,
    -- Informations sur la visite
    v.id_dataset, 
    d.dataset_name AS jeu_de_donnees,
    v.uuid_base_visit AS uuid_visite,
    v.visit_date_min AS date_visite,
    nullif(vc.data::json ->> 'duration', 'null') AS duree_parcours,
    obs.observers,
    nullif(vc.data::json ->> 'start_time', 'null') AS heure_debut,
    nullif(vc.data::json ->> 'meteo_cond', 'null') AS conditions_meteo,
    nullif(vc.data::json ->> 'temperature', 'null') AS temperature,
    nullif(vc.data::json ->> 'vent', 'null') AS vent,
    nullif(vc.data::json ->> 'ennuagement', 'null') AS ennuagement,
    v.comments AS commentaire_visite,
    -- Informations sur l'observation
    o.cd_nom AS cd_nom,
    t.lb_nom AS nom_latin,
    t.nom_vern AS nom_francais,
    r.prenom_role||' '||r.nom_role AS determinateur,
    nullif(oc.data::json ->> 'count_min', 'null') AS count_min,
    nullif(oc.data::json ->> 'count_max', 'null') AS count_max,
    ref_nomenclatures.get_nomenclature_label(nullif(json_extract_path(oc.data::json,'id_nomenclature_determination_method')::text,'null')::integer, 'fr') AS methode_determ,
    o.comments AS commentaire_obs
FROM gn_monitoring.t_observations o
JOIN gn_monitoring.t_observation_complements oc ON oc.id_observation = o.id_observation
JOIN gn_monitoring.t_base_visits v ON o.id_base_visit = v.id_base_visit
JOIN gn_monitoring.t_visit_complements vc ON v.id_base_visit = vc.id_base_visit
JOIN gn_monitoring.t_base_sites s ON s.id_base_site = v.id_base_site
JOIN gn_monitoring.t_site_complements sc ON sc.id_base_site = s.id_base_site
JOIN gn_commons.t_modules m ON m.id_module = v.id_module
JOIN taxonomie.taxref t ON t.cd_nom = o.cd_nom
LEFT JOIN gn_monitoring.cor_site_area csa ON csa.id_base_site = s.id_base_site
LEFT JOIN gn_meta.t_datasets d ON d.id_dataset=v.id_dataset
LEFT JOIN (select la.area_name, csa.id_base_site
    FROM ref_geo.l_areas la
    JOIN ref_geo.bib_areas_types bat ON la.id_type = bat.id_type
    JOIN gn_monitoring.cor_site_area csa ON csa.id_area = la.id_area
    WHERE bat.type_code='COM') com ON s.id_base_site = com.id_base_site
LEFT JOIN LATERAL ( SELECT array_agg(r.id_role) AS ids_observers,
    string_agg(concat(r.nom_role, ' ', r.prenom_role, ' (',org.nom_organisme,') '), ' ; '::text) AS observers
    FROM gn_monitoring.cor_visit_observer cvo
    JOIN utilisateurs.t_roles r ON r.id_role = cvo.id_role
    LEFT JOIN utilisateurs.bib_organismes org ON org.id_organisme =r.id_organisme
    WHERE cvo.id_base_visit = v.id_base_visit) obs ON true
LEFT JOIN LATERAL ref_geo.fct_get_altitude_intersection(s.geom_local) alt(altitude_min, altitude_max) ON true
LEFT JOIN utilisateurs.t_roles r ON nullif(json_extract_path(oc.data::json,'determiner')::text,'null')::integer = r.id_role
WHERE m.module_code = 'sterf'
GROUP BY 1, 2, 3, 4, 5, 6, 7, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33
);
