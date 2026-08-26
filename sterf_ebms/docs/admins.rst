Documentation administrateur·ice
================================

Cette documentation présente l'installation du module Sterf-eBMS, comment le
modifier pour vos besoins, la migration depuis un module pré-existant et comment
exporter ses données à l'eBMS.


.. _installation:

Installation
------------

Le module a été développé avec GeoNature en version 2.15 et le module
`Monitoring`_ en version 1.0.3 et doit fonctionner avec ces versions minimales.

.. _Monitoring: https://github.com/PnX-SI/gn_module_monitoring

La dernière version du module est toujours disponible sur son `propre dépôt`_.
Une version récente est également mise à disposition sur le `dépôt commun`_ aux
configurations des suivis mais peut ne pas être la version la plus à jour
disponible.

.. _propre dépôt: https://github.com/Opie-insectes/sterf-ebms
.. _dépôt commun: https://github.com/PnX-SI/protocoles_suivi

Téléchargez la dernière version du module sur la page des `releases`_ du module
et installez là dans votre dossier de modules de suivi. Ici on utilise
``~/modules`` comme dossier mais cela dépend de votre installation ; par exemple
la documentation du module Monitoring installe les modules directement dans le
dossier utilisateur.

.. _releases: https://github.com/Opie-insectes/sterf-ebms/releases

.. code-block:: bash

   # Remplacez X.Y.Z par la version à utiliser.
   cd ~/modules
   wget https://github.com/Opie-insectes/sterf-ebms/archive/refs/tags/X.Y.Z.tar.gz
   tar xf sterf-ebms-X.Y.Z.tar.gz
   rm sterf-ebms-X.Y.Z.tar.gz
   mv sterf-ebms-X.Y.Z sterf_ebms

Ensuite on suit la `procédure d'installation d'un sous-module
<https://github.com/PnX-SI/gn_module_monitoring?tab=readme-ov-file#installation-dun-sous-module>`__
du module Monitoring :

.. code-block:: bash

   # On se rend dans le dossier des sous-modules.
   cd ~/geonature/backend/media/monitorings/
   # Création du lien symbolique vers notre module, adaptez le chemin si besoin.
   ln -s ~/modules/sterf_ebms .
   # Installation du module.
   source ~/geonature/backend/venv/bin/activate
   geonature monitorings install sterf_ebms

Vous devrez ensuite paramétrer les permissions de vos utilisateurs pour utiliser
le module, ou bien en attendant ajouter les permissions manquantes aux comptes
administrateurs :

.. code-block:: bash

   geonature permissions supergrant --group --nom "Grp_admin"

Paramétrages
^^^^^^^^^^^^

À ce stade vous devriez pouvoir voir le module Sterf-eBMS dans la liste des
modules de suivis lorsque vous êtes sur l'accueil du module Monitorings.

Vous devez encore paramétrer le module avec deux éléments cruciaux : le *jeu de
données* concerné par le module et la *liste des taxons*.

Le module ne peut pas proposer sa propre liste de taxons, aussi vous devez
utiliser la vôtre. Si vous avez déjà une liste de taxons adaptée au Sterf sur
votre instance GeoNature (e.g. si vous avez déjà un module Sterf fonctionnel),
vous pouvez utiliser la même liste.

Sinon rendez-vous sur la `page de gestion des listes de Taxhub
<https://geonature.insectes.org/geonature/api/admin/biblistes/>`__ et créez
votre liste. Vous pouvez utiliser :download:`ce fichier CSV
<liste-taxonomique.csv>` qui contient tous les noms de référence des taxons de
papillons de jours selon TaxRef 18, de la famille à la sous-espèce, plus
précisément selon la requête SQL suivante :

.. code-block:: sql

   SELECT cd_nom, rang, nom_complet
   FROM refer.tr18
   WHERE
       famille in ('Lycaenidae', 'Riodinidae', 'Pieridae', 'Papilionidae', 'Nymphalidae', 'Hesperiidae', 'Zygaenidae')
       AND rang in ('FM', 'SBFM', 'TR', 'GN', 'ES', 'SSES')
       AND cd_nom = cd_ref
   ORDER BY cd_nom

Contenu additionnel installé
^^^^^^^^^^^^^^^^^^^^^^^^^^^^

En plus du module, de ses vues d'exports et de ses nomenclatures, le module
installe quelques éléments supplémentaires dans la base de données pour son
fonctionnement :

* La table `ref_habitats.cor_sterf_to_ebms` contient les informations permettant
  de traduire un identifiant d'habitat STOC vers les nomenclatures d'habitats
  eBMS.
* La fonction `gn_monitoring.sterf_ebms_geom_as_indicia_lat_lon_text` permet de
  traduire des coordonnées dans le format exact de degrés décimaux attendus par
  Indicia.

Vous ne devez pas modifier ou supprimer ces éléments ou bien le module ne
fonctionnera plus correctement. En cas de problème, vous pouvez toujours
les réinstaller avec la commande :

.. code-block:: bash

   geonature monitorings process_sql sterf_ebms


.. _update:

Mise à jour
-----------

Pour mettre à jour le module, vous pouvez télécharger la version que vous
souhaitez et la décompresser directement dans le dossier de la configuration. Si
vous avez un dépôt Git à cause de modifications apportées au module, vous pouvez
checkout la version souhaitée.

.. code-block:: bash

   cd ~/modules/sterf_ebms  # adapter le dossier
   tar xf /tmp/sterf-ebms-X.Y.Z.tar.gz

La seule manipulation nécessaire après chaque mise à jour est la recréation des
vues du module :

.. code-block:: bash

   geonature monitorings process_sql sterf_ebms


.. _module_edition:

Modifier le module
------------------

L'objectif principal du module est de permettre de saisir des données Sterf qui
puissent être exportée vers l'eBMS avec le minimum de friction. Le module permet
donc de saisir les attributs fréquemment attribués à des transects ou des
visites Sterf (habitat, couverture florale, etc.) mais ne peut pas être
exhaustif sur les besoins de chaque structure. Par conséquent, il est possible
de modifier le module pour que celui-ci s'adapte à vos besoins, en respectant
certaines contraintes pour vous faciliter la maintenance du module.

Si vous comptez modifier le module, il est sans doute préférable de cloner le
dépôt du module plutôt que télécharger une archive, de façon à pouvoir
enregistrer et suivre vos modifications avec Git et avoir une vision claire des
différences lors d'une possible mise à jour future du module.

Ajouter des attributs
^^^^^^^^^^^^^^^^^^^^^

À chaque niveau du module vous pouvez ajouter les attributs qu'il vous manque
pour votre propre usage. Pour des raisons de maintenance, préférez ajouter vos
nouveaux attributs à la fin du JSON.

.. danger::

   Il est vivement déconseillé de modifier les attributs existants car on ne
   pourra alors plus garantir que l'export continuera à fonctionner comme prévu.

Développer ses propres exports
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

Les exports proposés par le module ont été développés avec un seul objectif :
assurer une intégration optimale dans l'eBMS. Ils ne reflètent donc pas
intégralement la qualité des données de votre instance GeoNature, et ne sont
donc peut-être pas totalement adaptés à l'analyse de données dont vous avez
besoin.

Vous êtes encouragés à développer vos propres fonctions d'exports, au pied du
fichier ``exports/csv/export_csv.sql``.

.. danger::

   Il est vivement déconseillé de modifier les vues d'exports existantes :
   celles-ci ont été travaillées conjointement avec l'UKCEH pour garantir un
   certain format et iels risquent de ne pas savoir quoi faire de vos exports
   modifiés, voire d'intégrer des données erronées.


.. _module_migration:

Migrer depuis un module existant
--------------------------------

Il est tout à fait possible d'installer le module Sterf-eBMS en parallèle de
votre module Sterf actuel, et de les utiliser soit tous les deux, soit
uniquement le nouveau, en fonction du temps que vous pouvez donner à votre
gestion de données. Cela dit, migrer vos données depuis votre module actuel vers
le module Sterf-eBMS peut être la meilleure option : vous n'aurez qu'un module à
gérer, toutes vos données au même endroit, toutes vos données pourront être
exportées sans effort à l'eBMS et vous bénéficierez d'un SAV du tonnerre.

La migration demande cependant un travail conséquent pour s'assurer qu'il n'y
ait pas de dégradation de vos données et que vos usages ne soient pas impactés.

Problématiques communes
^^^^^^^^^^^^^^^^^^^^^^^

**Comment sont représentés vos transects ?** Certains modules n'utilisent qu'un
seul niveau géographique, le transect Sterf, et vous devrez donc choisir comment
traduire vos transects Sterf vers des transects et sections eBMS. De façon
automatique, en choisissant que chaque transect Sterf devienne un transect eBMS
constitué d'une seule section, ou bien manuellement, en regroupant vous-même vos
transects Sterf dans des sites. Dans tous les cas, vous devrez commencer par
ajouter le niveau de groupe de sites à votre module, puis décider comment les
créer.

.. note::

   « Transects Sterf et eBMS » ? Si ces termes ne vous parlent pas, consultez la
   section :ref:`Terminologie <terminologie>` de la documentation
   utilisateur·ice.

**Est-ce que certains de vos attributs n'existent pas dans le module Sterf-eBMS
?** Pour chaque niveau, si le nouveau module ne représente pas certaines données
que vous souhaitez conserver, vous devrez définir ces attributs dans le nouveau
module avant de pouvoir migrer vos données.

**Est-ce que le module Sterf-eBMS définit des attributs inexistants dans vos
données ?** Certains attributs du module Sterf-eBMS sont obligatoires et doivent
donc être renseignés pour chaque entité, ou bien l'export risque de ne pas
fonctionner.

Préparer et migrer ses données
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

Avant toute manipulation, pensez bien entendu à sauvegarder votre base de
données.

Une fois que vous aurez bien identifier les différences à résoudre, vous pourrez
suivre ce plan de migration :

#. Implémenter les changements au niveau de votre module existant ;
#. Appliquer des mises à jours au niveau de vos données ;
#. Réassigner le jeu de données et le type de site de vos transects.

Exemple de migration de module
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

Pour vous aider dans cette migration, nous avons préparé un :doc:`exemple de
migration <migration-example>` dont vous pouvez vous inspirer. Nous sommes
également disponible `par e-mail <admin@insectes.org>`__ pour vous aider dans ce
processus.


.. _send_my_data:

Envoyer mes données à l'eBMS
----------------------------

Dans le cadre de l'animation du Sterf, il vous est demandé de communiquer vos
données à la plateforme européenne eBMS. Le module est conçu pour produire les
exports dans un format facile à intégrer pour les partenaires de l'eBMS.

L'export de vos données se fait à partir du menu Téléchargements, à l'accueil du
module. Il y a quatre types d'exports disponibles dès l'installation du module :
les transects, les sections, les visites de transects et les observations. Les
quatre exports que vous devez fournir à l'eBMS sont nommés avec "(export pour
eBMS)" en suffixe, de façon à les distinguer de potentiels types d'export que
vous auriez rajoutés.

Il est recommandé de toujours exporter ces quatre fichiers de façon à ne pas
risquer de manquer d'éléments au moment de l'intégration. Chaque transect,
section, visite et observation est identifiée avec un UUID pour éviter les
dédoublements de données.

Vous pouvez envoyer vos données par e-mail à `l'adresse de l'eBMS`_. **Nous vous
prions de bien vouloir nous mettre en copie** via notre `adresse de gestion de
données`_, de façon à pouvoir suivre l'utilisation du module et le bon
déroulement des échanges de données dans le cadre de l'animation du programme.
Nous vous recommandons dans votre e-mail de préciser que ces données ont été
produites à l'aide de ce module, si possible avec le numéro de version du
module, et d'ajouter un lien vers la :doc:`documentation des données <data>`.

Si vous avez des questions sur vos exports ou que vous souhaitez un retour sur
vos données avant l'envoi à l'eBMS, n'hésitez pas à nous écrire directement.

.. _l'adresse de l'eBMS: ebms@ceh.ac.uk
.. _adresse de gestion de données: sig@insectes.org

Vous pouvez également consulter la :doc:`documentation des données <data>`
pour en savoir plus sur le format des exports.


.. _synthesis:

Mettre à jour la synthèse
-------------------------

Ce module vient avec un fichier SQL (``synthese.sql``) pour que le module
Monitoring puisse envoyer vos données depuis le module de suivi vers la synthèse
de GeoNature, de façon à ce qu'elles puissent être consultées comme les autres
données de votre instance. Cette fonctionnalité doit être activée dans
l'interface de configuration du module (case ``Activer la synthèse``) puis les
données peuvent être mises à jour avec le bouton ``Mettre à jour la synthèse``
sur la page des détails du module.

Il est possible que certains choix faits par le module lors de l'envoi vers la
synthèse ne vous conviennent pas. Par exemple, le module suppose que toutes les
observations renseignées concernent des imagos, mais si vous avez modifié le
module pour permettre la spécification du stade de vie de vos observations, il
vous faudra modifier le script de synthèse pour refléter ces changements.

Voici la liste des choix qui ont été faits :

* La nature des objets géographiques est *inventorielle*, i.e. le taxon observé
  est présent quelque part dans l'objet géographique mais ne le recouvre pas
  (nomenclature peu utilisée en entomologie) ;
* Les types de regroupements sont des *passages* ;
* La méthode d'observation est *"vu"*, i.e. observation directe d'un individu
  vivant ;
* Le statut biologique est non renseigné ;
* L'état biologique est *"vivant"* ;
* Le niveau de naturalité est *"sauvage"*, i.e. ce n'est pas un individu
  domestiqué ou féral ;
* Il est renseigné qu'il n'y a pas de preuve existante (*"inconnue"*) ;
* Le statut de validation est *"en attente de validation"* : ceci n'est pas un
  des cinq statuts de validation du SINP donc ça peut être intéressant de
  modifier cette définition si vous souhaitez valider automatiquement vos
  observations Sterf sur votre instance ;
* Le niveau de précision de diffusion souhaité est *standard* sauf si le
  transect a été noté comme sensible, auquel cas le niveau est *aucune* ;
* De la même manière, le niveau de sensibilité est *"aucune diffusion permise"*
  ou *"non sensible"* selon l'état de sensibilité du transect ;
* Le stade de vie est *imago* ;
* Le sexe est *indéterminé* ;
* L'objet du dénombrement est *"individu"* ;
* Le type de dénombrement est *"compté"* ;
* Le statut de l'observation est *"présent"* si l'effectif est positif, *"non
  observé"* sinon ;
* La donnée est indiquée comme non floutée ;
* Le statut de la source est *"venant du terrain"* ;
* Le type d'information géographique est le *"géoréférencement"*, i.e. l'objet
  géographique est bien celui où on a fait l'observation et n'est pas un objet
  rattaché après coup (e.g. le polygone de la commune) ;
* Le comportement des occurences observées est non renseigné ;
* Le module ne compte qu'un effectif, pas une fourchette, par conséquent le
  décompte minimal est identique au décompte maximal ;
* La méthode de détermination est non renseignée ;
* Le commentaire de contexte est celui de la visite ;
* Le commentaire de l'occurence est celui de l'observation.
