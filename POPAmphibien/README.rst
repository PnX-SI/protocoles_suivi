POPAmphibien
============

Sous-module de saisie GeoNature Monitoring du protocole POPAmphibien - Société Herpétologique de France


Pour installer l'outil de saisie POPAmphibien, vous devez disposer d'une instance GeoNature, dotée du module monitorings. POPAmphibien est un sous-module du module monitorings.


Installation
============

  ::
  
    wget https://github.com/DonovanMaillard/popamphibien/archive/refs/tags/1.0.0.zip
    unzip 1.0.0.zip
    mv popamphibien-1.0.0 popamphibien

    cd
    cd geonature
    source backend/venv/bin/activate
    geonature monitorings install <path/to/popamphibien> popamphibien


Vous pouvez ensuite vous connecter sur le module monitoring, puis "PopAmphibien" et enfin "editer" pour configurer le module (jeu de données, taxons, synthèse etc).

Pour tout complément d'information, consulter directement la documentation du module monitoring ; https://github.com/PnX-SI/gn_module_monitoring#readme

Attention
=========

Si vous utilisez un autre "module_code" que popamphibien tout en minuscule, vous devrez adapter les scripts SQL d'exports pour récupérer les données du modules dans vos exports standards et d'analyse.
