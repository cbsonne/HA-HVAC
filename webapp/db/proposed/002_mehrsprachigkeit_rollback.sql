-- Macht 002_mehrsprachigkeit.sql rückgängig. Löscht alle erfassten Übersetzungen!
BEGIN;
SET LOCAL search_path = ventilation_milheiros;
DROP TRIGGER IF EXISTS usage_types_translations_cleanup ON usage_types;
DROP TRIGGER IF EXISTS sensor_classes_translations_cleanup ON sensor_classes;
DROP TRIGGER IF EXISTS bus_types_translations_cleanup ON bus_types;
DROP TRIGGER IF EXISTS rooms_translations_cleanup ON rooms;
DROP FUNCTION IF EXISTS translations_cleanup();
DROP TABLE IF EXISTS translations;
DROP TABLE IF EXISTS languages;
COMMIT;
