
CREATE OR REPLACE VIEW gn_monitoring.v_synthese_osmodermes
AS WITH indices AS (
	 SELECT vc.id_base_visit , string_agg(tn.cd_nomenclature , '-') AS label_indices
	 FROM  gn_monitoring.t_visit_complements vc
	 JOIN LATERAL (
		SELECT (jsonb_array_elements_text(data->'id_nomenclature_indices'))::int AS idx
		WHERE data ? 'id_nomenclature_indices'
	) AS x ON TRUE
	JOIN ref_nomenclatures.t_nomenclatures tn 
	ON tn.id_nomenclature = x.idx AND NOT tn.cd_nomenclature IN ('Aucun', 'Ind')
	GROUP BY  vc.id_base_visit 
)
,  source AS (
         SELECT t_sources.id_source
           FROM gn_synthese.t_sources
          WHERE t_sources.name_source::text = concat('MONITORING_', upper('osmodermes'::text))
         LIMIT 1
        ), observers AS (
         SELECT array_agg(r.id_role) AS ids_observers,
            string_agg(concat(r.nom_role, ' ', r.prenom_role), ' ; '::text) AS observers,
            cvo.id_base_visit
           FROM gn_monitoring.cor_visit_observer cvo
             JOIN utilisateurs.t_roles r ON r.id_role = cvo.id_role
          GROUP BY cvo.id_base_visit
        )
 SELECT v.uuid_base_visit AS unique_id_sinp,
    v.uuid_base_visit AS unique_id_sinp_grp,
    source.id_source,
    v.id_base_visit AS entity_source_pk_value,
    v.id_dataset,
    ref_nomenclatures.get_id_nomenclature('NAT_OBJ_GEO'::character varying, 'St'::character varying) AS id_nomenclature_geo_object_nature,
    ref_nomenclatures.get_id_nomenclature('TYP_GRP'::character varying, 'REL'::character varying) AS id_nomenclature_grp_typ,
    ref_nomenclatures.get_id_nomenclature('OBJ_DENBR'::character varying, 'IND'::character varying) AS id_nomenclature_obj_count,
    ref_nomenclatures.get_id_nomenclature('TYP_DENBR'::character varying, 'Es'::character varying) AS id_nomenclature_type_count,
    ref_nomenclatures.get_id_nomenclature('STATUT_OBS'::character varying, 'Pr'::character varying) AS id_nomenclature_observation_status,
    ref_nomenclatures.get_id_nomenclature('STATUT_SOURCE'::character varying, 'Te'::character varying) AS id_nomenclature_source_status,
    ref_nomenclatures.get_id_nomenclature('METH_OBS'::character varying, '0'::character varying) AS id_nomenclature_obs_technique,
    ref_nomenclatures.get_id_nomenclature('METH_DETERMIN'::character varying, '17'::character varying) AS id_nomenclature_determination_method,
    1 AS count_min,
    1 AS count_max,
    t.cd_nom,
    t.nom_complet AS nom_cite,
    s.altitude_min,
    s.altitude_max,
    s.geom AS the_geom_4326,
    st_centroid(s.geom) AS the_geom_point,
    s.geom_local AS the_geom_local,
    v.visit_date_min AS date_min,
    COALESCE(v.visit_date_max, v.visit_date_min) AS date_max,
    obs.observers,
    v.id_digitiser,
    v.id_module,
    v.comments AS comment_description,
    obs.ids_observers,
    s.base_site_name AS place_name,
    v.id_base_site,
    v.id_base_visit, 
       json_build_object(
        'indices', i.label_indices, 
		'arbre_vitalité', tn_vi.mnemonique , 
		'arbre_cavite', tn_ca.mnemonique ,
		'prospection',  tn_pr.mnemonique,
		'circonférence', (vc."data" ->>'circ'),
	    'diamètre',(vc."data" ->>'diam')
        ) as additional_data        
   FROM gn_monitoring.t_base_visits v
   JOIN indices i ON v.id_base_visit = i.id_base_visit
     LEFT JOIN gn_monitoring.t_base_sites s ON s.id_base_site = v.id_base_site
     JOIN gn_commons.t_modules m ON m.id_module = v.id_module
     JOIN gn_monitoring.t_visit_complements vc ON vc.id_base_visit = v.id_base_visit
     JOIN taxonomie.taxref t ON t.cd_nom = 10979
     LEFT JOIN observers obs ON obs.id_base_visit = v.id_base_visit
     JOIN source ON TRUE 
LEFT JOIN ref_nomenclatures.t_nomenclatures tn_pr ON (vc."data" ->> 'id_nomenclature_prospection')::int = tn_pr.id_nomenclature 
LEFT JOIN ref_nomenclatures.t_nomenclatures tn_vi ON (vc."data" ->> 'id_nomenclature_vital')::int = tn_vi.id_nomenclature  
LEFT JOIN ref_nomenclatures.t_nomenclatures tn_ca ON (vc."data" ->> 'id_nomenclature_cavite')::int = tn_ca.id_nomenclature  
  WHERE m.module_code::text = 'osmodermes'::text ;
 