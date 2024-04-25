-- Export des observations
DROP VIEW gn_monitoring.v_export_ecrevisses_pattes_blanches_observations;

CREATE
OR REPLACE VIEW gn_monitoring.v_export_ecrevisses_pattes_blanches_observations AS
SELECT
  s.base_site_code AS code_site,
  s.base_site_name AS nom_site,
  st_x(s.geom) AS x,
  st_y(s.geom) AS y,
  tsc.data ->> 'bassin_versant' :: text AS bassin_versant,
  tsc.data ->> 'sous_bassin_versant' :: text AS sous_bassin_versant,
  tbv.id_base_visit AS id_visit,
  tbv.visit_date_min AS date_visite,
  tvc.data ->> 'participants_nom' :: text AS participants_nom,
  tbv.comments AS commentaire,
  obs.id_observation,
  t.lb_nom AS tax_nom_scientifique,
  t.nom_vern AS tax_nom_vern,
  t.cd_nom AS tax_cd_nom,
  tn.label_default AS statut_observation,
  toc.data ->> 'nb_0_50m' as nb_0_50m,
  toc.data ->> 'nb_50_100m' as nb_50_100m,
  toc.data ->> 'nb_100_150m' as nb_100_150m,
  toc.data ->> 'nb_150_200m' as nb_150_200m,
  obs.comments AS comment_obs,
  tbv.id_dataset
FROM
  gn_monitoring.t_base_sites s
  LEFT JOIN gn_monitoring.t_site_complements tsc ON s.id_base_site = tsc.id_base_site
  JOIN gn_monitoring.t_base_visits tbv ON tbv.id_base_site = s.id_base_site
  LEFT JOIN gn_monitoring.t_visit_complements tvc ON tvc.id_base_visit = tbv.id_base_visit
  JOIN gn_commons.t_modules m ON m.id_module = tbv.id_module
  JOIN gn_monitoring.t_observations obs ON obs.id_base_visit = tbv.id_base_visit
  LEFT JOIN gn_monitoring.t_observation_complements toc ON toc.id_observation = obs.id_observation
  LEFT JOIN taxonomie.taxref t ON t.cd_nom = obs.cd_nom
  LEFT JOIN ref_nomenclatures.t_nomenclatures tn ON (
    (
      toc.data ->> 'id_nomenclature_statut_observation' :: text
    ) :: integer
  ) = tn.id_nomenclature
WHERE
  m.module_code = :module_code;

CREATE
OR REPLACE VIEW gn_monitoring.v_export_ecrevisses_pattes_blanches_analyse AS WITH e_patte_blanche AS (
  SELECT
    obs.id_observation,
    obs.id_base_visit,
    t.cd_nom,
    CASE
      WHEN tn.cd_nomenclature = 'Pr' THEN 1
      ELSE 0
    END AS app_binaire,
    tn.label_default AS app,
    toc.data ->> 'nb_0_50m' as nb_0_50m,
    toc.data ->> 'nb_50_100m' as nb_50_100m,
    toc.data ->> 'nb_100_150m' as nb_100_150m,
    toc.data ->> 'nb_150_200m' as nb_150_200m
  FROM
    gn_monitoring.t_base_visits tbv
    LEFT JOIN gn_monitoring.t_visit_complements tvc ON tvc.id_base_visit = tbv.id_base_visit
    JOIN gn_commons.t_modules m ON m.id_module = tbv.id_module
    JOIN gn_monitoring.t_observations obs ON obs.id_base_visit = tbv.id_base_visit
    LEFT JOIN gn_monitoring.t_observation_complements toc ON toc.id_observation = obs.id_observation
    LEFT JOIN taxonomie.taxref t ON t.cd_nom = obs.cd_nom
    LEFT JOIN ref_nomenclatures.t_nomenclatures tn ON (
      (
        toc.data ->> 'id_nomenclature_statut_observation' :: text
      ) :: integer
    ) = tn.id_nomenclature
  WHERE
    m.module_code = :module_code
    AND t.cd_nom = 18437
),
e_americaine AS (
  SELECT
    obs.id_observation,
    obs.id_base_visit,
    t.cd_nom,
    CASE
      WHEN tn.cd_nomenclature = 'Pr' THEN 1
      ELSE 0
    END AS app_americaine_binaire,
    tn.label_default AS app_americaine
  FROM
    gn_monitoring.t_base_visits tbv
    LEFT JOIN gn_monitoring.t_visit_complements tvc ON tvc.id_base_visit = tbv.id_base_visit
    JOIN gn_commons.t_modules m ON m.id_module = tbv.id_module
    JOIN gn_monitoring.t_observations obs ON obs.id_base_visit = tbv.id_base_visit
    LEFT JOIN gn_monitoring.t_observation_complements toc ON toc.id_observation = obs.id_observation
    LEFT JOIN taxonomie.taxref t ON t.cd_nom = obs.cd_nom
    LEFT JOIN ref_nomenclatures.t_nomenclatures tn ON (
      (
        toc.data ->> 'id_nomenclature_statut_observation' :: text
      ) :: integer
    ) = tn.id_nomenclature
  WHERE
    m.module_code = :module_code
    AND NOT t.cd_nom = 853999
)
SELECT
  s.id_base_site AS code_site,
  s.base_site_name AS nom_site,
  st_x(s.geom) AS x,
  st_y(s.geom) AS y,
  tsc.data ->> 'bassin_versant' :: text AS bassin_versant,
  tsc.data ->> 'sous_bassin_versant' :: text AS sous_bassin_versant,
  tbv.id_base_visit AS id_visit,
  tbv.visit_date_min AS date_visite,
  tvc.data ->> 'participants_nom' :: text AS participants_nom,
  tvc.data ->> 'blocs' as blocs,
  tvc.data ->> 'dalle' as dalle,
  tvc.data ->> 'litiere' as litiere,
  tvc.data ->> 'periode' as periode,
  tvc.data ->> 'graviers' as graviers,
  tvc.data ->> 'colmatage' as colmatage,
  tvc.data ->> 'evolution' as evolution,
  tvc.data ->> 'organisme' as organisme,
  tvc.data ->> 'ripisylve' as ripisylve,
  tvc.data ->> 'technique' as technique,
  tvc.data ->> 'limon_sable' as limon_sable,
  tvc.data ->> 'sous_berges' as sous_berges,
  tvc.data ->> 'pierre_galets' as pierre_galets,
  tvc.data ->> 'lineaire_assec_m' as lineaire_assec_m,
  tvc.data ->> 'chevelu_racinaire' as chevelu_racinaire,
  tvc.data ->> 'embacle_branchage' as embacle_branchage,
  tvc.data ->> 'occupation_du_sol' as occupation_du_sol,
  tvc.data ->> 'etat_de_la_ripisylve' as etat_de_la_ripisylve,
  tvc.data ->> 'lineaire_prospection' as lineaire_prospection,
  tvc.data ->> 'vegetation_aquatique' as vegetation_aquatique,
  tvc.data ->> 'remarques_normalisées' as remarques_normalisées,
  tvc.data ->> 'conditions_d_observation' as conditions_d_observation,
  tvc.data ->> 'largeur_du_cours_d_eau_cm' as largeur_du_cours_d_eau_cm,
  tbv.comments AS commentaire,
  epb.app_binaire,
  epb.app,
  epb.nb_0_50m,
  epb.nb_50_100m,
  epb.nb_100_150m,
  epb.nb_150_200m,
  app_americaine_binaire,
  app_americaine
FROM
  gn_monitoring.t_base_sites s
  LEFT JOIN gn_monitoring.t_site_complements tsc ON s.id_base_site = tsc.id_base_site
  JOIN gn_monitoring.t_base_visits tbv ON tbv.id_base_site = s.id_base_site
  LEFT JOIN gn_monitoring.t_visit_complements tvc ON tvc.id_base_visit = tbv.id_base_visit
  JOIN gn_commons.t_modules m ON m.id_module = tbv.id_module
  JOIN e_patte_blanche epb ON epb.id_base_visit = tbv.id_base_visit
  JOIN e_americaine eam ON eam.id_base_visit = tbv.id_base_visit
WHERE
  m.module_code = :module_code;