-- Script d'exemple de migration depuis le module Sterf présent sur le dépôt
-- PnX-SI/protocoles_suivi avant la publication de ce module. Ne lancez pas ce
-- script sans avoir consulté auparavant la documentation qui l'accompagne.

--
-- GROUPES DE SITES
--

-- Création des groupes de sites.
INSERT INTO gn_monitoring.t_sites_groups
(sites_group_name, sites_group_code, sites_group_description, uuid_sites_group, id_digitiser)
SELECT base_site_name, '', base_site_description, uuid_generate_v4(), id_digitiser
FROM gn_monitoring.t_base_sites tbs
JOIN gn_monitoring.cor_site_type cst USING (id_base_site)
JOIN gn_monitoring.cor_module_type cmt USING (id_type_site)
JOIN gn_commons.t_modules tm USING (id_module)
WHERE module_code = 'sterf';

-- Association des transects à leurs groupes de sites, en utilisant le fait
-- qu'ils aient le même nom (libre à vous de créer une liaison différente).
-- Attention ça ratisse large, on part du principe que tous les groupes de
-- sites créés dans la journée sont concernés par la migration.
UPDATE gn_monitoring.t_site_complements tsc
SET id_sites_group = sites.id_sites_group
FROM (
   SELECT id_base_site, id_sites_group
   FROM gn_monitoring.t_sites_groups tsg
   JOIN gn_monitoring.t_base_sites tbs ON tbs.base_site_name = tsg.sites_group_name
   WHERE EXTRACT(DAY FROM tsg.meta_create_date) = EXTRACT(DAY FROM NOW())
) sites
WHERE tsc.id_base_site = sites.id_base_site;

-- Association des nouveaux groupes de sites avec le module Sterf actuel.
-- Pareil, ça s'applique à tous les groupes de sites créés aujourd'hui.
INSERT INTO gn_monitoring.cor_sites_group_module
SELECT
   id_sites_group,
   gn_commons.get_id_module_bycode('sterf') AS id_module
FROM gn_monitoring.t_sites_groups
WHERE EXTRACT(DAY FROM meta_create_date) = EXTRACT(DAY FROM NOW());

-- Import des attributs d'habitats de niveau 1.
UPDATE gn_monitoring.t_sites_groups tsg
SET "data" = COALESCE(tsg."data", jsonb_build_object()) || jsonb_build_object(
   'habitat_main_1',
   ref_nomenclatures.get_id_nomenclature(
       'STERF_HAB_N1',
       'HAB1_' || SUBSTRING(tsc.data->>'habitat_1' FROM 1 FOR 1)
   )
)
FROM gn_monitoring.t_base_sites tbs
JOIN gn_monitoring.t_site_complements tsc USING (id_base_site)
WHERE
   EXTRACT(DAY FROM tsg.meta_create_date) = EXTRACT(DAY FROM NOW())
   AND tsg.id_sites_group = tsc.id_sites_group
   AND tsc.data ? 'habitat_1';

-- Import des attributs d'habitats de niveau 2.
-- On commence par récupérer les infos de nomenclatures d'habitats des deux
-- premiers niveaux, le niveau 2 dépendant du premier.
WITH
   hab_n1 AS (
       SELECT id_nomenclature, mnemonique
       FROM ref_nomenclatures.t_nomenclatures
       WHERE id_type = ref_nomenclatures.get_id_nomenclature_type('STERF_HAB_N1')
   ),
   hab_n2 AS (
       SELECT id_nomenclature, cd_nomenclature, label_default
       FROM ref_nomenclatures.t_nomenclatures
       WHERE id_type = ref_nomenclatures.get_id_nomenclature_type('STERF_HAB_N2')
   )
UPDATE gn_monitoring.t_sites_groups tsg
SET "data" = tsg.data || jsonb_build_object('habitat_main_2', hab_n2.label_default)
FROM gn_monitoring.t_base_sites tbs
JOIN gn_monitoring.t_site_complements tsc USING (id_base_site)
JOIN gn_monitoring.t_sites_groups tsg_ USING (id_sites_group)
JOIN hab_n1
   ON hab_n1.id_nomenclature = (tsg_.data->'habitat_main_1')::int
JOIN hab_n2
   ON hab_n2.cd_nomenclature = CONCAT(
        -- On reconstitue le code HAB2_x_y en fonction de X le niveau 1 et
        -- Y le niveau 2. Il y a une subtilité : pour les niveaux 1 A et B,
        -- les niveaux 2 sont les mêmes, donc il s'agit de la même
        -- nomenclature pour les deux (HAB2_AB_y).
       'HAB2_',
       CASE hab_n1.mnemonique
           WHEN 'A' THEN 'AB'
           WHEN 'B' THEN 'AB'
           ELSE hab_n1.mnemonique
       END,
       '_',
       UPPER(SUBSTRING(tsc.data->>'habitat_2' FROM 1 FOR 1))
   )
WHERE
   EXTRACT(DAY FROM tsg.meta_create_date) = EXTRACT(DAY FROM NOW())
   AND tsg.id_sites_group = tsc.id_sites_group
   AND tsg.data ? 'habitat_main_1'
   AND tsc.data ? 'habitat_2';

-- On intègre nos transects dans le nouveau module.
-- Ils restent accessibles depuis l'ancien module.
INSERT INTO gn_monitoring.cor_sites_group_module
SELECT id_sites_group, gn_commons.get_id_module_bycode('sterf_ebms')
FROM gn_monitoring.t_sites_groups
JOIN gn_monitoring.cor_sites_group_module USING (id_sites_group)
WHERE id_module = gn_commons.get_id_module_bycode('sterf');

-- On change le type des sites de l'ancien module vers le nouveau.
UPDATE gn_monitoring.cor_site_type
SET id_type_site = ref_nomenclatures.get_id_nomenclature('TYPE_SITE', 'EBMS_SEC')
WHERE id_type_site = ref_nomenclatures.get_id_nomenclature('TYPE_SITE', 'STERF');

--
-- VISITES
--

-- Rattachement des visites au nouveau module.
UPDATE gn_monitoring.t_base_visits
SET id_module = gn_commons.get_id_module_bycode('sterf_ebms')
WHERE id_module = gn_commons.get_id_module_bycode('sterf');

--
-- OBSERVATIONS
--

-- Import des attributs de comptage.
WITH visit_sterf AS (
   SELECT id_base_visit
   FROM gn_monitoring.t_base_visits
   WHERE id_module = (SELECT id_module FROM gn_commons.t_modules WHERE module_code = 'sterf_ebms')
),
observation_sterf AS (
   SELECT id_observation
   FROM gn_monitoring.t_observations
   WHERE id_base_visit IN (SELECT id_base_visit FROM visit_sterf)
)
UPDATE gn_monitoring.t_observation_complements
SET data=data || jsonb_build_object('effectif', data->'count_min')
WHERE
   id_observation IN (SELECT id_observation FROM observation_sterf)
   AND data->>'effectif' IS NULL;
