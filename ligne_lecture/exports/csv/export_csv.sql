CREATE OR REPLACE VIEW gn_monitoring.v_export_ligne_lecture_all
 AS with observers as (
     SELECT 
     cvo2.id_base_visit,
     string_agg(concat(tr2.prenom_role, ' ', tr2.nom_role), ',') AS observateurs
     FROM gn_monitoring.cor_visit_observer cvo2
     JOIN utilisateurs.t_roles tr2 ON tr2.id_role = cvo2.id_role
     GROUP BY cvo2.id_base_visit  
 )
 SELECT 
s.id_base_site AS id_placette_maitre,
s.base_site_name AS nom_placette_maitre,
st_astext(s.geom) AS geometrie,
st_x(st_centroid(s.geom)) AS centroid_x,
st_y(st_centroid(s.geom)) AS centroid_y,
tbv.id_base_visit AS id_visit,
tbv.visit_date_min AS date_visite,
o.observateurs,
tbv.id_dataset as id_dataset,
tbv."comments" AS commentaire_visite,
obs.id_observation AS id_observation,
t.lb_nom AS nom_scientifique,
t.nom_vern AS nom_vern,
t.cd_nom AS cd_nom,
toc."data"->>'num_point' AS num_point,
m.module_code
from gn_monitoring.t_base_sites s
LEFT JOIN gn_monitoring.t_site_complements tsc ON s.id_base_site = tsc.id_base_site 
JOIN gn_monitoring.t_base_visits tbv ON tbv.id_base_site = s.id_base_site 
JOIN gn_monitoring.t_visit_complements tvc ON tvc.id_base_visit = tbv.id_base_visit
LEFT JOIN observers o ON o.id_base_visit = tbv.id_base_visit 
LEFT JOIN gn_commons.t_modules m ON m.id_module = tbv.id_module
JOIN gn_monitoring.t_observations obs ON obs.id_base_visit = tbv.id_base_visit 
JOIN gn_monitoring.t_observation_complements toc ON toc.id_observation = obs.id_observation 
JOIN taxonomie.taxref t ON t.cd_nom = obs.cd_nom
WHERE m.module_code::text = 'ligne_lecture';
