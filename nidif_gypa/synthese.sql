delete from gn_synthese.synthese ;

delete from gn_monitoring.t_base_visits ;


select concat(
'{"la":"li"}'::json,
'{"lo":"lu"}'::json
);

select  '{"la":"li"}'::jsonb ||'{"lo":"lu"}'::jsonb;







-- gn_monitoring.v_synthese_nidif_gypa source
  WHERE m.module_code::text = 'nidif_gypa'::text;

 
 select * from gn_monitoring.comportement_mapping cm;
 

update gn_monitoring.t_observation_complements o
set data = o."data" ||jsonb_build_object(
	'comportement', 
	case 
		when o."data"->>'id_nomenclature_behaviour'= '558' then null
		when o."data"->>'id_nomenclature_behaviour'= '559' then null 
		when o."data"->>'id_nomenclature_behaviour'= '566' then null --chasse alim
		when o."data"->>'id_nomenclature_behaviour'= '568' then '["Passage en vol"]' 
		when o."data"->>'id_nomenclature_behaviour'= '571' then null --esivage 
		when o."data"->>'id_nomenclature_behaviour'= '573' then null '["Posé"]'
		when o."data"->>'id_nomenclature_behaviour'= '577' then null '["Accouplement"]'
		when o."data"->>'id_nomenclature_behaviour'= '579' then '["Tandem"]' 
		when o."data"->>'id_nomenclature_behaviour'= '580' then '["Territorial"]',
	end
	) 
from gn_monitoring.t_base_visits v
join gn_monitoring.t_observations t using(id_base_visit)
where v.id_module = 9 and t.id_observation  = o.id_observation ;



update gn_monitoring.t_observation_complements o
set data = o."data" ||jsonb_build_object(
	'comportement', 
	case 
		when o."data"->>'id_nomenclature_behaviour'= '563' then jsonb_build_array('Accouplement', 'Posé')
		when o."data"->>'id_nomenclature_behaviour'= '559' then null 
		when o."data"->>'id_nomenclature_behaviour'= '566' then null --chasse alim
		when o."data"->>'id_nomenclature_behaviour'= '568' then  jsonb_build_array('Passage en vol') 
		when o."data"->>'id_nomenclature_behaviour'= '571' then null --esivage 
		when o."data"->>'id_nomenclature_behaviour'= '573' then jsonb_build_array('Posé')
		when o."data"->>'id_nomenclature_behaviour'= '577' then jsonb_build_array('Accouplement')
		when o."data"->>'id_nomenclature_behaviour'= '579' then jsonb_build_array('Tandem')
		when o."data"->>'id_nomenclature_behaviour'= '580' then jsonb_build_array('Territorial')

	end
	) 
from gn_monitoring.t_base_visits v
join gn_monitoring.t_observations t using(id_base_visit)
where v.id_module = 55 and t.id_observation  = o.id_observation;


select * from gn_commons.t_modules tm ;


select distinct "data"->>'comportement'
from gn_monitoring.t_observation_complements;


select distinct toc."data"->>'id_nomenclature_behaviour' from gn_monitoring.t_observation_complements toc where toc."data"->>'id_nomenclature_behaviour' is not null
order by toc."data"->>'id_nomenclature_behaviour'
;

SELECT COUNT(*) 
FROM gn_monitoring.v_synthese_nidif_gypa WHERE id_base_visit::varchar = '8';

select * from gn_commons.t_modules tm ;


-- gn_monitoring.comportement_mapping definition

-- Drop table

DROP TABLE gn_monitoring.comportement_mapping;

CREATE TABLE gn_monitoring.comportement_mapping (
	ordre int4 NOT NULL,
	val varchar(50) NULL,
	cd_nomenclature varchar(10) NULL,
	CONSTRAINT comportement_mapping_pkey PRIMARY KEY (ordre)
);



INSERT INTO gn_monitoring.comportement_mapping (ordre,val,cd_nomenclature) VALUES
	 (6,'Accouplement','19'),
	 (1,'Jeune envolé',NULL),
	 (12,'Aire vide',NULL),
	 (2,'Nourrissage des jeunes','14'),
	 (3,'Jeune au nid',NULL),
	 (8,'Recharge de l''aire',NULL),
	 (5,'Relève à l''aire',NULL),
	 (10,'Passage en vol','10'),
	 (9,'Tandem','21'),
	 (7,'Territorial','22');
INSERT INTO gn_monitoring.comportement_mapping (ordre,val,cd_nomenclature) VALUES
	 (11,'Posé','15'),
	 (4,'Couvaison','');

 drop view gn_monitoring.v_synthese_nidif_gypa;


CREATE OR REPLACE VIEW gn_monitoring.v_synthese_nidif_gypa
AS WITH source AS (
         SELECT t_sources.id_source
           FROM gn_synthese.t_sources
          WHERE t_sources.name_source::text = 'MONITORING_NIDIF_GYPA'::text
         LIMIT 1
        ), observers AS (
         SELECT string_agg(concat(r.nom_role, ' ', r.prenom_role), ' ; '::text) AS observers,
            array_agg(r.id_role) AS ids_observers,
            v_1.id_base_visit
           FROM gn_monitoring.t_visit_complements v_1
             JOIN gn_monitoring.cor_visit_observer cvo ON cvo.id_base_visit = v_1.id_base_visit
             JOIN utilisateurs.t_roles r ON r.id_role = cvo.id_role
          GROUP BY v_1.id_base_visit, cvo.id_role
        ), unnest_comp AS (
         SELECT jsonb_array_elements_text((toc1.data ->> 'comportement'::text)::jsonb) AS v,
            toc1.id_observation
           FROM gn_monitoring.t_observation_complements toc1
        ), selected_comp AS (
         SELECT unnest_comp.id_observation,
            min(comp.ordre) AS ordre
           FROM unnest_comp
             JOIN gn_monitoring.comportement_mapping comp ON comp.val::text = unnest_comp.v
          GROUP BY unnest_comp.id_observation
        )
 SELECT to2.uuid_observation AS unique_id_sinp,
    to2.id_observation,
    v.uuid_base_visit AS unique_id_sinp_grp,
    source.id_source,
    v.id_base_visit AS entity_source_pk_value,
    v.id_dataset,
    ref_nomenclatures.get_id_nomenclature('NAT_OBJ_GEO'::character varying, 'In'::character varying) AS id_nomenclature_geo_object_nature,
    v.id_nomenclature_tech_collect_campanule,
    ref_nomenclatures.get_id_nomenclature('ETA_BIO'::character varying, '2'::character varying) AS id_nomenclature_bio_condition,
    ref_nomenclatures.get_id_nomenclature('STAT_BIOGEO'::character varying, '1'::character varying) AS id_nomenclature_biogeo_status,
    ref_nomenclatures.get_id_nomenclature('OBJ_DENBR'::character varying, 'IND'::character varying) AS id_nomenclature_obj_count,
    ref_nomenclatures.get_id_nomenclature('TYP_DENBR'::character varying, 'Co'::character varying) AS id_nomenclature_type_count,
    ref_nomenclatures.get_id_nomenclature('STATUT_SOURCE'::character varying, 'Te'::character varying) AS id_nomenclature_source_status,
    ref_nomenclatures.get_id_nomenclature('TYP_INF_GEO'::character varying, '1'::character varying) AS id_nomenclature_info_geo_type,
    ref_nomenclatures.get_id_nomenclature('NATURALITE'::character varying, '1'::character varying) AS id_nomenclature_naturalness,
    (toc.data ->> 'id_nomenclature_life_stage'::text)::integer AS id_nomenclature_life_stage,
    (toc.data ->> 'id_nomenclature_sex'::text)::integer AS id_nomenclature_sex,
    COALESCE(ref_nomenclatures.get_id_nomenclature('OCC_COMPORTEMENT'::character varying, cm.cd_nomenclature), ref_nomenclatures.get_id_nomenclature('OCC_COMPORTEMENT'::character varying, '1'::character varying)) AS id_nomenclature_behaviour,
    case 
    	when cm.val in ('Passage en vol', 'Posé', 'Aire vide') then ref_nomenclatures.get_id_nomenclature('STATUT_BIO', '1')
    	else ref_nomenclatures.get_id_nomenclature('STATUT_BIO', '3')
    end as id_nomenclature_bio_status,
    ref_nomenclatures.get_id_nomenclature('TYP_GRP'::character varying, 'REL'::character varying) AS id_nomenclature_grp_typ,
    t.cd_nom,
    t.nom_complet AS nom_cite,
    alt.altitude_min,
    alt.altitude_max,
    st_centroid(s.geom) AS the_geom_4326,
    st_centroid(s.geom) AS the_geom_point,
    st_centroid(s.geom_local) AS the_geom_local,
    v.visit_date_min AS date_min,
    COALESCE(v.visit_date_max, v.visit_date_min) AS date_max,
    obs.observers,
    v.id_digitiser,
    v.id_module,
    v.comments AS comment_description,
    obs.ids_observers,
    v.id_base_site,
    v.id_base_visit,
    (toc.data ->> 'count'::text) as count_min,
    (toc.data ->> 'count'::text) as count_max,
    coalesce(vc."data", '{}'::jsonb) || coalesce(toc."data", '{}'::jsonb ) AS additional_data
   FROM gn_monitoring.t_base_visits v
     JOIN gn_monitoring.t_base_sites s ON s.id_base_site = v.id_base_site
     JOIN gn_commons.t_modules m ON m.id_module = v.id_module
     JOIN gn_monitoring.t_visit_complements vc ON vc.id_base_visit = v.id_base_visit
     JOIN gn_monitoring.t_observations to2 ON to2.id_base_visit = vc.id_base_visit
     JOIN gn_monitoring.t_observation_complements toc ON toc.id_observation = to2.id_observation
     JOIN taxonomie.taxref t ON t.cd_nom = to2.cd_nom
     left JOIN selected_comp sel ON sel.id_observation = toc.id_observation
     LEFT JOIN gn_monitoring.comportement_mapping cm ON cm.ordre = sel.ordre
     LEFT JOIN observers obs ON obs.id_base_visit = v.id_base_visit
     JOIN source ON true
     LEFT JOIN LATERAL ref_geo.fct_get_altitude_intersection(s.geom_local) alt(altitude_min, altitude_max) ON true
     
     
     
     