
CREATE OR REPLACE VIEW gn_monitoring.v_export_osmodermes_arbre_synthese
AS WITH type_site AS (
	 SELECT
	        tm.id_module, cmt.id_type_site
	FROM
	    gn_commons.t_modules tm
	    JOIN  gn_monitoring.cor_module_type cmt 
	    ON cmt.id_module = tm.id_module
	WHERE
	    tm.module_code = 'osmodermes'
), sites AS (
	SELECT DISTINCT tbs.id_base_site , tbs.base_site_code , tbs.base_site_name , tbs.base_site_description , tbs.geom_local 
	FROM gn_monitoring.t_base_sites tbs 
	JOIN gn_monitoring.cor_site_type cst ON cst.id_base_site = tbs.id_base_site 
    JOIN type_site m ON m.id_type_site = cst.id_type_site
), last_evol as (
	SELECT  distinct on (tbv.id_base_site ) tbv.id_base_site, tbv.visit_date_max , tvc.DATA->>'id_nomenclature_visit_evol' AS last_evol
	FROM gn_monitoring.t_visit_complements tvc 
	JOIN gn_monitoring.t_base_visits tbv 
	ON tbv.id_base_visit = tvc.id_base_visit 
	WHERE  tvc.DATA->>'id_nomenclature_visit_evol' IS NOT NULL
	ORDER BY tbv.id_base_site , tbv.visit_date_max 
), last_vitalite as (
	SELECT  distinct on (tbv.id_base_site ) tbv.id_base_site, tbv.visit_date_max , tvc.DATA->>'id_nomenclature_vital' AS last_vitalite
	FROM gn_monitoring.t_visit_complements tvc 
	JOIN gn_monitoring.t_base_visits tbv 
	ON tbv.id_base_visit = tvc.id_base_visit 
	WHERE  tvc.DATA->>'id_nomenclature_vital' IS NOT NULL
	ORDER BY tbv.id_base_site , tbv.visit_date_max 
), max_val AS ( 
 SELECT s.id_base_site,
            count(tbv.id_base_visit) AS nb_v,
            min(tbv.visit_date_max) AS date_pv,
            max(tbv.visit_date_max) AS date_dv,
            max((tvc.DATA->>'circ')::int) AS synt_circ,
            max((tvc.DATA->>'diam')::int) AS synt_diam
            FROM gn_monitoring.t_visit_complements tvc 
			JOIN gn_monitoring.t_base_visits tbv 
			ON tbv.id_base_visit = tvc.id_base_visit 
			JOIN sites s ON s.id_base_site = tbv.id_base_site
 		GROUP BY s.id_base_site 
          ) 
SELECT tbs.id_base_site , 
	tbs.base_site_code ,  
	tsc."data"->>'code_arbre_pnc' AS code_arbre_pnc,
	tbs.geom_local ,
st_astext(tbs.geom_local) AS geom_wkt, 
	tsc."data"->>'proprio' AS proprio,
	tsc."data"->>'secteur' AS secteur,
	t.cd_nom AS cd_nom_essence,
	t.lb_nom AS essence, 
	t.nom_vern AS nom_vern,
	 v.nb_v,
    v.date_pv,
    v.date_dv,
    v.synt_circ,
    v.synt_diam,  
     last_vitalite.last_vitalite AS synt_vit_l,
	tn.label_fr   AS synt_osm_l, 
     last_evol.last_evol AS synt_evol_l,
	tbs.base_site_description 
FROM sites tbs 
JOIN gn_monitoring.t_site_complements tsc ON tbs.id_base_site = tsc.id_base_site 
LEFT JOIN taxonomie.taxref t  ON t.cd_nom = (tsc."data"->>'cd_nom_essence')::int
LEFT JOIN ref_nomenclatures.t_nomenclatures tn   ON tn.id_nomenclature = (tsc."data"->>'id_nomenclature_synthese')::int
LEFT JOIN max_val v ON v.id_base_site = tbs.id_base_site
LEFT JOIN last_evol  ON last_evol.id_base_site = tbs.id_base_site
LEFT JOIN last_vitalite  ON last_vitalite.id_base_site = tbs.id_base_site;



CREATE OR REPLACE VIEW gn_monitoring.v_export_osmodermes_arbre_visits AS 
WITH observers AS (
    SELECT
        array_agg(r.id_role) AS ids_observers,
        STRING_AGG(CONCAT(UPPER(r.nom_role), ' ', prenom_role), ' ; ') AS observers,
        id_base_visit
    FROM gn_monitoring.cor_visit_observer cvo
    JOIN utilisateurs.t_roles r
    ON r.id_role = cvo.id_role
    GROUP BY id_base_visit
), indices AS (
	 SELECT vc.id_base_visit , string_agg(tn.cd_nomenclature , '-') AS label_indices
	 FROM  gn_monitoring.t_visit_complements vc
	 JOIN LATERAL (
		SELECT (jsonb_array_elements_text(data->'id_nomenclature_indices'))::int AS idx
		WHERE data ? 'id_nomenclature_indices'
	) AS x ON TRUE
	JOIN ref_nomenclatures.t_nomenclatures tn 
	ON tn.id_nomenclature = x.idx 
	GROUP BY  vc.id_base_visit 
)
SELECT 
a.id_base_site, 
a.base_site_code, 
a.code_arbre_pnc, 
a.geom_local, 
st_astext(a.geom_local) AS geom_wkt, 
a.proprio, 
a.secteur, 
a.cd_nom_essence, 
a.essence, 
a.nom_vern, 
a.nb_v, 
a.date_pv, 
a.date_dv, 
a.synt_circ, 
a.synt_diam, 
a.synt_vit_l, 
a.synt_osm_l, 
a.synt_evol_l, 
a.base_site_description,
tbv.visit_date_min AS visit_date , 
obs.observers ,
tn_evol.label_default AS evolution,
tn_ca.label_default AS cavite,
i.label_indices AS indices, 
tn_vit.label_default as vital,
tn_pro.label_default as prospection,
tn_sui.label_default as suite,
tn_pho.label_default as photo_orientation,
tbv.COMMENTS AS commentaires
FROM gn_monitoring.v_export_osmodermes_arbre_synthese a
JOIN gn_monitoring.t_base_visits tbv 
ON tbv.id_base_site = a.id_base_site 
JOIN gn_monitoring.t_visit_complements tvc 
ON tvc.id_base_visit = tbv.id_base_visit 
JOIN gn_commons.t_modules tm 
ON tm.id_module = tbv.id_module AND tm.module_code = 'osmodermes' 
LEFT JOIN observers obs ON obs.id_base_visit = tbv.id_base_visit 
LEFT JOIN indices i ON i.id_base_visit = tbv.id_base_visit 
LEFT JOIN ref_nomenclatures.t_nomenclatures tn_ca   ON   tn_ca.id_nomenclature = (tvc."data" ->> 'id_nomenclature_cavite')::int  
LEFT JOIN ref_nomenclatures.t_nomenclatures tn_evol ON tn_evol.id_nomenclature = (tvc."data" ->> 'id_nomenclature_visit_evol')::int    
LEFT JOIN ref_nomenclatures.t_nomenclatures tn_vit  ON tn_vit.id_nomenclature = (tvc."data" ->> 'id_nomenclature_vital')::int
LEFT JOIN ref_nomenclatures.t_nomenclatures tn_pro  ON tn_pro.id_nomenclature = (tvc."data" ->> 'id_nomenclature_prospection')::int
LEFT JOIN ref_nomenclatures.t_nomenclatures tn_sui  ON tn_sui.id_nomenclature = (tvc."data" ->> 'id_nomenclature_suite')::int
LEFT JOIN ref_nomenclatures.t_nomenclatures tn_pho  ON tn_pho.id_nomenclature = (tvc."data" ->> 'id_nomenclature_photo_orientation')::int;

