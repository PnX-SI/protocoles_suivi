-- #########################
--- OBSOLETE 
-- A SUPPRIMER


CREATE OR REPLACE FUNCTION procedure_cheveches_synthese() RETURNS TRIGGER AS $trigger_cheveches_synthese$
	BEGIN
		IF (TG_OP = 'DELETE') THEN
			DELETE FROM gn_synthese.synthese s WHERE OLD.uuid_base_visit = s.unique_id_sinp;
			RETURN OLD;
		ELSIF (TG_OP = 'UPDATE') THEN
			UPDATE gn_synthese.synthese  SET 
				count_min = vsc.count_min,
				count_max = vsc.count_max,
				cd_nom = vsc.cd_nom,
				id_module = vsc.id_module, 
				id_dataset = vsc.id_dataset,
				id_nomenclature_obs_technique = vsc.id_nomenclature_obs_technique,
				id_nomenclature_grp_typ = vsc.id_nomenclature_grp_typ,
				date_min = vsc.date_min, 
				date_max = vsc.date_max, 
				comment_description = vsc.comment_description,
				the_geom_4326 = vsc.the_geom_4326,
				the_geom_point = vsc.the_geom_point, 
				observers = vsc.observers, 
				nom_cite = vsc.nom_cite
				
				FROM gn_monitoring.vs_cheveches vsc
				JOIN gn_commons.t_modules m ON m.id_module = vsc.id_module
				WHERE  vsc.id_base_visit = NEW.id_base_visit
					AND m.module_path = 'cheveches';
			RETURN NEW;
		ELSIF (TG_OP = 'INSERT') THEN
			RAISE NOTICE '%', to_json((
			SELECT 
				id_base_visit
	
				FROM gn_monitoring.vs_cheveches vsc
				JOIN gn_commons.t_modules m ON m.id_module = vsc.id_module
				WHERE  vsc.id_base_visit = NEW.id_base_visit
					AND m.module_path = 'cheveches'
					LIMIT 1
			));
			INSERT INTO gn_synthese.synthese (
				count_min, count_max, cd_nom, id_module, id_dataset,
				id_nomenclature_obs_technique, id_nomenclature_grp_typ, date_min, date_max, comment_description,
				the_geom_4326, the_geom_point, observers, nom_cite)
			(SELECT 
				count_min, count_max, cd_nom, vsc.id_module, id_dataset,
				id_nomenclature_obs_technique, id_nomenclature_grp_typ, date_min, date_max, comment_description,
				the_geom_4326, the_geom_point, observers, nom_cite
	
				FROM gn_monitoring.vs_cheveches vsc
				JOIN gn_commons.t_modules m ON m.id_module = vsc.id_module
				WHERE  vsc.id_base_visit = NEW.id_base_visit
					AND m.module_path = 'cheveches'
				);			
			RETURN NEW;
		END IF;
	RETURN NULL;
	END;
$trigger_cheveches_synthese$ language plpgsql;


DROP TRIGGER trigger_cheveches_synthese ON gn_monitoring.vs_cheveches;

CREATE TRIGGER trigger_cheveches_synthese
    AFTER INSERT OR UPDATE OR DELETE ON gn_monitoring.vs_cheveches
    FOR EACH STATEMENT EXECUTE PROCEDURE procedure_cheveches_synthese();
