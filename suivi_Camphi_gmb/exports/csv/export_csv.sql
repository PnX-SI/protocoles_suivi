------------------------------------------------- export campagnol amphibie ------------------------------------------
-- View: gn_monitoring.v_export_suivicampagnolamph_telecharger_csv


DROP VIEW  IF EXISTS  gn_monitoring.v_export_suivicampagnolamph_telecharger_csv;

CREATE OR REPLACE VIEW gn_monitoring.v_export_suivicampagnolamph_telecharger_csv 
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
		case
			when sitecompl.data ->> 'secteur'::text = 'null' then null
			else sitecompl.data ->> 'secteur'::text 
		end as secteur,
		case
			when sitecompl.data ->> 'site_prot_nat'::text = 'null' then null
			else sitecompl.data ->> 'site_prot_nat'::text 
		end as site_prot_nat,
		case
			when sitecompl.data ->> 'code_prot_nat'::text = 'null' then null
			else sitecompl.data ->> 'code_prot_nat'::text 
		end as code_prot_nat,
		site.base_site_name as nom_site,
		ST_AsText(st_transform(site.geom,2154)) as geometrie,
		st_x(ST_Centroid(st_transform(site.geom,2154))) as x_l93,
		st_y(ST_Centroid(st_transform(site.geom,2154))) as y_l93,
		case
			when sitecompl.data ->> 'comments'::text = 'null' then null
			else sitecompl.data ->> 'comments'::text 
		end as comment_site,
		visite.uuid_base_visit as uuid_visite,
		visite.visit_date_min as date_visite,
		case
			when visitecompl.data -> 'id_nomenclature_tech_collect_campanule'::text = 'null' then null
			else visitecompl.data -> 'id_nomenclature_tech_collect_campanule'::text 
		end as techn_collecte_campanule,
		case
			when visitecompl.data ->> 'cadre_prosp'::text = 'null' then null
			else visitecompl.data ->> 'cadre_prosp'::text 
		end as cadre_prosp,
		case
			when visitecompl.data ->> 'cadre_precis'::text = 'null' then null
			else visitecompl.data ->> 'cadre_precis'::text 
		end as cadre_precis,
		case
			when visitecompl.data ->> 'hab_arsa'::text = 'null' then null
			else visitecompl.data ->> 'hab_arsa'::text 
		end as hab_arsa,
		case
			when visitecompl.data -> 'hab_arsa_vg_dom'::text = 'null' then null
			else visitecompl.data -> 'hab_arsa_vg_dom'::text 
		end as hab_arsa_vg_dom,
		case
			when visitecompl.data ->> 'megaph'::text = 'null' then null
			else visitecompl.data ->> 'megaph'::text 
		end as megaph,
		case
			when visitecompl.data -> 'gestion'::text = 'null' then null
			else visitecompl.data -> 'gestion'::text 
		end as gestion,
		case
			when visitecompl.data -> 'acces_riv'::text = 'null' then null
			else visitecompl.data -> 'acces_riv'::text 
		end as acces_riv,
		visite."comments" as remarques_visite,
		obs.uuid_observation as uuid_observation,
		obs.cd_nom as cd_nom,
		tx.cd_ref as cd_ref,
		tx.nom_vern as nom_vern_taxon,
		tx.nom_complet as nom_taxon,
		tx.lb_nom as nom_complet_taxon,
		case 
			when obscompl.data ->> 'nombre_individus'::text = 'null' then null
			else obscompl.data ->> 'nombre_individus'::text
		end AS nombre_individus,
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
			when obscompl.data -> 'densit_fs'::text = 'null' then null
			else obscompl.data -> 'densit_fs'::text
		end as densit_fs,
		case 
			when obscompl.data ->> 'nb_fs'::text = 'null' then null
			else obscompl.data ->> 'nb_fs'::text
		end AS nb_fs,
		obs."comments" as commentaire_observation


	FROM  gn_monitoring.t_base_sites site 
		JOIN gn_monitoring.t_site_complements sitecompl ON site.id_base_site = sitecompl.id_base_site
		JOIN gn_monitoring.t_base_visits visite ON visite.id_base_site = site.id_base_site
		JOIN gn_meta.t_datasets jdd ON jdd.id_dataset = visite.id_dataset
		JOIN gn_monitoring.t_visit_complements visitecompl ON visitecompl.id_base_visit = visite.id_base_visit
		JOIN gn_monitoring.t_observations obs ON obs.id_base_visit = visite.id_base_visit
		JOIN taxonomie.taxref tx ON obs.cd_nom = tx.cd_nom
		JOIN gn_monitoring.t_observation_complements obscompl ON obscompl.id_observation = obs.id_observation

	WHERE visite.id_module = gn_commons.get_id_module_bycode('suivicampagnolamph'::text)

),

--visite_ty_hab_arsa.ty_hab_arsa as ty_ha_aArsa, 
cor_ty_ha_aArsa_visite as (	
	SELECT visitecompl.id_base_visit as id_base_visit,
	    visitecompl."data",
		(ref_nomenclatures.get_nomenclature_label((json_array_elements( (visitecompl.data -> 'ty_habarsa')::json )::text)::int, 'fr'))::text as ty_habarsa
	FROM gn_monitoring.t_visit_complements visitecompl		
	WHERE (visitecompl.data -> 'ty_habarsa')::text != 'null'
	ORDER BY id_base_visit
),
visite_ty_hab_arsa AS (
	SELECT cor_ty_ha_aArsa_visite.id_base_visit,
		STRING_AGG(ty_habarsa, ', ' ORDER BY ty_habarsa)  AS ty_habarsa
	FROM cor_ty_ha_aArsa_visite	
	GROUP BY cor_ty_ha_aArsa_visite.id_base_visit
),

--visite_hab_arsa_vg_fav.hab_arsa_vg_fav as hab_arsa_vg_fav,
cor_hab_arsa_vg_fav_visite as (	
	SELECT visitecompl.id_base_visit as id_base_visit,
	    visitecompl."data",
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

--observation_ip_arsa.ip_arsa as ip_arsa, 
cor_ip_arsa_observation as (
	SELECT obscompl.id_observation as id_observation,
	    obscompl."data",
	    --(obscompl.data -> 'indices')::json as deterjson
		--json_array_elements( (obscompl.data -> 'indices')::json )::text as indices,
		(ref_nomenclatures.get_nomenclature_label((json_array_elements( (obscompl.data -> 'indices')::json )::text)::int, 'fr'))::text as indices
	FROM gn_monitoring.t_observation_complements obscompl		
	WHERE (obscompl.data -> 'indices')::text != 'null'
	ORDER BY id_observation
),
observation_ip_arsa AS (
	SELECT cor_ip_arsa_observation.id_observation,
		STRING_AGG(indices, ', ' ORDER BY indices) AS ip_arsa
	FROM cor_ip_arsa_observation	
	GROUP BY cor_ip_arsa_observation.id_observation
)



SELECT
datamonit.id_dataset,
datamonit.nom_jdd,
datamonit.nom_court_jdd,
datamonit.secteur,
datamonit.site_prot_nat,
datamonit.code_prot_nat,
datamonit.nom_site,
datamonit.geometrie,
datamonit.x_l93,
datamonit.y_l93,
datamonit.comment_site::text,

datamonit.uuid_visite,
datamonit.date_visite,
observers_monit.observateurs,
(ref_nomenclatures.get_nomenclature_label(datamonit.techn_collecte_campanule::int, 'fr'))::text as techn_collecte_campanule, 
datamonit.cadre_prosp,
datamonit.cadre_precis,
datamonit.hab_arsa,
visite_ty_hab_arsa.ty_habarsa as ty_hab_arsa, 
(ref_nomenclatures.get_nomenclature_label(datamonit.hab_arsa_vg_dom::int, 'fr'))::text as hab_arsa_vg_dom,
visite_hab_arsa_vg_fav.hab_arsa_vg_fav as hab_arsa_vg_fav, 
datamonit.megaph,
(ref_nomenclatures.get_nomenclature_label(datamonit.gestion::int, 'fr'))::text as gestion,
(ref_nomenclatures.get_nomenclature_label(datamonit.acces_riv::int, 'fr'))::text as acces_riv,
datamonit.remarques_visite,

datamonit.uuid_observation,
datamonit.cd_nom,
datamonit.cd_ref,
datamonit.nom_vern_taxon,
datamonit.nom_taxon,
datamonit.nom_complet_taxon,
datamonit.nombre_individus::int,
(ref_nomenclatures.get_nomenclature_label(datamonit.technique_observation::int, 'fr'))::text as technique_observation,
(ref_nomenclatures.get_nomenclature_label(datamonit.etat_biologique::int, 'fr'))::text as etat_biologique,
(ref_nomenclatures.get_nomenclature_label(datamonit.statut_observation::int, 'fr'))::text as statut_observation,
--(ref_nomenclatures.get_nomenclature_label(datamonit.statut_source::int, 'fr'))::text as statut_source,
observation_ip_arsa.ip_arsa as ip_arsa, 
(ref_nomenclatures.get_nomenclature_label(datamonit.densit_fs::int, 'fr'))::text as densit_fs,
datamonit.nb_fs::int,
datamonit.commentaire_observation

FROM data_monitoring datamonit 
JOIN observers_monit using(id_base_visit)
left JOIN visite_ty_hab_arsa using(id_base_visit)
left JOIN visite_hab_arsa_vg_fav using(id_base_visit)
left JOIN observation_ip_arsa using(id_observation);




