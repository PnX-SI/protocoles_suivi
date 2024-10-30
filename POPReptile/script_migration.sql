-- Script pour migration des données de POPReptile
-- En septembre 2024, nouveau format convenu pour les données POPReptile par la SHF
-- Avant de jouer ce script, il est fortement conseillé d'archiver les anciens schémas (back-up BDD, et/ou back-up csv (...) par exemple avec la requête ci-dessous
-- Après ce script, il est également conseillé de mettre à jour les données de la synthèse

-- Requête pour éventuelle récupération des données avant migration pour POPReptile
SELECT
o.uuid_observation,
tsg.id_sites_group,
tsg.DATA AS sites_group_json,
sc.id_base_site,
sc.DATA AS site_json,
vc.id_base_visit,
vc.DATA AS visit_json,
oc.id_observation,
oc.DATA AS obs_json
FROM gn_monitoring.t_base_visits v
     JOIN gn_monitoring.t_visit_complements vc on v.id_base_visit = vc.id_base_visit 
     JOIN gn_monitoring.t_base_sites s ON s.id_base_site = v.id_base_site        
     JOIN gn_monitoring.t_site_complements sc on sc.id_base_site = s.id_base_site   
     JOIN gn_monitoring.t_sites_groups tsg ON sc.id_sites_group = tsg.id_sites_group
     JOIN gn_commons.t_modules m ON m.id_module = v.id_module
     JOIN gn_monitoring.t_observations o ON o.id_base_visit = v.id_base_visit                  
     JOIN gn_monitoring.t_observation_complements oc ON oc.id_observation = o.id_observation
     LEFT JOIN gn_commons.t_medias tm ON (tm.id_table_location = gn_commons.get_table_location_id('gn_monitoring', 't_observations') AND tm.uuid_attached_row = o.uuid_observation)
     JOIN taxonomie.taxref t ON t.cd_nom = o.cd_nom
WHERE m.module_code = 'popreptile';

----------------
-- POPReptile --
----------------
-- Avec le changement au niveau du formulaire, certains attributs ne sont plus nécessaires et peuvent être supprimés des champs JSON "data".
-- D'autres ont vu leur format / nomenclature revus.
-- D'autres, enfin, ont été déplacés
-- Les requêtes suivantes visent à tout réharmoniser et à faciliter le traitement des informations par la suite, notamment :
-- - l'intégration dans la synthèse des données (y compris, les données d'absence !)
-- - l'uniformisation des vues pour les exports de données
-- On va faire le traitement en bottom-up (d'abord les observations, puis les visites, puis les sites, puis les groupes de sites)

-- T_OBSERVATION_COMPLEMENTS --
-- Modifications à faire :
-- - Harmonisation et cohérence des décomptes
--   Anciens attributs "nombre_compte, nombre_estime_min", "nombre_estime_max", "type_denombrement" à changer en
--   nouveaux "count_min", "count_max" et "id_nomenclature_typ_denbr" ;
-- - Suppression de l'attribut "abondance"
-- - Transformation du "stade_vie" en id_nomenclature_stade
--   Valeurs possibles : "Adultes", "Indéterminé", "Juvéniles", "Nouveaux-nés"

-- Vérifier que cette liste est vide : sinon, il faut probablement contacter les observateurs / prendre une décision par rapport à ces observations
--WITH selection AS
--(
--SELECT
--	oc.id_observation,
--	t.lb_nom,
--	oc.DATA,
--	oc.DATA->>'presence' AS presence,
--	CASE
--		WHEN oc.DATA->>'nombre_compte' IS NOT NULL THEN ref_nomenclatures.get_id_nomenclature('TYP_DENBR', 'Co')
--		WHEN oc.DATA->>'nombre_estime_min' IS NOT NULL THEN ref_nomenclatures.get_id_nomenclature('TYP_DENBR', 'Es')
--		ELSE NULL
--	END AS id_nomenclature_typ_denbr,
--	(oc.DATA->>'nombre_compte')::int AS nb_co,
--	(oc.DATA->>'nombre_estime_min')::int AS nb_es_min,
--	(oc.DATA->>'nombre_estime_max')::int AS nb_es_max,
--	oc.DATA->>'stade_vie' AS stade_vie
--FROM gn_monitoring.t_observation_complements oc
--LEFT JOIN gn_monitoring.t_observations o USING (id_observation)
--LEFT JOIN gn_monitoring.t_base_visits v USING (id_base_visit)
--LEFT JOIN gn_monitoring.t_visit_complements vc USING (id_base_visit)
--LEFT JOIN taxonomie.taxref t USING (cd_nom)
--LEFT JOIN gn_commons.t_modules m USING (id_module)
--WHERE m.module_code = 'popreptile' AND oc."data"->>'count_min' IS NULL
--)
--SELECT * FROM selection;
--WHERE presence = 'Non' AND lb_nom <> 'Squamata'
--ORDER BY id_observation;

-- On pourra également vérifier les erreurs sur les données de présence : il devrait y avoir au minimum un effectif dans l'un des champs.
-- Sinon, il faut décider d'une stratégie de gestion ou contacter les observateurs
--WITH selection AS
--(
--SELECT
--	oc.id_observation,
--	t.lb_nom,
--	oc.DATA,
--	oc.DATA->>'presence' AS presence,
--	CASE
--		WHEN oc.DATA->>'nombre_compte' IS NOT NULL THEN ref_nomenclatures.get_id_nomenclature('TYP_DENBR', 'Co')
--		WHEN oc.DATA->>'nombre_estime_min' IS NOT NULL THEN ref_nomenclatures.get_id_nomenclature('TYP_DENBR', 'Es')
--		ELSE NULL
--	END AS id_nomenclature_typ_denbr,
--	(oc.DATA->>'nombre_compte')::int AS nb_co,
--	(oc.DATA->>'nombre_estime_min')::int AS nb_es_min,
--	(oc.DATA->>'nombre_estime_max')::int AS nb_es_max,
--	oc.DATA->>'stade_vie' AS stade_vie
--FROM gn_monitoring.t_observation_complements oc
--LEFT JOIN gn_monitoring.t_observations o USING (id_observation)
--LEFT JOIN gn_monitoring.t_base_visits v USING (id_base_visit)
--LEFT JOIN gn_monitoring.t_visit_complements vc USING (id_base_visit)
--LEFT JOIN taxonomie.taxref t USING (cd_nom)
--LEFT JOIN gn_commons.t_modules m USING (id_module)
--WHERE m.module_code = 'popreptile' AND oc."data"->>'count_min' IS NULL
--AND oc.DATA->>'presence' = 'Oui'
--)
--SELECT * FROM selection WHERE nb_co IS NULL AND nb_es_min IS NULL AND nb_es_max IS NULL
--ORDER BY id_observation;

-- Gestion des données d'absence
WITH to_update AS
(
SELECT
	oc.id_observation,
	t.lb_nom,
	oc.DATA,
	oc.DATA->>'presence' AS presence,
	CASE
		WHEN oc.DATA->>'nombre_compte' IS NOT NULL THEN ref_nomenclatures.get_id_nomenclature('TYP_DENBR', 'Co')
		WHEN oc.DATA->>'nombre_estime_min' IS NOT NULL THEN ref_nomenclatures.get_id_nomenclature('TYP_DENBR', 'Es')
		ELSE NULL
	END AS id_nomenclature_typ_denbr,
	(oc.DATA->>'nombre_compte')::int AS nb_co,
	(oc.DATA->>'nombre_estime_min')::int AS nb_es_min,
	(oc.DATA->>'nombre_estime_max')::int AS nb_es_max,
	oc.DATA->>'stade_vie' AS stade_vie
FROM gn_monitoring.t_observation_complements oc
LEFT JOIN gn_monitoring.t_observations o USING (id_observation)
LEFT JOIN gn_monitoring.t_base_visits v USING (id_base_visit)
LEFT JOIN gn_monitoring.t_visit_complements vc USING (id_base_visit)
LEFT JOIN taxonomie.taxref t USING (cd_nom)
LEFT JOIN gn_commons.t_modules m USING (id_module)
WHERE m.module_code = 'popreptile' AND oc."data"->>'count_min' IS NULL
AND oc.DATA->>'presence' = 'Non' AND lb_nom = 'Squamata'
)
UPDATE gn_monitoring.t_observation_complements
SET "data" = jsonb_build_object('presence', 'Non') || jsonb_build_object('count_min', 0) || jsonb_build_object('count_max', 0) ||
	jsonb_build_object('id_nomenclature_typ_denbr', NULL) || jsonb_build_object('id_nomenclature_stade', NULL) || jsonb_build_object('id_nomenclature_sex', NULL)
WHERE t_observation_complements.id_observation IN (SELECT id_observation FROM to_update);

-- Gestion des données de présence
WITH selection AS
(
SELECT
	oc.id_observation,
	t.lb_nom,
	oc.DATA,
	oc.DATA->>'presence' AS presence,
	CASE
		WHEN oc.DATA->>'nombre_compte' IS NOT NULL THEN ref_nomenclatures.get_id_nomenclature('TYP_DENBR', 'Co')
		WHEN oc.DATA->>'nombre_estime_min' IS NOT NULL THEN ref_nomenclatures.get_id_nomenclature('TYP_DENBR', 'Es')
		ELSE NULL
	END AS id_nomenclature_typ_denbr,
	(oc.DATA->>'nombre_compte')::int AS nb_co,
	(oc.DATA->>'nombre_estime_min')::int AS nb_es_min,
	(oc.DATA->>'nombre_estime_max')::int AS nb_es_max,
	oc.DATA->>'stade_vie' AS stade_vie
FROM gn_monitoring.t_observation_complements oc
LEFT JOIN gn_monitoring.t_observations o USING (id_observation)
LEFT JOIN gn_monitoring.t_base_visits v USING (id_base_visit)
LEFT JOIN gn_monitoring.t_visit_complements vc USING (id_base_visit)
LEFT JOIN taxonomie.taxref t USING (cd_nom)
LEFT JOIN gn_commons.t_modules m USING (id_module)
WHERE m.module_code = 'popreptile' AND oc."data"->>'count_min' IS NULL
AND oc.DATA->>'presence' = 'Oui'
),
to_update AS 
(SELECT 
id_observation,
presence,
id_nomenclature_typ_denbr,
CASE
	WHEN nb_co = 0 THEN 1 -- Probable erreur de saisie, prise de décision à ce sujet !
	WHEN nb_co IS NOT NULL THEN nb_co
	ELSE nb_es_min
END AS count_min,
CASE
	WHEN nb_co = 0 THEN 1
	WHEN nb_co IS NOT NULL THEN nb_co
	ELSE nb_es_max
END AS count_max,
CASE
	-- Valeurs possibles : "Adultes", "Indéterminé", "Juvéniles", "Nouveaux-nés"
	WHEN stade_vie = 'Indéterminé' THEN ref_nomenclatures.get_id_nomenclature('STADE_VIE', '1')
	WHEN stade_vie = 'Adultes' THEN ref_nomenclatures.get_id_nomenclature('STADE_VIE', '2')
	WHEN stade_vie IN ('Juvéniles', 'Nouveaux-nés') THEN ref_nomenclatures.get_id_nomenclature('STADE_VIE', '3')
	ELSE NULL
END AS id_life_stage,
"data"
FROM selection 
WHERE id_observation NOT IN (SELECT id_observation FROM selection WHERE nb_co IS NULL AND nb_es_min IS NULL AND nb_es_max IS NULL))
UPDATE gn_monitoring.t_observation_complements
SET "data" = jsonb_build_object('presence', u.presence) || jsonb_build_object('count_min', u.count_min) || jsonb_build_object('count_max', u.count_max) ||
	jsonb_build_object('id_nomenclature_typ_denbr', u.id_nomenclature_typ_denbr) || jsonb_build_object('id_nomenclature_stade', u.id_life_stage) || jsonb_build_object('id_nomenclature_sex', NULL)
FROM to_update u
WHERE t_observation_complements.id_observation = u.id_observation;



-- T_VISIT_COMPLEMENTS --
-- Modifications à faire :
-- - retrait des attributs vent, meteo
-- - récupération de la méthode de prospection issues de la description du transect si elle n'est pas déjà renseignée
WITH to_update AS 
(SELECT 
	vc.id_base_visit,
	vc.DATA,
	vc.DATA - 'vent' - 'meteo' AS new_json_data
FROM gn_monitoring.t_visit_complements vc
JOIN gn_monitoring.t_base_visits v USING (id_base_visit)
JOIN gn_commons.t_modules m ON m.id_module = v.id_module
WHERE m.module_code = 'popreptile')
UPDATE gn_monitoring.t_visit_complements vc
SET "data" = new_json_data
FROM to_update tu 
WHERE tu.id_base_visit = vc.id_base_visit;

WITH selection AS 
(
SELECT vc.*,
sc."data"->>'methode_prospection' AS method_p
FROM gn_monitoring.t_visit_complements vc
JOIN gn_monitoring.t_base_visits v USING (id_base_visit)
JOIN gn_commons.t_modules m ON m.id_module = v.id_module
JOIN gn_monitoring.t_site_complements sc ON sc.id_base_site = v.id_base_site
WHERE m.module_code = 'popreptile' AND sc."data"->>'methode_prospection' IS NOT NULL AND vc."data"->>'methode_prospection' IS NULL),
to_update AS
(SELECT *,
CASE 
	WHEN method_p = 'Par plaques uniquement' THEN ARRAY['Par plaques']
	WHEN method_p = 'Par plaques et observation directe' THEN ARRAY['Par observation directe', 'Par plaques']
	ELSE ARRAY['Par observation directe']
END AS methode_prospection
FROM selection)
UPDATE gn_monitoring.t_visit_complements vc
SET "data" = u."data" || jsonb_build_object('methode_prospection', u.methode_prospection)
FROM to_update u 
WHERE u.id_base_visit = vc.id_base_visit;

-- T_SITE_COMPLEMENTS --
-- Modifications à faire :
-- - récupération du nombre de plaques, à mettre dans les commentaires du transect
-- - retrait des attributs milieu_bordier, type_materiaux, milieu_homogene, milieu_anthropique, frequentation_humaine, milieu_transect_autre, 
--   microhabitat_favorable, milieu_mosaique_vegetale, methode_prospection

WITH selection AS 
(SELECT tc.id_base_site,
tc.DATA->>'nb_plaques' AS nb_plaques
FROM gn_monitoring.t_site_complements tc
JOIN gn_commons.t_modules m ON m.id_module = tc.id_module
WHERE m.module_code = 'popreptile'),
to_update AS
(SELECT id_base_site, 
CASE WHEN base_site_description IS NULL THEN concat('nb plaques: ', nb_plaques)
ELSE concat(base_site_description, ' | nb plaques: ', nb_plaques)
END AS new_description
FROM selection
LEFT JOIN gn_monitoring.t_base_sites USING (id_base_site)
WHERE nb_plaques IS NOT NULL)
UPDATE gn_monitoring.t_base_sites s
SET base_site_description = new_description
FROM to_update u
WHERE u.id_base_site = s.id_base_site;

WITH to_update AS 
(SELECT tc.id_base_site,
tc.DATA - 'nb_plaques' - 'milieu_bordier' - 'type_materiaux' - 'milieu_homogene' - 'milieu_anthropique' - 'frequentation_humaine' - 'milieu_transect_autre' - 'microhabitat_favorable' - 'milieu_mosaique_vegetale' - 'methode_prospection'
AS new_json_data
FROM gn_monitoring.t_site_complements tc
JOIN gn_commons.t_modules m ON m.id_module = tc.id_module
WHERE m.module_code = 'popreptile')
UPDATE gn_monitoring.t_site_complements tc
SET "data" = new_json_data
FROM to_update u 
WHERE u.id_base_site = tc.id_base_site;

-- T_SITE_GROUPS --
-- Modifications à faire :
-- - retrait de l'attribut "expertise"
WITH to_update AS 
(SELECT tg.id_sites_group, tg.DATA - 'expertise' AS new_json_data FROM gn_monitoring.t_sites_groups tg
JOIN gn_commons.t_modules m ON m.id_module = tg.id_module
WHERE m.module_code = 'popreptile')
UPDATE gn_monitoring.t_sites_groups tg
SET "data" = tu.new_json_data
FROM to_update tu 
WHERE tu.id_sites_group = tg.id_sites_group;

-- Changement du type de site
-- Dans la première implémentation du module POPR, les types de sites étaient mis par défaut au code_nomenclature "7" qui correspond à un gite chiro indeterminé.
-- Il faut donc le modifier.
-- TODO En fonction de la version du monitoring dont vous disposez (pre 1.0.0 ou post 1.0.0), vous devez utiliser une méthode différente.
WITH to_update AS
(SELECT tc.id_base_site FROM gn_monitoring.t_site_complements tc
JOIN gn_commons.t_modules m ON m.id_module = tc.id_module
WHERE m.module_code = 'popreptile')
UPDATE gn_monitoring.t_base_sites 
SET id_nomenclature_type_site = ref_nomenclatures.get_id_nomenclature('TYPE_SITE', 'POPR')
WHERE t_base_sites.id_base_site IN (SELECT id_base_site FROM to_update);
