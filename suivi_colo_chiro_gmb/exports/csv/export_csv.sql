------------------------------------------------- export loutre local ------------------------------------------
-- View: gn_monitoring.v_export_comptagechiros_telecharger_csv


DROP VIEW  IF EXISTS  gn_monitoring.v_export_comptagechiros_telecharger_csv;

CREATE OR REPLACE VIEW gn_monitoring.v_export_comptagechiros_telecharger_csv 
 AS



WITH 

observers_monit AS (
	SELECT visite.id_base_visit as id_base_visit,
		STRING_AGG(roles.nom_role || ' ' || roles.prenom_role, ', ' ORDER BY roles.nom_role, roles.prenom_role) AS observateurs
	FROM gn_monitoring.t_base_visits visite
		JOIN gn_monitoring.cor_visit_observer visiteobser ON visiteobser.id_base_visit = visite.id_base_visit
		LEFT JOIN utilisateurs.t_roles roles ON roles.id_role = visiteobser.id_role
	GROUP BY visite.id_base_visit
),

data_monitoring AS (
	
	SELECT
		visite.id_base_visit as id_base_visit,
		obs.id_observation as id_observation,
		jdd.dataset_name as nom_jdd,
		jdd.id_dataset as id_dataset,
		jdd.dataset_shortname as nom_court_jdd,

		--groupe de sites
		grpsite.sites_group_code as code_site,
		grpsite.sites_group_name as nom_site,
		grpsite.sites_group_description as description_site,
		case
			when grpsite.data ->> 'commune_site'::text = 'null' then null
			else grpsite.data ->> 'commune_site'::text 
		end as comm_site,
		case
			when grpsite.data ->> 'regroup_site'::text = 'null' then null
			else grpsite.data ->> 'regroup_site'::text 
		end as regrpmt_site,
		case
			when grpsite.data ->> 'resp_site'::text = 'null' then null
			else grpsite.data ->> 'resp_site'::text 
		end as resp_site,
		case
			when grpsite.data -> 'XL93_site'::text = 'null' then null
			else grpsite.data -> 'XL93_site'::text 
		end as x_l93_site,
		case
			when grpsite.data -> 'YL93_site'::text = 'null' then null
			else grpsite.data -> 'YL93_site'::text 
		end as y_l93_site,

		--site
     	site.base_site_code as code_ss_site,
		site.base_site_name as nom_ss_site,
		site.base_site_description as description_ss_site,
		case
			when sitecompl.data ->> 'commune_sous_site'::text = 'null' then null
			else sitecompl.data ->> 'commune_sous_site'::text 
		end as comm_ss_site,
		ST_AsText(st_transform(site.geom,2154)) as geometrie,
		st_x(ST_Centroid(st_transform(site.geom,2154))) as x_l93_ss_site,
		st_y(ST_Centroid(st_transform(site.geom,2154))) as y_l93_ss_site,
		case
			when sitecompl.data -> 'type_sous_site'::text = 'null' then null
			else sitecompl.data -> 'type_sous_site'::text 
		end as type_ss_site,
		case
			when sitecompl.data -> 'cat_sous_site'::text = 'null' then null
			else sitecompl.data -> 'cat_sous_site'::text 
		end as cat_ss_site,
		CONCAT(roles.nom_role || ' ' || roles.prenom_role) as descripteur_ss_site,

		--visite
		visite.uuid_base_visit as uuid_visite,
		visite.visit_date_min as date_visite,
		case
			when visitecompl.data -> 'temp'::text = 'null' then null
			else visitecompl.data -> 'temp'::text 
		end as temp_visite,
		case
			when visitecompl.data -> 'hygro'::text = 'null' then null
			else visitecompl.data -> 'hygro'::text 
		end as hygro_visite,
		case
			when visitecompl.data ->> 'perturbation'::text = 'null' then null
			else visitecompl.data ->> 'perturbation'::text 
		end as perturb_visite,
		case
			when visitecompl.data ->> 'presence_jeunes_juste_ne'::text = 'null' then null
			else visitecompl.data ->> 'presence_jeunes_juste_ne'::text 
		end as pres_jeunes_visite,
		case
			when visitecompl.data -> 'id_nomenclature_tech_collect_campanule'::text = 'null' then null
			else visitecompl.data -> 'id_nomenclature_tech_collect_campanule'::text 
		end as id_nomenclature_tech_collect_campanule,
		visite."comments" as remarques_visite,

   		--observation
		obs.uuid_observation as uuid_observation,
		obs.cd_nom as cd_nom,
		tx.cd_ref as cd_ref,
		tx.nom_vern as nom_vern_taxon,
		tx.nom_complet as nom_taxon,
		tx.lb_nom as nom_complet_taxon,
		case
			when obscompl.data -> 'methode_observation'::text = 'null' then null
			else obscompl.data -> 'methode_observation'::text
		end as methode_observ,
		case
			when obscompl.data -> 'methode_determination'::text = 'null' then null
			else obscompl.data -> 'methode_determination'::text
		end as methode_deter,
		case
			when obscompl.data ->> 'statut_biologique'::text = 'null' then null
			else obscompl.data ->> 'statut_biologique'::text
		end as statut_biologique,
		case
			when obscompl.data -> 'statut_observation'::text = 'null' then null
			else obscompl.data -> 'statut_observation'::text
		end as statut_observation,
		case 
			when obscompl.data ->> 'statut_source'::text = 'null' then null
			else obscompl.data ->> 'statut_source'::text
		end AS statut_source,
		case
			when obscompl.data -> 'etat_biologique'::text = 'null' then null
			else obscompl.data -> 'etat_biologique'::text
		end as etat_biologique,
		case 
			when obscompl.data ->> 'nombre_individus'::text = 'null' then null
			else obscompl.data ->> 'nombre_individus'::text
		end AS nombre,
		case 
			when obscompl.data ->> 'stade_de_vie'::text = 'null' then null
			else obscompl.data ->> 'stade_de_vie'::text
		end AS stade_de_vie,
		case 
			when obscompl.data ->> 'sexe'::text = 'null' then null
			else obscompl.data ->> 'sexe'::text
		end AS sexe,
		obs."comments" as commentaire_observation

	FROM gn_monitoring.t_sites_groups grpsite
		JOIN gn_monitoring.t_site_complements sitecompl ON grpsite.id_sites_group = sitecompl.id_sites_group
		JOIN gn_monitoring.t_base_sites site ON sitecompl.id_base_site = site.id_base_site
		JOIN utilisateurs.t_roles roles ON roles.id_role = site.id_inventor
		JOIN gn_monitoring.t_base_visits visite ON visite.id_base_site = site.id_base_site
		JOIN gn_meta.t_datasets jdd ON jdd.id_dataset = visite.id_dataset
		JOIN gn_monitoring.t_visit_complements visitecompl ON visitecompl.id_base_visit = visite.id_base_visit
		JOIN gn_monitoring.t_observations obs ON obs.id_base_visit = visite.id_base_visit
		JOIN taxonomie.taxref tx ON obs.cd_nom = tx.cd_nom
		JOIN gn_monitoring.t_observation_complements obscompl ON obscompl.id_observation = obs.id_observation

	WHERE grpsite.id_module = gn_commons.get_id_module_bycode('comptagechiros'::text)

),


--visit_type_perturb
cor_visit_type_perturb as (	
	SELECT visitecompl.id_base_visit as id_base_visit,
	    visitecompl."data",
		(ref_nomenclatures.get_nomenclature_label((json_array_elements( (visitecompl.data -> 'type_perturbation')::json )::text)::int, 'fr'))::text as type_perturbation
	FROM gn_monitoring.t_visit_complements visitecompl		
	WHERE (visitecompl.data -> 'type_perturbation')::text != 'null'
	ORDER BY id_base_visit
),
visit_type_perturb AS (
	SELECT cor_visit_type_perturb.id_base_visit,
		STRING_AGG(type_perturbation, ', ' ORDER BY type_perturbation)  AS type_perturbation
	FROM cor_visit_type_perturb	
	GROUP BY cor_visit_type_perturb.id_base_visit
)

SELECT
--jdd pour filtre des exports
datamonit.id_dataset,
datamonit.nom_jdd,
datamonit.nom_court_jdd,

--groupe de sites
datamonit.code_site, --code du site
datamonit.nom_site, --nom du site
datamonit.description_site, --description du site
datamonit.comm_site, --communes du site
datamonit.regrpmt_site, --regroupement du site
datamonit.resp_site, --responsbale du site
datamonit.x_l93_site, --x93 du site
datamonit.y_l93_site, --y93 du site

--site
datamonit.code_ss_site, --code du sous-site
datamonit.nom_ss_site, --nom du sous-site
datamonit.description_ss_site,  --description du sous-site
datamonit.comm_ss_site,  --comune du sous-site
datamonit.geometrie, --geometrie du sous-site
datamonit.x_l93_ss_site::int, --x du sous-site
datamonit.y_l93_ss_site::int, --y du sous-site
(ref_nomenclatures.get_nomenclature_label(datamonit.type_ss_site::int, 'fr'))::text as type_ss_site, --type du sous-site
(ref_nomenclatures.get_nomenclature_label(datamonit.cat_ss_site::int, 'fr'))::text as cat_ss_site, --categorie du sous-site
datamonit.descripteur_ss_site, --descripteur du sous-site

--visite
datamonit.uuid_visite, --uuid visite / releve
datamonit.date_visite, --date visite / releve
observers_monit.observateurs, --observateurs visite / releve
datamonit.temp_visite::int, --temperature visite / releve
datamonit.hygro_visite::int, --hygrometrie visite / releve
datamonit.perturb_visite, --perturbzation  visite / releve
visit_type_perturb.type_perturbation as type_perturbation_visite, --type de perturbation visite / releve => multiple
datamonit.pres_jeunes_visite, --presence jeune visite / releve
datamonit.remarques_visite, --remarque visite / releve

--observation
datamonit.uuid_observation, --uuid observation
datamonit.cd_nom, --cd_nom observation
datamonit.cd_ref, --cd_ref observation
datamonit.nom_vern_taxon, --espece observation
datamonit.nom_taxon, --espece observation
datamonit.nom_complet_taxon, --espece observation
(ref_nomenclatures.get_nomenclature_label(datamonit.methode_observ::int, 'fr'))::text as methode_observ,  --methode deter obs observation
(ref_nomenclatures.get_nomenclature_label(datamonit.etat_biologique::int, 'fr'))::text as etat_biologique, --etat biologique observation
(ref_nomenclatures.get_nomenclature_label(datamonit.methode_deter::int, 'fr'))::text as methode_deter,  --methode deter obs observation
datamonit.statut_biologique as statut_biologique,  --statut biologique observation
(ref_nomenclatures.get_nomenclature_label(datamonit.statut_observation::int, 'fr'))::text as statut_observation,  --statut obs observation
(ref_nomenclatures.get_nomenclature_label(datamonit.statut_source::int, 'fr'))::text as statut_source,  --statut source observation
datamonit.nombre::int, --nombre observation
(ref_nomenclatures.get_nomenclature_label(datamonit.stade_de_vie::int, 'fr'))::text as stade_de_vie,--statut source observation
(ref_nomenclatures.get_nomenclature_label(datamonit.sexe::int, 'fr'))::text as sexe,  --sece observation
datamonit.commentaire_observation --commentaire observation


FROM data_monitoring datamonit 
JOIN observers_monit using(id_base_visit)
left JOIN visit_type_perturb using(id_base_visit)





