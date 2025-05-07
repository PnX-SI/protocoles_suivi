--- Export de la liste des taxons observés sur un site avec mention au première et dernière date de visites
CREATE
OR REPLACE VIEW gn_monitoring.v_export_flore_biotope_inventaires_cumulatifs AS WITH type_site AS (
 SELECT
        tm.id_module, cmt.id_type_site
FROM
    gn_commons.t_modules tm
    JOIN  gn_monitoring.cor_module_type cmt 
    ON cmt.id_module = tm.id_module
WHERE
    tm.module_code = 'flore_biotope'
),
type_plante AS (
    SELECT
        cta.*
    FROM
        taxonomie.cor_taxon_attribut cta
        JOIN taxonomie.bib_attributs ba ON ba.id_attribut = cta.id_attribut
        AND nom_attribut = 'type_plante'
)
SELECT
    tsg.sites_group_name,
    tsg.sites_group_code,
    tbs.id_base_site,
    tbs.base_site_name,
    visits.visit_max,
    visits.visit_min,
    visits.nb_visit,
    t.regne,
    t.group2_inpn,
    t.famille,
    cta.valeur_attribut AS type_plante,
    t.cd_ref,
    visits.cd_nom,
    t.nom_valide
FROM
    gn_monitoring.t_base_sites tbs
    JOIN gn_monitoring.t_site_complements tsc ON tbs.id_base_site = tsc.id_base_site
    JOIN gn_monitoring.cor_site_type cst ON tbs.id_base_site = cst.id_base_site
    JOIN type_site m ON m.id_type_site = cst.id_type_site
    JOIN gn_monitoring.t_sites_groups tsg ON tsg.id_sites_group = tsc.id_sites_group
    JOIN LATERAL (
        SELECT
            max(tbv.visit_date_min) AS visit_max,
            min(tbv.visit_date_min) AS visit_min,
            count(tbv.id_base_visit) AS nb_visit,
            tobs.cd_nom
        FROM
            gn_monitoring.t_base_visits tbv
            JOIN gn_monitoring.t_observations tobs ON tbv.id_base_visit = tobs.id_base_visit
        WHERE
            tbv.id_base_site = tbs.id_base_site
        GROUP BY
            tbv.id_base_site,
            tobs.cd_nom
    ) visits ON TRUE
    JOIN taxonomie.taxref t ON t.cd_nom = visits.cd_nom
    LEFT OUTER JOIN type_plante cta ON cta.cd_ref = t.cd_ref;

-- Export des sites
CREATE
OR REPLACE VIEW gn_monitoring.v_export_flore_biotope_sites AS


SELECT
    tsg.sites_group_name,
    tsg.sites_group_code,
    s.id_base_site,
    s.base_site_name AS nom_biotope,
    st_astext(s.geom) as geom,
    a.jname ->> 'COM' AS commune,
    a.jname ->> 'SEC' AS secteur,
    s.base_site_description AS description_biotope,
    tsc.data ->> 'pente' as pente,
    tn.label_default as exposition,
    tsc.data ->> 'altitude_moyenne' as altitude_moyenne,
    tsc.data ->> 'phytosociologie' as phytosociologie,
    tsc.data ->> 'grand_type_milieu' as grand_type_milieu,
    tsc.data ->> 'utilisation_agricole_historique' as utilisation_agricole_historique,
    (st_area(s.geom_local) / 1000) AS surface_calculee
from
    gn_monitoring.t_base_sites s
    JOIN gn_monitoring.t_site_complements tsc ON s.id_base_site = tsc.id_base_site
    JOIN gn_monitoring.cor_site_module csm on s.id_base_site = csm.id_base_site
    JOIN gn_commons.t_modules mod on mod.id_module = csm.id_module
    AND mod.module_code = 'flore_biotope'
    LEFT JOIN gn_monitoring.t_sites_groups tsg ON tsg.id_sites_group = tsc.id_sites_group
    LEFT JOIN ref_nomenclatures.t_nomenclatures tn ON (tsc.data ->> 'id_nomenclature_exposition') :: integer = tn.id_nomenclature
    LEFT JOIN LATERAL (
        SELECT
            d_1.id_base_site,
            json_object_agg(d_1.type_code, d_1.o_name) AS jname,
            json_object_agg(d_1.type_code, d_1.o_code) AS jcode
        FROM
            (
                SELECT
                    sa.id_base_site,
                    ta.type_code,
                    string_agg(DISTINCT a_1.area_name :: text, ',' :: text) AS o_name,
                    string_agg(DISTINCT a_1.area_code :: text, ',' :: text) AS o_code
                FROM
                    gn_monitoring.cor_site_area sa
                    JOIN ref_geo.l_areas a_1 ON sa.id_area = a_1.id_area
                    JOIN ref_geo.bib_areas_types ta ON ta.id_type = a_1.id_type
                WHERE
                    sa.id_base_site = s.id_base_site
                GROUP BY
                    sa.id_base_site,
                    ta.type_code
            ) d_1
        GROUP BY
            d_1.id_base_site
    ) a ON TRUE;

-- Export des observations
CREATE
OR REPLACE VIEW gn_monitoring.v_export_flore_biotope_observations AS WITH type_site AS (
 SELECT
        tm.id_module, cmt.id_type_site
FROM
    gn_commons.t_modules tm
    JOIN  gn_monitoring.cor_module_type cmt 
    ON cmt.id_module = tm.id_module
WHERE
    tm.module_code = 'flore_biotope'
),
type_plante AS (
    SELECT
        cta.*
    FROM
        taxonomie.cor_taxon_attribut cta
        JOIN taxonomie.bib_attributs ba ON ba.id_attribut = cta.id_attribut
        AND nom_attribut = 'type_plante'
)
SELECT
    tsg.sites_group_name,
    tsg.sites_group_code,
    tbs.id_base_site,
    tbs.base_site_name,
    tbv.id_base_visit AS id_visit,
    tbv.visit_date_min AS date_visite,
    observateurs.observateurs_noms,
    tvc.data ->> 'gestion_courante' as gestion_courante,
    tvc.data ->> 'historique_gestion' as historique_gestion,
    tbv.comments AS commentaire,
    obs.id_observation,
    t.regne,
    t.group2_inpn,
    t.famille,
    cta.valeur_attribut AS type_plante,
    t.cd_ref,
    obs.cd_nom,
    t.nom_valide,
    obs.comments AS comment_obs,
    tnoc.label_default as obj_count,
    tnls.label_default as life_stage,
    tnbb.label_default as abondance_braunblanquet,
    tntc.label_default as type_count,
    toc.data ->> 'recouvrement' as recouvrement,
    toc.data ->> 'count_min' as count_min,
    toc.data ->> 'num_herbier' as num_herbier
FROM
    gn_monitoring.t_base_sites tbs
    JOIN gn_monitoring.t_site_complements tsc ON tbs.id_base_site = tsc.id_base_site
    JOIN gn_monitoring.cor_site_type cst ON tbs.id_base_site = cst.id_base_site
    JOIN type_site m ON m.id_type_site = cst.id_type_site
    LEFT JOIN gn_monitoring.t_sites_groups tsg ON tsg.id_sites_group = tsc.id_sites_group
    JOIN gn_monitoring.t_base_visits tbv ON tbv.id_base_site = tbs.id_base_site
    LEFT JOIN gn_monitoring.t_visit_complements tvc ON tvc.id_base_visit = tbv.id_base_visit
    JOIN LATERAL (
        SELECT
            cvo.id_base_visit,
            string_agg(concat(tr.nom_role, ' ', tr.prenom_role), ', ') AS observateurs_noms
        FROM
            utilisateurs.t_roles tr
            JOIN gn_monitoring.cor_visit_observer cvo ON tr.id_role = cvo.id_role
        WHERE
            cvo.id_base_visit = tbv.id_base_visit
        GROUP BY
            cvo.id_base_visit
    ) AS observateurs ON TRUE
    JOIN gn_monitoring.t_observations obs ON obs.id_base_visit = tbv.id_base_visit
    LEFT JOIN gn_monitoring.t_observation_complements toc ON toc.id_observation = obs.id_observation
    JOIN taxonomie.taxref t ON t.cd_nom = obs.cd_nom
    LEFT OUTER JOIN type_plante cta ON cta.cd_ref = t.cd_ref
    LEFT JOIN ref_nomenclatures.t_nomenclatures tnoc ON (toc.data ->> 'id_nomenclature_obj_count') :: integer = tnoc.id_nomenclature
    LEFT JOIN ref_nomenclatures.t_nomenclatures tnls ON (toc.data ->> 'id_nomenclature_life_stage') :: integer = tnls.id_nomenclature
    LEFT JOIN ref_nomenclatures.t_nomenclatures tnbb ON (
        toc.data ->> 'id_nomenclature_abondance_braunblanquet'
    ) :: integer = tnbb.id_nomenclature
    LEFT JOIN ref_nomenclatures.t_nomenclatures tntc ON (toc.data ->> 'id_nomenclature_type_count') :: integer = tntc.id_nomenclature;
