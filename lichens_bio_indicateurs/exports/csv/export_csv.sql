DROP VIEW IF EXISTS gn_monitoring.v_export_lichens_bio_indicateurs_placettes;
-- gn_monitoring.v_export_lichens_bio_indicateurs_placettes source

CREATE OR REPLACE VIEW gn_monitoring.v_export_lichens_bio_indicateurs_placettes
AS SELECT s.id_base_site AS code_placette,
    s.base_site_name AS nom_placette,
    s.altitude_min,
    s.altitude_max,
    concat_ws(' '::text, tr.nom_role, tr.prenom_role) AS descripteur,
    st_astext(s.geom) AS geom_wkt,
    a.jname ->> 'COM'::text AS commune,
    a.jname ->> 'MASSIF'::text AS massif,
    s.base_site_description AS description,
    tsc.data ->> 'pente'::text AS pente,
    tn.label_default AS exposition,
    tsc.data ->> 'exposition_grade'::text AS exposition_grade,
    tsc.data ->> 'confinement'::text AS confinement,
    (((tvc.data ->> 'densite_couvert_n'::text)::numeric) + ((tvc.data ->> 'densite_couvert_e'::text)::numeric) + ((tvc.data ->> 'densite_couvert_s'::text)::numeric) + ((tvc.data ->> 'densite_couvert_o'::text)::numeric)) / 4::numeric * 1.04 AS densite_couvert,
    tbv.visit_date_min,
    obs.observateurs,
    tbv.comments,
    tbv.id_dataset,
    tvc.data ->> 'time_end'::text AS time_end,
    tvc.data ->> 'time_start'::text AS time_start,
    tvc.data ->> 'habitat_associe'::text AS habitat_associe,
    tvc.data ->> 'densite_couvert_n'::text AS densite_couvert_n,
    tvc.data ->> 'densite_couvert_e'::text AS densite_couvert_e,
    tvc.data ->> 'densite_couvert_s'::text AS densite_couvert_s,
    tvc.data ->> 'densite_couvert_o'::text AS densite_couvert_o,
    tvc.data ->> 'habitat_principal'::text AS habitat_principal,
    tvc.data ->> 'essence_principale'::text AS essence_principale,
    tvc.data ->> 'frein_exploitation'::text AS frein_exploitation,
    tvc.data ->> 'essence_preponderante'::text AS essence_preponderante,
    tvc.data ->> 'nb_arbres_dmh_loge_pics'::text AS nb_arbres_dmh_loge_pics,
    tvc.data ->> 'nb_arbres_dmh_dendrotelme'::text AS nb_arbres_dmh_dendrotelme,
    tvc.data ->> 'peuplement_type_structure'::text AS peuplement_type_structure,
    tvc.data ->> 'presence_tgb_hors_placette'::text AS presence_tgb_hors_placette,
    hde1.mnemonique AS hauteur_dominante_essence_1,
    tvc.data ->> 'contrainte_stationelle_forte'::text AS contrainte_stationelle_forte,
    tvc.data ->> 'hauteur_dominante_diametre_1'::text AS hauteur_dominante_diametre_1,
    tvc.data ->> 'hauteur_dominante_distance_1'::text AS hauteur_dominante_distance_1,
    tvc.data ->> 'indices_usages_passe_ou_actuel'::text AS indices_usages_passe_ou_actuel,
    tvc.data ->> 'peuplement_type_accompagnement_1'::text AS peuplement_type_accompagnement_1,
    tvc.data ->> 'peuplement_type_accompagnement_2'::text AS peuplement_type_accompagnement_2,
    tvc.data ->> 'peuplement_type_essences_objectifs_1'::text AS peuplement_type_essences_objectifs_1,
    tvc.data ->> 'peuplement_type_essences_objectifs_2'::text AS peuplement_type_essences_objectifs_2,
    tvc.data ->> 'surface_terriere_sup_17_5_inf_27_5'::text AS surface_terriere_sup_17_5_inf_27_5,
    tvc.data ->> 'surface_terriere_sup_27_5_inf_47_5'::text AS surface_terriere_sup_27_5_inf_47_5,
    tvc.data ->> 'surface_terriere_sup_47_5_inf_67_5'::text AS surface_terriere_sup_47_5_inf_67_5,
    tvc.data ->> 'surface_terriere_sup_67_5_inf_87_5'::text AS surface_terriere_sup_67_5_inf_87_5,
    tvc.data ->> 'surface_terriere_sup_87_5'::text AS surface_terriere_sup_87_5,
    tvc.data ->> 'surface_terriere_morts_sol_sup_87_5'::text AS surface_terriere_morts_sol_sup_87_5,
    tvc.data ->> 'surface_terriere_morts_debout_sup_87_5'::text AS surface_terriere_morts_debout_sup_87_5,
    tvc.data ->> 'surface_terriere_morts_sol_sup_17_5_inf_27_5'::text AS surface_terriere_morts_sol_sup_17_5_inf_27_5,
    tvc.data ->> 'surface_terriere_morts_sol_sup_27_5_inf_47_5'::text AS surface_terriere_morts_sol_sup_27_5_inf_47_5,
    tvc.data ->> 'surface_terriere_morts_sol_sup_47_5_inf_67_5'::text AS surface_terriere_morts_sol_sup_47_5_inf_67_5,
    tvc.data ->> 'surface_terriere_morts_sol_sup_67_5_inf_87_5'::text AS surface_terriere_morts_sol_sup_67_5_inf_87_5,
    tvc.data ->> 'surface_terriere_morts_debout_sup_17_5_inf_27_5'::text AS surface_terriere_morts_debout_sup_17_5_inf_27_5,
    tvc.data ->> 'surface_terriere_morts_debout_sup_27_5_inf_47_5'::text AS surface_terriere_morts_debout_sup_27_5_inf_47_5,
    tvc.data ->> 'surface_terriere_morts_debout_sup_47_5_inf_67_5'::text AS surface_terriere_morts_debout_sup_47_5_inf_67_5,
    tvc.data ->> 'surface_terriere_morts_debout_sup_67_5_inf_87_5'::text AS surface_terriere_morts_debout_sup_67_5_inf_87_5,
    tvc.data ->> 'nb_arbres_dmh_champignon_polypore'::text AS nb_arbres_dmh_champignon_polypore,
    tvc.data ->> 'nb_arbres_dmh_plage_bois_sans_ecorce'::text AS nb_arbres_dmh_plage_bois_sans_ecorce,
    tvc.data ->> 'nb_arbres_dmh_cavite_evolutive_a_terreau_pied'::text AS nb_arbres_dmh_cavite_evolutive_a_terreau_pied,
    tvc.data ->> 'nb_arbres_dmh_ecorce_decollee_formant_un_abri'::text AS nb_arbres_dmh_ecorce_decollee_formant_un_abri,
    tvc.data ->> 'nb_arbres_dmh_cavite_evolutive_a_terreau_tronc'::text AS nb_arbres_dmh_cavite_evolutive_a_terreau_tronc,
    tvc.data ->> 'nb_arbres_dmh_charpentière_ou_cime_recemment_brisee'::text AS "nb_arbres_dmh_charpentière_ou_cime_recemment_brisee",
    tvc.data ->> 'nb_arbres_dmh_fente_profonde'::text AS nb_arbres_dmh_fente_profonde,
    hdehp1.mnemonique AS hauteur_dominante_essence_tgb_hors_placette_1,
    tvc.data ->> 'hauteur_dominante_diametre_tgb_hors_placette_1'::text AS hauteur_dominante_diametre_tgb_hors_placette_1,
    tvc.data ->> 'hauteur_dominante_distance_tgb_hors_placette_1'::text AS hauteur_dominante_distance_tgb_hors_placette_1,
    hdehp2.mnemonique AS hauteur_dominante_essence_tgb_hors_placette_2,
    tvc.data ->> 'hauteur_dominante_diametre_tgb_hors_placette_2'::text AS hauteur_dominante_diametre_tgb_hors_placette_2,
    tvc.data ->> 'hauteur_dominante_distance_tgb_hors_placette_2'::text AS hauteur_dominante_distance_tgb_hors_placette_2,
    hdehp3.mnemonique AS hauteur_dominante_essence_tgb_hors_placette_3,
    tvc.data ->> 'hauteur_dominante_diametre_tgb_hors_placette_3'::text AS hauteur_dominante_diametre_tgb_hors_placette_3,
    tvc.data ->> 'hauteur_dominante_distance_tgb_hors_placette_3'::text AS hauteur_dominante_distance_tgb_hors_placette_3,
    tvc.data ->> 'num_echantillon'::text AS num_echantillon,
    dae1.mnemonique AS description_arbre_1_essence,
    tvc.data ->> 'description_arbre_1_diametre_1'::text AS description_arbre_1_diametre_1,
    tvc.data ->> 'description_arbre_1_diametre_2'::text AS description_arbre_1_diametre_2,
    (((tvc.data ->> 'description_arbre_1_diametre_1'::text)::numeric) + COALESCE(tvc.data ->> 'description_arbre_1_diametre_2'::text, tvc.data ->> 'description_arbre_1_diametre_1'::text)::numeric) / 2::numeric AS description_arbre_1_diametre_moyen,
    dae2.mnemonique AS description_arbre_2_essence,
    tvc.data ->> 'description_arbre_2_diametre_1'::text AS description_arbre_2_diametre_1,
    tvc.data ->> 'description_arbre_2_diametre_2'::text AS description_arbre_2_diametre_2,
    (((tvc.data ->> 'description_arbre_2_diametre_1'::text)::numeric) + COALESCE(tvc.data ->> 'description_arbre_2_diametre_2'::text, tvc.data ->> 'description_arbre_2_diametre_1'::text)::numeric) / 2::numeric AS description_arbre_2_diametre_moyen,
    dae3.mnemonique AS description_arbre_3_essence,
    tvc.data ->> 'description_arbre_3_diametre_1'::text AS description_arbre_3_diametre_1,
    tvc.data ->> 'description_arbre_3_diametre_2'::text AS description_arbre_3_diametre_2,
    (((tvc.data ->> 'description_arbre_3_diametre_1'::text)::numeric) + COALESCE(tvc.data ->> 'description_arbre_3_diametre_2'::text, tvc.data ->> 'description_arbre_3_diametre_1'::text)::numeric) / 2::numeric AS description_arbre_3_diametre_moyen,
    dae4.mnemonique AS description_arbre_4_essence,
    tvc.data ->> 'description_arbre_4_diametre_1'::text AS description_arbre_4_diametre_1,
    tvc.data ->> 'description_arbre_4_diametre_2'::text AS description_arbre_4_diametre_2,
    (((tvc.data ->> 'description_arbre_4_diametre_1'::text)::numeric) + COALESCE(tvc.data ->> 'description_arbre_4_diametre_2'::text, tvc.data ->> 'description_arbre_4_diametre_1'::text)::numeric) / 2::numeric AS description_arbre_4_diametre_moyen,
    dae5.mnemonique AS description_arbre_5_essence,
    tvc.data ->> 'description_arbre_5_diametre_1'::text AS description_arbre_5_diametre_1,
    tvc.data ->> 'description_arbre_5_diametre_2'::text AS description_arbre_5_diametre_2,
    (((tvc.data ->> 'description_arbre_5_diametre_1'::text)::numeric) + COALESCE(tvc.data ->> 'description_arbre_5_diametre_2'::text, tvc.data ->> 'description_arbre_5_diametre_1'::text)::numeric) / 2::numeric AS description_arbre_5_diametre_moyen,
    dae6.mnemonique AS description_arbre_6_essence,
    tvc.data ->> 'description_arbre_6_diametre_1'::text AS description_arbre_6_diametre_1,
    tvc.data ->> 'description_arbre_6_diametre_2'::text AS description_arbre_6_diametre_2,
    (((tvc.data ->> 'description_arbre_6_diametre_1'::text)::numeric) + COALESCE(tvc.data ->> 'description_arbre_6_diametre_2'::text, tvc.data ->> 'description_arbre_6_diametre_1'::text)::numeric) / 2::numeric AS description_arbre_6_diametre_moyen,
    dae7.mnemonique AS description_arbre_7_essence,
    tvc.data ->> 'description_arbre_7_diametre_1'::text AS description_arbre_7_diametre_1,
    tvc.data ->> 'description_arbre_7_diametre_2'::text AS description_arbre_7_diametre_2,
    (((tvc.data ->> 'description_arbre_7_diametre_1'::text)::numeric) + COALESCE(tvc.data ->> 'description_arbre_7_diametre_2'::text, tvc.data ->> 'description_arbre_7_diametre_1'::text)::numeric) / 2::numeric AS description_arbre_7_diametre_moyen,
    dae8.mnemonique AS description_arbre_8_essence,
    tvc.data ->> 'description_arbre_8_diametre_1'::text AS description_arbre_8_diametre_1,
    tvc.data ->> 'description_arbre_8_diametre_2'::text AS description_arbre_8_diametre_2,
    (((tvc.data ->> 'description_arbre_8_diametre_1'::text)::numeric) + COALESCE(tvc.data ->> 'description_arbre_8_diametre_2'::text, tvc.data ->> 'description_arbre_8_diametre_1'::text)::numeric) / 2::numeric AS description_arbre_8_diametre_moyen,
    dae9.mnemonique AS description_arbre_9_essence,
    tvc.data ->> 'description_arbre_9_diametre_1'::text AS description_arbre_9_diametre_1,
    tvc.data ->> 'description_arbre_9_diametre_2'::text AS description_arbre_9_diametre_2,
    (((tvc.data ->> 'description_arbre_9_diametre_1'::text)::numeric) + COALESCE(tvc.data ->> 'description_arbre_9_diametre_2'::text, tvc.data ->> 'description_arbre_9_diametre_1'::text)::numeric) / 2::numeric AS description_arbre_9_diametre_moyen,
    dae10.mnemonique AS description_arbre_10_essence,
    tvc.data ->> 'description_arbre_10_diametre_1'::text AS description_arbre_10_diametre_1,
    tvc.data ->> 'description_arbre_10_diametre_2'::text AS description_arbre_10_diametre_2,
    (((tvc.data ->> 'description_arbre_10_diametre_1'::text)::numeric) + COALESCE(tvc.data ->> 'description_arbre_10_diametre_2'::text, tvc.data ->> 'description_arbre_10_diametre_1'::text)::numeric) / 2::numeric AS description_arbre_10_diametre_moyen
   FROM gn_monitoring.t_base_sites s
     JOIN gn_monitoring.t_site_complements tsc ON s.id_base_site = tsc.id_base_site
     JOIN gn_monitoring.cor_site_module csm ON s.id_base_site = csm.id_base_site
     JOIN gn_monitoring.t_base_visits tbv ON tbv.id_base_site = tsc.id_base_site
     JOIN gn_monitoring.t_visit_complements tvc ON tbv.id_base_visit = tvc.id_base_visit AND NOT COALESCE((tvc.data ->> 'test_detectabilite'::text)::boolean, false) IS TRUE
     JOIN gn_commons.t_modules mod ON mod.id_module = csm.id_module AND mod.module_code::text = 'lichens_bio_indicateurs'::text
     LEFT JOIN utilisateurs.t_roles tr ON tr.id_role = s.id_inventor
     LEFT JOIN ref_nomenclatures.t_nomenclatures tn ON tn.id_nomenclature = ((tsc.data ->> 'id_nomenclature_exposition'::text)::integer)
     LEFT JOIN ref_nomenclatures.t_nomenclatures hde1 ON hde1.id_nomenclature = COALESCE(tvc.data ->> 'hauteur_dominante_essence_1'::text, '-1'::text)::integer
     LEFT JOIN ref_nomenclatures.t_nomenclatures hdehp1 ON hdehp1.id_nomenclature = COALESCE(tvc.data ->> 'hauteur_dominante_essence_tgb_hors_placette_1'::text, '-1'::text)::integer
     LEFT JOIN ref_nomenclatures.t_nomenclatures hdehp2 ON hdehp2.id_nomenclature = COALESCE(tvc.data ->> 'hauteur_dominante_essence_tgb_hors_placette_2'::text, '-1'::text)::integer
     LEFT JOIN ref_nomenclatures.t_nomenclatures hdehp3 ON hdehp3.id_nomenclature = COALESCE(tvc.data ->> 'hauteur_dominante_essence_tgb_hors_placette_3'::text, '-1'::text)::integer
     LEFT JOIN ref_nomenclatures.t_nomenclatures dae1 ON dae1.id_nomenclature = COALESCE(tvc.data ->> 'description_arbre_1_essence'::text, '-1'::text)::integer
     LEFT JOIN ref_nomenclatures.t_nomenclatures dae2 ON dae2.id_nomenclature = COALESCE(tvc.data ->> 'description_arbre_2_essence'::text, '-1'::text)::integer
     LEFT JOIN ref_nomenclatures.t_nomenclatures dae3 ON dae3.id_nomenclature = COALESCE(tvc.data ->> 'description_arbre_3_essence'::text, '-1'::text)::integer
     LEFT JOIN ref_nomenclatures.t_nomenclatures dae4 ON dae4.id_nomenclature = COALESCE(tvc.data ->> 'description_arbre_4_essence'::text, '-1'::text)::integer
     LEFT JOIN ref_nomenclatures.t_nomenclatures dae5 ON dae5.id_nomenclature = COALESCE(tvc.data ->> 'description_arbre_5_essence'::text, '-1'::text)::integer
     LEFT JOIN ref_nomenclatures.t_nomenclatures dae6 ON dae6.id_nomenclature = COALESCE(tvc.data ->> 'description_arbre_6_essence'::text, '-1'::text)::integer
     LEFT JOIN ref_nomenclatures.t_nomenclatures dae7 ON dae7.id_nomenclature = COALESCE(tvc.data ->> 'description_arbre_7_essence'::text, '-1'::text)::integer
     LEFT JOIN ref_nomenclatures.t_nomenclatures dae8 ON dae8.id_nomenclature = COALESCE(tvc.data ->> 'description_arbre_8_essence'::text, '-1'::text)::integer
     LEFT JOIN ref_nomenclatures.t_nomenclatures dae9 ON dae9.id_nomenclature = COALESCE(tvc.data ->> 'description_arbre_9_essence'::text, '-1'::text)::integer
     LEFT JOIN ref_nomenclatures.t_nomenclatures dae10 ON dae10.id_nomenclature = COALESCE(tvc.data ->> 'description_arbre_10_essence'::text, '-1'::text)::integer
     LEFT JOIN LATERAL ( SELECT d_1.id_base_site,
            json_object_agg(d_1.type_code, d_1.o_name) AS jname,
            json_object_agg(d_1.type_code, d_1.o_code) AS jcode
           FROM ( SELECT sa.id_base_site,
                    ta.type_code,
                    string_agg(DISTINCT a_1.area_name::text, ','::text) AS o_name,
                    string_agg(DISTINCT a_1.area_code::text, ','::text) AS o_code
                   FROM gn_monitoring.cor_site_area sa
                     JOIN ref_geo.l_areas a_1 ON sa.id_area = a_1.id_area
                     JOIN ref_geo.bib_areas_types ta ON ta.id_type = a_1.id_type
                  WHERE sa.id_base_site = s.id_base_site
                  GROUP BY sa.id_base_site, ta.type_code) d_1
          GROUP BY d_1.id_base_site) a ON true
     LEFT JOIN LATERAL ( SELECT string_agg(concat(upper(tr_1.nom_role::text), ' ', tr_1.prenom_role), ', '::text) AS observateurs
           FROM gn_monitoring.cor_visit_observer cvo
             JOIN utilisateurs.t_roles tr_1 ON tr_1.id_role = cvo.id_role
          WHERE cvo.id_base_visit = tbv.id_base_visit
          GROUP BY cvo.id_base_visit) obs ON true; 



---------------------------------------------------------------
--- Liste des taxons observés 
-- gn_monitoring.v_export_lichens_bio_indicateurs_taxons source

CREATE OR REPLACE VIEW gn_monitoring.v_export_lichens_bio_indicateurs_taxons
AS SELECT s.id_base_site AS code_placette,
    s.base_site_name AS nom_placette,
    st_astext(s.geom) AS geom,
    s.base_site_description AS description,
    obs.observateurs,
    tbv.visit_date_min,
    to2.cd_nom,
    t.nom_complet,
    toc.data ->> 'para_taxon'::text AS para_taxon,
    toc.data ->> 'presence_arbre_1'::text AS presence_arbre_1,
    toc.data ->> 'presence_arbre_2'::text AS presence_arbre_2,
    toc.data ->> 'presence_arbre_3'::text AS presence_arbre_3,
    toc.data ->> 'presence_arbre_4'::text AS presence_arbre_4,
    toc.data ->> 'presence_arbre_5'::text AS presence_arbre_5,
    toc.data ->> 'presence_arbre_6'::text AS presence_arbre_6,
    toc.data ->> 'presence_arbre_7'::text AS presence_arbre_7,
    toc.data ->> 'presence_arbre_8'::text AS presence_arbre_8,
    toc.data ->> 'presence_arbre_9'::text AS presence_arbre_9,
    toc.data ->> 'presence_arbre_10'::text AS presence_arbre_10,
    tbv.id_dataset
   FROM gn_monitoring.t_base_sites s
     JOIN gn_monitoring.t_site_complements tsc ON s.id_base_site = tsc.id_base_site
     JOIN gn_monitoring.cor_site_module csm ON s.id_base_site = csm.id_base_site
     JOIN gn_commons.t_modules mod ON mod.id_module = csm.id_module AND mod.module_code::text = 'lichens_bio_indicateurs'::text
     JOIN gn_monitoring.t_base_visits tbv ON tbv.id_base_site = tsc.id_base_site
     JOIN gn_monitoring.t_observations to2 ON to2.id_base_visit = tbv.id_base_visit
     JOIN gn_monitoring.t_observation_complements toc ON toc.id_observation = to2.id_observation
     JOIN taxonomie.taxref t ON t.cd_nom = to2.cd_nom
     LEFT JOIN LATERAL ( SELECT string_agg(concat(upper(tr.nom_role::text), ' ', tr.prenom_role), ', '::text) AS observateurs
           FROM gn_monitoring.cor_visit_observer cvo
             JOIN utilisateurs.t_roles tr ON tr.id_role = cvo.id_role
          WHERE cvo.id_base_visit = tbv.id_base_visit
          GROUP BY cvo.id_base_visit) obs ON true;
 