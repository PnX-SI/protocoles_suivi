CREATE OR REPLACE VIEW gn_monitoring.v_export_chiro_observations
 as SELECT 
s.id_base_site AS code_gite,
s.base_site_name AS nom_gite,
st_x(s.geom) AS X,
st_y(s.geom) AS Y,
tsc."data"->>'owner_name' AS nom_proprio,
tsc."data"->>'owner_adress' AS adresse_proprio,
tsc."data"->>'owner_tel' AS tel_proprio,
tsc."data"->>'owner_mail' AS email_proprio,
tsc."data"->>'roost_type' AS type_gite,
tsc."data"->>'opening' AS ouverture,
s.base_site_description AS description_gite,
tsc."data"->>'threat' AS menaces,
tsc."data"->>'recommandation' AS preconisations,
tvc."data"->>'sheet_id' AS ancien_num_fiche,
tbv.id_base_visit AS id_visit,
tbv.visit_date_min AS date_visite,
string_agg(concat(tr.nom_role, ' ', tr.prenom_role), ', ') AS observateurs,
tvc."data"->>'observers_txt' AS observateur_hors_pne,
tbv."comments" AS commentaire,
tvc."data"->>'guano_presency' AS presence_guano,
tvc."data"->>'guano_comment' AS commentaire_guano,
obs.id_observation AS id_observation,
t.lb_nom AS tax_nom_scientifique,
t.nom_vern as tax_nom_vern,
t.cd_nom AS tax_cd_nom,
tn.label_fr AS comportement,
tn1.label_fr AS etat_biologique,
tn1.label_fr AS method_obs,
tbv.id_dataset,
a.jname->>'COM' AS commune,
a.jname->>'SEC' AS secteur
from gn_monitoring.t_base_sites s
LEFT JOIN gn_monitoring.t_site_complements tsc ON s.id_base_site = tsc.id_base_site 
JOIN LATERAL ( SELECT d_1.id_base_site ,
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
LEFT JOIN gn_monitoring.t_visit_complements tvc ON tvc.id_base_visit = tbv.id_base_visit
JOIN gn_commons.t_modules m ON m.id_module = tbv.id_module
LEFT JOIN gn_monitoring.cor_visit_observer cvo ON cvo.id_base_visit = tbv.id_base_visit 
LEFT JOIN utilisateurs.t_roles tr ON tr.id_role = cvo.id_role 
JOIN gn_monitoring.t_observations obs ON obs.id_base_visit = tbv.id_base_visit 
LEFT JOIN gn_monitoring.t_observation_complements toc ON toc.id_observation = obs.id_observation 
LEFT JOIN taxonomie.taxref t ON t.cd_nom = obs.cd_nom 
LEFT JOIN ref_nomenclatures.t_nomenclatures tn on (toc."data"->>'id_nomenclature_behaviour')::integer = tn.id_nomenclature 
LEFT JOIN ref_nomenclatures.t_nomenclatures tn1 on (toc."data"->>'id_nomenclature_bio_condition')::integer = tn1.id_nomenclature 
LEFT JOIN ref_nomenclatures.t_nomenclatures tn2 on (toc."data"->>'id_nomenclature_meth_obs')::integer = tn2.id_nomenclature
WHERE m.module_code::text = 'chiro'
GROUP BY s.id_base_site,
s.base_site_name,
st_x(s.geom),
st_y(s.geom),
tsc."data"->>'owner_name',
tsc."data"->>'owner_adress',
tsc."data"->>'owner_tel',
tsc."data"->>'owner_mail',
tsc."data"->>'roost_type',
tsc."data"->>'opening',
s.base_site_description,
tsc."data"->>'threat',
tsc."data"->>'recommandation',
tvc."data"->>'sheet_id',
tbv.id_base_visit,
tbv.visit_date_min,
tvc."data"->>'observers_txt',
tbv."comments",
tvc."data"->>'guano_presency',
tvc."data"->>'guano_comment',
obs.id_observation,
t.lb_nom,
t.nom_vern,
t.cd_nom,
tn.label_fr,
tn1.label_fr,
tn1.label_fr,
tbv.id_dataset,
a.jname->>'COM',
a.jname->>'SEC';

CREATE OR REPLACE VIEW gn_monitoring.v_export_chiro_sites
 AS SELECT 
s.id_base_site AS code_gite,
s.base_site_name AS nom_gite,
st_x(s.geom) AS X,
st_y(s.geom) AS Y,
a.jname->>'COM' AS commune,
a.jname->>'SEC' AS secteur,
tsc."data"->>'owner_name' AS nom_proprio,
tsc."data"->>'owner_adress' AS adresse_proprio,
tsc."data"->>'owner_tel' AS tel_proprio,
tsc."data"->>'owner_mail' AS email_proprio,
tsc."data"->>'roost_type' AS type_gite,
tsc."data"->>'opening' AS ouverture,
s.base_site_description AS description_gite,
tsc."data"->>'threat' AS menaces,
tsc."data"->>'recommandation' AS preconisations,
16 as id_dataset-- id_dataset obligatoire.. todo enlever ça / corrigé sur la branche develop
from gn_monitoring.t_base_sites s
JOIN gn_monitoring.t_site_complements tsc ON s.id_base_site = tsc.id_base_site 
JOIN gn_monitoring.cor_site_module csm on s.id_base_site = csm.id_base_site
JOIN gn_commons.t_modules mod on mod.id_module = csm.id_module
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
WHERE mod.module_code = 'chiro'
GROUP BY d_1.id_base_site) a ON TRUE
;