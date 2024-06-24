# Documentation du Module

Ce module est conçu pour suivre le protocole [chronoventaire](http://spn.mnhn.fr/spn_rapports/archivage_rapports/2014/SPN%202014%20-%2022%20-%20Chronoventaire_18_avril_2014.pdf)

## Sites

### Station d'inventaire

#### Propriétés affichées :

- `Nom de la station`
- `Code de la station`
- `Date de pose`
- `Type d’habitat principale autour de la station` : Liste configurée via API `habref/habitats/autocomplete`
- `Type d’habitat secondaire autour de la station` : Liste configurée via API `habref/habitats/autocomplete`
- `Type d’habitat principale adjacent à la station` : Liste configurée via API `habref/habitats/autocomplete`
- `Type d’habitat secondaire adjacent à la station` : Liste configurée via API `habref/habitats/autocomplete`
- `Surface de prospection en m2`
- `Description libre de l’habitat`
- `Nb. de passages`
- `Dernier passage`

## Visites

### Passage

#### Propriétés affichées :

- `Heure de début du relevé`
- `Date du relevé`
- `Température au début du relevé`
- `Couverture nuageuse` : Liste configurée (0 à 10%, 10 à 25%, 25 à 50%, Plus de 50%)
- `Vent` : Liste configurée (Nul à faible, Moyen, Soutenu, Rafales)
- `Etat du pâturage` : Liste configurée (Non pâturé, Pâturage en cours, Pâturage terminé)
- `Disponibilité florale` : Liste configurée (FLEUR_1, FLEUR_2, FLEUR_3, FLEUR_4)
- `Groupes Chronoventaire` : Liste configurée (RHOP1, RHOP2, RHOPZYG1, RHOPZYG2)
- `Température à la fin du relevé`
- `Durée de la détermination`

## Observations

### Observation

#### Propriétés affichées :

- `Round` : Liste configurée (Round 1 : 0-5mn, Round 2 : 5-10mn, Round 3 : 10-15mn, ...)
- `Espèce`
- `Sexe` : Liste configurée via API `nomenclatures/nomenclature/SEXE`
- `Stade Biologique` : Liste configurée via API `nomenclatures/nomenclature/STADE_VIE`
- `Méthode de détermination` : Liste configurée via API `nomenclatures/nomenclature/METH_DETERMIN`
- `Effectif dénombré`
- `Commentaire`
