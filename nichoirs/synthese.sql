
-- Vue générique pour alimenter la synthèse dans le cadre d'un protocole site-visite-observation
--
-- Ce fichier peut être copié dans le dossier du sous-module et renommé en synthese.sql (et au besoin personnalisé)
-- le fichier sera joué à l'installation avec la valeur de module_code qui sera attribué automatiquement
--
--
-- Personalisations possibles
--
--  - ajouter des champs specifiques qui peuvent alimenter la synthese
--      jointure avec les table de complement
--
--  - choisir les valeurs de champs de nomenclatures qui seront propres au modules
--
-- Spécificité du module nichoirs : un site peut être un nichoir unique (nb_nichoirs = 1)
-- ou un groupe de nichoirs identiques sur une même façade (nb_nichoirs > 1).
--  - nichoir unique     : dénombrement compté d'individus = adultes + oeufs + jeunes vivants + jeunes morts
--  - groupe de nichoirs : dénombrement estimé
--                           . oiseaux : de nids = nombre de nichées estimé, à défaut nombre de nichoirs occupés
--                           . autres (chiroptères…) : effectif non connu (NSP, sans nombre)
--  - statut biologique : « Reproduction » uniquement sur preuve
--                           . nichoir unique : oeufs ou jeunes (vivants ou morts) > 0
--                           . groupe d'oiseaux : nichées estimées ou nichoirs occupés > 0
--                        sinon « Non renseigné » (un adulte seul ne suffit pas : dortoir possible)
--  - additional_data : type de nichoir, nombre de nichoirs, nichoirs occupés, nichées estimées


-- ce fichier contient une variable :module_code (ou :'module_code')
-- utiliser psql avec l'option -v module_code=<module_code

-- ne pas remplacer cette variable, elle est indispensable pour les scripts d'installations
-- le module pouvant être installé avec un code différent de l'original

DROP VIEW IF EXISTS gn_monitoring.v_synthese_nichoirs;
CREATE OR REPLACE VIEW gn_monitoring.v_synthese_nichoirs AS
WITH t_source AS (SELECT t_sources.id_source
                  FROM gn_synthese.t_sources
                  WHERE t_sources.name_source::text = concat('MONITORING_', upper('NICHOIRS'::text))),
     observers AS (SELECT array_agg(r.id_role)                                            AS ids_observers,
                          string_agg(concat(r.nom_role, ' ', r.prenom_role), ' ; '::text) AS observers,
                          cvo.id_base_visit
                   FROM gn_monitoring.cor_visit_observer cvo
                            JOIN utilisateurs.t_roles r ON r.id_role = cvo.id_role
                   GROUP BY cvo.id_base_visit),
     -- valeurs numériques des champs spécifiques (vides ou non numériques -> NULL)
     obs_values AS (SELECT toc.id_observation,
                           CASE WHEN (toc.data ->> 'adulte') ~ '^\d+$' THEN (toc.data ->> 'adulte')::integer END             AS adulte,
                           CASE WHEN (toc.data ->> 'oeuf') ~ '^\d+$' THEN (toc.data ->> 'oeuf')::integer END                 AS oeuf,
                           CASE WHEN (toc.data ->> 'jeune_vivant') ~ '^\d+$' THEN (toc.data ->> 'jeune_vivant')::integer END AS jeune_vivant,
                           CASE WHEN (toc.data ->> 'jeune_mort') ~ '^\d+$' THEN (toc.data ->> 'jeune_mort')::integer END     AS jeune_mort,
                           CASE WHEN (toc.data ->> 'nb_nichoirs_occupes') ~ '^\d+$'
                                THEN (toc.data ->> 'nb_nichoirs_occupes')::integer END                                       AS nb_nichoirs_occupes,
                           CASE WHEN (toc.data ->> 'nb_nichees_estimees') ~ '^\d+$'
                                THEN (toc.data ->> 'nb_nichees_estimees')::integer END                                       AS nb_nichees_estimees
                    FROM gn_monitoring.t_observation_complements toc),
     site_values AS (SELECT tsc.id_base_site,
                            tsc.id_sites_group,
                            tsc.data ->> 'nichoir_type'                                  AS nichoir_type,
                            COALESCE(CASE WHEN (tsc.data ->> 'nb_nichoirs') ~ '^\d+$'
                                          THEN (tsc.data ->> 'nb_nichoirs')::integer END, 1) AS nb_nichoirs
                     FROM gn_monitoring.t_site_complements tsc)
SELECT to2.uuid_observation                                                                               AS unique_id_sinp,
       tbs.uuid_base_site                                                                                 AS unique_id_sinp_grp,
       t_source.id_source,
       tbv.id_module,
       --to2.id_observation                                                                                  AS entity_source_pk_value,
       tbv.id_dataset,
       ref_nomenclatures.get_id_nomenclature('NAT_OBJ_GEO'::character varying,
                                             'St'::character varying)                                     AS id_nomenclature_geo_object_nature,
       ref_nomenclatures.get_id_nomenclature('OBJ_DENBR'::character varying, cnt.obj_denbr::character varying) AS id_nomenclature_obj_count,
       ref_nomenclatures.get_id_nomenclature('TYP_DENBR'::character varying, cnt.typ_denbr::character varying) AS id_nomenclature_type_count,
       ref_nomenclatures.get_id_nomenclature('STATUT_BIO'::character varying,
                                             CASE WHEN repro.est_reproduction THEN '3' ELSE '1' END::character varying)
                                                                                                          AS id_nomenclature_bio_status,
       ref_nomenclatures.get_id_nomenclature('STATUT_OBS'::character varying,
                                             'Pr'::character varying)                                     AS id_nomenclature_observation_status,
       ref_nomenclatures.get_id_nomenclature('STATUT_SOURCE'::character varying,
                                             'Te'::character varying)                                     AS id_nomenclature_source_status,
       ref_nomenclatures.get_id_nomenclature('TYP_INF_GEO'::character varying,
                                             '1'::character varying)                                      AS id_nomenclature_info_geo_type,
       cnt.nb                                                                                             AS count_min,
       cnt.nb                                                                                             AS count_max,
       to2.cd_nom,
       t.nom_complet                                                                                      AS nom_cite,
       tbs.altitude_min,
       tbs.altitude_max,
       tbs.geom                                                                                           AS the_geom_4326,
       st_centroid(tbs.geom)                                                                              AS the_geom_point,
       tbs.geom_local                                                                                     AS the_geom_local,
       tbv.visit_date_min                                                                                 AS date_min,
       COALESCE(tbv.visit_date_max, tbv.visit_date_min)                                                   AS date_max,
       tbs.id_inventor                                                                                    AS id_digitiser,
       concat(tr.nom_role, ' ', tr.prenom_role)                                                           AS observers,
       obs.ids_observers[1]                                                                               AS ids_observers,
       tbv.comments                                                                                       AS comment_context,
       CASE
           WHEN grp.est_groupe
               THEN concat_ws(' | ',
                              'Groupe de ' || sv.nb_nichoirs || ' nichoirs',
                              'nichoirs occupés : ' || ov.nb_nichoirs_occupes,
                              'nichées estimées : ' || ov.nb_nichees_estimees,
                              NULLIF(to2.comments, ''))
           ELSE to2.comments
           END                                                                                            AS comment_description,
       json_build_object(
               'type_nichoir', sv.nichoir_type,
               'nb_nichoirs', COALESCE(sv.nb_nichoirs, 1),
               'nb_nichoirs_occupes', ov.nb_nichoirs_occupes,
               'nb_nichees_estimees', ov.nb_nichees_estimees
       )                                                                                                  AS additional_data,
       sv.id_sites_group,
       tbs.id_base_site,
       tbv.id_base_visit,
       to2.id_observation
FROM gn_monitoring.t_base_sites tbs
         LEFT JOIN site_values sv ON sv.id_base_site = tbs.id_base_site
         LEFT JOIN gn_monitoring.t_base_visits tbv ON tbs.id_base_site = tbv.id_base_site
         LEFT JOIN observers obs ON obs.id_base_visit = tbv.id_base_visit
         LEFT JOIN gn_monitoring.t_observations to2 ON to2.id_base_visit = tbv.id_base_visit
         LEFT JOIN obs_values ov ON ov.id_observation = to2.id_observation
         LEFT JOIN utilisateurs.t_roles tr ON tr.id_role = obs.ids_observers[1]
         LEFT JOIN taxonomie.taxref t ON to2.cd_nom = t.cd_nom
         LEFT JOIN t_source ON true
         -- nichoir unique ou groupe, oiseau ou non
         LEFT JOIN LATERAL (
             SELECT COALESCE(sv.nb_nichoirs, 1) > 1      AS est_groupe,
                    COALESCE(t.classe = 'Aves', false)    AS est_oiseau
             ) grp ON true
         -- dénombrement
         LEFT JOIN LATERAL (
             SELECT CASE
                        WHEN NOT grp.est_groupe THEN COALESCE(ov.adulte, 0) + COALESCE(ov.oeuf, 0)
                                                     + COALESCE(ov.jeune_vivant, 0) + COALESCE(ov.jeune_mort, 0)
                        -- nids / nichées : seulement pour les oiseaux ; sinon effectif inconnu
                        WHEN grp.est_oiseau THEN COALESCE(ov.nb_nichees_estimees, ov.nb_nichoirs_occupes)
                        END AS nb,
                    CASE
                        WHEN NOT grp.est_groupe THEN 'IND'
                        WHEN grp.est_oiseau AND COALESCE(ov.nb_nichees_estimees, ov.nb_nichoirs_occupes) IS NOT NULL THEN 'NID'
                        ELSE 'NSP'
                        END AS obj_denbr,
                    CASE WHEN grp.est_groupe THEN 'Es' ELSE 'Co' END AS typ_denbr
             ) cnt ON true
         -- statut biologique : reproduction uniquement sur preuve
         LEFT JOIN LATERAL (
             SELECT (NOT grp.est_groupe
                        AND COALESCE(ov.oeuf, 0) + COALESCE(ov.jeune_vivant, 0) + COALESCE(ov.jeune_mort, 0) > 0)
                        OR (grp.est_groupe AND grp.est_oiseau
                            AND COALESCE(ov.nb_nichees_estimees, ov.nb_nichoirs_occupes, 0) > 0) AS est_reproduction
             ) repro ON true
         LEFT JOIN gn_commons.t_modules tm ON tm.id_module = tbv.id_module
WHERE tm.module_label::text ~~* 'Nichoirs'::text
  AND to2.cd_nom IS NOT NULL
  AND to2.uuid_observation IS NOT NULL;
