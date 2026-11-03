# Documentation du Module

Ce module est conçu pour gérer le suivi des nichoirs : un nichoir isolé, ou un groupe de
nichoirs identiques posés sur une même façade de bâtiment (nichoirs urbains à martinets,
moineaux, hirondelles, gîtes à chiroptères…).

## Règle de saisie : un site = un nichoir ou un groupe homogène

- **1 nichoir suivi individuellement** : `Nombre de nichoirs` = 1 (valeur par défaut).
  Le suivi se fait comme auparavant (adultes, œufs, jeunes).
- **Plusieurs nichoirs sur une même façade** : un seul site, avec `Nombre de nichoirs` > 1,
  à condition que les nichoirs soient **identiques** (même façade, même espèce cible, même modèle).
  Si une façade porte 10 nichoirs à martinets et 5 à moineaux, on crée **2 sites**.

## Sites

### Nichoir

- `Nom du nichoir`
- `Code du site`
- `Date de pose`
- `Jeu de données` (projet dans le cadre duquel le nichoir a été posé)
- `Lieu de pose` : Liste configurée (arbre, acrotère de bâtiment, aménagement de combles, ...)
- `Type de nichoir` : Liste configurée (Chevêche d'Athéna, Chouette de Tengmalm, Chouette hulotte, ...)
- `Nombre de nichoirs` : 1 par défaut ; plus de 1 pour un groupe de nichoirs identiques sur une même façade
- `Renseigner les caractéristiques techniques` : case à cocher qui affiche les champs facultatifs suivants
  - `Marque / modèle` : nomenclature `NICHOIR_MODELE` (Schwegler 1SP, WoodStone Beaumaris, GENESIS…,
    « Sur mesure », « Autre modèle »). La liste peut être complétée dans l'administration des nomenclatures.
  - `Précision sur le modèle` : référence, modèle non listé
  - `Matériau` : nomenclature `NICHOIR_MATERIAU` (Bois, Béton de bois, Terre cuite, Brique, Plastique / composite, Autre)
  - `Technique de pose` : nomenclature `NICHOIR_TYPE_POSE` (En applique, Intégré à l'isolation (ITE),
    Encastré dans la maçonnerie, Caisson, Suspendu / accroché, Autre)
  - `Nombre de cavités par nichoir`
  - `Hauteur du nichoir par rapport au sol (m)`
- `Adresse`
- `Nom du propriétaire`
- `E-mail (propriétaire)`
- `Numéro de tel (propriétaire)`
- `Référent du nichoir`
- `E-mail (référent)`
- `Numéro de tel (référent)`
- `Précision sur la localisation`
- `Indices de présence de prédateur`
- `Remarque`

## Visites

- `Date du passage`
- `Observateurs`
- `Jeu de données` (obligatoire : projet dans le cadre duquel le passage a été réalisé,
  qui peut différer de celui de la pose)
- `Etat du nichoir` : Liste configurée (bon état, à réparer, à replacer, non trouvé, autre)
- `Occupation` : Liste configurée (Oui, Non). Pour un groupe : « Oui » si au moins un nichoir est occupé.
- `Commentaire`

## Observations

Une observation par espèce. Les champs affichés dépendent du `Nombre de nichoirs` du site.

| Nichoir unique (nombre = 1) | Groupe de nichoirs (nombre > 1) |
|---|---|
| `Espèce` | `Espèce` |
| `Nombre d'adultes` | `Nombre de nichoirs occupés` (obligatoire) |
| `Nombre d'oeufs` | `Nombre de nichées estimé` |
| `Nombre de jeunes vivants` | |
| `Nombre de jeunes morts` | |
| `Remarque` | `Remarque` |

Les sites créés avant l'ajout du champ `Nombre de nichoirs` sont traités comme des nichoirs uniques.

## Synthèse

La vue `gn_monitoring.v_synthese_nichoirs` (`synthese.sql`) alimente la synthèse :

- nichoir unique : dénombrement **compté** d'**individus** (adultes + œufs + jeunes vivants + jeunes morts) ;
- groupe de nichoirs : dénombrement **estimé**
  - oiseaux : de **nids** = nombre de nichées estimé, à défaut nombre de nichoirs occupés
    (pas de conversion en individus : 1 nichoir occupé ≠ 2 individus certains) ;
  - autres (chiroptères…) : effectif non connu (`NSP`, sans nombre) ;
- **statut biologique** « Reproduction » uniquement sur preuve : œufs ou jeunes pour un nichoir unique,
  nichées estimées ou nichoirs occupés pour un groupe d'oiseaux ; « Non renseigné » sinon
  (un adulte seul ne suffit pas, le nichoir pouvant servir de dortoir) ;
- **`additional_data`** : type de nichoir, nombre de nichoirs, nichoirs occupés, nichées estimées.
  Le détail du groupe est aussi repris dans le commentaire.

La vue `gn_monitoring.v_qgis_nichoirs` (`synthese_personnalisation.sql`) reprend la même logique
avec les colonnes `nb_nichoirs`, `nb_nichoirs_occupes` et `nb_nichees_estimees` pour la cartographie.
