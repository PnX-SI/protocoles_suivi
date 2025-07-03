-- synthese.sql propre au protocole POPAmphibien.
-- Ce fichier a été généré à partir d'une copie du fichier synthese_svo.sql du module monitoring
-- (Vue générique pour alimenter la synthèse dans le cadre d'un protocole site-visite-observation)
-- 
-- Le fichier sera joué à l'installation avec la valeur de module_code qui sera attribué automatiquement
-- Il contient une variable :module_code (ou :'module_code')
-- utiliser psql avec l'option -v module_code=<module_code
-- Ne pas remplacer cette variable, elle est indispensable pour les scripts d'installations
-- le module pouvant être installé avec un code différent de l'original

DROP VIEW IF EXISTS gn_monitoring.v_synthese_POPAmphibien;

CREATE OR REPLACE VIEW gn_monitoring.v_synthese_POPAmphibien
AS WITH source AS (
    SELECT
        id_source
    FROM gn_synthese.t_sources
    WHERE name_source = CONCAT('MONITORING_', UPPER(:module_code))
    LIMIT 1
),
sites AS (
    SELECT
        id_base_site,
        base_site_name,
        altitude_min,
        altitude_max,
        geom AS the_geom_4326,
        ST_CENTROID(geom) AS the_geom_point,
        geom_local as geom_local
    FROM gn_monitoring.t_base_sites
),
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
GROUP BY id_base_visit),
visits AS (
    SELECT
        id_base_visit,
        uuid_base_visit,
        id_module,
        id_base_site,
        id_dataset,
        id_digitiser,
        visit_date_min AS date_min,
	COALESCE (visit_date_max, visit_date_min) AS date_max,
        comments
    FROM gn_monitoring.t_base_visits
),
observers AS (
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
    -- Champs obligatoires
    o.uuid_observation AS unique_id_sinp,
    obs.ids_observers,
    o.id_observation,
    o.id_observation AS entity_source_pk_value,
    -- Autres champs
    v.uuid_base_visit AS unique_id_sinp_grp,
    source.id_source,
    v.id_module as id_module,
    v.id_dataset,
    v.id_digitiser,
    ref_nomenclatures.get_id_nomenclature('NAT_OBJ_GEO', 'In') AS id_nomenclature_geo_object_nature,
    ref_nomenclatures.get_id_nomenclature('TYP_GRP', 'PASS') AS id_nomenclature_grp_typ,
    -- La méthode d'observation dépend du passage
    CASE
        -- Ne sait pas
       WHEN nullif(json_extract_path(vc.data::json, 'methode_de_prospection')::text, 'null') IS NULL THEN
            ref_nomenclatures.get_id_nomenclature('METH_OBS', '21')
        -- Identification par écoute
        WHEN json_extract_path(vc.data::json, 'methode_de_prospection')::text = '5' THEN
            ref_nomenclatures.get_id_nomenclature('METH_OBS', '1')
        -- Identification à vue
        ELSE ref_nomenclatures.get_id_nomenclature('METH_OBS', '0')
    END as id_nomenclature_obs_technique,
    -- On ne renseigne pas le bio_status : on n'en dispose pas
    ref_nomenclatures.get_id_nomenclature('ETA_BIO', '1') as id_nomenclature_bio_condition,
    -- On ne renseigne pas la naturalness : on n'en dispose pas
    -- On regarde s'il existe des médias pour transmettre les preuves
    CASE
        WHEN unique_id_media IS NOT NULL THEN ref_nomenclatures.get_id_nomenclature('PREUVE_EXIST', '1')
        ELSE ref_nomenclatures.get_id_nomenclature('PREUVE_EXIST', '2')
    END AS id_nomenclature_exist_proof,
    ref_nomenclatures.get_id_nomenclature('OBJ_DENBR', 'IND') AS id_nomenclature_obj_count,
    nullif(json_extract_path(oc.data::json,'id_nomenclature_typ_denbr')::text, 'null')::integer as id_nomenclature_type_count,
    CASE
        WHEN oc.DATA->>'presence' = 'Non' THEN ref_nomenclatures.get_id_nomenclature('STATUT_OBS', 'No')
        ELSE ref_nomenclatures.get_id_nomenclature('STATUT_OBS', 'Pr')
    END as id_nomenclature_observation_status,
    ref_nomenclatures.get_id_nomenclature('STATUT_SOURCE', 'Te') AS id_nomenclature_source_status,
    ref_nomenclatures.get_id_nomenclature('TYP_INF_GEO', '1') AS id_nomenclature_info_geo_type,
    nullif(json_extract_path(oc.data::json,'id_nomenclature_stade')::text, 'null')::integer AS id_nomenclature_life_stage,
    nullif(json_extract_path(oc.data::json,'id_nomenclature_sex')::text, 'null')::integer AS id_nomenclature_sex,
    nullif(json_extract_path(oc.data::json,'count_min')::text,'null')::integer AS count_min,
    nullif(json_extract_path(oc.data::json,'count_max')::text,'null')::integer AS count_max,
    o.cd_nom,
    t.nom_complet AS nom_cite,
    s.altitude_min,
    s.altitude_max,
    -- Normalement, pas besoin d'adapter en fonction du système de projection du module monitoring et de la synthese car ils sont sensés être cohérents.
    -- Par défaut, geom_local en lambert93 et geom en WGS84
    s.the_geom_4326,
    s.the_geom_point,
    s.geom_local AS the_geom_local,
    -- FIXME: on pourrait ajouter les horaires de visite (champs complémentaires si remplis)
    v.date_min,
    v.date_max,
    obs.observers,
    CASE
        -- Ne sait pas
        WHEN nullif(json_extract_path(vc.data::json, 'methode_de_prospection')::text, 'null') IS NULL THEN
            ref_nomenclatures.get_id_nomenclature('METH_DETERMIN', '1')
        -- Examen auditif "direct"
        WHEN json_extract_path(vc.data::json, 'methode_de_prospection')::text = '5' THEN
            ref_nomenclatures.get_id_nomenclature('METH_DETERMIN', '9')
        -- Examen visuel à "distance" (sans manipulation des individus)
        ELSE ref_nomenclatures.get_id_nomenclature('METH_DETERMIN', '18')
    END AS id_nomenclature_determination_method,
    v.comments AS comment_context,
    o.comments AS comment_description,
    -- Colonnes complémentaires qui ont leur utilité dans la fonction synthese.import_row_from_table
    v.id_base_site,
    v.id_base_visit,
    -- Informations complémentaires à conserver
    json_build_object(
	'methode_prospection', meth.meth,
        'expertise_operateur', json_extract_path(vc.DATA::json,'expertise'),
        'nom_aire', tsg.sites_group_name,
        'description_aire', tsg.sites_group_description,
        'categories_paysageres', ref_nomenclatures.get_nomenclature_label(NULLIF(json_extract_path(tsg.data::json,'categories_paysageres')::text, 'null')::integer, 'fr'),
        'commentaire_aire', tsg.comments,
        'nom_site', s.base_site_name,
        'accessibilite', json_extract_path(vc.DATA::json, 'accessibility'),
        'etat_site', json_extract_path(vc.DATA::json, 'etat_site'),
        'date_changement_etat_site', json_extract_path(vc.DATA::json, 'date_changement_etat_site'),
        'milieu_aquatique', ref_nomenclatures.get_nomenclature_label(nullif(json_extract_path(sc.data::json,'milieu_aquatique')::text,'null')::integer, 'fr'),
        'num_passage', json_extract_path(vc.data::json,'num_passage')::text,
        'heure_debut', json_extract_path(vc.data::json,'Heure_debut')::text,
        'heure_fin', json_extract_path(vc.data::json,'Heure_fin')::text
        ) as additional_data
FROM gn_monitoring.t_observations o
JOIN gn_monitoring.t_observation_complements oc USING(id_observation)
JOIN visits v USING (id_base_visit)
LEFT JOIN methods meth USING (id_base_visit)
JOIN gn_monitoring.t_visit_complements vc USING (id_base_visit)
JOIN sites s USING (id_base_site)
JOIN gn_monitoring.t_site_complements sc USING (id_base_site)
JOIN gn_monitoring.t_sites_groups tsg USING (id_sites_group)
JOIN gn_commons.t_modules m ON m.id_module = v.id_module
JOIN taxonomie.taxref t USING (cd_nom)
JOIN source ON TRUE
JOIN observers obs USING (id_base_visit)
LEFT JOIN gn_commons.t_medias tm ON (tm.id_table_location = gn_commons.get_table_location_id('gn_monitoring', 't_observations') AND tm.uuid_attached_row = o.uuid_observation)
WHERE m.module_code = :module_code;
