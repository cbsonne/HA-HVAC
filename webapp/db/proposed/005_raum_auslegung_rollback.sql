-- Rückgängig zu 005_raum_auslegung.sql
BEGIN;
DROP TABLE IF EXISTS ventilation_milheiros.room_design_airflows;
COMMIT;
