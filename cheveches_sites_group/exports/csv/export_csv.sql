DROP VIEW IF EXISTS gn_monitoring.v_export_cheveches_bilans;

CREATE OR REPLACE VIEW gn_monitoring.v_export_cheveches_bilans
 AS
WITH module AS (
    SELECT * FROM gn_commons.t_modules tm
    WHERE module_code = 'cheveches'
)
SELECT tsg.sites_group_name , tsg.sites_group_code ,
tbs.id_base_site , tbs.geom , tbs.base_site_name , tbs.base_site_code , tbs.base_site_description , tsc.DATA->>'inactif' AS inactif,
last_visit.visit_max, last_visit.visit_min, last_visit.nb_visit ,observers, id_dataset
FROM gn_monitoring.t_base_sites tbs
JOIN gn_monitoring.t_site_complements tsc
ON tbs.id_base_site = tsc.id_base_site
JOIN MODULE m
ON m.id_module = tsc.id_module
JOIN gn_monitoring.t_sites_groups tsg
ON tsg.id_sites_group = tsc.id_sites_group
 JOIN LATERAL (
    SELECT id_dataset, max(visit_date_min) AS visit_max, min(visit_date_min) AS visit_min, count(tbv.id_base_visit) AS nb_visit,
         string_agg(DISTINCT concat (UPPER(tr.nom_role), ' ', tr.prenom_role ), ', ' ORDER BY concat (UPPER(tr.nom_role), ' ', tr.prenom_role )) AS observers
    FROM gn_monitoring.t_base_visits tbv
    JOIN gn_monitoring.cor_visit_observer cvo
    ON cvo.id_base_visit = tbv.id_base_visit
    JOIN utilisateurs.t_roles tr
    ON tr.id_role = cvo.id_role
    WHERE tbv.id_base_site = tbs.id_base_site
    GROUP BY tbv.id_base_site, id_dataset
) last_visit ON TRUE;
