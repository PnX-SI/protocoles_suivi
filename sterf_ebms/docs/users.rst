Documentation utilisateur·ice
=============================

Cette documentation présente les fonctionnalités du module disponibles lors de
la saisie des données.


.. _terminologie:

Terminologie
------------

Il est important de noter que le module utilise la terminologie propre à
l'eBMS, qui diffère de la nomenclature historique du Sterf. Là où en « langage
Sterf » on parlait auparavant de *sites Sterf* composés d'un ou plusieurs
*transects*, dans l'eBMS on parle de *transects* composés d'une ou plusieurs
*sections*. Les concepts sont essentiellement similaires. En termes techniques
de GeoNature — qui parleront plutôt aux gestionnaires d'instances et ne sont
globalement pas visibles lors de l'utilisation de GeoNature — ces transects eBMS
sont définis comme des groupes de sites, et les sections comme les sites de
base.

=========== ========== =========================
Terme Sterf Terme eBMS Terme GeoNature (interne)
=========== ========== =========================
Site        Transect   Groupe de sites
Transect    Section    Site (ou site de base)
=========== ========== =========================

**Ce module et cette documentation utilisent exclusivement les termes eBMS.** Il
est donc possible que vous vous retrouviez à vouloir enregistrer les données de
ce que vous appeliez un transect, il faut désormais utiliser le terme de
section. Ce choix fait suite à la décision de l'équipe d'animation du Sterf
d'harmoniser l'utilisation des différents termes avec l'eBMS. Pour éviter la
confusion et faciliter la transition, les transects et sections sont
explicitement nommés « transects eBMS » et « section eBMS » dans le module. Dans
les cas où nous utilisons le terme de transect dans sa signification Sterf
originale, par exemple pour discuter de la migration de données de modules, nous
essayons de les appeler « transects Sterf ».


.. _geonature_characteristics:

Spécificités de GeoNature
-------------------------

Le module GeoNature apporte son lot de spécificités sur la façon de noter ses
données Sterf.

Il est courant de noter ses visites de transects en enregistrant la température,
le vent, bref toutes les données utiles de la visite à son début, puis de
parcourir les différentes sections pour faire ses observations. Dans GeoNature,
chaque section fait l'objet d'une visite *distincte*. Cela permet d'être plus
fin dans la saisie des informations sur ses sections, au prix parfois d'une
certaine redondance dans les informations saisies.

.. admonition:: Pourquoi cette différence ?

   GeoNature permet de définir deux niveaux de sites : les sites de bases et les
   groupes de sites. Les groupes de sites sont un simple regroupement de
   différents sites et les visites sont définies en rapport avec un site de base
   uniquement. Pour pouvoir coller à la définition à deux niveaux du Sterf et de
   l'eBMS, nous utilisons ces deux mêmes niveaux, mais celà a pour conséquence
   d'avoir à définir les informations d'une visite au niveau de chaque section
   plutôt qu'au niveau plus général du transect.


.. _enter_my_data:

Saisir ses données
------------------

Une fois le module installé par votre administrateur et les permissions
adéquates accordées à votre compte GeoNature, le module est disponible sur la
page du module Monitoring.

Nous allons détailler ci-dessous les quatre différents niveaux de données à
saisir et leurs attributs respectifs. Les attributs annotés du logo de l'eBMS
(|ebms|) signifie que l'information fait partie des données incluses dans
l'export à l'eBMS.

Transects
^^^^^^^^^

La première page du module est la liste de vos transects eBMS. L'aperçu
géographique sur la gauche cadre vos différents transects. De cette page vous
pouvez consulter vos transects ou en ajouter un nouveau.

.. figure::
   https://docs.insectes.org/media/sterf-ebms/transects.png
   :alt: Liste des transects du module

   Liste des transects du module.

.. figure::
   https://docs.insectes.org/media/sterf-ebms/transect_new.jpg
   :alt: Ajout d'un nouveau transect

   Formulaire de création de transect.

Vous pouvez, si le module a été configuré pour, tracer vous-même le transect sur
la carte au lieu d'utiliser l'enveloppe convexe des différentes sections qui le
composeront comme aire de délimitation.

Attributs :

Nom |ebms|
   Le nom du transect.
Code |ebms|
   Le code eBMS du transect, au format ``EBMS:France:XXXXXX``. S'il s'agit d'un
   transect existant déjà sur la plateforme eBMS, vous pouvez trouver son code
   sur sa page et l'inscrire ici : cela permettra de l'identifier au moment de
   l'intégration des données dans la plateforme. Si ce transect n'existe pas sur
   la plateforme eBMS, laissez ce champ vide : l'UUID interne permettra
   d'identifier ce transect lors des intégrations futures.
Description |ebms|
   Une description du transect.
Date de première utilisation
   Information propre à GeoNature.
Largeur des sections du transect |ebms|
   Par défaut, on considère que les sections font 5 mètres de large, et c'est ce
   que prévoyait le Sterf, mais l'eBMS permet plus de possibilités.
Localisation sensible |ebms|
   Est-ce que la localisation du transect doit être considérée comme sensible
   pour la plateforme eBMS ? Ce paramètre n'a pas d'influence sur son affichage
   dans GeoNature.
Habitat principal 1 |ebms|
   Niveau 1 de l'habitat Sterf principalement présent sur le transect. Il sera
   possible de spécifier individuellement pour chaque section des habitats qui
   diffèreraient de l'habitat du transect. La nomenclature suivie est le
   standard `STOC-EPS`_.
Habitat principal 2
   Niveau 2 de l'habitat Sterf principal, obligatoire.
Habitat principal 3
   Niveau 3 de l'habitat Sterf principal. Ce niveau est optionnel : il permet de
   mieux qualifier l'habitat qui sera exporté à l'eBMS mais le module peut faire
   sans.
Habitat principal 4
   Niveau 4 de l'habitat Sterf principal, optionnel également.
Habitat secondaire 1 |ebms|
   Niveau 1 d'un autre habitat Sterf présent sur le transect. Tous les niveaux
   d'habitats secondaires ne sont à définir qu'en cas de besoin. Un habitat
   secondaire sera transmis à l'eBMS seulement si au moins les deux premiers des
   quatre niveaux d'habitat secondaire sont définis.
Habitat secondaire 2
   …
Habitat secondaire 3
   …
Habitat secondaire 4
   …
Gestionnaire du terrain |ebms|
   Qui gère le terrain du transect ? Nomenclature eBMS.
Gestionnaire du terrain (secondaire, optionnel) |ebms|
   …
Gestion du terrain |ebms|
   Quelle est la gestion actuelle du terrain du transect ? Nomenclature eBMS.
Gestion du terrain (secondaire, optionnel) |ebms|
   …
Commentaires |ebms|
   Commentaires spécifiquement sur les choix d'habitats, de gestionnaire et de
   gestion de terrain.
Modules
   Les modules pouvant utiliser ce transect (en tant que groupe de sites).
   Le module Sterf-eBMS doit être dans la liste.
Médias
   Images éventuelles du site.

.. _STOC-EPS: https://docs.insectes.org/media/sterf-ebms/sterf-habitats.pdf

.. admonition:: Puis-je modifier mon transect après un premier export ?

   Certaines données comme la gestion du terrain pouvant évoluer, vous êtes
   libre de modifier cet attribut au fil de vos visites, mais il n'y a
   aujourd'hui pas de protocole défini par l'eBMS pour s'assurer que ces
   attributs soient mis à jour lorsqu'un nouvel export leur est communiqué. Il
   est plutôt probable qu'au moment de l'intégration, la personne en charge
   remarque que le transect en question est déjà présent en base de données et
   qu'elle l'exclut de l'intégration. Nous essayerons d'apporter des précisions
   à ce sujet suite aux premières intégrations de données issues de ce module.

   Si votre transect a beaucoup changé (habitat totalement différent, sections
   définitivement inaccessibles, etc.) et qu'il n'est désormais plus pertinent
   de comparer les données collectées dessus, il est plus raisonnable de définir
   un nouveau transect, quitte à avoir des géométries de section similaires,
   pour bien marquer cette différence.

.. admonition:: L'eBMS utilise une nomenclature d'habitat simplifiée par rapport
   au Sterf, y a t-il un risque de dégradation de données ?

   En effet lors de l'export, l'habitat est converti au format attendu par
   l'eBMS et on perd en finesse de description. Cependant, le code STOC saisi
   est conservé dans les métadonnées du transect (aujourd'hui, dans le champ
   commentaire) et suit ainsi la définition du transect même une fois dans
   l'eBMS.

Lors que vous sélectionnez un transect, la carte zoom sur lui, ses attributs
s'affichent ainsi que la liste de ses sections.

Sections
^^^^^^^^

Depuis la page d'un transect, vous pouvez voir les sections qui le composent et
ajouter une nouvelle section.

.. figure::
   https://docs.insectes.org/media/sterf-ebms/sections.png
   :alt: Liste des sections d'un transect

   Liste des sections d'un transect.

.. figure::
   https://docs.insectes.org/media/sterf-ebms/section_new.jpg
   :alt: Ajout d'une nouvelle section à un transect

   Ajout d'une nouvelle section à un transect.

Lors de l'ajout d'une nouvelle section, vous pouvez tracer son linéaire sur la
carte avec le bouton en haut à gauche en forme de ligne. Après avoir cliquer sur
le bouton, tracez point par point le linéaire de la section, et une fois
terminé, cliquez de nouveau sur le dernier point créé pour valider le tracé.
Utilisez le même bouton pour recommencer si besoin.

Vous pouvez également charger un fichier au format KML, GPX ou GeoJSON pour
importer votre géométrie depuis un autre logiciel.

Attributs :

Nom |ebms|
   Nom de la section, pour vous aider à vous en souvenir.
Code |ebms|
   Code eBMS de la section. Sur la plateforme, les sections d'un transect sont
   identifiées avec un code au format SN, N étant le numéro de la section : S1,
   S2, S3, etc. Si le transect existe déjà dans l'eBMS, utilisez les mêmes codes
   de section ; dans le cas contraire, définissez ces codes au fur et à mesure
   de la création des sections selon la même nomenclature.
Description |ebms|
   Description optionnelle de la section.
Observateur·ice par défaut
   Liste d'observateur·ice·s à ajouter par défaut aux nouvelles visites de
   sections, pour accélérer la saisie.
Date de première utilisation
   Information propre à GeoNature.
Habitat linéaire |ebms|
   L'habitat type du linéaire parcouru sur cette section, avec une nomenclature
   propre à l'eBMS.
Habitat principal 1 |ebms|
   Habitat principal présent sur la section. Ce champ, comme tous les champs
   d'habitats liés à la section, n'est à utiliser que s'il y a un habitat
   différent de ceux définis pour le transect. Ils peuvent rester vide s'il n'y
   a pas de différence majeure. Leur fonctionnement à part ça est le même que
   pour les habitats de transects.
Habitat principal 2
   …
Habitat principal 3
   …
Habitat principal 4
   …
Habitat secondaire 1 |ebms|
   …
Habitat secondaire 2
   …
Habitat secondaire 3
   …
Habitat secondaire 4
   …
Gestion du terrain |ebms|
   La gestion principale du terrain propre à cette section du transect, à
   définir seulement si elle diffère de celle du transect.
Gestion du terrain (secondaire) |ebms|
   La gestion secondaire du terrain propre à cette section du transect, à
   définir seulement si elle diffère de celle du transect.
Commentaires |ebms|
   Commentaires spécifiquement sur les choix d'habitats et de gestion de
   terrain.
Groupe de sites |ebms|
   Le transect à laquelle cette section appartient. Si vous avez ouvert le
   formulaire depuis un transect, ce champ est prérempli.
Médias
   Images éventuelles de la sections.
Type de site
   Le type de site GeoNature : a minima vous devez sélectionner « Section eBMS
   ».

Visites
^^^^^^^

Depuis la page d'une section, vous pouvez voir les visites faites sur une
section et ajouter une nouvelle visite.

.. important::

   Contrairement au Sterf et à l'eBMS qui considèrent qu'en règle générale, une
   visite se fait à l'échelle d'un transect sur toutes ses sections
   consécutives, GeoNature considère qu'une visite est effectuée sur une
   section.

   Par conséquent, lors du passage sur un transect contenant plusieurs sections,
   vous devrez créer autant de visites qu'il y a de sections. La saisie est
   un peu plus laborieuse mais permet d'être plus fin dans le renseignement de
   ses visites. Des solutions sont en cours de développement sur GeoNature pour
   faciliter la saisie successive de visites.

.. figure::
   https://docs.insectes.org/media/sterf-ebms/visits.png
   :alt: Détails d'une section avec la liste de ses visites

   Détails d'une section avec la liste de ses visites, enfin de la seule visite
   effectuée.

.. figure::
   https://docs.insectes.org/media/sterf-ebms/visit_new.jpg
   :alt: Ajout d'une nouvelle visite

   Ajout d'une nouvelle visite.

Attributs :

Avez-vous vu des papillons lors de cette visite ? |ebms|
   Cette information permet de distinguer deux types de visites : d'une part les
   visites qui ont permis de faire des observations mais dont les observations
   n'ont pas encore été renseignées dans le module, et d'autre part les visites
   où l'on sait qu'aucune observation n'a été faite. Elle est par défaut à
   ``Oui``.
Date |ebms|
   Date de la visite
Observateurs |ebms|
   La, le ou les observateur·ice·s présent·e·s sur la visite.
Heure de début |ebms|
   …
Heure de fin |ebms|
   …
Température |ebms|
   …
Couverture nuageuse (pourcentage) |ebms|
   …
Vitesse du vent |ebms|
   Vitesse du vent constatée, en utilisant `l'échelle de Beaufort`_. Notez que
   le niveau maximal rapporté à l'eBMS est 6, car a priori au delà il n'y a plus
   grand monde à observer.
Couverture florale
   …
Visite complète
   Est-ce que la visite a été interrompue ?
Fiabilité |ebms|
   Est-ce que les conditions permettent un décompte fidèle (A) ou non (B), voire
   ne permettent pas de décompte du tout (C) ?
Commentaires |ebms|
   Champ libre.
Jeu de données
   Le jeu de données où reporter les observations de cette visite.
Médias
   Images éventuelles de la visite.

.. _l'échelle de Beaufort: https://fr.wikipedia.org/wiki/%C3%89chelle_de_Beaufort

.. admonition:: Si l'eBMS traite les visites par transect et GeoNature par
   section, comment est-ce que l'export traite mes données ?

   Lors de l'export à l'eBMS, les différentes visites de sections sont
   regroupées selon le transect parent des sections et la journée, i.e. toutes
   les visites de sections d'un même transect sur une même journée constitue une
   seule visite de transect, et les différents attributs de la visite de
   transect sont calculés comme moyennes des visites de sections.

   Par exemple, deux visites le même jour sur deux sections d'un même transect,
   avec pour températures renseignées 21°C et 23°C, produiront une seule visite
   de transect avec une température moyenne calculée de 22°C.

   De la même manière, une visite de transect a pour liste d'observateurs
   l'ensemble de tous les observateurs présents sur les différentes visites de
   sections constituant cette visite de transect.

Observations
^^^^^^^^^^^^

Depuis la page d'une visite, vous pouvez voir les observations qui y ont été
faites et en ajouter de nouvelles.

Attributs :

Taxon |ebms|
   Le taxon qui a été observé. Les choix possibles sont configurés par votre
   administrateur GeoNature.
Effectif |ebms|
   …
Commentaires |ebms|
   …
Médias
   Images éventuelles.

.. admonition:: À quel rang dois-je identifier les papillons ?

   Celà dépend de liste taxonomique configurée par l'admin de votre GeoNature.
   Celle que nous proposons par défaut comprend tous les taxons de la famille à
   la sous-espèce, en passant par la sous-famille, la tribu, le genre et
   l'espèce.

   Une limite actuelle du module est qu'il n'est pas possible d'utiliser les
   complexes d'espèces tels que le Sterf les utilise, et il vous faudra donc
   utiliser le taxon de rang supérieur le plus adapté.

.. |ebms| image:: tiny-ebms.png
   :width: 1em
   :height: 1em
   :alt: Envoyé à l'eBMS
