DROP VIEW gn_monitoring.vs_visits CASCADE;
CREATE VIEW gn_monitoring.vs_visits AS

WITH observers AS
	(SELECT
		cvo.id_base_visit,
		STRING_AGG(CONCAT(r.nom_role, ' ', prenom_role), ' & ') AS observers
		FROM gn_monitoring.cor_visit_observer cvo
		JOIN utilisateurs.t_roles r
			ON r.id_role = cvo.id_role
		GROUP BY cvo.id_base_visit
	)
SELECT 
	v.id_module,
	v.uuid_base_visit,
	v.id_base_visit,
	v.id_dataset,
	id_nomenclature_obs_technique,
	id_nomenclature_grp_typ,
	v.visit_date_min AS date_min,
	CASE 
		WHEN v.visit_date_max IS NULL THEN v.visit_date_min
		ELSE visit_date_max
	END AS date_max,
	v.comments AS comment_description,
	s.geom AS the_geom_4326,
	ST_CENTROID(s.geom) AS the_geom_point, 
	o.observers
	
	FROM gn_monitoring.t_base_visits v
	JOIN gn_monitoring.t_base_sites s ON v.id_base_site = s.id_base_site
	JOIN observers o  ON o.id_base_visit = v.id_base_visit;

DROP VIEW IF EXISTS gn_monitoring.vs_cheveches;
CREATE VIEW gn_monitoring.vs_cheveches AS
	SELECT 
		CASE 
			WHEN n.cd_nomenclature = 'Pr' THEN 1
			ELSE 0 
		END AS count_min,
		CASE 
			WHEN n.cd_nomenclature = 'Pr' THEN 1
			ELSE 0 
		END AS count_max,
		(vc.data->>'cd_nom')::int AS cd_nom,
		t.nom_complet AS nom_cite,
		v.uuid_base_visit AS unique_id_sinp, 
		v.* 

	FROM gn_monitoring.vs_visits v
	JOIN gn_commons.t_modules m ON m.id_module = v.id_module
	JOIN gn_monitoring.t_visit_complements vc ON vc.id_base_visit = v.id_base_visit 
	JOIN ref_nomenclatures.t_nomenclatures n ON n.id_nomenclature = (vc.data->>'id_nomenclature_statut_obs')::int
	JOIN taxonomie.taxref t ON cd_nom = (vc.data->>'cd_nom')::int

	WHERE m.module_path = 'cheveches';

SELECT * FROM gn_monitoring.vs_cheveches LIMIT 1;


