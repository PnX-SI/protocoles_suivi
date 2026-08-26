:orphan:

Exemple de migration de module
==============================

.. note::

   Cet exemple illustre comment :ref:`migrer d'un module Sterf déjà installé
   vers le module Sterf-eBMS <module_migration>`, assurez-vous d'avoir lu cette
   section de la documentation avant de lire cette page.

Nous allons étudier ici un exemple de migration de module, plus précisement
depuis le `module Sterf` distribué sur le `dépôt des parcs nationaux` vers notre
module Sterf-eBMS. Dans cette page le nom de code du module Sterf actuel (aussi
désigné comme ancien module) est ``sterf``, et le module Sterf-eBMS (ou nouveau
module) est ``sterf_ebms``.

.. _module Sterf: https://github.com/PnX-SI/protocoles_suivi/tree/master/sterf
.. _dépôt des parcs nationaux: https://github.com/PnX-SI/protocoles_suivi

Cette migration nécessite d'avoir installé au préalable le module Sterf-eBMS de
façon à avoir ses nomenclatures disponibles en base de données et
vraisemblablement d'avoir bu un café ou deux. Ce document **n'est pas un guide
complet pas à pas** mais essaye seulement d'accompagner votre démarche de
migration.

Nous partons du principe que vous souhaitez automatiser au maximum la
migration, mais il est toujours possible de procéder manuellement sur une partie
ou toutes les entités que vous avez à migrer, par exemple recréer manuellement
les différents transects et section dans le nouveau module, mais migrer en SQL
les entités de visites et observations.

.. warning::

   Cette page contient différents exemples de code SQL pour accompagner la
   migration. Il **faut** les adapter pour vos besoins, ne les exécutez pas sans
   avoir effectué une copie de votre base de données, et de préférence sur une
   instance de test clonée depuis votre production !


Migrations des transects
------------------------

En parcourant le module Sterf, on peut noter les différences suivantes entre le
format de ses données et celles attendues par le module Sterf-eBMS.

#. Le module Sterf ne comprend qu'un niveau géographique, les *transects Sterf*.
   Ces transects doivent être convertis en *sections eBMS* et il va falloir
   créer le niveau de groupe de site dans le module pour regrouper ces futures
   sections dans des *transects eBMS*.
#. Les habitats doivent être convertis.
#. Il manque à nos transects les attributs obligatoires suivants (on décide
   d'ignorer tous les attributs optionnels par simplicité) :

   * La largeur de transect ;
   * Le gestionnaire et la gestion du terrain.

#. Le module Sterf-eBMS ne possède pas l'attribut suivant :

   * « Modalité de sélection du site ».

Nouveau niveau géographique
^^^^^^^^^^^^^^^^^^^^^^^^^^^

Concernant le nouveau niveau géographique, on va ici partir du principe qu'on
peut créer un transect eBMS par transect Sterf, qui ne contiendra donc qu'une
seule section représentant notre transect Sterf. On peut copier le
``sites_group.json`` du module Sterf-eBMS et l'épurer pour qu'il ne contienne
que les attributs qui nous importent.

Le code suivant va générer des groupes de sites à partir des transects associés
au module ``sterf``.

.. code-block:: sql

   -- Création des groupes de sites.
   INSERT INTO gn_monitoring.t_sites_groups
   (sites_group_name, sites_group_code, sites_group_description, uuid_sites_group, id_digitiser)
   SELECT base_site_name, '', base_site_description, uuid_generate_v4(), id_digitiser
   FROM gn_monitoring.t_base_sites tbs
   JOIN gn_monitoring.cor_site_type cst USING (id_base_site)
   JOIN gn_monitoring.cor_module_type cmt USING (id_type_site)
   JOIN gn_commons.t_modules tm USING (id_module)
   WHERE module_code = 'sterf';

   -- Association des transects à leurs groupes de sites, en utilisant le fait
   -- qu'ils aient le même nom (libre à vous de créer une liaison différente).
   -- Attention ça ratisse large, on part du principe que tous les groupes de
   -- sites créés dans la journée sont concernés par la migration.
   UPDATE gn_monitoring.t_site_complements tsc
   SET id_sites_group = sites.id_sites_group
   FROM (
       SELECT id_base_site, id_sites_group
       FROM gn_monitoring.t_sites_groups tsg
       JOIN gn_monitoring.t_base_sites tbs ON tbs.base_site_name = tsg.sites_group_name
       WHERE EXTRACT(DAY FROM tsg.meta_create_date) = EXTRACT(DAY FROM NOW())
   ) sites
   WHERE tsc.id_base_site = sites.id_base_site;

   -- Association des nouveaux groupes de sites avec le module Sterf actuel.
   -- Pareil, ça s'applique à tous les groupes de sites créés aujourd'hui.
   INSERT INTO gn_monitoring.cor_sites_group_module
   SELECT
       id_sites_group,
       gn_commons.get_id_module_bycode('sterf') AS id_module
   FROM gn_monitoring.t_sites_groups
   WHERE EXTRACT(DAY FROM meta_create_date) = EXTRACT(DAY FROM NOW());

À ce stade, le module n'affiche plus rien sur sa page d'accueil : en effet votre
utilisateur n'a pas la permission d'afficher des groupes de sites pour ce
module, car la permission n'existe pas encore, pour la bonne raison que
GeoNature ne les a pas créé lors de l'installation du module, celui-ci n'ayant
pas originellement de groupes de sites. Vous pouvez créer les permissions
adéquates et les donner à votre groupe administrateur :

.. code-block:: bash

   geonature monitorings update_module_available_permissions sterf
   geonature permissions supergrant --group --nom "Grp_admin"

Planifier les migrations d'attributs
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

Les prochaines sections abordent la migration des attributs de vos transects
Sterf vers les transects et sections eBMS. Avec ce nouveau niveau géographique,
vous aurez peut-être à planifier à quel niveau doit être intégré tel ou tel
attribut.

Par exemple dans le module actuel, on va vouloir migrer les attributs
d'habitats. Dans le module Sterf-eBMS, ces attributs existent à la fois dans les
transects et dans les sections, respectivement comme habitats à l'échelle de
tout le site et comme habitats spécifiquement différent sur une section en
particulier. Vu que l'on a choisi précédemment de créer un transect par section,
un choix de migration possible est tout simplement de copier les infos d'habitat
de la section vers son transect, et de conserver les attributs d'habitat de la
section — ces attributs nécessitant tout de même une conversion, qui est le
sujet de la prochaine section.

Habitats
^^^^^^^^

Concernant les habitats, heureusement les deux modules se basent sur la
nomenclature STOC et les données sont donc directement compatibles. Il faut
seulement prendre en compte le changement de format : le module Sterf utilise
des listes de sélection tandis que le module Sterf-eBMS utilise une nomenclature
détaillée pour les habitats.

La conversion a pour principale complexité que les niveaux 2, 3 et 4 sont
dépendants du niveau 1, c'est à dire par exemple que la même valeur en niveau 2,
par exemple la lettre ``a``, n'a pas la même signification selon si le premier
niveau est ``A`` (forêt, donc le niveau 2 signifie forêt de feuillus exclusifs)
ou ``E`` (milieux bâtis, donc le niveau 2 signifie zone urbaine résidentielle).

Dans l'exemple suivant, on prend le niveau d'habitat 1 du site, plus précisément
la première lettre de sa valeur, qui correspond à un code (une lettre de A à G),
et on le convertit en ID de nomenclature de type ``STERF_HAB_N1`` correspondant,
c'est à dire la nomenclature d'habitat de niveau 1. Si par exemple le premier
niveau correspond à la valeur ``E``, on va récupérer l'ID de la valeur
``HAB1_E`` de la nomenclature.

.. code-block:: sql

   UPDATE gn_monitoring.t_sites_groups tsg
   SET "data" = COALESCE(tsg."data", jsonb_build_object()) || jsonb_build_object(
       'habitat_main_1',
       ref_nomenclatures.get_id_nomenclature(
           'STERF_HAB_N1',
           'HAB1_' || SUBSTRING(tsc.data->>'habitat_1' FROM 1 FOR 1)
       )
   )
   FROM gn_monitoring.t_base_sites tbs
   JOIN gn_monitoring.t_site_complements tsc USING (id_base_site)
   WHERE
       EXTRACT(DAY FROM meta_create_date) = EXTRACT(DAY FROM NOW())
       AND tsg.id_sites_group = tsc.id_sites_group
       AND tsc.data ? 'habitat_1'

Tout ceci est à adapter à la représentation des habitats de votre module, et il
faut également prendre en compte les niveaux 2, 3 et 4 d'habitats. Pour
représenter les habitats eBMS, le module Sterf-eBMS a besoin des deux premiers
niveaux obligatoirement, les deux suivants sont optionnels mais conseillés.

Le code pour le niveau 2 des habitats, attachez vos ceintures :

.. code-block:: sql

   -- On commence par récupérer les infos de nomenclatures d'habitats des deux
   -- premiers niveaux, le niveau 2 dépendant du premier.
   WITH
       hab_n1 AS (
           SELECT id_nomenclature, mnemonique
           FROM ref_nomenclatures.t_nomenclatures
           WHERE id_type = ref_nomenclatures.get_id_nomenclature_type('STERF_HAB_N1')
       ),
       hab_n2 AS (
           SELECT id_nomenclature, cd_nomenclature, label_default
           FROM ref_nomenclatures.t_nomenclatures
           WHERE id_type = ref_nomenclatures.get_id_nomenclature_type('STERF_HAB_N2')
       )
   UPDATE gn_monitoring.t_sites_groups tsg
   SET "data" = tsg.data || jsonb_build_object('habitat_main_2', hab_n2.label_default)
   FROM gn_monitoring.t_base_sites tbs
   JOIN gn_monitoring.t_site_complements tsc USING (id_base_site)
   JOIN gn_monitoring.t_sites_groups tsg_ USING (id_sites_group)
   JOIN hab_n1
       ON hab_n1.id_nomenclature = (tsg_.data->'habitat_main_1')::int
   JOIN hab_n2
       ON hab_n2.cd_nomenclature = CONCAT(
           -- On reconstitue le code HAB2_x_y en fonction de X le niveau 1 et
           -- Y le niveau 2. Il y a une subtilité : pour les niveaux 1 A et B,
           -- les niveaux 2 sont les mêmes, donc il s'agit de la même
           -- nomenclature pour les deux (HAB2_AB_y).
           'HAB2_',
           CASE hab_n1.mnemonique
               WHEN 'A' THEN 'AB'
               WHEN 'B' THEN 'AB'
               ELSE hab_n1.mnemonique
           END,
           '_',
           UPPER(SUBSTRING(tsc.data->>'habitat_2' FROM 1 FOR 1))
       )
   WHERE
       EXTRACT(DAY FROM tsg.meta_create_date) = EXTRACT(DAY FROM NOW())
       AND tsg.id_sites_group = tsc.id_sites_group
       AND tsg.data ? 'habitat_main_1'
       AND tsc.data ? 'habitat_2'

Les niveaux 3 et 4 suivent le même principe, à ceci près que le niveau 3 n'est
pas sujet à la subtilité liée aux nomenclatures communes des types A et B de
niveau 1, et sont laissés comme exercices pour le lecteur 😌.

Nouveaux attributs
^^^^^^^^^^^^^^^^^^

Concernant les attributs à ajouter, heureusement ils possèdent tous une valeur
par défaut acceptable : la largeur de transect fait probablement 5 mètres, le
transect n'est probablement pas sensible, l'habitat secondaire est optionnel et
peut donc être ignoré. Les seuls attributs qu'il faudra impérativement remplir
sont le gestionnaire de terrain ainsi que la gestion de terrain, cependant les
deux nomenclatures acceptent une valeur par défaut qui peut servir en l'absence
d'information sur les transects, respectivement ``LT_UNKNOWN`` pour un
gestionnaire inconnu et ``LM_OTHER`` pour une gestion inconnue. Ces valeurs sont
à compléter avec des informations plus pertinentes quand c'est possible.

Il vous faudra également bien séparer les attributs des transects et les
attributs des sections dans le cas où un nouveau niveau géographique est
introduit.

Attributs manquants
^^^^^^^^^^^^^^^^^^^

Concernant les attributs manquants, il suffit d'ajouter votre attribut dans le
module Sterf-eBMS.

Inclure ses transects dans le nouveau module
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

Jusqu'à présent le nouveau module n'affichera pas vos transects migrés car
ceux-ci sont toujours rattachés à l'ancien module. Il va falloir inclure les
transects (groupes de sites) dans le nouveau module, et changer le type de site
pour utiliser celui du nouveau module.

.. code-block:: sql

   -- On intègre nos transects dans le nouveau module.
   -- Ils restent accessibles depuis l'ancien module.
   INSERT INTO gn_monitoring.cor_sites_group_module
   SELECT id_sites_group, gn_commons.get_id_module_bycode('sterf_ebms')
   FROM gn_monitoring.t_sites_groups
   JOIN gn_monitoring.cor_sites_group_module USING (id_sites_group)
   WHERE id_module = gn_commons.get_id_module_bycode('sterf');

   -- On change le type des sites de l'ancien module vers le nouveau.
   UPDATE gn_monitoring.cor_site_type
   SET id_type_site = ref_nomenclatures.get_id_nomenclature('TYPE_SITE', 'EBMS_SEC')
   WHERE id_type_site = ref_nomenclatures.get_id_nomenclature('TYPE_SITE', 'STERF');

GeoNature permet qu'un groupe de sites soit utilisable par plusieurs modules,
donc la première intégration ne les retire pas de l'ancien module. La seconde en
revanche change le type des transects Sterf, par conséquent ils ne seront plus
accessibles via l'ancien module tant que celui-ci ne sera pas reconfiguré pour
utiliser les sites "Section eBMS", dans le formulaire d'édition de module.

.. admonition:: Est-ce que mes attributs sont conservés après ces changements ?

   Oui, vos attributs de sites (sections) et groupes de sites (transects) sont
   conservés, dans les champs JSONB ``data`` respectivement des tables
   ``t_site_complements`` et ``t_sites_groups``. Une fois les modifications
   précédentes effectuées, si vous modifiez votre site — anciennement transect
   Sterf et désormais section eBMS — depuis le module Sterf-eBMS, les nouveaux
   attributs sont ajoutés à l'objet JSON et les anciens attributs ne sont pas
   supprimés. Vous pouvez donc envisager une migration progressive des
   attributs, si vous êtes pris par le temps.


Migrations des visites et observations
--------------------------------------

Les visites sont en général plus simples à migrer vu qu'il n'y a aujourd'hui
qu'un seul niveau de visite. La procédure consiste donc comme pour les transects
et les sections à transférer les attributs de son module Sterf vers ceux du
module Sterf-eBMS

Une fois cette étape terminée, les visites doivent être associées au nouveau
module pour apparaitre lors de la consultation du site.

.. code-block:: sql

   UPDATE gn_monitoring.t_base_visits
   SET id_module = gn_commons.get_id_module_bycode('sterf_ebms')
   WHERE id_module = gn_commons.get_id_module_bycode('sterf');

Les observations ne nécessitent pas de traitement particulier, à part la
transformation des attributs, mais à ce stade vous avez l'habitude !
