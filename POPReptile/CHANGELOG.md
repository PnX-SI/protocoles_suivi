2.1.0 (2026-01-22)
------------------

**🚀 Nouveautés**

* Mise à jour du protocole POPReptile pour conformité avec la version 2 du protocole POPReptile "Communauté" publié par la SHF en janvier 2025 (et mis à jour en septembre 2025)
* Ajout d'un numéro de version, qui correspond à la version du protocole publiée par la SHF (actuellement, [v2.2.0](https://lashf.org/?jet_download=b9ba5d144f7cfcdf71242ef67c206bfdcfa5b234)

**🐛 Corrections**

* Mise en conformité du sous-module avec le nouveau modèle de données du module Monitoring (versions >= 1.0.0). Cela concerne notamment l'ajout d'un type de site propre au protocole POPReptile.

**⚠️ Notes de version**

Si vous aviez une version du module POPReptile préalablement installée, vous allez devoir migrer vos anciennes données vers le nouveau format pour deux raisons :
* les évolutions dans les informations collectées depuis la version 2 du protocole POPReptile;
* les évolutions du module monitoring (versions >= 1.0.0).
Pour vous aider, un script est présent dans le dossier `for_install`.
Ce script doit potentiellement être adapté en fonction de votre version de monitoring et la version installée de votre sous-module POPReptile.
