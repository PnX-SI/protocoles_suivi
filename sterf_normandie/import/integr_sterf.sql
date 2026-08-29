WITH 
sterf_transect as (
	SELECT
		*
	FROM gn_monitoring.t_base_sites tbs
	LEFT JOIN gn_monitoring.t_site_complements tsc USING (id_base_site)
	WHERE id_module = 32
),
visits as (
	SELECT
		s.transect,
		s.id_visit_sterf,
		r.id_role,
		s.visit_date_min
	FROM gn_imports.sterf_import s
	LEFT JOIN utilisateurs.t_roles r ON s.determiner = (r.nom_role || ' ' || r.prenom_role)
	WHERE id_base_visit IS NULL
	GROUP BY 	 
		s.transect,
		r.id_role,
		s.id_visit_sterf,
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
	sterf_transect.id_base_site,
	1342 as id_dataset, -- jdd STELI
	32 as id_module, -- module STELI
	visits.id_role as id_digitiser,
	visits.visit_date_min,
	visits.visit_date_min,
	240 as id_nomenclature_tech_collect_campanule , -- Observation directe terrestre diurne (chasse à vue de jour)
	132 as id_nomenclature_grp_typ , -- Passage
	visits.id_visit_sterf as comments
FROM visits
LEFT JOIN sterf_transect on lower(sterf_transect.base_site_name) = lower(visits.transect)
ORDER BY extract(year from visit_date_min ), id_base_site, visit_date_min
;

UPDATE gn_imports.sterf_import s
	SET id_base_visit = tbv.id_base_visit
FROM  gn_monitoring.t_base_visits tbv
WHERE tbv.comments = s.id_visit_sterf::text
AND tbv.id_module = 32
AND s.id_base_visit IS NULL
;

WITH
	nomen_cn as (
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
	), observers as (
		SELECT
			r.id_role,
			s.id_visit_sterf
		FROM gn_imports.sterf_import s
		LEFT JOIN utilisateurs.t_roles r ON lower(s.determiner) =  lower(r.nom_role || ' ' || r.prenom_role)
		WHERE s.annee = 2024
		GROUP BY s.id_visit_sterf, r.id_role
	),
	visits as (
	SELECT
		s.transect,
		s.id_base_visit,
		s.id_visit_sterf,
		s.determiner,
		1342 as id_dataset,
		32 as id_module,
		s.visit_date_min,
		240 as id_nomenclature_tech_collect_campanule,
		132 as id_nomenclature_grp_typ,
		visit_comment,
		jsonb_build_object(
			'annee', 2024,
			'id_horaire_meteo', s.id_visit_sterf,
			'id_unique_mysql', s.id_transect_sterf || '_' || s.annee || '_' || s.num_passage,
			'num_passage', s.num_passage,
			'id_nomenclature_cn', nomen_cn.id_nomenclature_cn,
			'id_nomenclature_tp', nomen_tp.id_nomenclature_tp,
			'id_nomenclature_vt', nomen_vt.id_nomenclature_vt,
			'source', 'Intranet SER / 2024',
			'heure_debut', STRING_AGG(DISTINCT s.heure_min, ', '),
			'hab_1', STRING_AGG(DISTINCT s.hab_1, ', '),
			'hab_2',  STRING_AGG(DISTINCT s.hab_2, ', '),
			'occ_sol', STRING_AGG(DISTINCT s.os_1, ', '),
			'occ_sol_detail',  STRING_AGG(DISTINCT s.os_2, ', ')
		) as data
	FROM gn_imports.sterf_import s
		LEFT JOIN gn_monitoring.t_visit_complements tvc USING (id_base_visit)
		LEFT JOIN nomen_cn USING (cn)
		LEFT JOIN nomen_tp USING (tp)
		LEFT JOIN nomen_vt USING (vt)
		WHERE tvc.id_base_visit IS NULL --AND s.annee = 2024
	GROUP BY 	 
		s.transect, 
		s.id_transect_sterf,
		s.id_base_visit,
		s.num_passage,
		s.determiner,
		s.id_visit_sterf,
		s.annee,
		s.visit_date_min,
		s.visit_comment,
		nomen_cn.id_nomenclature_cn,
		nomen_tp.id_nomenclature_tp,
		nomen_vt.id_nomenclature_vt
	ORDER BY 
		s.transect, 
		s.num_passage,
		s.visit_date_min
)
INSERT INTO gn_monitoring.t_visit_complements (
	id_base_visit,
	data
)
SELECT
	v.id_base_visit,
	v.data
FROM visits v
ORDER BY v.id_base_visit
;

WITH observers as (
	SELECT
		i.id_base_visit,
		v.id_digitiser as id_role
	FROM gn_imports.sterf_import i
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

INSERT INTO gn_monitoring.t_observations (
	id_base_visit,
	cd_nom,
	comments
)
SELECT 
	s.id_base_visit,
	s.cd_nom,
	s.id_obs_sterf::text
FROM gn_imports.sterf_import s
WHERE  s.id_observation IS NULL
AND NOT id_base_visit IS NULL
--AND s.annee = 2024
;

UPDATE gn_imports.sterf_import i
	SET id_observation = o.id_observation
FROM gn_monitoring.t_observations o
LEFT JOIN gn_monitoring.t_base_visits v USING (id_base_visit)
WHERE v.id_module = 32 AND i.id_obs_sterf::text = o.comments
AND i.id_observation IS NULL 
;

WITH obs as (
	SELECT
		oc.*
	FROM gn_monitoring.t_observation_complements oc
	LEFT JOIN gn_monitoring.t_observations o USING (id_observation)
	LEFT JOIN gn_monitoring.t_base_visits v USING (id_base_visit)
	WHERE v.id_module = 32
)
INSERT INTO gn_monitoring.t_observation_complements (
	id_observation,
	data
)
SELECT
	i.id_observation,
	jsonb_strip_nulls(
		jsonb_build_object(
			'effectif', i.effectif,
			'nb_male', i.nb_male,
			'nb_femelle', i.nb_femelle,
			'determiner', i.determiner,
			'id_obs_mysql', i.id_obs_sterf,
			'id_nomenclature_obs_technique', 37,
			'id_nomenclature_determination_method', 453,
			'id_nomenclature_type_count', 89,
			'id_nomenclature_obj_count', 143
		)
	) as data
FROM gn_imports.sterf_import i
LEFT JOIN obs USING (id_observation)
WHERE obs.id_observation IS NULL
ORDER BY i.id_observation
;

WITH obs as (
	SELECT
		oc.*
	FROM gn_monitoring.t_observation_complements oc
	LEFT JOIN gn_monitoring.t_observations o USING (id_observation)
	LEFT JOIN gn_monitoring.t_base_visits v USING (id_base_visit)
	WHERE v.id_module = 32
)
SELECT
	i.*
FROM gn_imports.sterf_import i
LEFT JOIN obs USING (id_observation)
WHERE obs.id_observation is null
;

WITH obs_cmt as (
	SELECT 
		id_observation,
		STRING_AGG(DISTINCT obs_comment, ', ') as comments
	FROM gn_imports.sterf_import
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
	FROM gn_imports.sterf_import
	LEFT JOIN gn_monitoring.t_base_visits v USING (id_base_visit)
	WHERE id_observation is not null AND v.id_module = 32
	GROUP BY 
		id_base_visit
)
UPDATE gn_monitoring.t_base_visits vis
	SET comments = vis_cmt.comments
FROM vis_cmt 
WHERE vis.id_base_visit = vis_cmt.id_base_visit  and not vis_cmt.comments = vis.comments
and vis.id_module = 32
;