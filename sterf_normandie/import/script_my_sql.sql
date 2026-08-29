-- Passage
WITH hab AS (
	SELECT 
		concat(h.ID_Transect, '_', h.Annee , '_', h.ID_Passage  ) as id_unique,
		os.Occ_Sol_Larg_Echelle,
		os.Occ_Sol_Detaille,
		h.Habitat_Principale,
		h.Habitat_Secondaire,
		Remarque
	FROM obhn_habitat h
	LEFT JOIN obhn_occupation_sol os ON os.ID_Occupation_Sol = h.Occ_Sol_Detail
)
SELECT
	concat(m.ID_Transect, '_', YEAR(m.Date) , '_', m.ID_Passage  ) as id_unique,
	m.ID_Transect,
	t.Nom_Transect,
	r.Observateur,
	m.ID_Passage,
	YEAR(m.Date) AS Annee,
	m.Date,
	m.Heure,
	cn.Graduation_Couver,
	tp.Graduation_Temp,
	v.Graduation_Vent,
	m.Date_Saisie_Horaire,
	hab.*
FROM obhn_horaire_meteo m
LEFT JOIN hab ON hab.id_unique = concat(m.ID_Transect, '_', YEAR(m.Date) , '_', m.ID_Passage  ) 
LEFT JOIN obhn_transect t ON m.ID_Transect = t.ID_Transect
LEFT JOIN obhn_Temperature tp ON m.Temperature = tp.ID_Temperature
LEFT JOIN obhn_vent v ON m.Vent = v.ID_Vent
LEFT JOIN obhn_couverture_nuage cn ON m.Couverture_Nuage = cn.ID_Couverture
LEFT JOIN obhn_responsable r ON concat(m.ID_Transect, '_', YEAR(m.Date)  ) = concat(r.ID_Transect, '_', r.Annee  )
ORDER BY ID_Transect, Date
;
-- Observations
SELECT
	concat(o.ID_Transect, '_', Annee , '_', o.ID_Passage  ) as id_unique_passage,
	Id_Observation,
	o.Effectif_Total,
	o.Effectif_Male,
	o.Effectif_Femelle,
	o.ID_Taxon,
	tx.Taxon,
	tx.Nom_Simplifier AS lb_taxon,
	o.Remarque,
	o.Date_Saisie
FROM obhn_observation o
LEFT JOIN obhn_taxref tx ON tx.ID_Taxref = o.ID_Taxon
ORDER BY concat(o.ID_Transect, '_', Annee , '_', o.ID_Passage  )
;