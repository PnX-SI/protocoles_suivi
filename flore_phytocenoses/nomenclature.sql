

UPDATE ref_nomenclatures.t_nomenclatures tn  SET mnemonique = 'Pleine floraison', label_default='Pleine floraison', definition_default= 'Pleine floraison'
WHERE id_nomenclature = 710;

WITH val AS (
SELECT '0.10.0' || ((row_number() OVER ()) + 28)::varchar AS h , *
FROM (VALUES
('FLORAISON_BOUTON', 'Boutons floraux', 'Boutons floraux', 'Boutons floraux'),
('FLORAISON_DEBUT', 'Début de floraison', 'Début de floraison', 'Début de floraison'),
('FLORAISON_FIN', 'Fin de floraison', 'Fin de floraison', 'Fin de floraison, avec éventuellement maturation des fruits'),
('DISSEMINATION', 'Dissémination', 'Dissémination', 'Dissémination'),
('VEGETATIF', 'Végétatif', 'Végétatif', 'Végétatif')
('TIGE', 'Tige', 'Tige', 'Tige'),
) AS t (cd_nomenclature, mnemonique, label_fr, definition_fr)
)
INSERT INTO ref_nomenclatures.t_nomenclatures
( id_type, cd_nomenclature, mnemonique, label_default, definition_default, label_fr, definition_fr,
 "source", statut, id_broader, "hierarchy",   active)
 SELECT 10 as id_type, v.cd_nomenclature,  v.mnemonique, v.label_fr as label_default, v.definition_fr as definition_default
    , v.label_fr as label_fr, v.definition_fr as definition_fr,
    'PNC' as source, 'A VALIDER' as statut, 0 as id_broader, h as  "hierarchy", true as active
FROM val v;




WITH val AS (
SELECT '0.10.0' || ((row_number() OVER ()) + 28)::varchar AS h , *
FROM (VALUES
('FLORAISON_BOUTON', 'Boutons floraux', 'Boutons floraux', 'Boutons floraux'),
('FLORAISON_DEBUT', 'Début de floraison', 'Début de floraison', 'Début de floraison'),
('FLORAISON_FIN', 'Fin de floraison', 'Fin de floraison', 'Fin de floraison, avec éventuellement maturation des fruits'),
('DISSEMINATION', 'Dissémination', 'Dissémination', 'Dissémination'),
('VEGETATIF', 'Végétatif', 'Végétatif', 'Végétatif'),
('TIGE', 'Tige', 'Tige', 'Tige')
) AS t (cd_nomenclature, mnemonique, label_fr, definition_fr)
)
INSERT INTO ref_nomenclatures.cor_taxref_nomenclature
(id_nomenclature, regne, group2_inpn,  group3_inpn)
SELECT tn.id_nomenclature , 'Plantae', 'all', 'all'
FROM val
JOIN ref_nomenclatures.t_nomenclatures tn
ON tn.id_type = 10 and val. cd_nomenclature = tn.cd_nomenclature;