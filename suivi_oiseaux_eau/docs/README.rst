Sous-module Oiseaux d'eau
"""""""""""""""""""""""""""""


Description du module
=====================

Le sous-module "Suivi Oiseaux d'eau" permet de saisir les données de suivi obtenues lors des relevés terrain.

Description de la méthode de saisies des données
=====================


Dans ce sous-module, une visite est une visite d'un secteur d'un site spécifique.

.. image:: img/accueil.png


Détail des formulaires
======================

Sites
-----

Les sites de ce sous-module constituent les pièges exploités. Ces sites de piégeages sont caractérisés par les champs suivants :

- ``Nom du site de piégeage`` (exemple : Forêt du Lauvitel - point aval)
- ``Code du piège`` (exemple : TM04)
- ``L'installateur du piège`` (équivaut au descripteur du site de suivi)
- ``Date de première installation du piège`` (équivaut à la date de description du site)
- ``Le type de piège`` : dans notre cas, il s'agit de nomenclatures du type "METH_OBS" (voir spécificités plus bas)
- ``L'habitat dominant`` : basé sur une liste de valeurs configurables dans le fichier site.json
- ``Détail sur le site de piégeage`` : commentaire


.. image:: img/sites.png

Visites
-------

Les visites correspondent aux relevés des pièges. Elles sont caractérisées par les informations suivantes :

- ``Opérateur(s) du relevé`` : personnes effectuant le relevé des pièges. Ils seront "observateurs" une fois la donnée renvoyée dans la synthèse
- ``Date de début du piégeage`` : correspond à date_min de l'observation dans la synthèse
- ``Date de fin du piégeage`` : date du relevé du piège - correspond à date_max de l'observation dans la synthèse
- ``Commentaire``
- ``Jeu de données``

.. image:: img/visites.png

Observations
------------

Les observations de ce sous-modules sont décrites par les informations suivantes :

- ``Espèce`` : taxon parmi la liste configurée (saisie_occtax par défaut)
- ``Commentaire``
- ``Déterminateur``
- ``Méthode de détermination`` (nomenclature "METH_DETERMIN")
- ``Stade de vie`` (nomenclature "STADE_VIE")
- ``Sexe`` (nomenclature "SEXE")
- ``Effectif dénombré`` : correspond au nombre_min ET nombre_max de la synthèse

Par défaut dans la vue synthèse (synthese.sql), les dénombrements indiqués sont des "individus" "comptés". Les individus sont indiqués "trouvé mort".

.. image:: img/observations.png


Utilisation des médias
======================

Dans ce module, les médias sont activés à tous les niveaux, prévus pour comporter
des médias de différentes natures :

- Sous-module : Document décrivant le protocole, fiche de terrain exemple etc.
- Sites : Photos du milieu, du piège etc.
- Visites : Photos liées au relevé : piège détérioré, fiche de terrain complétée etc.
- Observations : Photos des individus collectés


Spécificités à gérer
====================

A Modifier

Dans le cas de Flavia APE, qui a généré ce sous-module, il a été souhaité que les types de pièges soient disponibles dans tous les modules, y compris occtax. Nous avons donc fait le choix de générer des nomenclatures "personnalisées" dans le type "METH_OBS", correspondant à nos différentes méthodes de captures, y compris les différents pièges à interceptions. Ces nomenclatures "personnalisées" sont des nomenclatures "filles" de la nomenclature standard "VU" (``ref_nomenclatures.t_nomenclatures``).

Deux solutions sont alors possibles pour déployer le module sur d'autres instances :

- Créer des nomenclatures personnalisées dans ``ref_nomenclatures.t_nomenclatures`` pour le type "METH_OBS" puis ajuster le widget ``id_trap_type`` et la vue ``synthese.sql`` avec vos ``cd_nomenclatures``
- Modifier la configuration du sous-module (``site.json``) et la vue ``synthese.sql`` pour créer une liste déroulante simple ou une nouvelle nomenclature dédiée


Import de données dans le sous-module
=====================================

A Modifier

Des données provenant de fichiers excel ont été importées dans ce module. 
Un script d'import (script_import_exemple.sql) est partagé dans le répertoire docs du sous-module pour partager la méthode utilisée. 

Ce script comporte des ``id_role`` "en dur", et dépend de nomenclatures propres à Flavia APE, qui a effectué cet import. Il ne peut donc pas être réutilisé directement sur d'autres instances mais peut servir d'exemple. Un modèle du fichier d'import correspondant a été ajouté au répertoire docs à titre d'information.
