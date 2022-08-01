WITH
default_dt AS (
    SELECT
        id_dataset
    FROM
        gn_meta.t_datasets td
    WHERE
        td.dataset_name  = 'Lichens bio indicateurs' --cheveches
)
 SELECT
s.id_base_site AS code_gite,
s.base_site_name AS nom_gite,
st_astext(s.geom) AS geom,
a.jname->>'COM' AS commune,
a.jname->>'MASSIF' AS massif,
s.base_site_description AS description,
tsc."data"->>'confinement' AS confinement,
tsc."data"->>'densite_couvert_e' AS densite_couvert_e,
tsc."data"->>'densite_couvert_n' AS densite_couvert_n,
tsc."data"->>'densite_couvert_o' AS densite_couvert_o,
tsc."data"->>'densite_couvert_s' AS densite_couvert_s,
tsc."data"->>'essence_preponderante' AS essence_preponderante,
tsc."data"->>'essence_principale' AS essence_principale,
tsc."data"->>'habitat_associe' AS habitat_associe,
tsc."data"->>'habitat_principal' AS habitat_principal,
tn.label_default AS exposition,
tsc."data"->>'pente' AS pente,
tsc."data"->>'peuplement_type' AS peuplement_type,
tsc."data"->>'peuplement_type_accompagnement' AS peuplement_type_accompagnement,
tsc."data"->>'surface_terriere_sup_17_5_inf_27_5' AS surface_terriere_sup_17_5_inf_27_5,
tsc."data"->>'surface_terriere_sup_27_5_inf_47_5' AS surface_terriere_sup_27_5_inf_47_5,
tsc."data"->>'surface_terriere_sup_47_5_inf_67_5' AS surface_terriere_sup_47_5_inf_67_5,
tsc."data"->>'surface_terriere_sup_67_5_inf_87_5' AS surface_terriere_sup_67_5_inf_87_5,
tsc."data"->>'surface_terriere_sup_87_5' AS surface_terriere_sup_87_5,
(SELECT id_dataset FROM default_dt LIMIT 1) AS id_dataset
from gn_monitoring.t_base_sites s
JOIN gn_monitoring.t_site_complements tsc ON s.id_base_site = tsc.id_base_site
JOIN gn_monitoring.cor_site_module csm on s.id_base_site = csm.id_base_site
JOIN gn_commons.t_modules mod on mod.id_module = csm.id_module AND mod.module_code = 'lichens_bio_indicateurs'
LEFT OUTER JOIN ref_nomenclatures.t_nomenclatures AS tn ON tn.id_nomenclature = (tsc."data"->>'id_nomenclature_exposition')::int
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
;

CREATE OR REPLACE VIEW gn_monitoring.v_export_lichens_bio_indicateurs_taxons
 AS
 SELECT
s.id_base_site AS code_gite,
s.base_site_name AS nom_gite,
st_astext(s.geom) AS geom,
s.base_site_description AS description,
tbv.visit_date_min ,
to2.cd_nom,
t.nom_complet,
toc."data"->>'nombre_individus_arbre_1' AS nombre_individus_arbre_1,
toc."data"->>'nombre_individus_arbre_10' AS nombre_individus_arbre_10,
toc."data"->>'nombre_individus_arbre_2' AS nombre_individus_arbre_2,
toc."data"->>'nombre_individus_arbre_3' AS nombre_individus_arbre_3,
toc."data"->>'nombre_individus_arbre_4' AS nombre_individus_arbre_4,
toc."data"->>'nombre_individus_arbre_5' AS nombre_individus_arbre_5,
toc."data"->>'nombre_individus_arbre_6' AS nombre_individus_arbre_6,
toc."data"->>'nombre_individus_arbre_7' AS nombre_individus_arbre_7,
toc."data"->>'nombre_individus_arbre_8' AS nombre_individus_arbre_8,
toc."data"->>'nombre_individus_arbre_9' AS nombre_individus_arbre_9,
tbv.id_dataset,
from gn_monitoring.t_base_sites s
JOIN gn_monitoring.t_site_complements tsc ON s.id_base_site = tsc.id_base_site
JOIN gn_monitoring.cor_site_module csm on s.id_base_site = csm.id_base_site
JOIN gn_commons.t_modules mod on mod.id_module = csm.id_module AND  mod.module_code = 'lichens_bio_indicateurs'
JOIN gn_monitoring.t_base_visits AS tbv ON tbv.id_base_site = tsc.id_base_site
JOIN gn_monitoring.t_observations AS to2 ON to2.id_base_visit = tbv.id_base_visit
JOIN gn_monitoring.t_observation_complements AS toc ON toc.id_observation = to2.id_observation
JOIN taxonomie.taxref AS t ON t.cd_nom = to2.cd_nom
;