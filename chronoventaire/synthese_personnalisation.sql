-- Visualisation des données dans un projet QGIS
CREATE OR REPLACE VIEW gn_monitoring.v_qgis_chronoventaire
AS WITH observers AS (
         SELECT array_agg(r.id_role) AS ids_observers,
            string_agg(concat(r.nom_role, ' ', r.prenom_role), ' ; '::text) AS observers,
            cvo.id_base_visit
           FROM gn_monitoring.cor_visit_observer cvo
             JOIN utilisateurs.t_roles r ON r.id_role = cvo.id_role
          GROUP BY cvo.id_base_visit
        )
 SELECT to2.id_observation AS id,
    tbs.base_site_name,
    st_pointonsurface(tbs.geom_local) AS geom,
    tbv.visit_date_min AS date_min,
    COALESCE(tbv.visit_date_max, tbv.visit_date_min) AS date_max,
    tvc.data #>> '{wind}'::text[] AS vent,
    tvc.data #>> '{duration}'::text[] AS temps_inventaires,
    tvc.data #>> '{cloudiness}'::text[] AS nuages,
    tvc.data #>> '{time_start}'::text[] AS heures_debut,
    tvc.data #>> '{floral_availability}'::text[] AS dispo_florale,
    tvc.data #>> '{group_chronoventaire}'::text[] AS group_chrono,
    concat(tr.nom_role, ' ', tr.prenom_role) AS observers,
    tbv.comments AS comment_visit,
    to2.cd_nom,
    t.nom_complet AS nom_cite,
    ref_nomenclatures.get_nomenclature_label((toc.data #>> '{id_nomenclature_stade}'::text[])::integer) AS life_stage,
    ref_nomenclatures.get_nomenclature_label((toc.data #>> '{id_sexe}'::text[])::integer) AS sex,
    ref_nomenclatures.get_nomenclature_label((toc.data #>> '{id_nomenclature_determination_method}'::text[])::integer) AS determination_method,
    ref_nomenclatures.get_id_nomenclature('STADE_VIE'::character varying, ((toc.data #>> '{id_nomenclature_stade}'::text[]))::character(1)::character varying) AS nomenclature_life_stage,
    ref_nomenclatures.get_id_nomenclature('SEXE'::character varying, ((toc.data #>> '{id_sexe}'::text[]))::character(1)::character varying) AS nomenclature_sex,
    ref_nomenclatures.get_id_nomenclature('METH_DETERMIN'::character varying, ((toc.data #>> '{id_nomenclature_determination_method}'::text[]))::character(1)::character varying) AS nomenclature_determination_method,
    toc.data #>> '{id_nomenclature_stade}'::text[] AS id_nomenclature_life_stage,
    toc.data #>> '{id_sexe}'::text[] AS id_nomenclature_sex,
    toc.data #>> '{id_nomenclature_determination_method}'::text[] AS id_nomenclature_determination_method,
    toc.data #>> '{nb_count}'::text[] AS count_min,
    toc.data #>> '{nb_count}'::text[] AS count_max,
    to2.comments AS comment_obs
   FROM gn_monitoring.t_base_sites tbs
     LEFT JOIN gn_monitoring.t_site_complements tsc ON tsc.id_base_site = tbs.id_base_site
     LEFT JOIN gn_monitoring.t_base_visits tbv ON tbs.id_base_site = tbv.id_base_site
     LEFT JOIN gn_monitoring.t_visit_complements tvc ON tvc.id_base_visit = tbv.id_base_visit
     LEFT JOIN observers obs ON obs.id_base_visit = tbv.id_base_visit
     LEFT JOIN gn_monitoring.t_observations to2 ON to2.id_base_visit = tbv.id_base_visit
     LEFT JOIN gn_monitoring.t_observation_complements toc ON toc.id_observation = to2.id_observation
     LEFT JOIN utilisateurs.t_roles tr ON tr.id_role = tbv.id_digitiser
     LEFT JOIN taxonomie.taxref t ON to2.cd_nom = t.cd_nom
     LEFT JOIN gn_commons.t_modules tm ON tm.id_module = tsc.id_module
  WHERE tm.module_label::text ~~* 'ChronoVentaire'::text;