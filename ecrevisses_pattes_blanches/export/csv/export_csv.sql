
-- Export des observations
CREATE OR REPLACE VIEW gn_monitoring.v_export_ecrevisses_pattes_blanches_observations
AS SELECT s.id_base_site AS code_gite,
    s.base_site_name AS nom_site,
    st_x(s.geom) AS x,
    st_y(s.geom) AS y,
    tsc.data ->> 'bassin_versant'::text AS bassin_versant,
    tsc.data ->> 'sous_bassin_versant'::text AS sous_bassin_versant,
    tbv.id_base_visit AS id_visit,
    tbv.visit_date_min AS date_visite,
    tvc.data ->> 'participants_nom'::text AS participants_nom,
    tbv.comments AS commentaire,
    obs.id_observation,
    t.lb_nom AS tax_nom_scientifique,
    t.nom_vern AS tax_nom_vern,
    t.cd_nom AS tax_cd_nom,
    tn.label_default AS statut_observation,
    toc.data ->> 'nb_0_50m' as nb_0_50m,
    toc.data ->> 'nb_0_50m' as nb_0_50m,
    toc.data ->> 'nb_50_100m' as nb_50_100m,
    toc.data ->> 'nb_100_150m' as nb_100_150m,
    toc.data ->> 'nb_150_200m' as nb_150_200m,
    obs.comments AS comment_obs,
    tbv.id_dataset
   FROM gn_monitoring.t_base_sites s
     LEFT JOIN gn_monitoring.t_site_complements tsc ON s.id_base_site = tsc.id_base_site
     JOIN gn_monitoring.t_base_visits tbv ON tbv.id_base_site = s.id_base_site
     LEFT JOIN gn_monitoring.t_visit_complements tvc ON tvc.id_base_visit = tbv.id_base_visit
     JOIN gn_commons.t_modules m ON m.id_module = tbv.id_module
     JOIN gn_monitoring.t_observations obs ON obs.id_base_visit = tbv.id_base_visit
     LEFT JOIN gn_monitoring.t_observation_complements toc ON toc.id_observation = obs.id_observation
     LEFT JOIN taxonomie.taxref t ON t.cd_nom = obs.cd_nom
     LEFT JOIN ref_nomenclatures.t_nomenclatures tn ON ((toc.data ->> 'id_nomenclature_statut_observation'::text)::integer) = tn.id_nomenclature
  WHERE m.module_code = :module_code;