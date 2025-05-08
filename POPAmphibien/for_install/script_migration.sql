-- Script pour migration des données de POPAmphibien
-- En janvier 2025, nouveau format convenu pour les données
-- Avant de jouer ce script, il est fortement conseillé d'archiver les anciens schémas (back-up BDD, et/ou back-up csv (...) par exemple avec les deux requêtes ci-dessous)
-- Après ce script, il est également conseillé de mettre à jour les données de la synthèse

-- Requête pour éventuelle récupération des données avant migration pour POPAmphibien
CREATE TABLE perso.tmp_bkp_monitoring_popa AS (SELECT
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
							WHERE m.module_code ilike 'popamphibien';
-- On sauvegarde aussi les nomenclatures qu'on suppprimera pour garder une correspondance des IDs !
CREATE TABLE perso.tmp_bkp_monitoring_popa_nomenclature AS (SELECT
								*
								FROM ref_nomenclatures.t_nomenclatures n
								WHERE n.id_type IN (SELECT id_type FROM ref_nomenclatures.bib_nomenclatures_types WHERE mnemonique
IN ('TURBIDITE', 'VARIATION_EAU', 'COURANT_EAU', 'VEGETATION_AQUATIQUE', 'RIVES', 'HABITAT_TERRESTRE_MAJORITAIRE', 'ACTIVITE_HUMAINE', 'PLUVIOSITE', 'COUVERTURE_NUAGEUSE', 'VENT'))

------------------
-- POPAmphibien --
------------------
-- Avec le changement au niveau du formulaire, certains attributs ne sont plus nécessaires et peuvent être supprimés des champs JSON "data".
-- D'autres ont vu leur format / nomenclature revus.
-- D'autres, enfin, ont été déplacés
-- Les requêtes suivantes visent à tout réharmoniser et à faciliter le traitement des informations par la suite, notamment :
-- - l'intégration dans la synthèse des données (y compris, les données d'absence !)
-- - l'uniformisation des vues pour les exports de données
-- On va faire le traitement en bottom-up (d'abord les observations, puis les visites, puis les sites, puis les groupes de sites)

-- T_OBSERVATION_COMPLEMENTS --
-- Modifications à faire :
-- - S'assurer que les décomptes (count_min et count_max) sont corrects ;
-- - Aucune suppression d'attributs du formulaire ;
-- - Ajout de l'attribut "presence" dans le formulaire.

/*todo : attention, script à personnaliser pour restreindre aux données à mettre à jour (pop amphibien de l'ancien module uniquement*/

-- Harmonisation des décomptes (count_min et count_max)
BEGIN;

WITH liste AS
(
SELECT oc.*,
oc."data"->>'count_max' AS count_max,
oc."data"->>'count_min' AS count_min
FROM gn_monitoring.t_observation_complements oc
LEFT JOIN gn_monitoring.t_observations o USING (id_observation)
LEFT JOIN gn_monitoring.t_base_visits v USING (id_base_visit)
LEFT JOIN gn_monitoring.t_visit_complements vc USING (id_base_visit)
LEFT JOIN gn_commons.t_modules m USING (id_module)
WHERE m.module_code ilike 'popamphibien' AND oc."data"->>'presence' IS NULL AND (oc."data"->>'id_nomenclature_typ_denbr') IS NULL
), to_update AS
(SELECT
id_observation,
CASE
	WHEN count_min = count_max THEN ref_nomenclatures.get_id_nomenclature('TYP_DENBR', 'Co')
	ELSE ref_nomenclatures.get_id_nomenclature('TYP_DENBR', 'Es')
END AS id_nomenclature_typ_denbr
FROM liste)
UPDATE gn_monitoring.t_observation_complements oc
SET "data" = oc."data" || jsonb_build_object('id_nomenclature_typ_denbr', id_nomenclature_typ_denbr)
FROM to_update u
WHERE oc.id_observation = u.id_observation;

WITH to_update AS
(
SELECT oc.*,
CASE
	WHEN ref_nomenclatures.get_cd_nomenclature((oc."data"->>'id_nomenclature_typ_denbr')::int) = 'Es' THEN 1
	ELSE (oc."data"->>'count_max')::int
END AS new_count_min
FROM gn_monitoring.t_observation_complements oc
LEFT JOIN gn_monitoring.t_observations o USING (id_observation)
LEFT JOIN gn_monitoring.t_base_visits v USING (id_base_visit)
LEFT JOIN gn_monitoring.t_visit_complements vc USING (id_base_visit)
LEFT JOIN gn_commons.t_modules m USING (id_module)
WHERE m.module_code ilike 'popamphibien' AND oc."data"->>'presence' IS NULL AND oc."data"->>'count_min' IS NULL
)
UPDATE gn_monitoring.t_observation_complements oc
SET "data" = oc."data" || jsonb_build_object('count_min', u.new_count_min)
FROM to_update u
WHERE oc.id_observation = u.id_observation;

WITH to_update AS
(
SELECT oc.*,
CASE
	WHEN ref_nomenclatures.get_cd_nomenclature((oc."data"->>'id_nomenclature_typ_denbr')::int) = 'Co' THEN (oc."data"->>'count_min')::int
	ELSE NULL
END AS new_count_max
FROM gn_monitoring.t_observation_complements oc
LEFT JOIN gn_monitoring.t_observations o USING (id_observation)
LEFT JOIN gn_monitoring.t_base_visits v USING (id_base_visit)
LEFT JOIN gn_monitoring.t_visit_complements vc USING (id_base_visit)
LEFT JOIN gn_commons.t_modules m USING (id_module)
WHERE m.module_code ilike 'popamphibien' AND oc."data"->>'presence' IS NULL AND oc."data"->>'count_max' IS NULL
)
UPDATE gn_monitoring.t_observation_complements oc
SET "data" = oc."data" || jsonb_build_object('count_max', u.new_count_max)
FROM to_update u
WHERE oc.id_observation = u.id_observation;

-- Ajout de l'attribut "presence"
-- Ce champ était auparavant au niveau de la visite (attribut JSON "data" dans t_visit_complements, "presence_amphibien"). Il est maintenant au niveau de l'observation.
-- À faire :
-- - Pour les visites où il a été indiqué "presence_amphibien" à "Non", créer une observation rattachée à la visite, de données d'absence, avec ces informations :
--    - cd_nom : 914450 (absence)
--    - presence : 'Non'
--    - count_min : 0
--    - count_max : 0
-- - Pour les visites où il a été indiqué "presence_amphibien" à "Oui" observations d'Amphibiens, il faut ajouter le champ "presence" et le mettre à "Oui" dans les observations associées.

-- Cependant, en amont, on vérifie que lorsqu'on a "presence_amphibien" mis à "Non", on n'a réellement PAS d'observation (d'amphibiens !) associés !
-- Sur certaines visites, on peut avoir eu une erreur de saisie dans la visite, et finalement, des observations d'amphibiens.
-- Dans ce cas, on peut corriger le champ avec cette requête :
-- UPDATE gn_monitoring.t_visit_complements v
-- SET DATA = "data" || jsonb_build_object('presence_amphibien', 'Oui')
-- FROM gn_monitoring.t_base_visits t
-- WHERE t.id_base_visit IN (XXX)
-- AND t.id_base_visit = v.id_base_visit;
-- où XXX est une liste des visites identifiées comme à modifer, qu'on aura pu vérifier à la main, par exemple avec cette requête :
--WITH presence_amphibiens AS
--  (SELECT
--  vc.id_base_visit,
--	vc.DATA->>'presence_amphibien' AS presence_amphibien,
--	vc.DATA AS dataz,
--	o.*
--  FROM gn_monitoring.t_visit_complements vc
--  JOIN gn_monitoring.t_base_visits v USING (id_base_visit)
--  JOIN gn_commons.t_modules m ON m.id_module = v.id_module
--  LEFT JOIN gn_monitoring.t_observations o USING (id_base_visit)
--  WHERE m.module_code ilike 'popamphibien')
--SELECT * FROM presence_amphibiens
--WHERE presence_amphibien = 'Non' AND id_observation IS NOT NULL;
WITH selection AS
(SELECT oc.*,
vc."data"->>'presence_amphibien' AS presence_amphibien
FROM gn_monitoring.t_observation_complements oc
LEFT JOIN gn_monitoring.t_observations o USING (id_observation)
LEFT JOIN gn_monitoring.t_base_visits v USING (id_base_visit)
LEFT JOIN gn_monitoring.t_visit_complements vc USING (id_base_visit)
LEFT JOIN gn_commons.t_modules m USING (id_module)
WHERE m.module_code ilike 'popamphibien' AND oc."data"->>'presence' IS NULL
)
UPDATE gn_monitoring.t_observation_complements oc
SET "data" = oc."data" || jsonb_build_object('presence', s.presence_amphibien)
FROM selection s
WHERE oc.id_observation = s.id_observation;

WITH selection AS (
SELECT DISTINCT vc.*
FROM gn_monitoring.t_base_visits v
LEFT JOIN gn_monitoring.t_visit_complements vc USING (id_base_visit)
LEFT JOIN gn_commons.t_modules m USING (id_module)
LEFT JOIN gn_monitoring.t_observations o USING (id_base_visit)
WHERE m.module_code ilike 'popamphibien' AND vc."data"->>'presence_amphibien' = 'Non' AND o.id_observation IS NULL
)
INSERT INTO gn_monitoring.t_observations (id_base_visit, cd_nom)
SELECT id_base_visit, 914450 FROM selection;

WITH selection AS (
SELECT DISTINCT o.id_observation
FROM gn_monitoring.t_base_visits v
LEFT JOIN gn_monitoring.t_visit_complements vc USING (id_base_visit)
LEFT JOIN gn_commons.t_modules m USING (id_module)
LEFT JOIN gn_monitoring.t_observations o USING (id_base_visit)
WHERE m.module_code ilike 'popamphibien' AND vc."data"->>'presence_amphibien' = 'Non' AND o.cd_nom = 914450
)
INSERT INTO gn_monitoring.t_observation_complements (id_observation, "data")
SELECT id_observation, (jsonb_build_object('count_min', 0) || jsonb_build_object('count_max', 0) || jsonb_build_object('presence', 'Non')) FROM selection;

-- T_VISIT_COMPLEMENTS --
-- Modifications à faire :
-- - retrait des attributs vent, rives, turbidite, pluviosite, couverture_nuageuse, vegetation_aquatique_principale, activite_humaine, habitat_terrestre_environnant, presence_amphibien
-- - conversion du numéro de passage (en nombre, en gardant le premier character de la chaîne)
WITH to_update AS
(SELECT
	vc.id_base_visit,
	vc.DATA,
	left(vc.DATA->>'num_passage', 1)::integer AS num_passage,
	vc.DATA - 'vent' - 'rives' - 'turbidite' - 'pluviosite' - 'activite_humaine' - 'couverture_nuageuse'
	- 'vegetation_aquatique_principale' - 'habitat_terrestre_environnant' - 'num_passage' - 'presence_amphibien' AS new_json_data
FROM gn_monitoring.t_visit_complements vc
JOIN gn_monitoring.t_base_visits v USING (id_base_visit)
JOIN gn_commons.t_modules m ON m.id_module = v.id_module
WHERE m.module_code ilike 'popamphibien')
UPDATE gn_monitoring.t_visit_complements vc
SET "data" = new_json_data || jsonb_build_object('num_passage', num_passage)
FROM to_update tu
WHERE tu.id_base_visit = vc.id_base_visit;

-- T_SITE_COMPLEMENTS --
-- Modifications à faire :
-- - retrait des attributs courant, variation_eau
WITH to_update AS
(SELECT tc.id_base_site, tc.DATA - 'courant' - 'variation_eau' AS new_json_data FROM gn_monitoring.t_site_complements tc
JOIN gn_commons.t_modules m ON m.id_module = tc.id_module
WHERE m.module_code ilike 'popamphibien')
UPDATE gn_monitoring.t_site_complements tc
SET "data" = tu.new_json_data
FROM to_update tu
WHERE tu.id_base_site = tc.id_base_site;

-- T_SITE_GROUPS --
-- Modifications à faire :
-- - retrait de l'attribut "commune"
WITH to_update AS
(SELECT tg.id_sites_group, tg.DATA - 'commune' AS new_json_data FROM gn_monitoring.t_sites_groups tg
JOIN gn_commons.t_modules m ON m.id_module = tg.id_module
WHERE m.module_code ilike 'popamphibien')
UPDATE gn_monitoring.t_sites_groups tg
SET "data" = tu.new_json_data
FROM to_update tu
WHERE tu.id_sites_group = tg.id_sites_group;


-- Evolution nomenclatures POPAmphibien --
------------------------------------------
-- Certaines nomenclatures ne sont plus utilisées, on peut donc les supprimer :
-- TURBIDITE, VARIATION_EAU, COURANT_EAU, VEGETATION_AQUATIQUE, RIVES, HABITAT_TERRESTRE_MAJORITAIRE, ACTIVITE_HUMAINE, PLUVIOSITE, COUVERTURE_NUAGEUSE, VENT
-- D'autres ont été modifiées : on va répercuter ces changements.
DELETE FROM ref_nomenclatures.t_nomenclatures n
WHERE n.id_type IN (SELECT id_type FROM ref_nomenclatures.bib_nomenclatures_types WHERE mnemonique
IN ('TURBIDITE', 'VARIATION_EAU', 'COURANT_EAU', 'VEGETATION_AQUATIQUE', 'RIVES', 'HABITAT_TERRESTRE_MAJORITAIRE', 'ACTIVITE_HUMAINE', 'PLUVIOSITE', 'COUVERTURE_NUAGEUSE', 'VENT'));
DELETE FROM ref_nomenclatures.bib_nomenclatures_types b
WHERE b.mnemonique IN ('TURBIDITE', 'VARIATION_EAU', 'COURANT_EAU', 'VEGETATION_AQUATIQUE', 'RIVES', 'HABITAT_TERRESTRE_MAJORITAIRE', 'ACTIVITE_HUMAINE', 'PLUVIOSITE', 'COUVERTURE_NUAGEUSE', 'VENT');

UPDATE ref_nomenclatures.t_nomenclatures t
SET mnemonique = 'Ruisselet'
WHERE t.mnemonique = 'Ruissele' AND cd_nomenclature = 'MILIEU_AQUATIQUE_3';
UPDATE ref_nomenclatures.t_nomenclatures t
SET label_default = 'Mare (< 50 m²)',
definition_default = 'Mare (< 50 m²)'
WHERE t.mnemonique = 'Mare' AND cd_nomenclature = 'MILIEU_AQUATIQUE_7';
UPDATE ref_nomenclatures.t_nomenclatures t
SET mnemonique = 'Prairies'
WHERE t.mnemonique = 'Prairiese' AND cd_nomenclature = 'CATEGORIE_PAYSAGERE_3';
UPDATE ref_nomenclatures.bib_nomenclatures_types b
SET definition_default = 'Catégories paysagères (protocole de suivi POPAmphibien)'
WHERE b.mnemonique = 'CATEGORIE_PAYSAGERE';
UPDATE ref_nomenclatures.bib_nomenclatures_types b
SET definition_default = 'Milieu aquatique (protocole de suivi POPAmphibien)'
WHERE b.mnemonique = 'MILIEU_AQUATIQUE';
UPDATE ref_nomenclatures.bib_nomenclatures_types b
SET definition_default = 'Méthode de prospection (protocole de suivi POPAmphibien)'
WHERE b.mnemonique = 'METHODE_PROSPECTION';
UPDATE ref_nomenclatures.t_nomenclatures t
SET cd_nomenclature = RIGHT(cd_nomenclature, 1)
WHERE id_type IN (SELECT id_type FROM ref_nomenclatures.bib_nomenclatures_types WHERE mnemonique = 'METHODE_PROSPECTION');
UPDATE ref_nomenclatures.t_nomenclatures t
SET definition_default = 'Capture à l’épuisette (dérogation préfectorale obligatoire)', definition_fr = 'Capture à l’épuisette (dérogation préfectorale obligatoire)'
WHERE cd_nomenclature = '2' AND mnemonique = 'Capture_épuisette';

-- Changement du type de site
-- Dans la première implémentation du module POPA, les types de sites étaient mis par défaut au code_nomenclature "7" qui correspond à un gite chiro indeterminé.
-- Il faut donc le modifier.
-- TODO En fonction de la version du monitoring dont vous disposez (pre 1.0.0 ou post 1.0.0, vous devez utiliser une méthode différente).
WITH to_update AS
(SELECT tc.id_base_site FROM gn_monitoring.t_site_complements tc
JOIN gn_commons.t_modules m ON m.id_module = tc.id_module
WHERE m.module_code ilike 'popamphibien')
UPDATE gn_monitoring.t_base_sites
SET id_nomenclature_type_site = ref_nomenclatures.get_id_nomenclature('TYPE_SITE', 'POPA')
WHERE t_base_sites.id_base_site IN (SELECT id_base_site FROM to_update);

COMMIT;
