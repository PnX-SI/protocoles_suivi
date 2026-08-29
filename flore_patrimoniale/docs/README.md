# Documentation du Module

Ce module est conçu pour gérer le suivi de la flore patrimoniale.

### Aire d'études

- `sites_group_name` - **Nom de l'aire d'études** 
- `sites_group_description` - **Remarque/description** 
- `sites_group_code` - **Type d'aire d'études** : (Espace Naturel Sensible, Natura 2000, Réserve Naturelle, Site sous convention, Autres)

### Sites

- `base_site_name` - **Nom du site**
- `id_inventor` - **Inventeur**
- `surface` - **Surface en m²**
- `base_site_description` - **Description du site**
- `first_use_date` - **Date de description** 

### Visites

- `id_dataset` - **Jeu de données**
- `observers` - **Observateurs**
- `visit_date_min` - **Date**
- `comments` - **Remarques libres** 

### Observations

- `cd_nom` - **Espèces observées**
- `nombre` - **Nombre**
- `comments` - **Commentaire**
