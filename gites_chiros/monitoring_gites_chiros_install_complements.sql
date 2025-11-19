/* MODULE DE SUIVI DES GÎTES À CHIROPTÈRES
 * ---------------------------------------
 * Compléments d'installation du sous-module monitoring
 * Suivi des gîtes à chiroptères du GT National.
 */



/* I) Typologie des sites
 * ----------------------
 * Import de la nomenclature des types de site
 * avec traduction de la typologie, exprimée via les codes nomenclature,
 * dans les champs GeoNature id_broader et hierarchy.
 */

-- upload 
CREATE TABLE ref_nomenclatures.temp_typologie_sites_chiro (
	code char(4),
	label varchar(100),
	definition varchar(500)
);

\copy ref_nomenclatures.temp_typologie_sites_chiro (code, label, definition) FROM 'nomenclature_type_gite_chiro.csv' WITH DELIMITER ';' CSV HEADER;

-- Écriture dans la nomenclature GN
INSERT INTO ref_nomenclatures.t_nomenclatures (
	id_type, cd_nomenclature, mnemonique, 
	label_default, definition_default, 
	label_fr, definition_fr, 
	source, statut, hierarchy
)
SELECT
	ref_nomenclatures.get_id_nomenclature_type('TYPE_GITE_CHIRO') as id_type,
	code as cd_nomenclature,
	label as mnemonique,
	label as label_default,
	definition as definition_default,
	label as label_fr,
	definition as definition_fr,
	'GT National Gîtes chiros' as source,
	'Validé' as statut,
	array_to_string(
		array[
			lpad(ref_nomenclatures.get_id_nomenclature_type('TYPE_GITE_CHIRO')::text, 3, '0'),
			lpad(left(code, 2), 3, '0'),
			nullif(lpad(right(code, 2), 3, '0'), '000')
		],
		'.'
	) as hierarchy
FROM ref_nomenclatures.temp_typologie_sites_chiro;


-- Ajout du id_broader (doit se faire après l'insert,
-- quand l'ID des types de niveau 1 existe)
update ref_nomenclatures.t_nomenclatures
set id_broader = case
	when right(cd_nomenclature, 2) = '00'
	then null
	else ref_nomenclatures.get_id_nomenclature(
		'TYPE_GITE_CHIRO',
		left(cd_nomenclature, 2) || '00'
	)
end
where id_type = ref_nomenclatures.get_id_nomenclature_type('TYPE_GITE_CHIRO');

-- Nettoyage
DROP TABLE ref_nomenclatures.temp_typologie_sites_chiro;


/* II) Champs hybrides site
 * ------------------------
 * Mise en place de triggers chargés d'alimenter les champs hybrides du site
 * à partir des infos saisies à l'échelle des observations saisies sur ce site.
 */

-- 1) Calcul des attributs d'un site

CREATE OR REPLACE FUNCTION gn_monitoring.compute_hybrid_attributes_site(id_target_site integer)
 RETURNS void
 LANGUAGE plpgsql
AS $function$
BEGIN
	UPDATE gn_monitoring.t_site_complements
        SET "data" = coalesce("data", '{}'::jsonb) || jsonb_build_object(
        	'hybrid_chiros_spots', coalesce(b.chiros_spots, ''),
        	'hybrid_chiro_activities', coalesce(b.chiro_activities, '')
        	)
		FROM (
			SELECT
			    tbv.id_base_site,
				string_agg(
			    	distinct ref_nomenclatures.get_nomenclature_label((comp."data" ->> 'id_nomenclature_chiros_spot')::integer),
			    	' | '
			    ) as chiros_spots,
				string_agg(
			    	distinct ref_nomenclatures.get_nomenclature_label((comp."data" ->> 'id_nomenclature_chiro_activity')::integer),
			    	' | '
			    ) AS chiro_activities
			FROM gn_monitoring.t_observations obs
			JOIN gn_monitoring.t_observation_complements comp USING (id_observation)
			JOIN gn_monitoring.t_base_visits tbv  USING (id_base_visit)
			WHERE tbv.id_base_site = id_target_site
			GROUP BY tbv.id_base_site 
		) as b
        WHERE t_site_complements.id_base_site = b.id_base_site ;
END;
$function$
;

-- 2) Insertion / Mise à jour

CREATE OR REPLACE FUNCTION gn_monitoring.fct_tri_upsert_hybrid_attributes_site()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
	-- Déclenche la mise à jour des attributs hybrides du site
	-- lors de l'ajout ou de la modification d'une observation.
	DECLARE _id_base_site int;
	DECLARE _id_module_visit int;
BEGIN

	-- Récupération de la visite et du module (protocole)
	-- auxquels est rattachée l'observation
	SELECT INTO
		_id_base_site, _id_module_visit
		tbs.id_base_site, tbv.id_module
	FROM gn_monitoring.t_observations obs
	JOIN gn_monitoring.t_base_visits tbv USING (id_base_visit)
	JOIN gn_monitoring.t_base_sites tbs USING (id_base_site)
	WHERE obs.id_observation = NEW.id_observation;

  	-- Uniquement pour les visites réalisées dans le cadre du suivi des gîtes chiro
  	-- /!\ CODE MODULE À ADAPTER MANUELLEMENT (si modifié) /!\
  	IF _id_module_visit = (SELECT id_module FROM gn_commons.t_modules WHERE module_code = 'gites_chiros') THEN 
    	PERFORM gn_monitoring.compute_hybrid_attributes_site(_id_base_site);
    END IF;

RETURN NEW;
END;
$function$
;

create trigger tri_upsert_hybrid_attributes_site 
after insert or update on gn_monitoring.t_observation_complements 
for each row execute function gn_monitoring.fct_tri_upsert_hybrid_attributes_site();

-- 3) Suppression

CREATE OR REPLACE FUNCTION gn_monitoring.fct_tri_delete_hybrid_attributes_site()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
	-- Déclenche la mise à jour des attributs hybrides du site
	-- lors de la suppression d'une observation.
	DECLARE _id_base_site int;
	DECLARE _id_module_visit int;
BEGIN

	-- Récupération de la visite et du module (protocole)
	-- auxquels est rattachée l'observation
	SELECT INTO
		_id_base_site, _id_module_visit
		tbs.id_base_site, tbv.id_module
	FROM gn_monitoring.t_observations obs
	JOIN gn_monitoring.t_base_visits tbv USING (id_base_visit)
	JOIN gn_monitoring.t_base_sites tbs USING (id_base_site)
	WHERE obs.id_observation = OLD.id_observation;

  	-- Uniquement pour les visites réalisées dans le cadre du suivi des gîtes chiro
  	-- /!\ CODE MODULE À ADAPTER MANUELLEMENT (si modifié) /!\
  	IF _id_module_visit = (SELECT id_module FROM gn_commons.t_modules WHERE module_code = 'gites_chiros') THEN 
  		PERFORM gn_monitoring.compute_hybrid_attributes_site(_id_base_site);
    END IF;
RETURN OLD;
END;
$function$
;

create trigger tri_delete_hybrid_attributes_site
after delete on gn_monitoring.t_observation_complements 
for each row execute function gn_monitoring.fct_tri_delete_hybrid_attributes_site();
