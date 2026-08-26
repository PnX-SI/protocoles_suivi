.. Module GN Sterf-eBMS documentation master file, created by
   sphinx-quickstart on Mon Feb 23 14:40:34 2026.
   You can adapt this file completely to your liking, but it should at least
   contain the root `toctree` directive.

Module GeoNature Sterf-eBMS
===========================

.. toctree::
   :maxdepth: 2
   :hidden:

   users
   admins
   data

Bienvenue sur la documentation du module GeoNature Sterf-eBMS. Ce module permet
de renseigner les données de suivis de transects de papillons suivant le
protocole `Sterf`_ dans une instance `GeoNature`_ via son `module de suivi`_ et
d'exporter ses données à destination de la plateforme européenne, `eBMS`_.

.. _Sterf: https://sterf.mnhn.fr/
.. _GeoNature: https://geonature.fr/
.. _module de suivi: https://github.com/PnX-SI/gn_module_monitoring
.. _eBMS: https://butterfly-monitoring.net/

.. image::
   https://docs.insectes.org/media/sterf-ebms/img.jpg
   :height: 10rem
   :width: 10rem
   :alt: Logo de l'eBMS
   :align: center

Ses objectifs sont :

1. Fournir une configuration adéquate pour la saisie de données à laquelle les
   participant·e·s au Sterf sont habitué·e·s ;
2. Fournir la capacité d'exporter ses données Sterf de façon standardisée et en
   autonomie vers l'eBMS.

Cette documentation se présente en trois parties : une première à destination
des utilisateurs du module, une deuxième à destination des administrateurs
d'instance de GeoNature et une troisième à destination des intégrateurs de
données de la plateforme eBMS.

* Si vous devez **saisir vos données Sterf** sur le module Sterf-eBMS de votre
  structure ou de votre région, rendez-vous sur la :doc:`documentation
  utilisateur·ice <users>`.
* Si vous devez **installer, administrer ou mettre à jour** ce module sur une
  instance GeoNature, rendez-vous sur la :doc:`documentation administrateur·ice
  <admins>`.
* Si vous souhaitez plus d'informations sur les **exports de données** produits
  par le module, rendez-vous sur la :doc:`documentation sur les données
  <data>` (section en anglais).
* If you **received data exported from this module** (e.g. you work at or with
  the UKCEH, on the eBMS platform, or with Indicia), you want to read the
  :doc:`data documentation <data>`.

Nous vous conseillons tout de même de toujours parcourir a minima la doc
utilisateur·ice, qui présente certains éléments de terminologie important.


FAQ
---

.. admonition:: Pourquoi un nouveau module Sterf alors que plusieurs régions ont
   déjà conçu leurs propres configurations pour saisir des données Sterf sur
   GeoNature ?

   L'objectif de ce module est de garantir que les données saisies soient
   suffisamment exhaustives pour pouvoir être exportées et envoyer aux
   administrateurs de la plateforme eBMS, de façon à intégrer les données Sterf
   dans la base de données européenne.

.. admonition:: Est-ce que je peux installer ce module sur mon instance
   GeoNature ?

   Oui, la documentation d'administration est là pour ça, et vous pouvez `nous
   contacter <admin@insectes.org>`__ en cas de problème.

.. admonition:: J'ai déjà un module Sterf, est-ce que je peux installer ce
   module en parallèle, voire migrer mes données ?

   Oui, vous pouvez ajouter ce module en plus de vos modules existants. Il est
   toujours possible de migrer les données d'un module à un autre, soit
   manuellement soit à l'aide de requêtes SQL ; dans tous les cas c'est un
   processus qui varie selon chaque module, mais vous trouverez dans la
   documentation d'administration des conseils ainsi qu'un exemple de migration
   pour vous aider à migrer vos données.


À propos
--------

Ce module a été développé par l’`Office pour les insectes et leur
environnement`_, en partenariat avec l’`UKCEH`_, avec le soutien de l’`Office
français de la biodiversité`_.

.. _Office pour les insectes et leur environnement: https://insectes.org
.. _UKCEH: https://www.ceh.ac.uk/
.. _Office français de la biodiversité: https://ofb.gouv.fr/

Contributeur·ice·s :

* Adrien Abraham (développement)
* Alexia Monsavoir (gestion de données)
* Mathieu de Flores (coordination Opie)
* Reto Schmucki (coordination UKCEH)
* Jim Bacon (accompagnement technique UKCEH)

Nous tenons à remercier le `CEN Normandie`_, `Nature en Occitanie`_ et le `CEN
Bourgogne`_ pour nous avoir transmis leurs propres modules Sterf durant la phase
d'étude de ce projet, ainsi que les développeurs de GeoNature et du module
Monitorings pour leur accompagnement.

.. _CEN Normandie: https://www.cen-normandie.fr/
.. _Nature en Occitanie: https://www.natureo.org/
.. _CEN Bourgogne: https://www.cen-bourgogne.fr/

Cette documentation a été rédigée sans avoir recours à l'intelligence
artificielle.
