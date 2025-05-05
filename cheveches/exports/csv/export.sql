DROP VIEW IF EXISTS gn_monitoring.v_export_cheveches_bilans;

DROP VIEW IF EXISTS gn_monitoring.v_export_cheveches_bilans_sites;

CREATE
OR REPLACE VIEW gn_monitoring.v_export_cheveches_bilans_sites AS WITH module AS (
    SELECT
        *
    FROM
        gn_commons.t_modules tm
    WHERE
        module_code = :module_code
)
SELECT
    tsg.sites_group_name,
    tsg.sites_group_code,
    tbs.id_base_site,
    tbs.geom,
    tbs.base_site_name,
    tbs.base_site_code,
    tbs.base_site_description,
    tsc.DATA ->> 'inactif' AS inactif,
    last_visit.visit_max,
    last_visit.visit_min,
    last_visit.nb_visit,
    observers,
    id_dataset
FROM
    gn_monitoring.t_base_sites tbs
    JOIN gn_monitoring.t_site_complements tsc ON tbs.id_base_site = tsc.id_base_site
	JOIN gn_monitoring.cor_site_module csm 
	ON  tbs.id_base_site = csm.id_base_site  
    JOIN MODULE m ON m.id_module = csm.id_module
    JOIN gn_monitoring.t_sites_groups tsg ON tsg.id_sites_group = tsc.id_sites_group
    JOIN LATERAL (
        SELECT
            id_dataset,
            max(visit_date_min) AS visit_max,
            min(visit_date_min) AS visit_min,
            count(tbv.id_base_visit) AS nb_visit,
            string_agg(
                DISTINCT concat (UPPER(tr.nom_role), ' ', tr.prenom_role),
                ', '
                ORDER BY
                    concat (UPPER(tr.nom_role), ' ', tr.prenom_role)
            ) AS observers
        FROM
            gn_monitoring.t_base_visits tbv
            JOIN gn_monitoring.cor_visit_observer cvo ON cvo.id_base_visit = tbv.id_base_visit
            JOIN utilisateurs.t_roles tr ON tr.id_role = cvo.id_role
        WHERE
            tbv.id_base_site = tbs.id_base_site
        GROUP BY
            tbv.id_base_site,
            id_dataset
    ) last_visit ON TRUE;

--------------------------------------------------
-- Bilan des visites de l'année précédante
--------------------------------------------------
DROP VIEW IF EXISTS gn_monitoring.v_export_cheveches_bilans_visites_annee_nmoins1;

CREATE
OR REPLACE VIEW gn_monitoring.v_export_cheveches_bilans_visites_annee_nmoins1 AS WITH module AS (
    SELECT
        *
    FROM
        gn_commons.t_modules tm
    WHERE
        module_code = :module_code
), 
visites AS (
    SELECT
        tbv.id_base_site,
        tbv.id_base_visit,
        tvc.DATA ->> 'num_passage' AS num_passage,
        tbv.visit_date_min,
        tn.label_default AS contact,
        string_agg(
            DISTINCT concat (UPPER(tr.nom_role), ' ', tr.prenom_role),
            ', '
            ORDER BY
                concat (UPPER(tr.nom_role), ' ', tr.prenom_role)
        ) AS observers,
        id_dataset
    FROM
        gn_monitoring.t_base_visits tbv
        JOIN gn_monitoring.t_visit_complements tvc ON tvc.id_base_visit = tbv.id_base_visit
        JOIN gn_monitoring.cor_visit_observer cvo ON cvo.id_base_visit = tbv.id_base_visit
        JOIN utilisateurs.t_roles tr ON tr.id_role = cvo.id_role
        LEFT OUTER JOIN ref_nomenclatures.t_nomenclatures tn ON tn.id_nomenclature :: text = tvc.DATA ->> 'id_nomenclature_statut_obs'
    WHERE
        DATE_PART('YEAR', tbv.visit_date_min) = DATE_PART('YEAR', current_timestamp) -1
    GROUP BY
        tbv.id_base_site,
        tbv.id_base_visit,
        tvc.DATA ->> 'num_passage',
        tbv.visit_date_min,
        tn.label_default
)
SELECT
    tsg.sites_group_name,
    tsg.sites_group_code,
    tbs.id_base_site,
    tbs.geom,
    tbs.base_site_name,
    tbs.base_site_code,
    tbs.base_site_description,
    (tsc.DATA ->> 'inactif') :: boolean AS inactif,
    passage_1.visit_date_min AS passage_1_date,
    passage_1.contact AS passage_1_contact,
    passage_1.observers AS passage_1_observers,
    passage_2.visit_date_min AS passage_2_date,
    passage_2.contact AS passage_2_contact,
    passage_2.observers AS passage_2_observers,
    passage_autre.*,
    passage_1.id_dataset
FROM
    gn_monitoring.t_base_sites tbs
    JOIN gn_monitoring.t_site_complements tsc ON tbs.id_base_site = tsc.id_base_site
	JOIN gn_monitoring.cor_site_module csm 
	ON  tbs.id_base_site = csm.id_base_site  
    JOIN MODULE m ON m.id_module = csm.id_module
    JOIN gn_monitoring.t_sites_groups tsg ON tsg.id_sites_group = tsc.id_sites_group
    LEFT JOIN LATERAL (
        SELECT
            *
        FROM
            visites tbv
        WHERE
            tbv.id_base_site = tbs.id_base_site
            AND num_passage = '1'
    ) passage_1 ON TRUE
    LEFT JOIN LATERAL (
        SELECT
            *
        FROM
            visites tbv
        WHERE
            tbv.id_base_site = tbs.id_base_site
            AND num_passage = '2'
    ) passage_2 ON TRUE
    LEFT JOIN LATERAL (
        SELECT
            TRUE AS autre_passages
        FROM
            visites tbv
        WHERE
            tbv.id_base_site = tbs.id_base_site
            AND (
                NOT num_passage IN ('2', '1')
                OR num_passage IS NULL
            )
        GROUP BY
            tbv.id_base_site
    ) passage_autre ON TRUE
ORDER BY
    sites_group_name,
    base_site_name;

--------------------------------------------------
-- Bilan des visites de l'année en cours
--------------------------------------------------
DROP VIEW IF EXISTS gn_monitoring.v_export_cheveches_bilans_visites_annee_en_cours;

CREATE
OR REPLACE VIEW gn_monitoring.v_export_cheveches_bilans_visites_annee_en_cours AS WITH module AS (
    SELECT
        *
    FROM
        gn_commons.t_modules tm
    WHERE
        module_code = :module_code
), 
visites AS (
    SELECT
        tbv.id_base_site,
        tbv.id_base_visit,
        tvc.DATA ->> 'num_passage' AS num_passage,
        tbv.visit_date_min,
        tn.label_default AS contact,
        string_agg(
            DISTINCT concat (UPPER(tr.nom_role), ' ', tr.prenom_role),
            ', '
            ORDER BY
                concat (UPPER(tr.nom_role), ' ', tr.prenom_role)
        ) AS observers,
        id_dataset
    FROM
        gn_monitoring.t_base_visits tbv
        JOIN gn_monitoring.t_visit_complements tvc ON tvc.id_base_visit = tbv.id_base_visit
        JOIN gn_monitoring.cor_visit_observer cvo ON cvo.id_base_visit = tbv.id_base_visit
        JOIN utilisateurs.t_roles tr ON tr.id_role = cvo.id_role
        LEFT OUTER JOIN ref_nomenclatures.t_nomenclatures tn ON tn.id_nomenclature :: text = tvc.DATA ->> 'id_nomenclature_statut_obs'
    WHERE
        DATE_PART('YEAR', tbv.visit_date_min) = DATE_PART('YEAR', current_timestamp)
    GROUP BY
        tbv.id_base_site,
        tbv.id_base_visit,
        tvc.DATA ->> 'num_passage',
        tbv.visit_date_min,
        tn.label_default
)
SELECT
    tsg.sites_group_name,
    tsg.sites_group_code,
    tbs.id_base_site,
    tbs.geom,
    tbs.base_site_name,
    tbs.base_site_code,
    tbs.base_site_description,
    (tsc.DATA ->> 'inactif') :: boolean AS inactif,
    passage_1.visit_date_min AS passage_1_date,
    passage_1.contact AS passage_1_contact,
    passage_1.observers AS passage_1_observers,
    passage_2.visit_date_min AS passage_2_date,
    passage_2.contact AS passage_2_contact,
    passage_2.observers AS passage_2_observers,
    passage_autre.*,
    passage_1.id_dataset
FROM
    gn_monitoring.t_base_sites tbs
    JOIN gn_monitoring.t_site_complements tsc ON tbs.id_base_site = tsc.id_base_site
	JOIN gn_monitoring.cor_site_module csm 
	ON  tbs.id_base_site = csm.id_base_site  
    JOIN MODULE m ON m.id_module = csm.id_module
    JOIN gn_monitoring.t_sites_groups tsg ON tsg.id_sites_group = tsc.id_sites_group
    LEFT JOIN LATERAL (
        SELECT
            *
        FROM
            visites tbv
        WHERE
            tbv.id_base_site = tbs.id_base_site
            AND num_passage = '1'
    ) passage_1 ON TRUE
    LEFT JOIN LATERAL (
        SELECT
            *
        FROM
            visites tbv
        WHERE
            tbv.id_base_site = tbs.id_base_site
            AND num_passage = '2'
    ) passage_2 ON TRUE
    LEFT JOIN LATERAL (
        SELECT
            TRUE AS autre_passages
        FROM
            visites tbv
        WHERE
            tbv.id_base_site = tbs.id_base_site
            AND (
                NOT num_passage IN ('2', '1')
                OR num_passage IS NULL
            )
        GROUP BY
            tbv.id_base_site
    ) passage_autre ON TRUE
ORDER BY
    sites_group_name,
    base_site_name;