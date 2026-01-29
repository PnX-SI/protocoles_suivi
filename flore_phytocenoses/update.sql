UPDATE gn_commons.t_modules SET  
module_label='Suivis botanique de phytocénoses',  
module_desc='Suivi des phytocénoses',  
module_path='monitorings/module/flore_phytocenoses',
module_code='flore_phytocenoses'
WHERE id_module=30;


UPDATE gn_synthese.t_sources ts
	SET 
		name_source = 'MONITORING_FLORE_PHYTOCENOSES',
		desc_source = 'Données issues du module de suivi générique (sous-module: suivis flore phytocénoses)',
		url_source = '#/monitorings/object/flore_phytocenoses/observation',
		entity_source_pk_field=		'gn_monitoring.vs_flore_phytocenoses.entity_source_pk_value'
WHERE ts.id_source = 113;




UPDATE gn_meta.t_datasets td
	SET 
		dataset_name = 'Suivis botanique de phytocénoses',
		dataset_shortname = 'Suivis phytocénoses'
WHERE td.id_dataset = 425;


UPDATE ref_nomenclatures.t_nomenclatures tn SET 
	cd_nomenclature =  'FLORE_PHYTOCENOSE',
	mnemonique =  'phytocenose',
	label_fr =  'Phytocenose',
	label_default =  'Phytocenose',
	definition_fr =  'phytocenoses',
	definition_default =  'phytocenose'
WHERE tn.id_nomenclature  = 797;