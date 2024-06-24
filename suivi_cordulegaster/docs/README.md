# Documentation du Module

Ce module est conçu pour gérer le suivi de la flore patrimoniale.

### Aire d'études

  -  ``sites_group_name`` - **Nom de l'aire d'études**
  -  ``sites_group_description`` - **Remarque/description**
  -  ``sites_group_code`` - **Type d'aire d'études :** (Espace Naturel Sensible, Natura 2000, Réserve Naturelle, Site sous convention, Autres)

### Sites

   - ``id_sites_group`` - **Air d'études**
   - ``base_site_name`` - **Nom du site**
   - ``base_site_description`` - **Description du site**
   - ``type_milieu`` - **Type de milieu**
   - ``tuf`` - **Habitat tufeux ? :** (Oui, Non)
   - ``altitude_min`` - **Altitude**
   - ``couv_arboree`` - **Couverture d'arborée :** (0-25%, 25-50%, 50-75%, 75-100%)
   - ``couv_herbacee`` - **Couverture d'herbacée :** (0-25%, 25-50%, 50-75%, 75-100%)
   - ``especes_dominantes`` - **Espèces dominantes présentes**
   - ``type_boisement`` - **Type de boisement :** (Feuillus, Résineux, Mixtes, Non boisé)
   - ``last_visit`` - **Dernier passage**
   - ``nb_visits`` - **Nb. de passages**
   - ``id_inventor`` - **Inventeur**
   - ``first_use_date`` - **Date de création du site**

### Visites

- `id_base_site` - **Site visité**
- `visit_date_min` - **Date de la visite**
- `observers` - **Observateurs**
- `time_start` - **Heure de début du relevé**
- `time_end` - **Heure de fin du relevé**
- `quadrat` - **Quadrat** : ("1a" ,"1b" ,"2a" ,"2b" ,"3a" ,"3b" ,"4a" ,"4b" ,"5a" ,"5b" ,"6a" ,"6b" ,"8a" ,"8b" ,"HQ")
- `temperature` - **Température au début du relevé**
- `cloudiness` - **Couverture nuageuse** : ("0 à 10%","10 à 25%", "25 à 50%", "Plus de 50%")
- `rain` - **Pluie** : ("Pas de précipitations","Averses", "Pluie continue", "Orage")
- `wind` - **Vent** : ("Nul","Faible", "Moyen", "Soutenu", "Rafales")
- `data_abiotique` - **Transmission de données abiotiques**
- `physicochimie_temp` - **Physico-chimie - Température**
- `physicochimie_ph` - **Physico-chimie - Ph**
- `physicochimie_conductivite` - **Physico-chimie - Conductivité**
- `physicochimie_O2_dissous_mg_l` - **Physico-chimie - O2 dissous (mg/l)**
- `physicochimie_tx_O2` - **Physico-chimie - Taux O2 (%)**
- `habitat_hauteur_lame_eau_classe` - **Habitat - Classe de hauteur de la lame d'eau**
- `habitat_hauteur_lame_eau_cm` - **Habitat - Hauteur de la lame d'eau (cm)** : ("0","0,5 à 4", "4 à 8", "8  à 15", "15 à 20",  "plus de  20")
- `habitat_hauteur_sediments_cm` - **Habitat - Hauteur des sédiments (cm)**
- `habitat_substrat_organique` - **Habitat - Substrat organique** : ("Absence","Traces/présence", "Majoritaire")
- `habitat_granulo_sediments_majoritaire` - **Habitat - Granulo sediments majoritaire** : (<2mm, 2<X<5mm, >5mm)
- `habitat_commentaires` - **Habitat - Commentaires**
- `data_labo_DBO5` - **Laboratoire - DBO5 (mg/l)**
- `data_labo_COD` - **Laboratoire - COD (mg/l)**
- `data_labo_PO4` - **Laboratoire - PO4 (mg/l)**
- `data_labo_Ptotal` - **Laboratoire - Ptotal (mg/l)**
- `data_labo_NH4` - **Laboratoire - NH4 (mg/l)**
- `data_labo_NO2` - **Laboratoire - NO2 (mg/l)**
- `data_labo_NO3` - **Laboratoire - NO3 (mg/l)**
- `data_labo_chlorures` - **Laboratoire - Chlorures (mg/l)**
- `data_labo_sulfates` - **Laboratoire - Sulfates (mg/l)**
- `data_labo_cuivre` - **Laboratoire - Cuivre (µg/l)**
- `data_labo_micropolluants` - **Laboratoire - Micropolluants**
- `comments` - **Commentaires**

### Observations

- `id_nomenclature_observation_status` - **Statut d'observation**
- `id_nomenclature_obs_technique` - **Techniques d'observation**
- `cd_nom` - **Espèces observées**
- `id_nomenclature_stade` - **Stade Biologique**
- `id_nomenclature_sex` - **Sexe**
- `num_cp_tamis` - **Nombre de coup de tamis**
- `larve_stade` - **Stade de la larve**
- `larve_long_cm` - **Longueur de la larve (cm)**
- `larve_large_tete_cm` - **Largeur de la tête (cm)**
- `exuvie_support` - **Support de l'exuvie**
- `exuvie_haut_cm` - **Haut de l'exuvie (cm)**
- `exuvie_dist_eau_cm` - **Distance eau de l'exuvie (cm)**
- `id_nomenclature_behaviour` - **Comportement des imago observées**
- `comments` - **Commentaire**