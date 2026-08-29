UPDATE gn_imports.ila_import i SET id_digitiser = r.id_role
FROM utilisateurs.t_roles r WHERE lower(i.determiner) = lower(r.nom_role || ' ' || r.prenom_role)
;

WITH ila_transect as (
	SELECT
		*
	FROM gn_monitoring.t_base_sites tbs
	LEFT JOIN gn_monitoring.t_site_complements tsc USING (id_base_site)
	WHERE id_module = 33
),visits as (
SELECT
	s.transect,
	s.id_visit_ila,
	s.id_digitiser,
	s.visit_date_min
FROM gn_imports.ila_import s
GROUP BY 	 
	s.transect,
	s.id_digitiser,
	s.id_visit_ila,
	s.visit_date_min
)
INSERT INTO  gn_monitoring.t_base_visits 
(
	id_base_site,
	id_dataset,
	id_module,
	id_digitiser,
	visit_date_min,
	visit_date_max,
	id_nomenclature_tech_collect_campanule,
	id_nomenclature_grp_typ,
	comments
)
SELECT
	ila_transect.id_base_site,
	1343,
	33 ,
	visits.id_digitiser,
	visits.visit_date_min,
	visits.visit_date_min,
	240 ,
	132 ,
	CASE WHEN visits.id_visit_ila > 0 THEN visits.id_visit_ila::text
	ELSE visits.transect || '_' || visits.num_passage|| '_' || visits.annee::text
	END 
FROM visits
LEFT JOIN ila_transect on ila_transect.base_site_name = visits.transect
;

UPDATE gn_imports.ila_import s
SET id_base_visit = tbv.id_base_visit
FROM  gn_monitoring.t_base_visits tbv
WHERE 
	CASE WHEN s.id_visit_ila IS NULL THEN tbv.comments = s.transect || '_' || s.num_passage|| '_' || s.annee
	ELSE tbv.comments = s.id_visit_ila::text
	END
AND tbv.id_module = 33
AND s.id_base_visit IS NULL
;

SELECT id_base_visit FROM gn_imports.ila_import s
GROUP BY s.id_base_visit
;

WITH nomen_cn as (
	SELECT
		id_nomenclature as id_nomenclature_cn,
		mnemonique as cn
	FROM ref_nomenclatures.t_nomenclatures WHERE id_type = 173
),
nomen_tp as (
	SELECT
		id_nomenclature as id_nomenclature_tp,
		mnemonique as tp
	FROM ref_nomenclatures.t_nomenclatures WHERE id_type = 172
),
nomen_vt as (
	SELECT
		id_nomenclature as id_nomenclature_vt,
		mnemonique as vt
	FROM ref_nomenclatures.t_nomenclatures WHERE id_type = 183
)
INSERT INTO gn_monitoring.t_visit_complements (
	id_base_visit,
	data
)
SELECT 
	id_base_visit,
	jsonb_strip_nulls(
		jsonb_build_object(
			'annee', s.annee,
			'id_horaire_meteo', CASE WHEN s.id_visit_ila > 0 THEN s.id_visit_ila  ELSE NULL END,
			'num_passage', s.num_passage,
			'id_nomenclature_cn', nomen_cn.id_nomenclature_cn,
			'id_nomenclature_tp', nomen_tp.id_nomenclature_tp,
			'id_nomenclature_vt', nomen_vt.id_nomenclature_vt,
			 'source', CASE WHEN s.id_visit_ila IS NULL THEN 'Intranet SER' ELSE 'Excel' END,
			'heure_debut', STRING_AGG(DISTINCT s.heure_min, ', '),
			'habitat', STRING_AGG(DISTINCT s.habitat, ', '),
			'gestion',  STRING_AGG(DISTINCT s.gestion, ', '),
			'impact', STRING_AGG(DISTINCT s.impact, ', ')
		)
	) as data
FROM gn_imports.ila_import s
LEFT JOIN nomen_cn USING (cn)
LEFT JOIN nomen_tp USING (tp)
LEFT JOIN nomen_vt USING (vt)
LEFT JOIN gn_monitoring.t_visit_complements tvc USING (id_base_visit)
WHERE tvc.id_base_visit IS NULL
GROUP BY 
	s.id_base_visit,
	s.id_visit_ila,
	s.annee,
	s.num_passage,
	nomen_cn.id_nomenclature_cn,
	nomen_tp.id_nomenclature_tp,
	nomen_vt.id_nomenclature_vt
ORDER BY s.id_base_visit
;

WITH observers as (
	SELECT
		i.id_base_visit,
		v.id_digitiser as id_role
	FROM gn_imports.ila_import i
	LEFT JOIN gn_monitoring.cor_visit_observer cvo USING (id_base_visit)
	LEFT JOIN gn_monitoring.t_base_visits v USING (id_base_visit)
	WHERE cvo.id_base_visit IS NULL and NOT i.id_base_visit IS NULL
	ORDER BY id_base_visit
)
INSERT INTO gn_monitoring.cor_visit_observer (
	id_base_visit,
	id_role
)
SELECT
	*
FROM observers
GROUP BY id_base_visit, id_role
ON CONFLICT DO NOTHING
;

INSERT INTO gn_monitoring.t_observations(
	id_base_visit,
	cd_nom,
	comments
)
SELECT 
	i.id_base_visit,
	i.cd_nom,
	CASE WHEN i.id_obs_ila> 0 THEN i.id_obs_ila::text ELSE i.id_base_visit::text || '_' || i.cd_nom::text END
FROM gn_imports.ila_import i
WHERE id_base_visit IS NOT NULL AND id_observation IS NULL
GROUP BY
	i.id_base_visit,
	i.cd_nom,
	i.id_obs_ila
ORDER BY i.id_base_visit, i.id_obs_ila
;

UPDATE gn_imports.ila_import i
SET id_observation = o.id_observation
FROM gn_monitoring.t_observations o
LEFT JOIN gn_monitoring.t_base_visits v USING (id_base_visit)
WHERE v.id_module = 33 
AND i.id_obs_ila::text = o.comments
and i.id_observation IS NULL
;

SELECT
	id_observation,
	count (distinct fid)as nb_rows
FROM gn_imports.ila_import
WHERE id_obs_ila = 0
group by id_observation
ORDER BY nb_rows DESC
;

INSERT INTO gn_monitoring.t_observation_complements (
	id_observation,
	data
)
SELECT
	id_observation,
	jsonb_strip_nulls(
		jsonb_build_object(
			'effectif', min(i.effectif),
			'nb_male', min(i.nb_male),
			'nb_femelle', min(i.nb_femelle),
			'determiner', min(i.determiner),
			'id_obs_mysql', CASE WHEN  i.id_obs_ila> 0 THEN i.id_obs_ila ELSE NULL END,
			'id_nomenclature_obs_technique', 37,
			'id_nomenclature_determination_method', 453,
			'id_nomenclature_type_count', 89,
			'id_nomenclature_obj_count', 143
		)
	) as data
FROM gn_imports.ila_import i
LEFT JOIN gn_monitoring.t_observation_complements toc USING (id_observation)
WHERE toc.id_observation IS NULL
AND NOT i.id_observation is null
GROUP BY i.id_observation, i.id_obs_ila
ORDER BY i.id_observation
;

WITH obs_cmt as (
	SELECT 
		id_observation,
		STRING_AGG(DISTINCT obs_comment, ', ') as comments
	FROM gn_imports.ila_import
	WHERE id_observation is not null
	GROUP BY 
		id_observation
)
UPDATE gn_monitoring.t_observations o
	SET comments = obs_cmt.comments
FROM obs_cmt 
WHERE o.id_observation = obs_cmt.id_observation and not obs_cmt.comments = o.comments
;

WITH 
vis_cmt as (
	SELECT 
		id_base_visit,
		STRING_AGG(DISTINCT visit_comment, ', ') as comments
	FROM gn_imports.ila_import
	LEFT JOIN gn_monitoring.t_base_visits v USING (id_base_visit)
	WHERE id_observation is not null AND v.id_module = 33
	GROUP BY 
		id_base_visit
)
UPDATE gn_monitoring.t_base_visits vis
	SET comments = vis_cmt.comments
FROM vis_cmt 
WHERE vis.id_base_visit = vis_cmt.id_base_visit  and not vis_cmt.comments = vis.comments
and vis.id_module = 33
;

WITH site as (
	SELECT * FROM ref_geo.l_areas WHERE id_type in (12,34,37)
),
com as (
	SELECT * FROM ref_geo.l_areas WHERE id_type =25
),
sc as (
	SELECT
		site.area_code as id_site,
		site.area_name as nom_site,
		STRING_AGG(com.area_name, ',' ORDER BY com.area_name) as communes
	FROM site
	LEFT JOIN com ON ST_Intersects( com.geom, site.geom)
	GROUP BY site.area_code, site.area_name
	ORDER BY site.area_name
)
UPDATE gn_monitoring.t_sites_groups tsg
	SET data = jsonb_set(	
			tsg.data::jsonb, 
			'{commune}', 
			to_jsonb(
				sc.communes
			))
FROM sc 
WHERE id_module = 33 AND sc.id_site = tsg.sites_group_code
;
WITH lv AS 
(SELECT
	tbv.id_base_site,
	LAST_VALUE(tvc.data ->> 'habitat')
	OVER (
		PARTITION BY id_base_site
		ORDER BY (tbv.visit_date_min)
		RANGE BETWEEN 
            UNBOUNDED PRECEDING AND 
            UNBOUNDED FOLLOWING
	) as last_habitat,
 	LAST_VALUE(tvc.data ->> 'gestion')
	OVER (
		PARTITION BY id_base_site
		ORDER BY (tbv.visit_date_min)
		RANGE BETWEEN 
            UNBOUNDED PRECEDING AND 
            UNBOUNDED FOLLOWING
	) as last_gestion,
 	LAST_VALUE(tvc.data ->> 'impact')
	OVER (
		PARTITION BY id_base_site
		ORDER BY (tbv.visit_date_min)
		RANGE BETWEEN 
            UNBOUNDED PRECEDING AND 
            UNBOUNDED FOLLOWING
	) as last_impact
FROM gn_monitoring.t_base_visits tbv
LEFT JOIN gn_monitoring.t_visit_complements tvc USING (id_base_visit)
WHERE id_module = 33
 ), sd as (
	SELECT
		lv.id_base_site,
		jsonb_build_object(
			'habitat',lv.last_habitat,
			'gestion', lv.last_gestion,
			'impact', lv.last_impact
		) as data
	FROM lv
	LEFT JOIN gn_monitoring.t_site_complements tsc USING (id_base_site)
	WHERE tsc.id_module = 33
	GROUP BY id_base_site,last_habitat, last_gestion, last_impact, tsc.data
	ORDER BY id_base_site
)
UPDATE gn_monitoring.t_site_complements tsc
SET data = sd.data
FROM sd
WHERE sd.id_base_site = tsc.id_base_site