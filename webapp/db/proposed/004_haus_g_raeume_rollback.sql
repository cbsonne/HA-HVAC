-- Rückgängig zu 004_haus_g_raeume.sql (vorher 005 zurücknehmen)
BEGIN;
SET LOCAL search_path = ventilation_milheiros;
DELETE FROM ventilation_systems WHERE name = 'KWL Haus G';
DELETE FROM rooms WHERE location = 'Haus G' AND name LIKE 'G %';
DELETE FROM usage_types u WHERE u.description = 'Haus G'
  AND NOT EXISTS (SELECT 1 FROM rooms r WHERE r.usage_type_id = u.usage_type_id)
  AND NOT EXISTS (SELECT 1 FROM minimum_airflow_rates m WHERE m.usage_type_id = u.usage_type_id);
COMMIT;
