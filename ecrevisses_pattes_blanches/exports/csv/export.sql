-- Export des observations
DROP VIEW IF EXISTS gn_monitoring.v_export_ecrevisses_pattes_blanches_observations;

CREATE
OR REPLACE VIEW gn_monitoring.v_export_ecrevisses_pattes_blanches_observations AS
 SELECT s.base_site_code AS code_site,
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
    toc.data ->> 'nb_0_50m'::text AS nb_0_50m,
    toc.data ->> 'nb_50_100m'::text AS nb_50_100m,
    toc.data ->> 'nb_100_150m'::text AS nb_100_150m,
    toc.data ->> 'nb_150_200m'::text AS nb_150_200m,
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
  WHERE m.module_code::text = 'ecrevisses_pattes_blanches'::text;



-- Export matrice analyse

DROP VIEW IF EXISTS gn_monitoring.v_export_ecrevisses_pattes_blanches_analyse;

CREATE OR REPLACE VIEW gn_monitoring.v_export_ecrevisses_pattes_blanches_analyse
AS WITH e_patte_blanche AS (
         SELECT obs.id_observation,
            obs.id_base_visit,
            t.cd_nom,
                CASE
                    WHEN tn.cd_nomenclature::text = 'Pr'::text THEN 1
                    ELSE 0
                END AS app_binaire,
            tn.label_default AS app,
            toc.data ->> 'nb_0_50m'::text AS nb_0_50m,
            toc.data ->> 'nb_50_100m'::text AS nb_50_100m,
            toc.data ->> 'nb_100_150m'::text AS nb_100_150m,
            toc.data ->> 'nb_150_200m'::text AS nb_150_200m
           FROM gn_monitoring.t_base_visits tbv_1
             LEFT JOIN gn_monitoring.t_visit_complements tvc_1 ON tvc_1.id_base_visit = tbv_1.id_base_visit
             JOIN gn_commons.t_modules m_1 ON m_1.id_module = tbv_1.id_module
             JOIN gn_monitoring.t_observations obs ON obs.id_base_visit = tbv_1.id_base_visit
             LEFT JOIN gn_monitoring.t_observation_complements toc ON toc.id_observation = obs.id_observation
             LEFT JOIN taxonomie.taxref t ON t.cd_nom = obs.cd_nom
             LEFT JOIN ref_nomenclatures.t_nomenclatures tn ON ((toc.data ->> 'id_nomenclature_statut_observation'::text)::integer) = tn.id_nomenclature
          WHERE m_1.module_code::text = 'ecrevisses_pattes_blanches'::text AND t.cd_nom = 18437
        ), e_americaine AS (
         SELECT obs.id_observation,
            obs.id_base_visit,
            t.cd_nom,
                CASE
                    WHEN tn.cd_nomenclature::text = 'Pr'::text THEN 1
                    ELSE 0
                END AS app_americaine_binaire,
            tn.label_default AS app_americaine,
            toc.data ->> 'nb'::text AS nb,
            toc.data ->> 'nb_0_50m'::text AS nb_0_50m,
            toc.data ->> 'nb_50_100m'::text AS nb_50_100m,
            toc.data ->> 'nb_100_150m'::text AS nb_100_150m,
            toc.data ->> 'nb_150_200m'::text AS nb_150_200m
           FROM gn_monitoring.t_base_visits tbv_1
             LEFT JOIN gn_monitoring.t_visit_complements tvc_1 ON tvc_1.id_base_visit = tbv_1.id_base_visit
             JOIN gn_commons.t_modules m_1 ON m_1.id_module = tbv_1.id_module
             JOIN gn_monitoring.t_observations obs ON obs.id_base_visit = tbv_1.id_base_visit
             LEFT JOIN gn_monitoring.t_observation_complements toc ON toc.id_observation = obs.id_observation
             LEFT JOIN taxonomie.taxref t ON t.cd_nom = obs.cd_nom
             LEFT JOIN ref_nomenclatures.t_nomenclatures tn ON ((toc.data ->> 'id_nomenclature_statut_observation'::text)::integer) = tn.id_nomenclature
          WHERE m_1.module_code::text = 'ecrevisses_pattes_blanches'::text AND t.cd_nom = 853999
        )
 SELECT s.base_site_code AS code_site,
    s.base_site_name AS nom_site,
    st_x(s.geom) AS x,
    st_y(s.geom) AS y,
    tsc.data ->> 'bassin_versant'::text AS bassin_versant,
    tsc.data ->> 'sous_bassin_versant'::text AS sous_bassin_versant,
    tbv.id_base_visit AS id_visit,
    tbv.visit_date_min AS date_visite,
    tvc.data ->> 'participants_nom'::text AS participants_nom,
    tvc.data ->> 'time_start'::text AS heure_debut,
    tvc.data ->> 'time_end'::text AS heure_fin,
    tvc.data ->> 'substrats_majoritaires'::text AS substrats_majoritaires,
    tvc.data ->> 'habitats_aquatiques'::text AS habitats_aquatiques,  
    tvc.data ->> 'periode'::text AS periode, 
    tvc.data ->> 'colmatage'::text AS colmatage, 
    tvc.data ->> 'organisme'::text AS organisme,
    tvc.data ->> 'ripisylve'::text AS ripisylve,
    tvc.data ->> 'technique'::text AS technique, 
    tvc.data ->> 'lineaire_assec_m'::text AS lineaire_assec_m, 
    tvc.data ->> 'lineaire_prospection'::text AS lineaire_prospection,
      tvc.data ->> 'conditions_d_observation'::text AS conditions_d_observation,
    tvc.data ->> 'largeur_du_cours_d_eau_m'::text AS largeur_du_cours_d_eau_m,
    tbv.comments AS commentaire,
    epb.app_binaire,
    epb.app,
    epb.nb_0_50m,
    epb.nb_50_100m,
    epb.nb_100_150m,
    epb.nb_150_200m,
    eam.app_americaine_binaire,
    eam.app_americaine,
    eam.nb as americaine_nb,
    eam.nb_0_50m as americaine_nb_0_50m,
    eam.nb_50_100m as americaine_nb_50_100m,
    eam.nb_100_150m as americaine_nb_100_150m,
    eam.nb_150_200m as americaine_nb_150_200m
   FROM gn_monitoring.t_base_sites s
     LEFT JOIN gn_monitoring.t_site_complements tsc ON s.id_base_site = tsc.id_base_site
     JOIN gn_monitoring.t_base_visits tbv ON tbv.id_base_site = s.id_base_site
     LEFT JOIN gn_monitoring.t_visit_complements tvc ON tvc.id_base_visit = tbv.id_base_visit
     JOIN gn_commons.t_modules m ON m.id_module = tbv.id_module
     LEFT JOIN e_patte_blanche epb ON epb.id_base_visit = tbv.id_base_visit
     LEFT JOIN e_americaine eam ON eam.id_base_visit = tbv.id_base_visit
  WHERE m.module_code::text = 'ecrevisses_pattes_blanches'::text;