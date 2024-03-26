# Documentation du Module Pyrale

Ce module est conçu pour la surveillance et le suivi des dommages de la pyrale du buis en milieu forestier. 
Il est adapté au protocole fourni par le Département de la santé des forêts. (en Annexe 13) : [Protocole du DSF](https://www.google.com/url?sa=t&source=web&rct=j&opi=89978449&url=https://info.agriculture.gouv.fr/gedei/site/bo-agri/instruction-2017-964/telechargement&ved=2ahUKEwiI5L36j5KFAxVvUqQEHSqKAYcQFnoECBMQAQ&usg=AOvVaw05KxxViZJ9_pYOyBl1xGEu
)


## Groupe de Sites

### Description générale

Ce groupe de sites contient des informations sur l'environnement dans lequel sont les placettes.

#### Propriétés affichées :

- `Code CO`
- `Code Placette`
- `Date Observation`
- `Type d'observation` : Liste configurée (Installation, Suivi évolution)
- `Type de forêt` : Liste configurée (Forêt domaniale, Forêt Communale, Association de Forestiers Privés, Forêt privée)
- `Type de peuplement` : Liste configurée (A définir)
- `Essence dominante` : Liste configurée (Hêtre, Chêne sessile, Chêne pédonculé, Chêne cf. pubescent, ...)
- `Buis présent` : Liste configurée (sous étages (SE), seul (AL), mélange avec autre essences (ME))
- `Couvert Forestier libre (%)`
- `Recouvrement du sous étage de buis (%)`
- `Couvert Forestier libre (%)`

## Sites

### Cépée

Ce fichier définit les propriétés des sites individuels où sont effectués les relevés sur lequel ont définie une cépée.

#### Propriétés affichées :

- `N° de la cépée`
- `Nom de la cépée`
- `Circonférence (En cm)`
- `Nombre de brins`
- `Hauteur maximale`
- `Remarques libres`
- `Dernier relevé`
- `Nb. de relevé`

## Visites

### Relevé

Ce fichier contient les détails des relevés effectués sur une cépée.

#### Propriétés affichées :

- `Date du relevé`
- `Opérateur(s) du relevé (= observateur.s)`
- `Cépée vivante` : Liste configurée (Oui, Non)
- `Mortalité de branches (%)`
- `Déficit foliaire (%)`
- `Consommation d'écorce ramification fine (%)`
- `Consommation d'écorce branches petites (%)`
- `Consommation d'écorce branches moyenne et tige (%)`
- `Rejets (inf 20 cm)` : Liste configurée (Oui, Non)
- `Hauteur max des gourmands (en m)`
- `Gourmands sur tige et BM (sup à 2cm) en classes` : Liste configurée (Aucun, Rares, Présents peu dynamiques, Fréquents, Couvrent la totalité)
- `Rejets (longueur maxi)`
- `Consommation du feuillage sur les rejets et gourmands` : Liste configurée (0%, 1-10%, 10-25%, 25-50%, 50-75%, >75%)
- `Précisions présence Pyrales`
- `Remarques libres`
- `Jeux de donnée associé`
