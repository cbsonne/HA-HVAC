-- Macht 001_objekt_adresse.sql rückgängig. Löscht alle erfassten Objekte und Adressen!
BEGIN;
SET LOCAL search_path = ventilation_milheiros;
ALTER TABLE ventilation_systems DROP COLUMN IF EXISTS object_id;
DROP TABLE IF EXISTS object_addresses;
DROP TABLE IF EXISTS objects;
COMMIT;
