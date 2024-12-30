------------------------------------------------- export loutre local ------------------------------------------
-- View: gn_monitoring.v_export_suiviloutreuicn_telecharger_csv

DROP VIEW  IF EXISTS  gn_monitoring.v_export_suiviloutreuicn_telecharger_csv;
CREATE OR REPLACE VIEW gn_monitoring.v_export_suiviloutreuicn_telecharger_csv 
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
data_monitoring AS (
		SELECT
		visite.id_base_visit as id_base_visit,
		obs.id_observation as id_observation,
		jdd.dataset_name as nom_jdd,
		jdd.id_dataset as id_dataset,
		jdd.dataset_shortname as nom_court_jdd,
		grpsite.sites_group_code as code_zonehydro,
		grpsite.sites_group_name as nom_zonehydro,
		site.base_site_code as code_site,
		site.base_site_name as nom_site,
		case
			when sitecompl.data ->> 'site_uicn'::text = 'null' then null
			else sitecompl.data ->> 'site_uicn'::text 
		end as site_uicn,
		case
			when sitecompl.data ->> 'num_site_uicn'::text = 'null' then null
			else sitecompl.data ->> 'num_site_uicn'::text 
		end as num_site_uicn,
		site.base_site_description as site_description,
		ST_AsText(st_transform(site.geom,2154)) as geometrie,
		st_x(ST_Centroid(st_transform(site.geom,2154))) as x_l93,
		st_y(ST_Centroid(st_transform(site.geom,2154))) as y_l93,
		visite.uuid_base_visit as uuid_visite,
		visite.visit_date_min as date_visite,
		case
			when visitecompl.data -> 'megaph'::text = 'null' then null
			else visitecompl.data -> 'megaph'::text 
		end as megaph,
		case
			when visitecompl.data -> 'gestion'::text = 'null' then null
			else visitecompl.data -> 'gestion'::text 
		end as gestion,
		case
			when visitecompl.data ->> 'hab_arsa'::text = 'null' then null
			else visitecompl.data ->> 'hab_arsa'::text 
		end as hab_arsa,
		case
			when visitecompl.data -> 'acces_riv'::text = 'null' then null
			else visitecompl.data -> 'acces_riv'::text 
		end as acces_riv,
		case
			when visitecompl.data ->> 'lin_prosp'::text = 'null' then null
			else visitecompl.data ->> 'lin_prosp'::text 
		end as lin_prosp,
		case
			when visitecompl.data -> 'post_marq'::text = 'null' then null
			else visitecompl.data -> 'post_marq'::text 
		end as post_marq,
		case
			when visitecompl.data -> 'berg_prosp'::text = 'null' then null
			else visitecompl.data -> 'berg_prosp'::text 
		end as berg_prosp,
		case
			when visitecompl.data -> 'cond_prosp'::text = 'null' then null
			else visitecompl.data -> 'cond_prosp'::text 
		end as cond_prosp,
		case
			when visitecompl.data -> 'sens_prosp'::text = 'null' then null
			else visitecompl.data -> 'sens_prosp'::text 
		end as sens_prosp,
		case
			when visitecompl.data ->> 'cadre_prosp'::text = 'null' then null
			else visitecompl.data ->> 'cadre_prosp'::text 
		end as cadre_prosp,
		case
			when visitecompl.data -> 'hab_arsa_vg_dom'::text = 'null' then null
			else visitecompl.data -> 'hab_arsa_vg_dom'::text 
		end as hab_arsa_vg_dom,
		case
			when visitecompl.data -> 'saisie_details_arsa'::text = 'null' then null
			else visitecompl.data -> 'saisie_details_arsa'::text 
		end as saisie_details_arsa,
		case
			when visitecompl.data -> 'saisie_details_prosp'::text = 'null' then null
			else visitecompl.data -> 'saisie_details_prosp'::text 
		end as saisie_details_prosp,
		case
			when visitecompl.data -> 'id_nomenclature_tech_collect_campanule'::text = 'null' then null
			else visitecompl.data -> 'id_nomenclature_tech_collect_campanule'::text 
		end as id_nomenclature_tech_collect_campanule,
		visite."comments" as remarques_visite,
		obs.uuid_observation as uuid_observation,
		obs.cd_nom as cd_nom,
		tx.cd_ref as cd_ref,
		tx.nom_vern as nom_vern_taxon,
		tx.nom_complet as nom_taxon,
		tx.lb_nom as nom_complet_taxon,
				case 
			when obscompl.data ->> 'sexe'::text = 'null' then null
			else obscompl.data ->> 'sexe'::text
		end AS sexe,
		case
			when obscompl.data -> 'repro'::text = 'null' then null
			else obscompl.data -> 'repro'::text
		end as repro,
		case
			when obscompl.data ->> 'catich'::text = 'null' then null
			else obscompl.data ->> 'catich'::text
		end as catich,
		case
			when obscompl.data ->> 'ty_catich'::text = 'null' then null
			else obscompl.data ->> 'ty_catich'::text
		end as ty_catich,
		case
			when obscompl.data -> 'stade_de_vie'::text = 'null' then null
			else obscompl.data -> 'stade_de_vie'::text
		end as stade_de_vie,
		case
			when obscompl.data -> 'etat_biologique'::text = 'null' then null
			else obscompl.data -> 'etat_biologique'::text
		end as etat_biologique,
		obs."comments" as commentaire_observation,
		case 
			when obscompl.data ->> 'nombre_individus'::text = 'null' then null
			else obscompl.data ->> 'nombre_individus'::text
		end AS nombre_individus,
		case 
			when obscompl.data ->> 'statut_observation'::text = 'null' then null
			else obscompl.data ->> 'statut_observation'::text
		end AS statut_observation,
		case 
			when obscompl.data ->> 'technique_observation'::text = 'null' then null
			else obscompl.data ->> 'technique_observation'::text
		end AS technique_observation
	FROM gn_monitoring.t_sites_groups grpsite
		JOIN gn_monitoring.cor_sites_group_module grpsitemodule on grpsitemodule.id_sites_group = grpsite.id_sites_group
		JOIN gn_monitoring.t_site_complements sitecompl ON grpsite.id_sites_group = sitecompl.id_sites_group
		JOIN gn_monitoring.t_base_sites site ON sitecompl.id_base_site = site.id_base_site
		JOIN gn_monitoring.t_base_visits visite ON visite.id_base_site = site.id_base_site
		JOIN gn_meta.t_datasets jdd ON jdd.id_dataset = visite.id_dataset
		JOIN gn_monitoring.t_visit_complements visitecompl ON visitecompl.id_base_visit = visite.id_base_visit
		JOIN gn_monitoring.t_observations obs ON obs.id_base_visit = visite.id_base_visit
		JOIN taxonomie.taxref tx ON obs.cd_nom = tx.cd_nom
		JOIN gn_monitoring.t_observation_complements obscompl ON obscompl.id_observation = obs.id_observation
			WHERE  grpsitemodule.id_module =  gn_commons.get_id_module_bycode('suiviloutreuicn'::text)
		),
		--ty_habarsa
cor_ty_habarsa_visite as (	
	SELECT visitecompl.id_base_visit as id_base_visit,
	    visitecompl."data",
	    --(visitecompl.data -> 'ty_habarsa')::json as deterjson
		--json_array_elements( (visitecompl.data -> 'ty_habarsa')::json )::text as ty_habarsa,
		(ref_nomenclatures.get_nomenclature_label((json_array_elements( (visitecompl.data -> 'ty_habarsa')::json )::text)::int, 'fr'))::text as ty_habarsa
	FROM gn_monitoring.t_visit_complements visitecompl		
	WHERE (visitecompl.data -> 'ty_habarsa')::text != 'null'
	ORDER BY id_base_visit
),
visite_ty_habarsa AS (
	SELECT cor_ty_habarsa_visite.id_base_visit,
		STRING_AGG(ty_habarsa, ', ' ORDER BY ty_habarsa)  AS ty_habarsa
	FROM cor_ty_habarsa_visite	
	GROUP BY cor_ty_habarsa_visite.id_base_visit
),
--hab_arsa_vg_fav
cor_hab_arsa_vg_fav_visite as (	
	SELECT visitecompl.id_base_visit as id_base_visit,
	    visitecompl."data",
	    --(visitecompl.data -> 'hab_arsa_vg_fav')::json as deterjson
		--json_array_elements( (visitecompl.data -> 'hab_arsa_vg_fav')::json )::text as hab_arsa_vg_fav,
		(ref_nomenclatures.get_nomenclature_label((json_array_elements( (visitecompl.data -> 'hab_arsa_vg_fav')::json )::text)::int, 'fr'))::text as hab_arsa_vg_fav
	FROM gn_monitoring.t_visit_complements visitecompl		
	WHERE (visitecompl.data -> 'hab_arsa_vg_fav')::text != 'null'
	ORDER BY id_base_visit
),
visite_hab_arsa_vg_fav AS (
	SELECT cor_hab_arsa_vg_fav_visite.id_base_visit,
		STRING_AGG(hab_arsa_vg_fav, ', ' ORDER BY hab_arsa_vg_fav)  AS hab_arsa_vg_fav
	FROM cor_hab_arsa_vg_fav_visite	
	GROUP BY cor_hab_arsa_vg_fav_visite.id_base_visit
),

--fraich_ep
cor_fraich_ep_obs as (	
	SELECT obscompl.id_observation as id_observation,
	    obscompl."data",
	    --(obscompl.data -> 'fraich_ep')::json as deterjson
		--json_array_elements( (obscompl.data -> 'fraich_ep')::json )::text as fraich_ep,
		(ref_nomenclatures.get_nomenclature_label((json_array_elements( (obscompl.data -> 'fraich_ep')::json )::text)::int, 'fr'))::text as fraich_ep
	FROM gn_monitoring.t_observation_complements obscompl		
	WHERE (obscompl.data -> 'fraich_ep')::text != 'null'
	ORDER BY id_observation
),
observation_fraich_ep AS (
	SELECT cor_fraich_ep_obs.id_observation,
		STRING_AGG(fraich_ep, ', ' ORDER BY fraich_ep)  AS fraich_ep
	FROM cor_fraich_ep_obs	
	GROUP BY cor_fraich_ep_obs.id_observation
)

SELECT
--jdd pour filtre des exports
datamonit.id_dataset,
datamonit.nom_jdd,
datamonit.nom_court_jdd,
--groupe de sites
datamonit.code_zonehydro,
datamonit.nom_zonehydro,
--site
datamonit.code_site,
datamonit.nom_site,
datamonit.site_uicn,
datamonit.num_site_uicn,
datamonit.geometrie,
datamonit.x_l93,
datamonit.y_l93,
datamonit.site_description,
--visite
datamonit.uuid_visite,
datamonit.date_visite,
observers_monit.observateurs,
(ref_nomenclatures.get_nomenclature_label(datamonit.id_nomenclature_tech_collect_campanule::int, 'fr'))::text as id_nomenclature_tech_collect_campanule, 
datamonit.cadre_prosp, 
(ref_nomenclatures.get_nomenclature_label(datamonit.cond_prosp::int, 'fr'))::text as cond_prosp, 
(ref_nomenclatures.get_nomenclature_label(datamonit.berg_prosp::int, 'fr'))::text as berg_prosp, 
(ref_nomenclatures.get_nomenclature_label(datamonit.sens_prosp::int, 'fr'))::text as sens_prosp, 
datamonit.lin_prosp,
(ref_nomenclatures.get_nomenclature_label(datamonit.post_marq::int, 'fr'))::text as post_marq, 
datamonit.hab_arsa,
visite_ty_habarsa.ty_habarsa as ty_habarsa, 
(ref_nomenclatures.get_nomenclature_label(datamonit.hab_arsa_vg_dom::int, 'fr'))::text as hab_arsa_vg_dom, 
visite_hab_arsa_vg_fav.hab_arsa_vg_fav as hab_arsa_vg_fav, 
datamonit.megaph,
(ref_nomenclatures.get_nomenclature_label(datamonit.gestion::int, 'fr'))::text as gestion, 
(ref_nomenclatures.get_nomenclature_label(datamonit.acces_riv::int, 'fr'))::text as acces_riv, 
datamonit.remarques_visite,
--observation
datamonit.uuid_observation,
datamonit.cd_nom,
datamonit.cd_ref,
datamonit.nom_vern_taxon,
datamonit.nom_taxon,
datamonit.nom_complet_taxon,
(ref_nomenclatures.get_nomenclature_label(datamonit.technique_observation::int, 'fr'))::text as technique_observation,
(ref_nomenclatures.get_nomenclature_label(datamonit.etat_biologique::int, 'fr'))::text as etat_biologique,
(ref_nomenclatures.get_nomenclature_label(datamonit.statut_observation::int, 'fr'))::text as statut_observation,
datamonit.commentaire_observation,
observation_fraich_ep.fraich_ep,
datamonit.repro,
datamonit.catich,
datamonit.ty_catich,
datamonit.nombre_individus::int,
(ref_nomenclatures.get_nomenclature_label(datamonit.stade_de_vie::int, 'fr'))::text as stade_de_vie,
(ref_nomenclatures.get_nomenclature_label(datamonit.sexe::int, 'fr'))::text as sexe
FROM data_monitoring datamonit 
JOIN observers_monit using(id_base_visit)
left JOIN visite_ty_habarsa using(id_base_visit)
left JOIN visite_hab_arsa_vg_fav using(id_base_visit)
left JOIN observation_fraich_ep using(id_observation);

