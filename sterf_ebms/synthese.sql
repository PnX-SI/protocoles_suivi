-- Vue de synthèse du module Sterf-eBMS.

DROP VIEW IF EXISTS gn_monitoring.v_synthese_sterf_ebms;
CREATE VIEW gn_monitoring.v_synthese_sterf_ebms AS

WITH
    source AS (
        SELECT id_source
        FROM gn_synthese.t_sources
        WHERE name_source = CONCAT('MONITORING_STERF_EBMS')
        LIMIT 1
    ),
    sections AS (
        SELECT
            tbs.id_base_site,
            tbs.base_site_name,
            tbs.geom AS the_geom_4326,
            ST_Centroid(tbs.geom) AS the_geom_point,
            tbs.geom_local AS geom_local,
            (tsg.data->>'sensitivity')::text AS sensitivity,
            tsg.sites_group_name
        FROM gn_monitoring.t_base_sites tbs
        JOIN gn_monitoring.t_site_complements tsc USING (id_base_site)
        JOIN gn_monitoring.t_sites_groups tsg USING (id_sites_group)
    ),
    visits AS (
        SELECT
            id_base_visit,
            uuid_base_visit,
            id_module,
            id_base_site,
            id_dataset,
            id_digitiser,
            visit_date_min AS date_min,
            COALESCE(visit_date_max, visit_date_min) AS date_max,
            comments,
            id_nomenclature_tech_collect_campanule,
            id_nomenclature_grp_typ
        FROM gn_monitoring.t_base_visits
    ),
    observers AS (
        SELECT
            array_agg(r.id_role) AS ids_observers,
            STRING_AGG(CONCAT(r.nom_role, ' ', prenom_role), ' ; ') AS observers,
            id_base_visit
        FROM gn_monitoring.cor_visit_observer cvo
        JOIN utilisateurs.t_roles r USING (id_role)
        GROUP BY id_base_visit
    )
SELECT
    -- UUID de l'observation.
    o.uuid_observation AS unique_id_sinp,
    -- UUID de la visite, qui sert d'UUID de regroupement.
    v.uuid_base_visit AS unique_id_sinp_grp,
    -- ID de la source de synthèse (= module).
    source.id_source,
    -- ID du module configuré pour la visite.
    v.id_module,
    -- Clé externe de l'observation.
    o.id_observation AS entity_source_pk_value,
    -- Jeu de données configuré pour la visite.
    v.id_dataset,
    -- Nature d'objet géographique = inventoriel.
    ref_nomenclatures.get_id_nomenclature('NAT_OBJ_GEO', 'In') AS id_nomenclature_geo_object_nature,
    -- Type de regroupement, "Passage" par défaut.
    COALESCE(v.id_nomenclature_grp_typ, ref_nomenclatures.get_id_nomenclature('TYP_GRP', 'PASS')) AS id_nomenclature_grp_typ,
    -- Méthodes d'observation = vu.
    ref_nomenclatures.get_id_nomenclature('METH_OBS', '0') AS id_nomenclature_obs_technique,
    -- Statut biologique = non renseigné.
    ref_nomenclatures.get_id_nomenclature('STATUT_BIO', '1') AS id_nomenclature_bio_status,
    -- État biologique = vivant.
    ref_nomenclatures.get_id_nomenclature('ETA_BIO', '2') AS id_nomenclature_bio_condition,
    -- Niveau de naturalité = sauvage.
    ref_nomenclatures.get_id_nomenclature('NATURALITE', '1') AS id_nomenclature_naturalness,
    -- Preuve existante = inconnu.
    ref_nomenclatures.get_id_nomenclature('PREUVE_EXIST', '0') AS id_nomenclature_exist_proof,
    -- Statut de validation = en attente de validation.
    ref_nomenclatures.get_id_nomenclature('STATUT_VALID', '0') AS id_nomenclature_valid_status,
    -- Niveau de précision de diffusion souhaités, aucune si le transect est
    -- noté comme sensible, sinon niveau de diffusion standard.
    ref_nomenclatures.get_id_nomenclature(
        'NIV_PRECIS',
        CASE WHEN s.sensitivity = 'Oui' THEN '4' ELSE '0' END
    ) AS id_nomenclature_diffusion_level,
    -- Stade de vie = imago.
    ref_nomenclatures.get_id_nomenclature('STADE_VIE', '15') AS id_nomenclature_life_stage,
    -- Sexe = indéterminé.
    ref_nomenclatures.get_id_nomenclature('SEXE', '1') AS id_nomenclature_sex,
    -- Objet du dénombrement = individus.
    ref_nomenclatures.get_id_nomenclature('OBJ_DENBR', 'IND') AS id_nomenclature_obj_count,
    -- Type de dénombrement = compté.
    ref_nomenclatures.get_id_nomenclature('TYP_DENBR', 'Co') AS id_nomenclature_type_count,
    -- Niveau de sensibilité, aucune diffusion permise si le transect est noté
    -- comme sensible, sinon niveau non sensible.
    ref_nomenclatures.get_id_nomenclature(
        'SENSIBILITE',
        CASE WHEN s.sensitivity = 'Oui' THEN '4' ELSE '0' END
    ) AS id_nomenclature_sensitivity,
    -- Statut de l'observation, présence ou non, en fonction de l'effectif.
    ref_nomenclatures.get_id_nomenclature(
        'STATUT_OBS',
        CASE WHEN (toc.data->'effectif')::integer > 0 THEN 'Pr' ELSE 'No' END
    ) AS id_nomenclature_observation_status,
    -- Existence d'un floutage sur la donnée = non.
    -- La donnée n'a pas été floutée, même si le transect est sensible ; cette
    -- information est contenue dans un autre champ.
    ref_nomenclatures.get_id_nomenclature('DEE_FLOU', 'NON') AS id_nomenclature_blurring,
    -- Statut de la source = la donnée vient du terrain.
    ref_nomenclatures.get_id_nomenclature('STATUT_SOURCE', 'Te') AS id_nomenclature_source_status,
    -- Type d'information géographique = géoréférencement.
    ref_nomenclatures.get_id_nomenclature('TYP_INF_GEO', '1') AS id_nomenclature_info_geo_type,
    -- Comportement des occurrences observées = non renseigné.
    ref_nomenclatures.get_id_nomenclature('OCC_COMPORTEMENT', '1') AS id_nomenclature_behaviour,
    -- Décompte minimal.
    (toc.data->'effectif')::integer AS count_min,
    -- Décompte maximal.
    (toc.data->'effectif')::integer AS count_max,
    -- CD_NOM de l'espèce.
    o.cd_nom,
    -- Nom complet cité.
    t.nom_complet AS nom_cite,
    -- Altitude minimale (déduite de la position).
    alt.altitude_min,
    -- Altitude maximale (déduite de la position).
    alt.altitude_max,
    -- Nom de l'emplacement = nom de la section ou du transect.
    COALESCE(s.base_site_name, s.sites_group_name) as place_name,
    -- Géométrie WGS 84.
    s.the_geom_4326,
    -- Centroïde WGS 84.
    s.the_geom_point,
    -- Géométrie dans le référentiel local de l'instance.
    s.geom_local as the_geom_local,
    -- Date minimale = date de la visite.
    v.date_min,
    -- Date minimale = date de la visite.
    v.date_max,
    -- Observateur·ice·s.
    obs.observers,
    -- Détermination = observateur·ice·s.
    obs.observers AS determiner,
    -- Personne ayant renseigné la visite.
    v.id_digitiser,
    -- Méthode de détermination = non renseigné.
    ref_nomenclatures.get_id_nomenclature('METH_DETERMIN', '1') AS id_nomenclature_determination_method,
    -- Commentaires sur la visite.
    v.comments AS comment_context,
    -- Commentaires sur l'occurence.
    o.comments AS comment_description,
    -- Colonnes complémentaires qui ont leur utilité dans la fonction synthese.import_row_from_table
    v.id_base_site,
    v.id_base_visit,
    obs.ids_observers
FROM gn_monitoring.t_observations o
JOIN gn_monitoring.t_observation_complements toc USING (id_observation)
JOIN visits v USING (id_base_visit)
JOIN sections s USING (id_base_site)
JOIN gn_commons.t_modules m USING (id_module)
JOIN taxonomie.taxref t USING (cd_nom)
JOIN source ON TRUE
JOIN observers obs USING (id_base_visit)
LEFT JOIN LATERAL ref_geo.fct_get_altitude_intersection(s.geom_local) alt (altitude_min, altitude_max) ON TRUE
WHERE m.module_code = 'sterf_ebms'
;
