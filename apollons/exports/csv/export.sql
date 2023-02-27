

DROP VIEW  IF EXISTS  gn_monitoring.v_export_apollons_results_per_dalle;

CREATE OR REPLACE VIEW gn_monitoring.v_export_apollons_results_per_dalle
 AS
WITH MOD AS (
    SELECT *
    FROM gn_commons.t_modules AS tm
    WHERE module_code = :module_code
)
SELECT
tbs.base_site_code ,
st_x(tbs.geom) AS longitude,
st_y(tbs.geom) AS latitude,
tbv.visit_date_min ,
tvc."data"->>'time_start' AS time_start,
tvc."data"->>'time_end' AS time_end,
tvc.data->>'num_passage' as num_passage,
tvc.data->>'count_stade_l1' as count_stade_l1,
tvc.data->>'count_stade_l2' as count_stade_l2,
tvc.data->>'count_stade_l3' as count_stade_l3,
tvc.data->>'count_stade_l4' as count_stade_l4,
tvc.data->>'count_stade_l5' as count_stade_l5,
a.observateur
FROM gn_monitoring.t_base_sites AS tbs
JOIN gn_monitoring.t_base_visits AS tbv
ON tbv.id_base_site = tbs.id_base_site
JOIN gn_monitoring.t_visit_complements AS tvc
ON tvc.id_base_visit  = tbv.id_base_visit
JOIN gn_monitoring.t_site_complements AS tsc
ON tbs.id_base_site = tsc.id_base_site AND tsc.id_module = (SELECT id_module FROM mod)
JOIN LATERAL (
    SELECT string_agg(concat_ws(' ', tr.nom_role, tr.prenom_role), ',') AS observateur, cvo.id_base_visit
    FROM gn_monitoring.cor_visit_observer AS cvo
    JOIN utilisateurs.t_roles AS tr
    ON tr.id_role = cvo.id_role AND cvo.id_base_visit = tbv.id_base_visit
    GROUP BY cvo.id_base_visit
) a
ON true
ORDER BY base_site_code,tbv.visit_date_min,   tvc.data->>'num_passage';