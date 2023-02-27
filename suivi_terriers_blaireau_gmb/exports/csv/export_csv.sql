------------------------------------------------- export loutre local ------------------------------------------
-- View: gn_monitoring.v_export_suiviblaireau_telecharger_csv


DROP VIEW  IF EXISTS  gn_monitoring.v_export_suiviblaireau_telecharger_csv;

CREATE OR REPLACE VIEW gn_monitoring.v_export_suiviblaireau_telecharger_csv 
 AS


WITH 

observers_monit AS (
	SELECT visite.id_base_visit as id_base_visit,
		STRING_AGG(roles.nom_role || ' ' || roles.prenom_role, ', ' ORDER BY roles.nom_role, roles.prenom_role)  AS observateurs

	FROM gn_monitoring.t_base_visits visite
		JOIN gn_monitoring.cor_visit_observer visiteobser ON visiteobser.id_base_visit = visite.id_base_visit
		LEFT JOIN utilisateurs.t_roles roles ON roles.id_role = visiteobser.id_role
	GROUP BY visite.id_base_visit
),	

/*cor_deter_obsvation as (	
	SELECT obscompl.id_observation as id_observation,
	    --(obscompl.data -> 'determinateur')::json as deterjson,
		json_array_elements( (obscompl.data -> 'determinateur')::json ) as id_role
		from gn_monitoring.t_observation_complements obscompl
		order by id_observation
),
determinateurs_monit AS (
    SELECT cor_deter_obsvation.id_observation,
		STRING_AGG(roles.nom_role || ' ' || roles.prenom_role, ', ' ORDER BY roles.nom_role, roles.prenom_role)  AS determinateurs

	FROM cor_deter_obsvation
		LEFT JOIN utilisateurs.t_roles roles ON roles.id_role::text = cor_deter_obsvation.id_role::text
	GROUP BY cor_deter_obsvation.id_observation
),*/

data_monitoring AS (

	SELECT
		visite.id_base_visit as id_base_visit,
		obs.id_observation as id_observation,
		jdd.dataset_name as nom_jdd,
		jdd.id_dataset as id_dataset,
		jdd.dataset_shortname as nom_court_jdd,
		grpsite.sites_group_code as code_gpe_blai,
		grpsite.sites_group_name as nom_gpe_blai,
		grpsite."comments" as comment_gpe_blai,
		site.base_site_code as code_blai,
		site.base_site_name as nom_blai,
		ST_AsText(st_transform(site.geom,2154)) as geometrie,
		st_x(ST_Centroid(st_transform(site.geom,2154))) as x_l93,
		st_y(ST_Centroid(st_transform(site.geom,2154))) as y_l93,
		case
			when sitecompl.data ->> 'comments'::text = 'null' then null
			else sitecompl.data ->> 'comments'::text 
		end as comment_blai,
		case
			when sitecompl.data ->> 'env_site'::text = 'null' then null
			else sitecompl.data ->> 'env_site'::text 
		end as env_site,
		visite.uuid_base_visit as uuid_visite,
		visite.visit_date_min as date_visite,
		case
			when visitecompl.data -> 'id_nomenclature_tech_collect_campanule'::text = 'null' then null
			else visitecompl.data -> 'id_nomenclature_tech_collect_campanule'::text 
		end as techn_collecte_campanule,

		case
			when visitecompl.data ->> 'nb_gueule_tot'::text = 'null' then null
			else visitecompl.data ->> 'nb_gueule_tot'::text 
		end as nb_gueule_tot,
		case
			when visitecompl.data ->> 'nb_gueule_act'::text = 'null' then null
			else visitecompl.data ->> 'nb_gueule_act'::text 
		end as nb_gueule_act,

		visite."comments" as remarques_visite,
		obs.uuid_observation as uuid_observation,
		obs.cd_nom as cd_nom,
		tx.cd_ref as cd_ref,
		tx.nom_vern as nom_vern_taxon,
		tx.nom_complet as nom_taxon,
		tx.lb_nom as nom_complet_taxon,
		case 
			when obscompl.data -> 'technique_observation'::text = 'null' then null
			else obscompl.data -> 'technique_observation'::text
		end AS technique_observation,
		case
			when obscompl.data -> 'etat_biologique'::text = 'null' then null
			else obscompl.data -> 'etat_biologique'::text
		end as etat_biologique,
		case
			when obscompl.data -> 'statut_observation'::text = 'null' then null
			else obscompl.data -> 'statut_observation'::text
		end as statut_observation,
		/*case
			when obscompl.data -> 'statut_source'::text = 'null' then null
			else obscompl.data -> 'statut_source'::text
		end as statut_source,*/
		case 
			when obscompl.data -> 'methode_deter'::text = 'null' then null
			else obscompl.data -> 'methode_deter'::text
		end AS methode_deter,
		case
			when obscompl.data -> 'stade_de_vie'::text = 'null' then null
			else obscompl.data -> 'stade_de_vie'::text
		end as stade_de_vie,
		case 
			when obscompl.data ->> 'nombre_individus'::text = 'null' then null
			else obscompl.data ->> 'nombre_individus'::text
		end AS nombre_individus,
		case
			when obscompl.data -> 'sexe'::text = 'null' then null
			else obscompl.data -> 'sexe'::text
		end as sexe,
		obs."comments" as commentaire_observation


	FROM gn_monitoring.t_sites_groups grpsite
		JOIN gn_monitoring.t_site_complements sitecompl ON grpsite.id_sites_group = sitecompl.id_sites_group
		JOIN gn_monitoring.t_base_sites site ON sitecompl.id_base_site = site.id_base_site
		JOIN gn_monitoring.t_base_visits visite ON visite.id_base_site = site.id_base_site
		JOIN gn_meta.t_datasets jdd ON jdd.id_dataset = visite.id_dataset
		JOIN gn_monitoring.t_visit_complements visitecompl ON visitecompl.id_base_visit = visite.id_base_visit
		JOIN gn_monitoring.t_observations obs ON obs.id_base_visit = visite.id_base_visit
		JOIN taxonomie.taxref tx ON obs.cd_nom = tx.cd_nom
		JOIN gn_monitoring.t_observation_complements obscompl ON obscompl.id_observation = obs.id_observation

	WHERE grpsite.id_module = gn_commons.get_id_module_bycode('suiviblaireau'::text)

),


cor_indiceblai_visite as (	
	SELECT visitecompl.id_base_visit as id_base_visit,
	    visitecompl."data",
	    --(visitecompl.data -> 'indices_blai')::json as deterjson
		--json_array_elements( (visitecompl.data -> 'indices_blai')::json )::text as id_indices_blai,
		(ref_nomenclatures.get_nomenclature_label((json_array_elements( (visitecompl.data -> 'indices_blai')::json )::text)::int, 'fr'))::text as indices_blai
	FROM gn_monitoring.t_visit_complements visitecompl		
	WHERE (visitecompl.data -> 'indices_blai')::text != 'null'
	ORDER BY id_base_visit
),
visite_indice_blai AS (
	SELECT cor_indiceblai_visite.id_base_visit,
		STRING_AGG(indices_blai, ', ' ORDER BY indices_blai)  AS indices_blai
	FROM cor_indiceblai_visite	
	GROUP BY cor_indiceblai_visite.id_base_visit
),


cor_perturb_visite as (	
	SELECT visitecompl.id_base_visit as id_base_visit,
	    visitecompl."data",
	    --(visitecompl.data -> 'perturb')::json as deterjson
		--json_array_elements( (visitecompl.data -> 'perturb')::json )::text as perturb,
		(ref_nomenclatures.get_nomenclature_label((json_array_elements( (visitecompl.data -> 'perturb')::json )::text)::int, 'fr'))::text as perturb
	FROM gn_monitoring.t_visit_complements visitecompl		
	WHERE (visitecompl.data -> 'perturb')::text != 'null'
	ORDER BY id_base_visit
),
visite_perturb AS (
	SELECT cor_perturb_visite.id_base_visit,
		STRING_AGG(perturb, ', ' ORDER BY perturb)  AS perturb
	FROM cor_perturb_visite	
	GROUP BY cor_perturb_visite.id_base_visit
),

cor_depredation_visite as (	
	SELECT visitecompl.id_base_visit as id_base_visit,
	    visitecompl."data",
	    --(visitecompl.data -> 'depredation')::json as deterjson
		--json_array_elements( (visitecompl.data -> 'depredation')::json )::text as depredation,
		(ref_nomenclatures.get_nomenclature_label((json_array_elements( (visitecompl.data -> 'depredation')::json )::text)::int, 'fr'))::text as depredation
	FROM gn_monitoring.t_visit_complements visitecompl		
	WHERE (visitecompl.data -> 'depredation')::text != 'null'
	ORDER BY id_base_visit
),
visite_depredation AS (
	SELECT cor_depredation_visite.id_base_visit,
		STRING_AGG(depredation, ', ' ORDER BY depredation) AS depredation
	FROM cor_depredation_visite	
	GROUP BY cor_depredation_visite.id_base_visit
)



SELECT
datamonit.id_dataset,
datamonit.nom_jdd,
datamonit.nom_court_jdd,
datamonit.code_gpe_blai,
datamonit.nom_gpe_blai,
datamonit.comment_gpe_blai,
datamonit.code_blai,
datamonit.nom_blai,
datamonit.geometrie,
datamonit.x_l93,
datamonit.y_l93,
datamonit.comment_blai,
datamonit.env_site,
datamonit.uuid_visite,
datamonit.date_visite,
observers_monit.observateurs,
(ref_nomenclatures.get_nomenclature_label(datamonit.techn_collecte_campanule::int, 'fr'))::text as techn_collecte_campanule, 
visite_indice_blai.indices_blai as indices_blai, 
datamonit.nb_gueule_tot::int,
datamonit.nb_gueule_act::int,
visite_perturb.perturb as perturb, 
visite_depredation.depredation as depredation, 
datamonit.remarques_visite,
datamonit.uuid_observation,
datamonit.cd_nom,
datamonit.cd_ref,
datamonit.nom_vern_taxon,
datamonit.nom_taxon,
datamonit.nom_complet_taxon,
(ref_nomenclatures.get_nomenclature_label(datamonit.technique_observation::int, 'fr'))::text as technique_observation,
(ref_nomenclatures.get_nomenclature_label(datamonit.etat_biologique::int, 'fr'))::text as etat_biologique,
(ref_nomenclatures.get_nomenclature_label(datamonit.statut_observation::int, 'fr'))::text as statut_observation,
--(ref_nomenclatures.get_nomenclature_label(datamonit.statut_source::int, 'fr'))::text as statut_source,
--determinateurs_monit.determinateurs,
(ref_nomenclatures.get_nomenclature_label(datamonit.methode_deter::int, 'fr'))::text as methode_deter,
(ref_nomenclatures.get_nomenclature_label(datamonit.stade_de_vie::int, 'fr'))::text as stade_de_vie,
datamonit.nombre_individus::int,
(ref_nomenclatures.get_nomenclature_label(datamonit.sexe::int, 'fr'))::text as sexe,
datamonit.commentaire_observation

FROM data_monitoring datamonit 
JOIN observers_monit using(id_base_visit)
left JOIN visite_indice_blai using(id_base_visit)
left JOIN visite_perturb using(id_base_visit)
left JOIN visite_depredation using(id_base_visit)
--left JOIN determinateurs_monit using(id_observation);




