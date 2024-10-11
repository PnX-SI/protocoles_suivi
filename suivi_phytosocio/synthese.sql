
-- Vue générique pour alimenter la synthèse dans le cadre d'un protocole site-visite-observation
-- 
-- Ce fichier peut être copié dans le dossier du sous-module et renommé en synthese.sql (et au besoin personnalisé)
-- le fichier sera joué à l'installation avec la valeur de module_code qui sera attribué automatiquement
--
--
-- Personalisations possibles
--
--  - ajouter des champs specifiques qui peuvent alimenter la synthese
--      jointure avec les table de complement
--
--  - choisir les valeurs de champs de nomenclatures qui seront propres au modules


-- ce fichier contient une variable :module_code (ou :'module_code')
-- utiliser psql avec l'option -v module_code=<module_code

-- ne pas remplacer cette variable, elle est indispensable pour les scripts d'installations
-- le module pouvant être installé avec un code différent de l'original

DROP VIEW IF EXISTS gn_monitoring.v_synthese_:module_code;
CREATE VIEW gn_monitoring.v_synthese_:module_code AS

WITH source AS (

	SELECT

        id_source

    FROM gn_synthese.t_sources
	WHERE name_source = CONCAT('MONITORING_', UPPER(:'module_code'))
	LIMIT 1

), sites AS (

    SELECT

        id_base_site,
        geom AS the_geom_4326,
	    ST_CENTROID(geom) AS the_geom_point,
	    geom_local as geom_local ,
		id_nomenclature_type_site,
		sg.sites_group_name,
		sg.sites_group_description,
		base_site_name,
		base_site_description

        FROM gn_monitoring.t_base_sites
		JOIN gn_monitoring.t_site_complements sc USING (id_base_site)
		LEFT JOIN gn_monitoring.t_sites_groups sg USING (id_sites_group)

), visits AS (
    
    SELECT
    
        id_base_visit,
        uuid_base_visit,
        id_module,
        id_base_site,
        id_dataset,
        id_digitiser,
		jsonb_set(
			vc."data",array['physio_veg'],
			to_jsonb(
				ref_nomenclatures.get_nomenclature_label(("data"::json#>>'{id_nomenclature_physio_veg}')::int)
			)
		)  - '{surf_releve_c,surf_releve_q,id_nomenclature_physio_veg}'::text[] AS "data",

        visit_date_min AS date_min,
	    COALESCE (visit_date_max, visit_date_min) AS date_max,
        comments,

	    --o.observers,
	    --o.ids_observers,

    	id_nomenclature_tech_collect_campanule,
	    id_nomenclature_grp_typ

        FROM gn_monitoring.t_base_visits
		JOIN gn_monitoring.t_visit_complements vc USING (id_base_visit)

), observers AS (
    SELECT
        array_agg(r.id_role) AS ids_observers,
        STRING_AGG(CONCAT(r.nom_role, ' ', prenom_role), ' ; ') AS observers,
        id_base_visit
    FROM gn_monitoring.cor_visit_observer cvo
    JOIN utilisateurs.t_roles r
    ON r.id_role = cvo.id_role
    GROUP BY id_base_visit
)

SELECT
		
        o.uuid_observation AS unique_id_sinp, 
		v.uuid_base_visit AS unique_id_sinp_grp,
		source.id_source,
		o.id_observation AS entity_source_pk_value,
		v.id_dataset,
		s.id_nomenclature_type_site,
        ref_nomenclatures.get_id_nomenclature('NAT_OBJ_GEO', 'St') AS id_nomenclature_geo_object_nature,
		--id_nomenclature_obs_technique, -- METH_OBS
		--id_nomenclature_bio_status, -- STATUT_BIO
		--id_nomenclature_bio_condition, -- ETA_BIO
		--id_nomenclature_naturalness, -- NATURALITE
		--id_nomenclature_exist_proof, -- PREUVE_EXIST
		--id_nomenclature_valid_status,  --STATUT_VALID
		--id_nomenclature_diffusion_level, -- NIV_PRECIS
		--oc.id_nomenclature_life_stage, -- STADE_VIE
		--oc.id_nomenclature_sex, -- SEXE
 		-- id_nomenclature_sensitivity, --SENSIBILITE
		-- id_nomenclature_blurring, -- DEE_FLOU
        -- id_nomenclature_behaviour, -- OCC_COMPORTEMENT
 		ref_nomenclatures.get_id_nomenclature('OBJ_DENBR','SURF') AS id_nomenclature_obj_count,
 		ref_nomenclatures.get_id_nomenclature('TYP_DENBR','Es') AS id_nomenclature_type_count,
		ref_nomenclatures.get_id_nomenclature('STATUT_SOURCE', 'Te') AS id_nomenclature_source_status,
		ref_nomenclatures.get_id_nomenclature('TYP_INF_GEO', '1') AS id_nomenclature_info_geo_type,
		ref_nomenclatures.get_id_nomenclature('TYP_GRP', 'REL') as id_nomenclature_grp_typ, 
    	ref_nomenclatures.get_id_nomenclature('NIV_PRECIS', '4') as id_nomenclature_diffusion_level, -- pas de diffusion pour l'instant (en attente des règles),
 		CASE WHEN (oc."data"::json#>>'{present}')::text = 'Oui'
			THEN ref_nomenclatures.get_id_nomenclature('STATUT_OBS', 'Pr') 
			ELSE ref_nomenclatures.get_id_nomenclature('STATUT_OBS', 'No')
		END AS id_nomenclature_observation_status, 
		CASE WHEN (oc."data"::json#>>'{nb_pieds}')::int IS NULL
			THEN 0
			ELSE (oc."data"::json#>>'{nb_pieds}')::int
		END AS count_min,
		CASE WHEN (oc."data"::json#>>'{nb_pieds}')::int IS NULL
			THEN 0
			ELSE (oc."data"::json#>>'{nb_pieds}')::int
		END AS count_max,
		id_observation,
		t.cd_nom,
		t.nom_complet AS nom_cite,
		--meta_v_taxref
		--sample_number_proof
		--digital_proofvue
		alt.altitude_min,
		alt.altitude_max,
		s.the_geom_4326,
		s.the_geom_point,
		s.geom_local,
		v.date_min,
		v.date_max,
		--validator
		--validation_comment
		obs.observers,
		--determiner
		v.id_digitiser,
		--id_nomenclature_determination_method
		--meta_validation_date
		--meta_create_date,
		--meta_update_date,
		--last_action
		v.id_module,
		v.comments AS comment_context,
		o.comments AS comment_description,
		obs.ids_observers,
		-- ## Colonnes complémentaires qui ont leur utilité dans la fonction synthese.import_row_from_table
		v.id_base_site,
		v.id_base_visit,
		v."data" || jsonb_build_object(
			'strate_flore',ref_nomenclatures.get_nomenclature_label((oc."data"::json#>>'{id_nomenclature_strate_flore}')::int),
			'stade_pheno',ref_nomenclatures.get_nomenclature_label((oc."data"::json#>>'{id_nomenclature_stade_pheno}')::int),
			'effectif_textuel',ref_nomenclatures.get_nomenclature_label((oc."data"::json#>>'{id_nomenclature_braunblanq_abdom}')::int)
		) || oc."data" - '{nb_pieds,present,id_nomenclature_strate_flore,id_nomenclature_stade_pheno,id_nomenclature_braunblanq_abdom}'::text[] AS additional_data

    FROM gn_monitoring.t_observations o 
	JOIN gn_monitoring.t_observation_complements oc USING (id_observation)
	--JOIN ref_nomenclatures.t_nomenclatures n_stade ON n_stade.id_nomenclature = (oc.data->>'id_nomenclature_stade')::int 
    JOIN visits v
        ON v.id_base_visit = o.id_base_visit
    JOIN sites s 
        ON s.id_base_site = v.id_base_site
	JOIN gn_commons.t_modules m 
        ON m.id_module = v.id_module
	JOIN taxonomie.taxref t 
        ON t.cd_nom = o.cd_nom
	JOIN source 
        ON TRUE
	JOIN observers obs ON obs.id_base_visit = v.id_base_visit
    
 	LEFT JOIN LATERAL ref_geo.fct_get_altitude_intersection(s.geom_local) alt (altitude_min, altitude_max)
        ON TRUE
    WHERE m.module_code = :'module_code'
    ;
