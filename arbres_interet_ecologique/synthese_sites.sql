DROP VIEW IF EXISTS gn_monitoring.v_synthese_sites_arbres  ;


CREATE OR REPLACE VIEW gn_monitoring.v_synthese_sites_arbres   AS 
WITH source AS (
         SELECT t_sources.id_source 
           FROM gn_synthese.t_sources
          WHERE t_sources.name_source::text = concat('MONITORING_', upper('arbres_interet_ecologique'::text))
         LIMIT 1
        ) ,
dataset AS (
 SELECT id_dataset
   FROM gn_meta.t_datasets
  WHERE dataset_shortname::text = 'AIE'
 LIMIT 1
) ,selected_type_site AS (
	SELECT   cst.id_base_site , string_agg(DISTINCT tn.label_default, ', ') AS type
	FROM gn_monitoring.bib_type_site ts 
	JOIN ref_nomenclatures.t_nomenclatures tn 
	ON tn.id_nomenclature = ts.id_nomenclature_type_site
	JOIN gn_monitoring.cor_site_type cst 
	ON cst.id_type_site = ts.id_nomenclature_type_site 
	WHERE cd_nomenclature IN ( 
	  'ARBRES_AIE',
	  'ARBRES_LOGES',
	  'ARBRES_CHIRO' 
	  )
	  GROUP BY  cst.id_base_site
)
 SELECT s.uuid_base_site AS unique_id_sinp, 
    source.id_source,
    s.id_base_site AS entity_source_pk_value,
    (SELECT id_dataset FROM dataset) AS id_dataset,
    ref_nomenclatures.get_id_nomenclature('NAT_OBJ_GEO'::character varying, 'St'::character varying) AS id_nomenclature_geo_object_nature,
    ref_nomenclatures.get_id_nomenclature('TYP_GRP'::character varying, 'REL'::character varying) AS id_nomenclature_grp_typ, 
    ref_nomenclatures.get_id_nomenclature('OBJ_DENBR'::character varying, 'IND'::character varying) AS id_nomenclature_obj_count,
    ref_nomenclatures.get_id_nomenclature('TYP_DENBR'::character varying, 'Es'::character varying) AS id_nomenclature_type_count,
    ref_nomenclatures.get_id_nomenclature('STATUT_OBS'::character varying, 'Pr'::character varying) AS id_nomenclature_observation_status,
    ref_nomenclatures.get_id_nomenclature('STATUT_SOURCE'::character varying, 'Te'::character varying) AS id_nomenclature_source_status,
    ref_nomenclatures.get_id_nomenclature('TYP_INF_GEO'::character varying, '1'::character varying) AS id_nomenclature_info_geo_type,
    ref_nomenclatures.get_id_nomenclature('STADE_VIE'::character varying, '1'::character varying) AS id_nomenclature_life_stage,
    1 AS count_min,
    1 AS count_max,
    t.cd_nom,
    t.nom_complet AS nom_cite,
    s.altitude_min,
    s.altitude_max,
    s.geom AS the_geom_4326,
    st_centroid(s.geom) AS the_geom_point,
    s.geom_local AS the_geom_local,
    s.first_use_date AS date_min,
    s.first_use_date AS date_max,
    concat(UPPER(tr.nom_role), ' ', tr.prenom_role) AS  observers,
    s.id_digitiser, 
    s.base_site_description AS comment_description,
    tr.id_role AS ids_observers,
    s.base_site_name AS place_name,
	jsonb_build_object(
		'type_site' , st.type
	)as additional_data,
    s.id_base_site
FROM gn_monitoring.t_base_sites s
JOIN selected_type_site st ON st.id_base_site = s.id_base_site
JOIN utilisateurs.t_roles tr ON tr.id_role = s.id_inventor 
JOIN gn_monitoring.t_site_complements sc ON sc.id_base_site = s.id_base_site
JOIN taxonomie.taxref t ON t.cd_nom = (sc.DATA->>'cd_nom_essence')::int
JOIN source ON true ;
 


    
CREATE OR REPLACE FUNCTION gn_monitoring.fct_trg_sync_synthese_sites()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
BEGIN
    PERFORM gn_synthese.import_json_row((SELECT row_to_json(c)::jsonb d
    FROM gn_monitoring.v_synthese_sites_arbres c
    WHERE id_base_site = NEW.id_base_site)); 
    RETURN NEW;
END;
$function$
; 

 

ALTER FUNCTION gn_monitoring.fct_trg_sync_synthese_sites() OWNER TO geonatadmin;

CREATE TRIGGER trg_sync_synthese_sites AFTER
INSERT
    OR
UPDATE ON
    gn_monitoring.t_base_sites FOR EACH ROW EXECUTE FUNCTION gn_monitoring.fct_trg_sync_synthese_sites()
    
    
    
CREATE OR REPLACE FUNCTION gn_synthese.fct_trg_delete_synthese_sites()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
        BEGIN
            --Suppression des données dans la synthèse
            DELETE FROM gn_synthese.synthese WHERE unique_id_sinp = OLD.uuid_base_site;
            RETURN OLD;
        END;
        $function$
;

-- Permissions

ALTER FUNCTION gn_synthese.fct_trg_delete_synthese_sites() OWNER TO geonatadmin;
GRANT ALL ON FUNCTION gn_synthese.fct_trg_delete_synthese_sites() TO geonatadmin;


CREATE TRIGGER trg_delete_synthese_sites AFTER
DELETE
    ON
    gn_monitoring.t_base_sites FOR EACH ROW EXECUTE FUNCTION gn_synthese.fct_trg_delete_synthese_sites();
    