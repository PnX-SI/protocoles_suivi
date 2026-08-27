# Suivi de gîtes à chiroptères 🦇 

Sous-module permettant la saisie d'observations de chiroptères en gîtes conformes au standard défini par le GT National (v. les [résultats des travaux](https://docs.google.com/spreadsheets/d/1eG2vosBlrKXuCu2Wv6sui3rf1IbdemFe/edit?gid=490661796#gid=490661796) en ligne).

La configuration proposée ici constitue une base conforme aux travaux du GT. 
Elle peut ensuite être adaptée aux spécificités locales de chaque structure :
ajout/modification de champs dans les formulaires, adaptation/enrichissement
des nomenclatures ...

Toutefois, si ces modifications impactent le format des données bancarisées,
il est de la responsabilité de chaque structure de s'assurer
de l'interopérabilité du format modifié vers le standard national.

## Procédure d'installation

Le sous-module doit d'abord être installé dans l'instance GeoNature
selon [la procédure habituelle](https://github.com/PnX-SI/gn_module_monitoring/tree/34754b9f48cd0f2873c33719aa6b16a8cf0b6883?tab=readme-ov-file#installation-dun-sous-module).

Une fois le sous-module installé et configuré,
lancez le script `monitoring_gites_chiros_install_complements.sql` 
pour compléter l'installation :
* Import de la nomenclature hierarchisée des types de gîtes
* Mise en place des triggers chargés d'aggréger à l'échelle du site
  les infos saisies par observation (champs hybrides).
* **TODO** Mise en place d'une vue de projection des données de suivi
  vers le format SINP (SOT v3).

Le script peut être lancé sur la BDD GeoNature avec `psql` : 

`psql <infos de connexion à votre base GN> -f monitoring_gites_chiros_install_complements.sql`

**ATTENTION** si vous avez modifié le code module (`gites_chiros` par défaut)
il faut penser à adapter dans le script la déclaration de la fonction
`gn_monitoring.fct_tri_hybrid_attributes_site`
(params `-v` ne marchent pas à cet endroit).


## Spécificités du sous-module

### Typologie des gîtes

Les gîtes à chiroptères ont été classés selon une typologie sur deux niveaux : 
un niveau générique ("macro"), oligatoire, et un niveau spécifique ("micro"),
optionnel, qui découle du type générique.

Dans le formulaire de création de gîtes, un mécanisme (`filters`) 
permet de restreindre la saisie du type spécifique
selon le type génréique sélectionné, ce qui permet d'assurer la cohérence
des deux niveaux.

**Attention toutefois**, le code du module GN Monitoring ne permet pas encore 
de réinitialiser le niveau 2 en cas de changement de niveau 1 
une fois celui-ci sélectionné (v. [ticket #504](https://github.com/PnX-SI/gn_module_monitoring/issues/504)).
Un contournement possible est de sélectionner le type générique 'Autres',
dépourvu de type spécfique, pour réinitialiser le champ dans le formulaire,
puis de sélectionner le type générique voulu.

Dans la liste des sites sur la page du module,
seul le type le plus précis renseigné par l'utilisateur est affiché.


### Emplacements fonctionnels

Il est possible d'indiquer à quel endroit du gîte les individus 
ont été observés grâce au champ "Emplacement fonctionnel",
à l'échelle de l'observation.

L'info est facultative mais permet de guider les prospections futures,
et peur être utile aux validateurs (cohérence espèce/emplacement). 
Elle évite également de devoir multiplier les sites pour représenter 
les différents emplacements des individus  au sein d'un même gîte.

Là encore, les valeurs proposées  dans le formulaire dépendent
du type de gîte (générique) dans lequel l'observation est effectuée.
Si le type de gîte n'admet aucun emplacement fonctionnel,
le champ n'est pas affiché (cas des nichoirs / Gîtes artificiels).


### Champs hybrides

L'emplacement fonctionnel et la nature de la fréquentation,
saisies à l'échelle de l'observation, sont aggrégées 
à l'échelle du site dans des champs dits "hybrides".
Ces champs permettent de connaître l'utilisation d'un gîte
par les chiros directement depuis la page du gîte, 
sans devoir naviguer dans toutes les données.

Pour éviter de devoir saisir l'information deux fois, ces champs
sont masqués à la saisie, et sont alimentés automatiquement
par un système de *triggers* SQL qui actualise l'info du site
à chaque ajout, modification ou suppression d'observation.


### Lien avec la synthèse

Les informations saisies dans le module de suivi sont reprises
directement dans la synthèse quand le format le permet
(sexe, dénombrement, stade de vie...). Certaines ont une valeur fixe,
propre au protocole de suivi (type de regroupement, objet du dénombrement...)

Certains champs du format standards sont absent du formulaire,
mais peuvent être déduits de la valeurs d'autres champs du module de suivi
(technique d'observation, statut biologique...).

Enfin, les informations qui ne rentrent dans aucun champ de la synthèses
sont reprises en tant qu'attribut additionnels, en toute lettre,
si jugées utiles (emplacement fonctionnel, présence de juvéniles...).
