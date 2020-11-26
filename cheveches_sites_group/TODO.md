# Fait
* Groupes de sites -> Circuits
* Site -> Stations
* Dernière visite -> max(date des visites)
* Gestion des droit différent par objets
  * restreindre action sur sites groupe de sites aux administrateurs 
* tri site par nom
* tri groupe_site par nom
* numéro de passage select 1 ou 2
* visite ordre des champs
  * proprieté, formulaire
    * site, date, heure, observation, num passage, observateurs, meteos, commentaire
  * liste
    * site, data, observation , num_passage, observateur    
* visite formulaire site dans l'ordre
* données à jour sur prod
* pouvoir filter les données (inactif) avec la config (dans FRONTEND)
  * filtre par default pour les tableaux 
* ordonner liste dans select site
* re init site pour les visites enchaînées
* routes depuis classe monitoring object
* affichage carte garder group site pendant visite
* breadcrumb se relance BUG!!!! (snapshot)
* afficher les codes sur la carte
  * effacer les codes 

# A faire

* saisie enchainée voir les saisies
* grp site - visite 
  * parentsPath contient id site#1 (pour le lien visite groupe de sites)
  * créer visite à partir de groupe de site (+ problématique lien visite - circuit)
* bug chained met tout dans un site (bon apres ctrl enter )

