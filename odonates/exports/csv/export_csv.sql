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
DROP view IF EXISTS gn_monitoring.v_export_odonates_standard;
CREATE OR REPLACE VIEW gn_monitoring.v_export_odonates_standard AS 
with 
module as (
select
	tm.id_module,
	tm.module_code
from
	gn_commons.t_modules tm
where
	tm.module_code::text = 'odonates'::text
	or tm.module_code::text = 'caracterisation_mare'::text
        ),
sites as (
select
	tbs.id_base_site,
	sc.id_module,
	tbs.base_site_name as nompzh,
	tbs.base_site_code,
	tbs.base_site_description,
	tbs.id_inventor,
	tbs.id_digitiser,
	coalesce(tbs.meta_update_date,
	tbs.first_use_date::timestamp without time zone) as date_site,
	tbs.altitude_min,
	tbs.altitude_max,
	tbs.geom_local,
	st_x(st_centroid(tbs.geom)) as wgs84_x,
	st_y(st_centroid(tbs.geom)) as wgs84_y,
	st_x(st_centroid(tbs.geom_local)) as l93_x,
	st_y(st_centroid(tbs.geom_local)) as l93_y,
	sc.data::json #>> '{pzhCode}'::text[] as pzhcode,
	(roles.nom_role::text || ' '::text) || roles.prenom_role::text as numer_site,
	org.nom_organisme as organisme,
	a.jname->>'COM' as commune,
	a.jcode->>'DEP' as code_dep,
	a.jname->>'DEP' as departement,
	rfg_i_com.commune_from_centroid,
	rfg_i_dep.dep_from_centroid,
	case
		when (sc.data ->> 'qObserver'::text) = '[]'::text then null::text
		when (sc.data ->> 'qObserver'::text) is null then null::text
		else (
		select
			string_agg(btrim(jsonb_array_elements_text.value,
			'"'::text),
			', '::text) as string_agg
		from
			jsonb_array_elements_text(sc.data -> 'qObserver'::text) jsonb_array_elements_text(value))
	end as qobserver,
	case
		when (sc.data ->> 'observateurCompl'::text) = ''::text then null::text
		when (sc.data ->> 'observateurCompl'::text) = '[]'::text then null::text
		when (sc.data ->> 'observateurCompl'::text) is null then null::text
		else array_to_string(array(
		select
			(tr.nom_role::text || ' '::text) || tr.prenom_role::text
		from
			unnest(array(
			select
				jsonb_array_elements_text(sc.data -> 'observateurCompl'::text)::integer as jsonb_array_elements_text)) entity_id(entity_id)
		join utilisateurs.t_roles tr on
			tr.id_role = entity_id.entity_id),
		', '::text)
	end as observateurcompl,
	sc.data::json #>> '{gestionnaire}'::text[] as gestionnairepzh,
	sc.data::json #>> '{owner}'::text[] as proprietairepzh,
	sc.data::json #>> '{proprietepzh}'::text[] as proprietepzh,
	tn2_1.label_fr as typezh,
	--tn3.label_fr as methodepzh,
	array_to_string(
	array(
	select 
			case 
				when entity_id.entity_id = 'no_media' then null
			else concat('https://geonature.snpn.com/geonature/api/media/attachments/',
			entity_id.entity_id)
		end
	from
		unnest(
        	array(
		select
			case
				when tmed3.media_path is null then '{no_media}'
				else tmed3.media_path
			end
	        )
        ) entity_id(entity_id)
	),
	', '
) as public_media_path_sites
from
	gn_monitoring.t_base_sites tbs
join gn_monitoring.t_site_complements sc on
	sc.id_base_site = tbs.id_base_site
join ref_nomenclatures.t_nomenclatures tn2_1 on
	tn2_1.id_nomenclature = tbs.id_nomenclature_type_site
--join ref_nomenclatures.t_nomenclatures tn3 on
--	tn3.id_nomenclature::text = (sc.data ->> 'id_nomenclature_prospection'::text)
join utilisateurs.t_roles roles on
	roles.id_role = tbs.id_digitiser
join utilisateurs.bib_organismes org on
	org.id_organisme = roles.id_organisme
join lateral (
	select
		d_1.id_base_site ,
		json_object_agg(d_1.type_code,
		d_1.o_name) as jname,
		json_object_agg(d_1.type_code,
		d_1.o_code) as jcode
	from
		(
		select
			sa.id_base_site ,
			ta.type_code,
			string_agg(distinct a_1.area_name::text,
			','::text) as o_name,
			string_agg(distinct a_1.area_code::text,
			','::text) as o_code
		from
			gn_monitoring.cor_site_area sa
		join ref_geo.l_areas a_1 on
			sa.id_area = a_1.id_area
		join ref_geo.bib_areas_types ta on
			ta.id_type = a_1.id_type
		where
			sa.id_base_site = tbs.id_base_site
		group by
			sa.id_base_site ,
			ta.type_code) d_1
	group by
		d_1.id_base_site) a on
	true
join lateral (select area_name as commune_from_centroid from 
ref_geo.fct_get_area_intersection(st_centroid(tbs.geom_local)) rfg
join ref_geo.bib_areas_types bat 
on rfg.id_type = bat.id_type and bat.type_code = 'COM') rfg_i_com on true
join lateral (select area_name as dep_from_centroid from 
ref_geo.fct_get_area_intersection(st_centroid(tbs.geom_local)) rfg
join ref_geo.bib_areas_types bat 
on rfg.id_type = bat.id_type and bat.type_code = 'DEP') rfg_i_dep on true
left join lateral (
	select 
		array_agg(
			concat(tmed.media_path,
		' (titre : ',
		tmed.title_fr,
		')')
		) as media_path,
		tmed.uuid_attached_row
	from
		gn_commons.t_medias tmed
	where
		tmed.uuid_attached_row is not null
	group by
		tmed.uuid_attached_row) tmed3 on
	tmed3.uuid_attached_row = tbs.uuid_base_site
join module m on
	(
	select
		id_module
	from
		module m
	where
		m.module_code = 'caracterisation_mare') = sc.id_module
group by
	tbs.id_base_site,
	((roles.nom_role::text || ' '::text) || roles.prenom_role::text),
	sc.id_module,
	org.nom_organisme,
	sc.data,
	a.jname->>'COM',
	a.jcode->>'DEP',
	a.jname->>'DEP',
	rfg_i_com.commune_from_centroid,
	rfg_i_dep.dep_from_centroid,
	tn2_1.label_fr,
	--tn3.label_fr,
	tmed3.media_path
        ),
visites as (
select
	tbv.id_base_site,
	tbv.id_module,
	tbv.id_base_visit,
	string_agg((tr_digi.nom_role::text || ' '::text) || tr_digi.prenom_role::text,
	', '::text
order by
	tr_digi.nom_role,
	tr_digi.prenom_role) as numer_visit,
	string_agg(distinct concat(upper(tr.nom_role::text),
	' ',
	tr.prenom_role),
	', '::text
order by
	(concat(upper(tr.nom_role::text),
	' ',
	tr.prenom_role))) as observers_visit,
	case
		when (tvc.data ->> 'qObserver'::text) = '[]'::text then null::text
		when (tvc.data ->> 'qObserver'::text) is null then null::text
		else (
		select
			string_agg(btrim(jsonb_array_elements_text.value,
			'"'::text),
			', '::text) as string_agg
		from
			jsonb_array_elements_text(tvc.data -> 'qObserver'::text) jsonb_array_elements_text(value))
	end as qobserver_visit,
	case
		when (tvc.data ->> 'observateurCompl'::text) = ''::text then null::text
		when (tvc.data ->> 'observateurCompl'::text) = '[]'::text then null::text
		when (tvc.data ->> 'observateurCompl'::text) is null then null::text
		else array_to_string(array(
		select
			(tr_1.nom_role::text || ' '::text) || tr_1.prenom_role::text
		from
			unnest(array(
			select
				jsonb_array_elements_text(tvc.data -> 'observateurCompl'::text)::integer as jsonb_array_elements_text)) entity_id(entity_id)
		join utilisateurs.t_roles tr_1 on
			tr_1.id_role = entity_id.entity_id),
		', '::text)
	end as observateurcompl_visit,
	org.nom_organisme as organisme_numer_visit,
	tbv.visit_date_min AS "date_min",
	tvc.data::json #>> '{heureDebut}'::text[] as heuredebut,
	tvc.data::json #>> '{heureFin}'::text[] as heurefin,
	tvc.data::json #>> '{passage}'::text[] as passage,
	tvc.data::json #>> '{periode}'::text[] as periode,
	tvc.data::json #>> '{tempAir}'::text[] as tempair,
	tvc.data::json #>> '{humidite}'::text[] as humidite,
	concat(
	floor(extract('EPOCH' from age(
		concat(tbv.visit_date_min, ' ',tvc."data"->>'heureFin')::timestamp, 
		concat(tbv.visit_date_min, ' ',tvc."data"->>'heureDebut')::timestamp
	)/3600)
	),
	'h',
	to_char(
        concat(tbv.visit_date_min, ' ',tvc."data"->>'heureFin')::timestamp 
        - concat(tbv.visit_date_min, ' ',tvc."data"->>'heureDebut')::timestamp, 'MI'
	),
	'm'
)AS temps_releve,
	ref_nomenclatures.get_nomenclature_label((tvc."data"->>'pluviosite')::integer) as pluviosite,
	tvc.data::json #>> '{couvertureNuageuse}'::text[] as couverturenuageuse,
	ref_nomenclatures.get_nomenclature_label((tvc."data"->>'vent')::integer) as vent,
	tvc.data::json #>> '{pertubations}'::text[] as pertubations,
	tbv.comments as commentairevisite,
	array_to_string(
	array(
	select 
			case 
				when entity_id.entity_id = 'no_media' then null
			else concat('https://geonature.snpn.com/geonature/api/media/attachments/',
			entity_id.entity_id)
		end
	from
		unnest(
        	array(
		select
			case
				when tmed2.media_path is null then '{no_media}'
				else tmed2.media_path
			end
	        )
        ) entity_id(entity_id)
	),
	', '
) as public_media_path_visits
from
	gn_monitoring.t_base_visits tbv
join module on
	tbv.id_module = (
	select
		id_module
	from
		module m
	where
		m.module_code = 'odonates')
join gn_monitoring.t_visit_complements tvc on
	tvc.id_base_visit = tbv.id_base_visit
join gn_monitoring.cor_visit_observer cvo on
	cvo.id_base_visit = tbv.id_base_visit
join utilisateurs.t_roles tr on
	tr.id_role = cvo.id_role
join utilisateurs.t_roles tr_digi on
	tr_digi.id_role = tbv.id_digitiser
join utilisateurs.bib_organismes org on
	org.id_organisme = tr_digi.id_organisme
left join lateral (
	select 
		array_agg(
			concat(tmed.media_path,
		' (titre : ',
		tmed.title_fr,
		')')
		) as media_path,
		tmed.uuid_attached_row
	from
		gn_commons.t_medias tmed
	where
		tmed.uuid_attached_row is not null
	group by
		tmed.uuid_attached_row) tmed2 on
	tmed2.uuid_attached_row = tbv.uuid_base_visit
group by
	tbv.id_base_site,
	tbv.id_base_visit,
	tvc.data,
	org.nom_organisme,
	tmed2.media_path
        )
 select
 	s.nompzh,
	s.numer_site,
	s.organisme,
	s.departement,
	s.code_dep,
	s.commune,
	s.commune_from_centroid,
	s.dep_from_centroid,
	s.l93_x as longitude,
	s.l93_y as latitude,
	s.date_site,
	s.qobserver,
	s.proprietairepzh,
	s.proprietepzh,
	s.observateurcompl,
	s.gestionnairepzh,
	s.pzhcode,
	s.typezh,
	--s.methodepzh,
	s.public_media_path_sites,
	v.numer_visit,
	v.observers_visit,
	v.qobserver_visit,
	v.observateurcompl_visit,
	v.organisme_numer_visit,
	v.date_min,
	v.heuredebut,
	v.heurefin,
	v.temps_releve,
	v.passage,
	v.periode,
	v.tempair,
	v.humidite,
	v.pluviosite,
	v.couverturenuageuse,
	v.vent,
	v.pertubations,
	v.commentairevisite,
	v.public_media_path_visits,
	t.lb_nom as nomscientifiqueref,
	t.cd_nom,
	t.regne,
	t.classe,
	t.ordre,
	t.famille,
	t.sous_famille as genre,
	t.nom_complet as nomcite,
	t.nom_vern as nomvernaculaire,
	tn.label_fr as ocetatbio,
	tn1.label_fr as ocstade,
	tn2.label_fr as ocsexe,
	case
		when toc."data"->>'id_nomenclature_behaviour' = '[]' then null
		when toc."data"->>'id_nomenclature_behaviour' is null then null
		else (
				array_to_string(ARRAY( SELECT tn.label_fr::text
		        FROM unnest(ARRAY( SELECT jsonb_array_elements_text(toc."data" -> 'id_nomenclature_behaviour'::text)::integer AS jsonb_array_elements_text)) entity_id(entity_id)
		        JOIN ref_nomenclatures.t_nomenclatures tn ON tn.id_nomenclature = entity_id.entity_id
		        WHERE  jsonb_typeof(toc."data" -> 'id_nomenclature_behaviour') = 'array' 
	        ), '; '::text)
	    )
	end AS "id_nomenclature_behaviour",
	toc.data::json #>> '{count_exact}'::text[] as countexact,
	split_part(tn3.mnemonique,
	'-',
	1) as count_min,
	case 
		when split_part(tn3.mnemonique,
		'-',
		1) = '>100' then 'Indéterminé'
		else split_part(tn3.mnemonique,
		'-',
		2)
	end as count_max,
	tn3.label_fr as count_tranche,
	case 
		when tn3.label_fr in ('>100', 'Indéterminé') then null
		else (((split_part(tn3.label_fr,
		'-',
		2))::integer + (split_part(tn3.label_fr,
		'-',
		1))::integer)/ 2)
	end as count_average,
	case  
		when toc."data"->>'count_exact' is not null then 'Compté'
		else 
			case 
				when toc."data"->>'count_tranche' is not null
			and toc."data"->>'count_exact' is null then 'Estimé'
		end
	end as type_denombrement,
	obs.comments as commentaireobs
from
	sites s
join visites v on
	v.id_base_site = s.id_base_site
join gn_monitoring.t_observations obs on
	obs.id_base_visit = v.id_base_visit
join gn_monitoring.t_observation_complements toc on
	toc.id_observation = obs.id_observation
join taxonomie.taxref t on
	t.cd_nom = obs.cd_nom
left join ref_nomenclatures.t_nomenclatures tn on
	((toc.data ->> 'id_nomenclature_etat_bio')::integer) = tn.id_nomenclature
left join ref_nomenclatures.t_nomenclatures tn1 on
	((toc.data ->> 'id_nomenclature_stade')::integer) = tn1.id_nomenclature
left join ref_nomenclatures.t_nomenclatures tn2 on
	((toc.data ->> 'id_nomenclature_sex')::integer) = tn2.id_nomenclature
left join ref_nomenclatures.t_nomenclatures tn3 on 
	((toc.data->>'count_tranche')::integer) = tn3.id_nomenclature

