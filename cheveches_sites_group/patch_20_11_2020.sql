-- pour enlever circuit devant

UPDATE gn_monitoring.t_sites_groups
SET sites_group_name = REPLACE(sites_group_name, 'circuit ', '') 
WHERE sites_group_name LIKE 'circuit%';
