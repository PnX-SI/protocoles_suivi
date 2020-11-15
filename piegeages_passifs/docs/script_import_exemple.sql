--------------------------------------
---- SCRIPT EXEMPLE IMPORT DONNEES----
--------------------------------------

-- COTE SERVEUR : Import des données tente malaise 2020 dans un schéma fla_archives_malaise, table data_malaise_202, à l'aide de la fonction gn_imports.load_csv_file ;

-- Ajout des champs qu'il faudra calculer au fichier source. Ces données sont calculées et ajoutées à la source en amont de l'import. 
-- Cela permet, notamment pour le champs uuid, de refaire facilement le lien avec les données sources une fois importées dans le module
ALTER TABLE fla_archives_malaise.data_malaise_2020 
ADD COLUMN nb_count integer,
ADD COLUMN sex varchar(20),
ADD COLUMN the_geom_local geometry,
ADD COLUMN the_geom_4326 geometry,
ADD COLUMN the_geom_point geometry(POINT, 4326),
ADD COLUMN unique_id_sinp uuid;

-- Calcul des informations préparées avant l'import
UPDATE fla_archives_malaise.data_malaise_2020 SET
sex=CASE WHEN (nb_male IS NOT NULL) THEN ref_nomenclatures.get_id_nomenclature('SEXE','3')
		WHEN (nb_femelle IS NOT NULL) THEN ref_nomenclatures.get_id_nomenclature('SEXE','2')
		ELSE ref_nomenclatures.get_id_nomenclature('SEXE','1')
		END,
nb_count=CASE WHEN (nb_male IS NOT NULL) THEN nb_male
		WHEN (nb_femelle IS NOT NULL) THEN nb_femelle
		ELSE nb_indetermine
		END,
the_geom_local=ST_SetSRID(ST_MakePoint(REPLACE(longitude_m,',','.')::numeric,REPLACE(latitude_m,',','.')::numeric),2154),
the_geom_4326=ST_Transform(ST_SetSRID(ST_MakePoint(REPLACE(longitude_m,',','.')::numeric,REPLACE(latitude_m,',','.')::numeric),2154),4326),
the_geom_point=ST_Transform(ST_SetSRID(ST_MakePoint(REPLACE(longitude_m,',','.')::numeric,REPLACE(latitude_m,',','.')::numeric),2154),4326),
unique_id_sinp=uuid_generate_v4();


-- Prépare les champs id_base_site, id_base_visit et id_observation pour les récupérer dans la source, limiter les erreurs et faciliter l'intégration
ALTER TABLE fla_archives_malaise.data_malaise_2020 
ADD COLUMN gn_id_base_site integer,
ADD COLUMN gn_id_base_visit integer,
ADD COLUMN gn_id_observation integer;


---------------------
------- SITES -------
---------------------
-- Création des sites - base :
INSERT INTO gn_monitoring.t_base_sites (id_inventor,id_digitiser,id_nomenclature_type_site,base_site_name, base_site_code, first_use_date, geom, geom_local)
SELECT DISTINCT 
11 AS id_inventor,
11 AS id_digitiser,
ref_nomenclatures.get_id_nomenclature('TYPE_SITE','SPIP'), -- nomenclature créée par le module pour "Suivi Piégeages Interception Passifs"
code_site AS base_site_name,
code_site AS base_site_code,
min(date_debut) AS first_use_date,
the_geom_4326,
the_geom_local
FROM fla_archives_malaise.data_malaise_2020 
GROUP BY code_site, the_geom_4326, the_geom_local;

-- Récupérer dans le fichier source l'id_base_site créé dans la t_base_site du module monitoring
UPDATE fla_archives_malaise.data_malaise_2020
SET gn_id_base_site=id_base_site 
FROM gn_monitoring.t_base_sites tbs
WHERE code_site=tbs.base_site_code;

-- Rattacher ces sites au sous-module dédié
INSERT INTO gn_monitoring.cor_site_module(id_base_site, id_module)
SELECT DISTINCT 
s.gn_id_base_site,
m.id_module
FROM fla_archives_malaise.data_malaise_2020 s, gn_commons.t_modules m
WHERE module_code='piegeages_passifs';

-- Complément des sites :
INSERT INTO gn_monitoring.t_site_complements (id_base_site, id_module, data)
SELECT DISTINCT
s.gn_id_base_site,
m.id_module,
jsonb_build_object(
	'comment_site',s.comment_context,
	'desc_habitat','Autre',
	'id_trap_type',1000052
	) 
FROM fla_archives_malaise.data_malaise_2020 s, gn_commons.t_modules m
WHERE module_code='piegeages_passifs';

-- A partir de ce stade, les informations sur les sites sont complètes. Les sites importés devraient apparaitre sur l'interface. 



---------------------
------ VISITES ------
---------------------
-- Création des visites - base : 
INSERT INTO gn_monitoring.t_base_visits (id_base_site, id_dataset, id_module, id_digitiser, visit_date_min, visit_date_max)
SELECT DISTINCT 
s.gn_id_base_site AS id_base_site, 
193 AS id_dataset,
m.id_module AS id_module,
11 AS id_digitiser,
s.date_debut AS visit_date_min,
s.date_fin AS visit_date_max
FROM fla_archives_malaise.data_malaise_2020 s ,gn_commons.t_modules m
WHERE module_code='piegeages_passifs'; 

-- Récupérer dans le fichier source l'id_base_site créé dans la t_base_site du module monitoring
UPDATE fla_archives_malaise.data_malaise_2020
SET gn_id_base_visit=id_base_visit
FROM gn_monitoring.t_base_visits tbv
WHERE tbv.id_base_site=gn_id_base_site
AND tbv.visit_date_min=date_debut
AND tbv.visit_date_max=date_fin;

-- Complément des visites :
INSERT INTO gn_monitoring.t_visit_complements (id_base_visit)
SELECT DISTINCT id_base_visit 
FROM gn_monitoring.t_base_visits
WHERE id_module=(SELECT id_module FROM gn_commons.t_modules WHERE module_code='piegeages_passifs');
-- Même s'il n'y a aucune information additionnelle le module crée une ligne avec data=NULL

-- Correspondance entre visites et observateurs :
INSERT INTO gn_monitoring.cor_visit_observer (id_base_visit, id_role)
SELECT 
id_base_visit, 
id_digitiser
FROM gn_monitoring.t_base_visits
WHERE id_module=(SELECT id_module FROM gn_commons.t_modules WHERE module_code='piegeages_passifs');

-- A ce stade, les sites ont bien leurs visites attribuées et renseignées, consultables en interface



---------------------
--- OBSERVATIONS ----
---------------------
-- Création des observations - base : 
INSERT INTO gn_monitoring.t_observations (id_base_visit, cd_nom, uuid_observation)
SELECT 
s.gn_id_base_visit AS id_base_visit, 
s.cd_ref AS cd_nom, 
s.unique_id_sinp AS uuid_observation
FROM fla_archives_malaise.data_malaise_2020 s;

-- Récupération de l'id_observation vers les données sources
UPDATE fla_archives_malaise.data_malaise_2020
SET gn_id_observation = id_observation 
FROM gn_monitoring.t_observations o
WHERE unique_id_sinp=o.uuid_observation ;

-- Complément des observations :
INSERT INTO gn_monitoring.t_observation_complements (id_observation, data)
SELECT DISTINCT
s.gn_id_observation,
jsonb_build_object(
	'nb_count',s.nb_count,
	'determiner',11,
	'id_nomenclature_sex',s.sex,
	'id_nomenclature_life_stage',16,--imago
	'id_nomenclature_determination_method',
		CASE WHEN s.meth_deter='Genitalia' THEN ref_nomenclatures.get_id_nomenclature('METH_DETERMIN','66') -- Genitalia
			WHEN s.meth_deter='Examen Macroscopique' THEN ref_nomenclatures.get_id_nomenclature('METH_DETERMIN','67') -- Examen Macroscopique
			ELSE ref_nomenclatures.get_id_nomenclature('METH_DETERMIN','1') -- Non renseigné
			END
	) 
FROM fla_archives_malaise.data_malaise_2020 s;

-- A ce stade les données sont disponibles dans le module. 