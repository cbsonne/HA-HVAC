-- Macht 003_luftqualitaet_referenzwerte.sql rückgängig.
-- Löscht die mit [003] markierten Korridore (samt raumspezifischer Abweichungen),
-- alle Referenzwerte der fünf Quellen und die Quellen selbst.
-- Achtung: auch später von Hand ergänzte Referenzwerte dieser Quellen gehen verloren.
BEGIN;
SET LOCAL search_path = ventilation_milheiros;

DELETE FROM room_air_quality_corridors
WHERE corridor_id IN (SELECT corridor_id FROM air_quality_corridors WHERE reasoning_source LIKE '[003]%');
DELETE FROM air_quality_corridors WHERE reasoning_source LIKE '[003]%';

DELETE FROM air_quality_references
WHERE source_id IN (SELECT source_id FROM air_quality_sources
                    WHERE short_name IN ('DIN EN 16798-1','WHO AQG 2021','WHO IAQ 2010','WHO Radon 2009','UBA AIR'));

DELETE FROM air_quality_sources
WHERE short_name IN ('DIN EN 16798-1','WHO AQG 2021','WHO IAQ 2010','WHO Radon 2009','UBA AIR')
  AND NOT EXISTS (SELECT 1 FROM air_quality_corridors c WHERE c.source_id = air_quality_sources.source_id)
  AND NOT EXISTS (SELECT 1 FROM damper_characteristics d WHERE d.source_id = air_quality_sources.source_id);

COMMIT;
