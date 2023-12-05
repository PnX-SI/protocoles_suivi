-- Export des observations
CREATE OR REPLACE VIEW gn_monitoring.v_export_nidif_gypa_observations
AS 
with observers as (
select 
    string_agg(concat(tr.nom_role, ' ', tr.prenom_role), ', '::text) AS observateurs,
    cvo.id_base_visit
     FROM gn_monitoring.cor_visit_observer cvo
     join utilisateurs.t_roles tr on tr.id_role = cvo.id_role
     group by id_base_visit
)
SELECT s.id_base_site AS code_gite,
    s.base_site_name AS nom_gite,
    ST_AsText(s.geom) AS geom,
    tbv.id_base_visit AS id_visit,
    tbv.visit_date_min AS date_visite,
    (tvc.data ->> 'hour_min')::text AS heure_debut_visit,
    (tvc.data ->> 'hour_max')::text AS heure_fin_visit,
    observers.observateurs,
    (tvc.data ->> 'obs_txt')::text AS observateur_hors_pne,
    tbv.comments AS comment_visit,
    (tvc.data ->> 'visibility')::text AS visibilite,
    (tvc.data ->> 'etat_aire')::text AS etat_aire,
    obs.id_observation,
    t.lb_nom AS tax_nom_scientifique,
    tn.label_fr AS comportement,
    tn3.label_fr AS stade_vie,
    tn4.label_fr AS sexe,
    obs.comments AS comment_obs,
    (toc.data ->> 'count')::text AS denombrement,
    (toc.data ->> 'indiv_a_aire')::text AS indiv_a_aire,
    (toc.data ->> 'chargement_aire')::text AS chargement_aire,
    (toc.data ->> 'bague_plastique')::text AS bague_plastique,
    (toc.data ->> 'bague_mnhn')::text AS bague_mnhn,
    (toc.data ->> 'nom_individu')::text AS nom_individu,
    tbv.id_dataset,
    a.jname ->> 'COM'::text AS commune,
    a.jname ->> 'SEC'::text AS secteur
   FROM gn_monitoring.t_base_sites s
     LEFT JOIN gn_monitoring.t_site_complements tsc ON s.id_base_site = tsc.id_base_site
     JOIN LATERAL ( SELECT d_1.id_base_site,
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
     LEFT JOIN gn_monitoring.t_visit_complements tvc ON tvc.id_base_visit = tbv.id_base_visit
     JOIN gn_commons.t_modules m ON m.id_module = tbv.id_module
     join observers observers on observers.id_base_visit = tvc.id_base_visit
     JOIN gn_monitoring.t_observations obs ON obs.id_base_visit = tbv.id_base_visit
     LEFT JOIN gn_monitoring.t_observation_complements toc ON toc.id_observation = obs.id_observation
     LEFT JOIN taxonomie.taxref t ON t.cd_nom = obs.cd_nom
     LEFT JOIN ref_nomenclatures.t_nomenclatures tn ON ((toc.data ->> 'id_nomenclature_behaviour'::text)::integer) = tn.id_nomenclature
     LEFT JOIN ref_nomenclatures.t_nomenclatures tn3 ON ((toc.data ->> 'id_nomenclature_life_stage'::text)::integer) = tn3.id_nomenclature
     LEFT JOIN ref_nomenclatures.t_nomenclatures tn4 ON ((toc.data ->> 'id_nomenclature_sex'::text)::integer) = tn4.id_nomenclature
  --GROUP BY s.id_base_site, s.base_site_name, (st_x(s.geom)), (st_y(s.geom)), (tsc.data ->> 'threat'::text), (tvc.data ->> 'sheet_id'::text), tbv.id_base_visit, tbv.visit_date_min, (tvc.data ->> 'observers_txt'::text), tbv.comments, (tvc.data ->> 'guano_presency'::text), (tvc.data ->> 'guano_comment'::text), obs.id_observation, t.lb_nom, t.nom_vern, t.cd_nom, tn.label_fr, tn1.label_fr, tn2.label_fr, tbv.id_dataset, (a.jname ->> 'COM'::text), (a.jname ->> 'SEC'::text), (toc.data ->> 'count_indiv'::text), tn3.label_fr, tn4.label_fr, obs.comments;
  WHERE m.module_code = 'nidif_gypa';

-- Export des sites

 CREATE OR REPLACE VIEW gn_monitoring.v_export_nidif_gypa_sites AS
SELECT
  s.id_base_site AS code_gite,
  s.base_site_name AS nom_gite,
  st_astext(s.geom) AS geom,
  a.jname->>'COM' AS commune,
  a.jname->>'SEC' AS secteur,
  s.base_site_description AS description_aire
FROM gn_monitoring.t_base_sites s
JOIN gn_monitoring.t_site_complements tsc ON s.id_base_site = tsc.id_base_site
JOIN gn_monitoring.cor_site_module csm on s.id_base_site = csm.id_base_site
JOIN gn_commons.t_modules mod on mod.id_module = csm.id_module  AND mod.module_code = 'nidif_gypa'
LEFT JOIN LATERAL (
  SELECT d_1.id_base_site ,
    json_object_agg(d_1.type_code, d_1.o_name) AS jname,
    json_object_agg(d_1.type_code, d_1.o_code) AS jcode
  FROM (
    SELECT sa.id_base_site ,
      ta.type_code,
      string_agg(DISTINCT a_1.area_name::text, ','::text) AS o_name,
      string_agg(DISTINCT a_1.area_code::text, ','::text) AS o_code
    FROM gn_monitoring.cor_site_area  sa
    JOIN ref_geo.l_areas a_1 ON sa.id_area = a_1.id_area
    JOIN ref_geo.bib_areas_types ta ON ta.id_type = a_1.id_type
    WHERE sa.id_base_site  = s.id_base_site
    GROUP BY sa.id_base_site , ta.type_code
    ) d_1
  GROUP BY d_1.id_base_site
) a ON TRUE
