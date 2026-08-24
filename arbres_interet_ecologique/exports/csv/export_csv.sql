
CREATE OR REPLACE VIEW gn_monitoring.v_export_arbres_interet_ecologique_arbres
AS WITH selected_type_site AS (
         SELECT DISTINCT cst.id_base_site
           FROM gn_monitoring.bib_type_site ts
             JOIN ref_nomenclatures.t_nomenclatures tn ON tn.id_nomenclature = ts.id_nomenclature_type_site
             JOIN gn_monitoring.cor_site_type cst ON cst.id_type_site = ts.id_nomenclature_type_site
          WHERE tn.cd_nomenclature::text = ANY (ARRAY['ARBRES_AIE'::character varying::text, 'ARBRES_LOGES'::character varying::text, 'ARBRES_CHIRO'::character varying::text, 'ARBRES_OSMO'::character varying::text])
        ), selected_site AS (
         SELECT tbs_1.id_base_site,
            string_agg(DISTINCT tns.label_default::text, ', '::text) AS type,
            string_agg(DISTINCT tns.cd_nomenclature::text, ', '::text) AS cd_type,
                CASE
                    WHEN 'ARBRES_AIE'::text = ANY (array_agg(DISTINCT tns.cd_nomenclature)::text[]) THEN 'x'::text
                    ELSE NULL::text
                END AS type_arbres_aie,
                CASE
                    WHEN 'ARBRES_LOGES'::text = ANY (array_agg(DISTINCT tns.cd_nomenclature)::text[]) THEN 'x'::text
                    ELSE NULL::text
                END AS type_arbres_loges,
                CASE
                    WHEN 'ARBRES_CHIRO'::text = ANY (array_agg(DISTINCT tns.cd_nomenclature)::text[]) THEN 'x'::text
                    ELSE NULL::text
                END AS type_arbres_noctules,
                CASE
                    WHEN 'ARBRES_OSMO'::text = ANY (array_agg(DISTINCT tns.cd_nomenclature)::text[]) THEN 'x'::text
                    ELSE NULL::text
                END AS type_arbres_osmo,
            string_agg(DISTINCT t_1.nom_valide::text, ', '::text) AS taxon_observes
           FROM gn_monitoring.t_base_sites tbs_1
             JOIN selected_type_site ts ON tbs_1.id_base_site = ts.id_base_site
             JOIN gn_monitoring.cor_site_type cst ON tbs_1.id_base_site = cst.id_base_site
             JOIN ref_nomenclatures.t_nomenclatures tns ON tns.id_nomenclature = cst.id_type_site
             LEFT JOIN gn_monitoring.t_base_visits tbv ON tbv.id_base_site = tbs_1.id_base_site
             LEFT JOIN gn_monitoring.t_observations tobs ON tobs.id_base_visit = tbv.id_base_visit
             LEFT JOIN taxonomie.taxref t_1 ON t_1.cd_nom = tobs.cd_nom
          GROUP BY tbs_1.id_base_site
        ), marquage AS (
         SELECT un.id_base_site,
            string_agg(tn.label_default::text, ','::text ORDER BY tn.label_default) AS marquage_label,
                CASE
                    WHEN 'Cercle'::text = ANY (array_agg(DISTINCT tn.label_default)::text[]) THEN 'x'::text
                    ELSE NULL::text
                END AS marquage_cercle,
                CASE
                    WHEN 'Rubalise'::text = ANY (array_agg(DISTINCT tn.label_default)::text[]) THEN 'x'::text
                    ELSE NULL::text
                END AS marquage_rubalise,
                CASE
                    WHEN 'Triangle'::text = ANY (array_agg(DISTINCT tn.label_default)::text[]) THEN 'x'::text
                    ELSE NULL::text
                END AS marquage_triangle,
                CASE
                    WHEN 'Point'::text = ANY (array_agg(DISTINCT tn.label_default)::text[]) THEN 'x'::text
                    ELSE NULL::text
                END AS marquage_point,
                CASE
                    WHEN 'Plaquette'::text = ANY (array_agg(DISTINCT tn.label_default)::text[]) THEN 'x'::text
                    ELSE NULL::text
                END AS marquage_plaquette
           FROM ( SELECT tsc_1.id_base_site,
                    jsonb_array_elements(NULLIF(tsc_1.data -> 'id_nomenclature_marquage'::text, 'null'::jsonb))::integer AS id_nomenclature_marquage
                   FROM selected_site tbs_1
                     JOIN gn_monitoring.t_site_complements tsc_1 ON tbs_1.id_base_site = tsc_1.id_base_site) un
             JOIN ref_nomenclatures.t_nomenclatures tn ON tn.id_nomenclature = un.id_nomenclature_marquage
          GROUP BY un.id_base_site
        ), unnest_dmh AS (
         SELECT tsc_1.id_base_site,
            jsonb_array_elements(NULLIF(tsc_1.data -> 'id_nomenclature_dmh'::text, 'null'::jsonb))::integer AS id_nomenclature_dmh
           FROM selected_site tbs_1
             JOIN gn_monitoring.t_site_complements tsc_1 ON tbs_1.id_base_site = tsc_1.id_base_site
        ), indexed_dmh AS (
         SELECT u.id_base_site,
            u.id_nomenclature_dmh,
            tn.label_default AS dmh_label,
            row_number() OVER (PARTITION BY u.id_base_site ORDER BY true::boolean) AS row_number
           FROM unnest_dmh u
             JOIN ref_nomenclatures.t_nomenclatures tn ON tn.id_nomenclature = u.id_nomenclature_dmh
        )
 SELECT DISTINCT s.id_base_site,
    s.base_site_code AS code_arbre,
    prf.area_code AS code_prf,
    concat(upper(tr.nom_role::text), ' ', tr.prenom_role) AS observateur,
    s.first_use_date,
    tbs.cd_type,
        CASE
            WHEN NOT (tsc.data ->> 'categorie_aie'::text) = 'null'::text THEN ( SELECT string_agg(a.value, ', '::text ORDER BY a.value) AS string_agg
               FROM jsonb_array_elements_text(tsc.data -> 'categorie_aie'::text) a(value))
            ELSE NULL::text
        END AS categorie_aie,
    t.nom_valide AS essence,
    split_part(t.nom_vern::text, ','::text, 1) AS nom_vern,
    (tsc.data ->> 'diametre'::text)::integer AS diametre,
    m.marquage_label AS marquages,
    tsc.data ->> 'espece_loges'::text AS espece_loges,
    tsc.data ->> 'nb_ebauches'::text AS nb_ebauches,
    tsc.data ->> 'nb_loges'::text AS nb_loges,
    tsc.data ->> 'num_plaquette'::text AS num_plaquette,
    tsc.data ->> 'ancien_code'::text AS ancien_code_arbre_loge,
    dmh_1.dmh_label AS dmh_1_label,
    dmh_2.dmh_label AS dmh_2_label,
    dmh_3.dmh_label AS dmh_3_label,
    dmh_4.dmh_label AS dmh_4_label,
    dmh_5.dmh_label AS dmh_5_label,
    dmh_6.dmh_label AS dmh_6_label,
    dmh_7.dmh_label AS dmh_7_label,
    dmh_8.dmh_label AS dmh_8_label,
    s.base_site_description AS commentaire,
    st_x(st_centroid(s.geom)) AS x,
    st_y(st_centroid(s.geom)) AS y,
    tbs.type,
    tbs.type_arbres_aie,
    tbs.type_arbres_loges,
    tbs.type_arbres_noctules,
    m.marquage_cercle,
    m.marquage_rubalise,
    m.marquage_triangle,
    m.marquage_point,
    m.marquage_plaquette,
    st_astext(s.geom) AS wkt,
    tbs.taxon_observes,
    s.geom
   FROM selected_site tbs
     JOIN gn_monitoring.t_base_sites s ON s.id_base_site = tbs.id_base_site
     JOIN gn_monitoring.t_site_complements tsc ON tbs.id_base_site = tsc.id_base_site
     LEFT JOIN marquage m ON m.id_base_site = tbs.id_base_site
     LEFT JOIN taxonomie.taxref t ON ((tsc.data ->> 'cd_nom_essence'::text)::integer) = t.cd_nom
     LEFT JOIN indexed_dmh dmh_1 ON dmh_1.id_base_site = tbs.id_base_site AND dmh_1.row_number = 1
     LEFT JOIN indexed_dmh dmh_2 ON dmh_2.id_base_site = tbs.id_base_site AND dmh_2.row_number = 2
     LEFT JOIN indexed_dmh dmh_3 ON dmh_3.id_base_site = tbs.id_base_site AND dmh_3.row_number = 3
     LEFT JOIN indexed_dmh dmh_4 ON dmh_4.id_base_site = tbs.id_base_site AND dmh_4.row_number = 4
     LEFT JOIN indexed_dmh dmh_5 ON dmh_5.id_base_site = tbs.id_base_site AND dmh_5.row_number = 5
     LEFT JOIN indexed_dmh dmh_6 ON dmh_6.id_base_site = tbs.id_base_site AND dmh_6.row_number = 6
     LEFT JOIN indexed_dmh dmh_7 ON dmh_7.id_base_site = tbs.id_base_site AND dmh_7.row_number = 7
     LEFT JOIN indexed_dmh dmh_8 ON dmh_8.id_base_site = tbs.id_base_site AND dmh_8.row_number = 8
     LEFT JOIN ( SELECT la.area_code,
            csa.id_base_site
           FROM gn_monitoring.cor_site_area csa
             JOIN ref_geo.l_areas la ON la.id_area = csa.id_area
             JOIN ref_geo.bib_areas_types bat ON bat.id_type = la.id_type AND bat.type_code::text = 'ONF_PRF'::text) prf ON prf.id_base_site = tbs.id_base_site
     LEFT JOIN utilisateurs.t_roles tr ON tr.id_role = s.id_inventor;

CREATE OR REPLACE VIEW gn_monitoring.v_export_arbres_interet_ecologique_observations
AS WITH observers AS (
         SELECT array_agg(r.id_role) AS ids_observers,
            string_agg(concat(upper(r.nom_role::text), ' ', r.prenom_role), ' ; '::text) AS observers,
            cvo_1.id_base_visit
           FROM gn_monitoring.cor_visit_observer cvo_1
             JOIN utilisateurs.t_roles r ON r.id_role = cvo_1.id_role
          GROUP BY cvo_1.id_base_visit
        )
 SELECT s.id_base_site AS code_arbre,
    s.base_site_name AS nom_arbre,
    st_x(st_centroid(s.geom)) AS x,
    st_y(st_centroid(s.geom)) AS y,
    tbv.id_base_visit AS id_visit,
    tbv.visit_date_min AS date_visite,
    cvo.observers AS observateurs,
    tbv.comments AS commentaire,
    obs.id_observation,
    t.lb_nom AS tax_nom_scientifique,
    t.nom_vern AS tax_nom_vern,
    t.cd_nom AS tax_cd_nom,
    tn.label_fr AS comportement,
    tn1.label_fr AS etat_biologique,
    tn2.label_fr AS method_obs,
    tn3.label_fr AS stade_vie,
    tn4.label_fr AS sexe,
    obs.comments AS comment_obs,
    toc.data ->> 'count_min'::text AS count_min,
    toc.data ->> 'count_max'::text AS count_max,
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
     LEFT JOIN observers cvo ON cvo.id_base_visit = tbv.id_base_visit
     JOIN gn_monitoring.t_observations obs ON obs.id_base_visit = tbv.id_base_visit
     LEFT JOIN gn_monitoring.t_observation_complements toc ON toc.id_observation = obs.id_observation
     LEFT JOIN taxonomie.taxref t ON t.cd_nom = obs.cd_nom
     LEFT JOIN ref_nomenclatures.t_nomenclatures tn ON ((toc.data ->> 'id_nomenclature_behaviour'::text)::integer) = tn.id_nomenclature
     LEFT JOIN ref_nomenclatures.t_nomenclatures tn1 ON ((toc.data ->> 'id_nomenclature_bio_condition'::text)::integer) = tn1.id_nomenclature
     LEFT JOIN ref_nomenclatures.t_nomenclatures tn2 ON ((toc.data ->> 'id_nomenclature_meth_obs'::text)::integer) = tn2.id_nomenclature
     LEFT JOIN ref_nomenclatures.t_nomenclatures tn3 ON ((toc.data ->> 'id_nomenclature_life_stage'::text)::integer) = tn3.id_nomenclature
     LEFT JOIN ref_nomenclatures.t_nomenclatures tn4 ON ((toc.data ->> 'id_nomenclature_sex'::text)::integer) = tn4.id_nomenclature
  WHERE m.module_code::text = 'arbres_interet_ecologique'::text;
