------------------------------------------------- export peloterejection ------------------------------------------
-- View: gn_monitoring.v_export_peloterejection_telecharger_csv


DROP VIEW  IF EXISTS  gn_monitoring.v_export_peloterejection_telecharger_csv;

CREATE OR REPLACE VIEW gn_monitoring.v_export_peloterejection_telecharger_csv 
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


cor_deter_obsvation as (	
	SELECT visitcompl.id_base_visit as id_base_visit,
	    --(obscompl.data -> 'determinateur')::json as deterjson,
		json_array_elements( (visitcompl.data -> 'determinateur')::json ) as id_role
		from gn_monitoring.t_visit_complements visitcompl
),
determinateurs_monit AS (
    SELECT cor_deter_obsvation.id_base_visit,
		STRING_AGG(roles.nom_role || ' ' || roles.prenom_role, ', ' ORDER BY roles.nom_role, roles.prenom_role)  AS determinateurs

	FROM cor_deter_obsvation
		LEFT JOIN utilisateurs.t_roles roles ON roles.id_role::text = cor_deter_obsvation.id_role::text
	GROUP BY cor_deter_obsvation.id_base_visit
),


data_monitoring AS (
	
	SELECT
	    visite.id_base_visit as id_base_visit,
		obs.id_observation as id_observation,
		jdd.id_dataset as id_dataset,
		jdd.dataset_name as nom_jdd,
		jdd.dataset_shortname as nom_court_jdd,

		--site
     	site.base_site_code as code_site,
		site.base_site_name as nom_site,
		site.base_site_description as description_ss_site,
		case
			when sitecompl.data ->> 'commune_site'::text = 'null' then null
			else sitecompl.data ->> 'commune_site'::text 
		end as comm_site,
		ST_AsText(st_transform(site.geom,2154)) as geometrie,
		st_x(ST_Centroid(st_transform(site.geom,2154))) as x_l93_ss_site,
		st_y(ST_Centroid(st_transform(site.geom,2154))) as y_l93_ss_site,
		site.base_site_description as commentaire_site,

		--visite
		visite.uuid_base_visit as uuid_visite,
		visite.visit_date_min as date_collecte,
		visite.visit_date_max as date_analyse,
		case
			when visitecompl.data ->> 'pelotes'::text = 'null' then null
			else visitecompl.data ->> 'pelotes'::text 
		end as pelotes,
		case
			when visitecompl.data -> 'nombre_dans_pelote'::text = 'null' then null
			else visitecompl.data -> 'nombre_dans_pelote'::text 
		end as nombre_dans_pelote,
		case
			when visitecompl.data ->> 'fond_de_sac'::text = 'null' then null
			else visitecompl.data ->> 'fond_de_sac'::text 
		end as fond_de_sac,
		case
			when visitecompl.data -> 'predateur'::text = 'null' then null
			else visitecompl.data -> 'predateur'::text 
		end as predateur,
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
			when obscompl.data -> 'technique_observation'::text = 'null' then null
			else obscompl.data -> 'technique_observation'::text
		end AS technique_observation,
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
		end AS nombre_individus,
		case 
			when obscompl.data ->> 'stade_de_vie'::text = 'null' then null
			else obscompl.data ->> 'stade_de_vie'::text
		end AS stade_de_vie,
		case 
			when obscompl.data ->> 'sexe'::text = 'null' then null
			else obscompl.data ->> 'sexe'::text
		end AS sexe,
		obs."comments" as remarques_observation


	FROM  gn_monitoring.t_base_sites site 
		JOIN gn_monitoring.t_site_complements sitecompl ON site.id_base_site = sitecompl.id_base_site
		JOIN gn_monitoring.t_base_visits visite ON visite.id_base_site = site.id_base_site
		JOIN gn_meta.t_datasets jdd ON jdd.id_dataset = visite.id_dataset
		JOIN gn_monitoring.t_visit_complements visitecompl ON visitecompl.id_base_visit = visite.id_base_visit
		JOIN gn_monitoring.t_observations obs ON obs.id_base_visit = visite.id_base_visit
		JOIN taxonomie.taxref tx ON obs.cd_nom = tx.cd_nom
		JOIN gn_monitoring.t_observation_complements obscompl ON obscompl.id_observation = obs.id_observation

	WHERE visite.id_module = gn_commons.get_id_module_bycode('peloterejection'::text)

)


SELECT
--jdd pour filtre des exports
datamonit.id_dataset,
datamonit.nom_jdd,
datamonit.nom_court_jdd,

--sites
datamonit.code_site, --code du site
datamonit.nom_site, --nom du site
datamonit.comm_site, --communes du site
datamonit.geometrie, --geometrie du site
datamonit.commentaire_site, --commentaire du site


--visite
datamonit.uuid_visite, --uuid visite / releve
(ref_nomenclatures.get_nomenclature_label(datamonit.id_nomenclature_tech_collect_campanule::int, 'fr'))::text as technique_collecte_campanule,--technique collect campanul
datamonit.pelotes, -- pelotes oui non
datamonit.date_collecte, --date min visite / releve : collecte des pelotes
datamonit.date_analyse, --date max visite / releve : analyse  des pelotes
observers_monit.observateurs, --observateurs visite / releve
determinateurs_monit.determinateurs, --determinteurs des pelotes
datamonit.nombre_dans_pelote, --nombre de cadavres dans pelote
datamonit.fond_de_sac, --fond de sac oui non
(ref_nomenclatures.get_nomenclature_label(datamonit.predateur::int, 'fr'))::text as predateur, --prédateur
datamonit.remarques_visite, --remarque visite / releve


--observation
datamonit.uuid_observation, --uuid observation
datamonit.cd_nom, --cd_nom observation
datamonit.cd_ref, --cd_ref observation
datamonit.nom_vern_taxon, --espece observation
datamonit.nom_taxon, --espece observation
datamonit.nom_complet_taxon, --espece observation
(ref_nomenclatures.get_nomenclature_label(datamonit.technique_observation::int, 'fr'))::text as technique_observation, --methode obs observation
(ref_nomenclatures.get_nomenclature_label(datamonit.statut_observation::int, 'fr'))::text as statut_observation,  --statut obs observation
(ref_nomenclatures.get_nomenclature_label(datamonit.statut_source::int, 'fr'))::text as statut_source,  --statut source observation
(ref_nomenclatures.get_nomenclature_label(datamonit.etat_biologique::int, 'fr'))::text as etat_biologique, --etat biologique observation
datamonit.nombre_individus, --nombre du taxon
datamonit.remarques_observation --commentaire observation



FROM data_monitoring datamonit 
JOIN observers_monit using(id_base_visit)
left JOIN determinateurs_monit using(id_base_visit);





