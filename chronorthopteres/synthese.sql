DROP VIEW IF EXISTS gn_monitoring.v_synthese_chronoventaire;
CREATE VIEW gn_monitoring.v_synthese_chronoventaire AS (
with t_source as (select id_source 
				FROM gn_synthese.t_sources 
				WHERE name_source = CONCAT('MONITORING_', UPPER('CHRONOVENTAIRE'))
				),
	 observers AS (SELECT array_agg(r.id_role) AS ids_observers,
				        STRING_AGG(CONCAT(r.nom_role, ' ', prenom_role), ' ; ') AS observers,
				        id_base_visit
			    FROM gn_monitoring.cor_visit_observer cvo
			    JOIN utilisateurs.t_roles r ON r.id_role = cvo.id_role
			    GROUP BY id_base_visit)
select to2.uuid_observation as unique_id_sinp,
	   tbs.id_base_site as unique_id_sinp_grp, 
	   t_source.id_source,
	   to2.id_observation as entity_source_pk_value,
	   tbv.id_dataset,
	   ref_nomenclatures.get_id_nomenclature('NAT_OBJ_GEO', 'St') AS id_nomenclature_geo_object_nature,
	   ref_nomenclatures.get_id_nomenclature('METH_OBS', '50') AS id_nomenclature_obs_meth,
	   toc."data" #>> '{id_nomenclature_stade}' AS id_nomenclature_life_stage,
	   toc."data" #>> '{id_sexe}' AS id_nomenclature_sex,
	   ref_nomenclatures.get_id_nomenclature('OBJ_DENBR', 'IND') AS id_nomenclature_obj_count,
 	   ref_nomenclatures.get_id_nomenclature('TYP_DENBR', 'Co') AS id_nomenclature_type_count,
 	   ref_nomenclatures.get_id_nomenclature('STATUT_OBS', 'Pr') AS id_nomenclature_observation_status, 
	   ref_nomenclatures.get_id_nomenclature('STATUT_SOURCE', 'Te') AS id_nomenclature_source_status,
	   ref_nomenclatures.get_id_nomenclature('TYP_INF_GEO', '1') AS id_nomenclature_info_geo_type,
	   toc."data" #>> '{id_nomenclature_determination_method}' as id_nomenclature_determination_method,
	   toc."data" #>> '{nb_count}' as count_min,
	   toc."data" #>> '{nb_count}' as count_max,
	   to2.cd_nom as cd_nom,
	   t.nom_complet as nom_cite,
	   alt.altitude_min,
	   alt.altitude_max,
	   tbs.geom AS the_geom_4326,
	   ST_CENTROID(tbs.geom) AS the_geom_point,
	   tbs.geom_local as the_geom_local,
	   tbv.visit_date_min AS date_min,
	   COALESCE (tbv.visit_date_max, tbv.visit_date_min) AS date_max,
	   tbv.id_base_visit as id_visit,
	   tbv.visit_date_max,	
	   tbv.id_digitiser,
	   tbs.id_inventor,
	   concat(tr.nom_role, ' ',tr.prenom_role) as observers,
	   tsc.id_module,
	   tbv."comments" AS comment_context,
	   to2."comments" AS comment_description,
	   obs.ids_observers,
	   tbv.id_base_site,
	   tbv.id_base_visit
from gn_monitoring.t_base_sites tbs
left join gn_monitoring.t_site_complements tsc on tsc.id_base_site = tbs.id_base_site 
left join gn_monitoring.t_base_visits tbv on tbs.id_base_site = tbv.id_base_site 
--left join gn_monitoring.t_visit_complements tvc on tvc.id_base_visit = tbv.id_base_visit 
left join observers obs on obs.id_base_visit = tbv.id_base_visit 
left join gn_monitoring.t_observations to2 on to2.id_base_visit = tbv.id_base_visit 
left join gn_monitoring.t_observation_complements toc on toc.id_observation = to2.id_observation 
left join utilisateurs.t_roles tr on tr.id_role = tbv.id_digitiser 
left join taxonomie.taxref t on to2.cd_nom = t.cd_nom 
left join t_source on true
left join lateral ref_geo.fct_get_altitude_intersection(tbs.geom_local) alt (altitude_min, altitude_max) ON true
left join gn_commons.t_modules tm on tm.id_module = tsc.id_module 
where tm.module_label ilike 'ChronOrthopteres'
);
