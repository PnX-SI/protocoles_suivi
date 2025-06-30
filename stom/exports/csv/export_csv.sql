CREATE OR REPLACE VIEW gn_monitoring.v_export_stom_observations_and_habitat
AS WITH observers AS (
         SELECT cvo2.id_base_visit,
            string_agg(concat(tr2.prenom_role, ' ', tr2.nom_role), ','::text) AS observateurs
           FROM gn_monitoring.cor_visit_observer cvo2
             JOIN utilisateurs.t_roles tr2 ON tr2.id_role = cvo2.id_role
          GROUP BY cvo2.id_base_visit
        )
 SELECT 
     obs.id_observation,
 	tsg.sites_group_name AS nom_site,
    s.base_site_code AS id_point_ecoute,
    s.base_site_name AS nom_point_ecoute,
    st_x(s.geom) AS x,
    st_y(s.geom) AS y,
    a.jname ->> 'COM'::text AS commune,
    a.jname ->> 'SEC'::text AS secteur,
    tbv.id_base_visit AS id_visit,
    tbv.visit_date_min AS date_visite,
    tvc.data ->> 'heure'::text AS heure_debut,
    o.observateurs,
    tbv.comments AS commentaire_visite,
    tvc.data ->> 'debutant'::text AS observateur_debutant,
    tvc.data ->> 'nuages'::text AS nuages,
    tvc.data ->> 'pluie'::text AS pluie,
    tvc.data ->> 'vent'::text AS vent,
    tvc.data ->> 'visi'::text AS visibilite,
    tvc.data ->> 'deneigement'::text AS deneigement,
    tvc.data ->> 'paturage'::text AS paturage,
    tvc.data ->> 'habitat_input'::text AS saisie_habitat,
    tvc.data ->> 'roche'::text AS roche,
    tvc.data ->> 'sol_nu'::text AS sol_nu,
    tvc.data ->> 'herb'::text AS herbace,
    tvc.data ->> 'arb_inf_30cm'::text AS arb_inf_30cm,
    tvc.data ->> 'arb_inf_1m'::text AS arb_inf_1m,
    tvc.data ->> 'arb_1_4m'::text AS arb_1_4m,
    tvc.data ->> 'arb_sup_4m'::text AS arb_sup_4m,
    tvc.data ->> 'elem_paysager'::text AS elem_paysager,
    t.lb_nom AS tax_nom_scientifique,
    t.nom_vern AS tax_nom_vern,
    t.cd_nom AS tax_cd_nom,
    toc.data ->> 'nb_0_5'::text AS nb_0_5,
    toc.data ->> 'nb_5_10'::text AS nb_5_10,
    toc.data ->> 'nb_10_15'::text AS nb_10_15,
    toc.data ->> 'nb_hors_proto'::text AS nb_hors_proto,
    toc.data ->> 'presence_juvenile'::text AS presence_juvenile,
    obs.comments AS commentaire_observation,
    tbv.id_dataset
   FROM gn_monitoring.t_base_sites s
     LEFT JOIN gn_monitoring.t_site_complements tsc ON s.id_base_site = tsc.id_base_site
     LEFT JOIN gn_monitoring.t_sites_groups tsg ON tsg.id_sites_group = tsc.id_sites_group
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
     JOIN gn_monitoring.t_base_visits tbv ON tbv.id_base_site = s.id_base_site
     JOIN gn_monitoring.t_visit_complements tvc ON tvc.id_base_visit = tbv.id_base_visit
     LEFT JOIN observers o ON o.id_base_visit = tbv.id_base_visit
     LEFT JOIN gn_commons.t_modules m ON m.id_module = tbv.id_module
     JOIN gn_monitoring.t_observations obs ON obs.id_base_visit = tbv.id_base_visit
     JOIN gn_monitoring.t_observation_complements toc ON toc.id_observation = obs.id_observation
     JOIN taxonomie.taxref t ON t.cd_nom = obs.cd_nom
  WHERE m.module_code::text = 'stom'::text
  ORDER BY tsg.id_sites_group, tbv.visit_date_min, s.base_site_name;

CREATE OR REPLACE VIEW gn_monitoring.v_export_stom_only_observations
 as with observers as (
     SELECT 
     cvo2.id_base_visit,
     string_agg(concat(tr2.prenom_role, ' ', tr2.nom_role), ',') AS observateurs
     FROM gn_monitoring.cor_visit_observer cvo2
     JOIN utilisateurs.t_roles tr2 ON tr2.id_role = cvo2.id_role
     GROUP BY cvo2.id_base_visit  
 )
 SELECT 
tsg.sites_group_name AS nom_site,
s.id_base_site AS id_point_ecoute,
s.base_site_name AS nom_point_ecoute,
st_x(s.geom) AS X,
st_y(s.geom) AS Y,
tbv.id_base_visit AS id_visit,
tbv.visit_date_min AS date_visite,
tvc."data"->>'heure' AS heure_debut,
o.observateurs,
obs.id_observation AS id_observation,
t.lb_nom AS tax_nom_scientifique,
t.nom_vern as tax_nom_vern,
t.cd_nom AS tax_cd_nom,
toc."data"->>'nb_0_5' AS nb_0_5,
toc."data"->>'nb_5_10' AS nb_5_10,
toc."data"->>'nb_10_15' AS nb_10_15,
toc."data"->>'nb_hors_proto' AS nb_hors_proto,
toc."data"->>'presence_juvenile' AS presence_juvenile,
obs."comments" AS commentaire_observation,
tbv.id_dataset
from gn_monitoring.t_base_sites s
LEFT JOIN gn_monitoring.t_site_complements tsc ON s.id_base_site = tsc.id_base_site 
LEFT JOIN gn_monitoring.t_sites_groups tsg ON tsg.id_sites_group = tsc.id_sites_group 
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
      GROUP BY d_1.id_base_site) a ON true
JOIN gn_monitoring.t_base_visits tbv ON tbv.id_base_site = s.id_base_site 
JOIN gn_monitoring.t_visit_complements tvc ON tvc.id_base_visit = tbv.id_base_visit
LEFT JOIN observers o ON o.id_base_visit = tbv.id_base_visit 
LEFT JOIN gn_commons.t_modules m ON m.id_module = tbv.id_module
JOIN gn_monitoring.t_observations obs ON obs.id_base_visit = tbv.id_base_visit 
JOIN gn_monitoring.t_observation_complements toc ON toc.id_observation = obs.id_observation 
JOIN taxonomie.taxref t ON t.cd_nom = obs.cd_nom
WHERE m.module_code::text = :module_code;


CREATE OR REPLACE VIEW gn_monitoring.v_export_stom_sites
AS SELECT 
    tsg.id_sites_group AS id_site,
    tsg.sites_group_name AS nom_site,
    s.id_base_site AS id_point_ecoute,
    s.base_site_name AS nom_point_ecoute,
    st_x(s.geom) AS x,
    st_y(s.geom) AS y,
    a.jname ->> 'COM'::text AS commune,
    a.jname ->> 'SEC'::text AS secteur, 
    (
        SELECT id_dataset
        FROM gn_commons.t_modules tm
        JOIN gn_commons.cor_module_dataset cmd 
        ON tm.id_module = cmd.id_module 
        WHERE module_code = :module_code
        LIMIT 1
    ) as id_dataset
FROM gn_monitoring.t_base_sites s
JOIN gn_monitoring.t_site_complements tsc ON s.id_base_site = tsc.id_base_site
JOIN gn_monitoring.cor_site_module csm ON s.id_base_site =csm.id_base_site 
LEFT JOIN gn_monitoring.t_sites_groups tsg ON tsg.id_sites_group = tsc.id_sites_group
LEFT JOIN LATERAL ( 
    SELECT 
        d_1.id_base_site,
        json_object_agg(d_1.type_code, d_1.o_name) AS jname,
        json_object_agg(d_1.type_code, d_1.o_code) AS jcode
        FROM ( 
            SELECT sa.id_base_site,
                ta.type_code,
                string_agg(DISTINCT a_1.area_name::text, ','::text) AS o_name,
                string_agg(DISTINCT a_1.area_code::text, ','::text) AS o_code
            FROM gn_monitoring.cor_site_area sa
            JOIN ref_geo.l_areas a_1 ON sa.id_area = a_1.id_area
            JOIN ref_geo.bib_areas_types ta ON ta.id_type = a_1.id_type
            WHERE sa.id_base_site = s.id_base_site
            GROUP BY sa.id_base_site, ta.type_code
        ) d_1
        GROUP BY d_1.id_base_site
) a ON true
 WHERE csm.id_module =  (SELECT id_module FROM gn_commons.t_modules tm WHERE module_code =:module_code);