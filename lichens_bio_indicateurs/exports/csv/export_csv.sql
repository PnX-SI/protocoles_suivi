DROP VIEW IF EXISTS gn_monitoring.v_export_lichens_bio_indicateurs_placettes;
CREATE OR REPLACE VIEW gn_monitoring.v_export_lichens_bio_indicateurs_placettes
 AS
SELECT
    s.id_base_site AS code_placette,
    s.base_site_name AS nom_placette,
    concat_ws(' ', tr.nom_role, tr.prenom_role) AS descripteur,
    st_astext(s.geom) AS geom,
    a.jname->>'COM' AS commune,
    a.jname->>'MASSIF' AS massif,
    s.base_site_description AS description,
    tsc."data"->>'pente' AS pente,
    tn.label_default AS exposition,
    tsc."data"->>'exposition_grade' AS exposition_grade,
    tsc."data"->>'confinement_nord' AS confinement_nord,
    tsc."data"->>'confinement_est' AS confinement_est,
    tsc."data"->>'confinement_sud' AS confinement_sud,
    tsc."data"->>'confinement_ouest' AS confinement_ouest,
    tbv.visit_date_min ,
    obs.observateurs,
    tbv."comments" ,
    tbv.id_dataset ,
    tvc.data->>'time_end' as time_end,
    tvc.data->>'time_start' as time_start,
    tvc.data->>'habitat_associe' as habitat_associe,
    tvc.data->>'densite_couvert_n' as densite_couvert_n,
    tvc.data->>'densite_couvert_e' as densite_couvert_e,
    tvc.data->>'densite_couvert_s' as densite_couvert_s,
    tvc.data->>'densite_couvert_o' as densite_couvert_o,
    tvc.data->>'habitat_principal' as habitat_principal,
    tvc.data->>'essence_principale' as essence_principale,
    tvc.data->>'frein_exploitation' as frein_exploitation,
    tvc.data->>'essence_preponderante' as essence_preponderante,
    tvc.data->>'nb_arbres_dmh_loge_pics' as nb_arbres_dmh_loge_pics,
    tvc.data->>'nb_arbres_dmh_dendrotelme' as nb_arbres_dmh_dendrotelme,
    tvc.data->>'peuplement_type_structure' as peuplement_type_structure,
    tvc.data->>'presence_tgb_hors_placette' as presence_tgb_hors_placette,
    hde1.mnemonique AS hauteur_dominante_essence_1,
    tvc.data->>'contrainte_stationelle_forte' as contrainte_stationelle_forte,
    tvc.data->>'hauteur_dominante_diametre_1' as hauteur_dominante_diametre_1,
    tvc.data->>'hauteur_dominante_distance_1' as hauteur_dominante_distance_1,
    tvc.data->>'indices_usages_passe_ou_actuel' as indices_usages_passe_ou_actuel,
    tvc.data->>'peuplement_type_accompagnement_1' as peuplement_type_accompagnement_1,
    tvc.data->>'peuplement_type_accompagnement_2' as peuplement_type_accompagnement_2,
    tvc.data->>'peuplement_type_essences_objectifs_1' as peuplement_type_essences_objectifs_1,
    tvc.data->>'peuplement_type_essences_objectifs_2' as peuplement_type_essences_objectifs_2,
    tvc.data->>'surface_terriere_sup_17_5_inf_27_5' as surface_terriere_sup_17_5_inf_27_5,
    tvc.data->>'surface_terriere_sup_27_5_inf_47_5' as surface_terriere_sup_27_5_inf_47_5,
    tvc.data->>'surface_terriere_sup_47_5_inf_67_5' as surface_terriere_sup_47_5_inf_67_5,
    tvc.data->>'surface_terriere_sup_67_5_inf_87_5' as surface_terriere_sup_67_5_inf_87_5,
    tvc.data->>'surface_terriere_sup_87_5' as surface_terriere_sup_87_5,
    tvc.data->>'surface_terriere_morts_sol_sup_87_5' as surface_terriere_morts_sol_sup_87_5,
    tvc.data->>'surface_terriere_morts_debout_sup_87_5' as surface_terriere_morts_debout_sup_87_5,
    tvc.data->>'surface_terriere_morts_sol_sup_17_5_inf_27_5' as surface_terriere_morts_sol_sup_17_5_inf_27_5,
    tvc.data->>'surface_terriere_morts_sol_sup_27_5_inf_47_5' as surface_terriere_morts_sol_sup_27_5_inf_47_5,
    tvc.data->>'surface_terriere_morts_sol_sup_47_5_inf_67_5' as surface_terriere_morts_sol_sup_47_5_inf_67_5,
    tvc.data->>'surface_terriere_morts_sol_sup_67_5_inf_87_5' as surface_terriere_morts_sol_sup_67_5_inf_87_5,
    tvc.data->>'surface_terriere_morts_debout_sup_17_5_inf_27_5' as surface_terriere_morts_debout_sup_17_5_inf_27_5,
    tvc.data->>'surface_terriere_morts_debout_sup_27_5_inf_47_5' as surface_terriere_morts_debout_sup_27_5_inf_47_5,
    tvc.data->>'surface_terriere_morts_debout_sup_47_5_inf_67_5' as surface_terriere_morts_debout_sup_47_5_inf_67_5,
    tvc.data->>'surface_terriere_morts_debout_sup_67_5_inf_87_5' as surface_terriere_morts_debout_sup_67_5_inf_87_5,
    tvc.data->>'nb_arbres_dmh_champignon_polypore' as nb_arbres_dmh_champignon_polypore,
    tvc.data->>'nb_arbres_dmh_plage_bois_sans_ecorce' as nb_arbres_dmh_plage_bois_sans_ecorce,
    tvc.data->>'nb_arbres_dmh_cavite_evolutive_a_terreau_pied' as nb_arbres_dmh_cavite_evolutive_a_terreau_pied,
    tvc.data->>'nb_arbres_dmh_ecorce_decollee_formant_un_abri' as nb_arbres_dmh_ecorce_decollee_formant_un_abri,
    tvc.data->>'nb_arbres_dmh_cavite_evolutive_a_terreau_tronc' as nb_arbres_dmh_cavite_evolutive_a_terreau_tronc,
    tvc.data->>'nb_arbres_dmh_charpentière_ou_cime_recemment_brisee' as nb_arbres_dmh_charpentière_ou_cime_recemment_brisee,
    tvc.data->>'nb_arbres_dmh_fente_profonde' as nb_arbres_dmh_fente_profonde,
    hdehp1.mnemonique AS hauteur_dominante_essence_tgb_hors_placette_1,
    tvc.data->>'hauteur_dominante_diametre_tgb_hors_placette_1' as hauteur_dominante_diametre_tgb_hors_placette_1,
    tvc.data->>'hauteur_dominante_distance_tgb_hors_placette_1' as hauteur_dominante_distance_tgb_hors_placette_1,
    hdehp2.mnemonique AS hauteur_dominante_essence_tgb_hors_placette_2,
    tvc.data->>'hauteur_dominante_diametre_tgb_hors_placette_2' as hauteur_dominante_diametre_tgb_hors_placette_2,
    tvc.data->>'hauteur_dominante_distance_tgb_hors_placette_2' as hauteur_dominante_distance_tgb_hors_placette_2,
    hdehp3.mnemonique AS hauteur_dominante_essence_tgb_hors_placette_3,
    tvc.data->>'hauteur_dominante_diametre_tgb_hors_placette_3' as hauteur_dominante_diametre_tgb_hors_placette_3,
    tvc.data->>'hauteur_dominante_distance_tgb_hors_placette_3' as hauteur_dominante_distance_tgb_hors_placette_3,
    tvc.data->>'num_echantillon' as num_echantillon,
    dae1.mnemonique AS description_arbre_1_essence,
    tvc.data->>'description_arbre_1_diametre_1' as description_arbre_1_diametre_1,
    tvc.data->>'description_arbre_1_diametre_2' as description_arbre_1_diametre_2,
    dae2.mnemonique AS description_arbre_2_essence,
    tvc.data->>'description_arbre_2_diametre_1' as description_arbre_2_diametre_1,
    tvc.data->>'description_arbre_2_diametre_2' as description_arbre_2_diametre_2,
    dae3.mnemonique AS description_arbre_3_essence,
    tvc.data->>'description_arbre_3_diametre_1' as description_arbre_3_diametre_1,
    tvc.data->>'description_arbre_3_diametre_2' as description_arbre_3_diametre_2,
    dae4.mnemonique AS description_arbre_4_essence,
    tvc.data->>'description_arbre_4_diametre_1' as description_arbre_4_diametre_1,
    tvc.data->>'description_arbre_4_diametre_2' as description_arbre_4_diametre_2,
    dae5.mnemonique AS description_arbre_5_essence,
    tvc.data->>'description_arbre_5_diametre_1' as description_arbre_5_diametre_1,
    tvc.data->>'description_arbre_5_diametre_2' as description_arbre_5_diametre_2,
    dae6.mnemonique AS description_arbre_6_essence,
    tvc.data->>'description_arbre_6_diametre_1' as description_arbre_6_diametre_1,
    tvc.data->>'description_arbre_6_diametre_2' as description_arbre_6_diametre_2,
    dae7.mnemonique AS description_arbre_7_essence,
    tvc.data->>'description_arbre_7_diametre_1' as description_arbre_7_diametre_1,
    tvc.data->>'description_arbre_7_diametre_2' as description_arbre_7_diametre_2,
    dae8.mnemonique AS description_arbre_8_essence,
    tvc.data->>'description_arbre_8_diametre_1' as description_arbre_8_diametre_1,
    tvc.data->>'description_arbre_8_diametre_2' as description_arbre_8_diametre_2,
    dae9.mnemonique AS description_arbre_9_essence,
    tvc.data->>'description_arbre_9_diametre_1' as description_arbre_9_diametre_1,
    tvc.data->>'description_arbre_9_diametre_2' as description_arbre_9_diametre_2,
    dae10.mnemonique AS description_arbre_10_essence,
    tvc.data->>'description_arbre_10_diametre_1' as description_arbre_10_diametre_1,
    tvc.data->>'description_arbre_10_diametre_2' as description_arbre_10_diametre_2
from gn_monitoring.t_base_sites s
JOIN gn_monitoring.t_site_complements tsc ON s.id_base_site = tsc.id_base_site
JOIN gn_monitoring.cor_site_module csm on s.id_base_site = csm.id_base_site
JOIN gn_monitoring.t_base_visits AS tbv ON tbv.id_base_site = tsc.id_base_site
JOIN gn_monitoring.t_visit_complements AS tvc ON tbv.id_base_visit  = tvc.id_base_visit AND NOT COALESCE((tvc.DATA->>'test_detectabilite')::boolean, FALSE) IS TRUE
JOIN gn_commons.t_modules mod on mod.id_module = csm.id_module AND mod.module_code = :module_code
LEFT OUTER JOIN utilisateurs.t_roles AS tr on tr.id_role = s.id_inventor
LEFT OUTER JOIN ref_nomenclatures.t_nomenclatures AS tn ON tn.id_nomenclature = (tsc."data"->>'id_nomenclature_exposition')::int
LEFT OUTER JOIN ref_nomenclatures.t_nomenclatures AS hde1 ON hde1.id_nomenclature = (COALESCE(tvc."data"->>'hauteur_dominante_essence_1', '-1'))::int
LEFT OUTER JOIN ref_nomenclatures.t_nomenclatures AS hdehp1 ON hdehp1.id_nomenclature = (COALESCE(tvc."data"->>'hauteur_dominante_essence_tgb_hors_placette_1', '-1'))::int
LEFT OUTER JOIN ref_nomenclatures.t_nomenclatures AS hdehp2 ON hdehp2.id_nomenclature = (COALESCE(tvc."data"->>'hauteur_dominante_essence_tgb_hors_placette_2', '-1'))::int
LEFT OUTER JOIN ref_nomenclatures.t_nomenclatures AS hdehp3 ON hdehp3.id_nomenclature = (COALESCE(tvc."data"->>'hauteur_dominante_essence_tgb_hors_placette_3', '-1'))::int
LEFT OUTER JOIN ref_nomenclatures.t_nomenclatures AS dae1 ON dae1.id_nomenclature = (COALESCE(tvc."data"->>'description_arbre_1_essence', '-1'))::int
LEFT OUTER JOIN ref_nomenclatures.t_nomenclatures AS dae2 ON dae2.id_nomenclature = (COALESCE(tvc."data"->>'description_arbre_2_essence', '-1'))::int
LEFT OUTER JOIN ref_nomenclatures.t_nomenclatures AS dae3 ON dae3.id_nomenclature = (COALESCE(tvc."data"->>'description_arbre_3_essence', '-1'))::int
LEFT OUTER JOIN ref_nomenclatures.t_nomenclatures AS dae4 ON dae4.id_nomenclature = (COALESCE(tvc."data"->>'description_arbre_4_essence', '-1'))::int
LEFT OUTER JOIN ref_nomenclatures.t_nomenclatures AS dae5 ON dae5.id_nomenclature = (COALESCE(tvc."data"->>'description_arbre_5_essence', '-1'))::int
LEFT OUTER JOIN ref_nomenclatures.t_nomenclatures AS dae6 ON dae6.id_nomenclature = (COALESCE(tvc."data"->>'description_arbre_6_essence', '-1'))::int
LEFT OUTER JOIN ref_nomenclatures.t_nomenclatures AS dae7 ON dae7.id_nomenclature = (COALESCE(tvc."data"->>'description_arbre_7_essence', '-1'))::int
LEFT OUTER JOIN ref_nomenclatures.t_nomenclatures AS dae8 ON dae8.id_nomenclature = (COALESCE(tvc."data"->>'description_arbre_8_essence', '-1'))::int
LEFT OUTER JOIN ref_nomenclatures.t_nomenclatures AS dae9 ON dae9.id_nomenclature = (COALESCE(tvc."data"->>'description_arbre_9_essence', '-1'))::int
LEFT OUTER JOIN ref_nomenclatures.t_nomenclatures AS dae10 ON dae10.id_nomenclature = (COALESCE(tvc."data"->>'description_arbre_10_essence', '-1'))::int
LEFT JOIN LATERAL ( SELECT d_1.id_base_site ,
        json_object_agg(d_1.type_code, d_1.o_name) AS jname,
        json_object_agg(d_1.type_code, d_1.o_code) AS jcode
       FROM ( SELECT sa.id_base_site ,
                ta.type_code,
                string_agg(DISTINCT a_1.area_name::text, ','::text) AS o_name,
                string_agg(DISTINCT a_1.area_code::text, ','::text) AS o_code
               FROM gn_monitoring.cor_site_area  sa
                 JOIN ref_geo.l_areas a_1 ON sa.id_area = a_1.id_area
                 JOIN ref_geo.bib_areas_types ta ON ta.id_type = a_1.id_type
              WHERE sa.id_base_site  = s.id_base_site
              GROUP BY sa.id_base_site , ta.type_code) d_1
GROUP BY d_1.id_base_site)
a ON TRUE
LEFT JOIN LATERAL ( SELECT string_agg(concat(UPPER(tr.nom_role), ' ', tr.prenom_role), ', ') AS observateurs
       FROM  gn_monitoring.cor_visit_observer AS cvo
       JOIN utilisateurs.t_roles AS tr
       ON tr.id_role = cvo.id_role
       WHERE cvo.id_base_visit = tbv.id_base_visit
    GROUP BY cvo.id_base_visit)
obs ON TRUE
;

DROP VIEW IF EXISTS gn_monitoring.v_export_lichens_bio_indicateurs_taxons;
CREATE OR REPLACE VIEW gn_monitoring.v_export_lichens_bio_indicateurs_taxons
 AS
SELECT
    s.id_base_site AS code_placette,
    s.base_site_name AS nom_placette,
    st_astext(s.geom) AS geom,
    s.base_site_description AS description,
    obs.observateurs,
    tbv.visit_date_min ,
    to2.cd_nom,
    t.nom_complet,
    toc."data"->>'para_taxon' AS para_taxon,
    toc."data"->>'presence_arbre_1' AS presence_arbre_1,
    toc."data"->>'presence_arbre_2' AS presence_arbre_2,
    toc."data"->>'presence_arbre_3' AS presence_arbre_3,
    toc."data"->>'presence_arbre_4' AS presence_arbre_4,
    toc."data"->>'presence_arbre_5' AS presence_arbre_5,
    toc."data"->>'presence_arbre_6' AS presence_arbre_6,
    toc."data"->>'presence_arbre_7' AS presence_arbre_7,
    toc."data"->>'presence_arbre_8' AS presence_arbre_8,
    toc."data"->>'presence_arbre_9' AS presence_arbre_9,
    toc."data"->>'presence_arbre_10' AS presence_arbre_10,
    tbv.id_dataset
from gn_monitoring.t_base_sites s
JOIN gn_monitoring.t_site_complements tsc ON s.id_base_site = tsc.id_base_site
JOIN gn_monitoring.cor_site_module csm on s.id_base_site = csm.id_base_site
JOIN gn_commons.t_modules mod on mod.id_module = csm.id_module AND  mod.module_code = :module_code
JOIN gn_monitoring.t_base_visits AS tbv ON tbv.id_base_site = tsc.id_base_site
JOIN gn_monitoring.t_observations AS to2 ON to2.id_base_visit = tbv.id_base_visit
JOIN gn_monitoring.t_observation_complements AS toc ON toc.id_observation = to2.id_observation
JOIN taxonomie.taxref AS t ON t.cd_nom = to2.cd_nom
LEFT JOIN LATERAL ( SELECT string_agg(concat(UPPER(tr.nom_role), ' ', tr.prenom_role), ', ') AS observateurs
       FROM  gn_monitoring.cor_visit_observer AS cvo
       JOIN utilisateurs.t_roles AS tr
       ON tr.id_role = cvo.id_role
       WHERE cvo.id_base_visit = tbv.id_base_visit
    GROUP BY cvo.id_base_visit)
obs ON TRUE
;