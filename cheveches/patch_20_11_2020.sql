-- pour enlever circuit devant

UPDATE gn_monitoring.t_sites_groups
SET sites_group_name = REPLACE(sites_group_name, 'circuit ', '') 
WHERE sites_group_name LIKE 'circuit%';


-- fix code_site
UPDATE gn_monitoring.t_base_sites SET base_site_code = SPLIT_PART(base_site_name, ' ', 1)
