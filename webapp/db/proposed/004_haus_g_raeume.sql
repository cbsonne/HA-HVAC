-- =====================================================================
-- Haus G: Räume und Lüftungsanlage (Daten, keine Schemaänderung)
-- Erzeugt von planung-haus-g/01_lueftung/luftmengen.py am 2026-10-12.
-- Quelle: haus-g/Haus_G_Raeume.csv (Aufmaß bis 12.10.2026).
-- Idempotent: vorhandene Einträge gleichen Namens werden aktualisiert.
-- Anwenden (nach Backup):
--   psql -h <host> -U <user> -d solver -v ON_ERROR_STOP=1 -f 004_haus_g_raeume.sql
-- =====================================================================

BEGIN;
SET LOCAL search_path = ventilation_milheiros;

-- Nutzungsarten
INSERT INTO usage_types (name, description) VALUES ('Abstellraum', 'Haus G') ON CONFLICT (name) DO NOTHING;
INSERT INTO usage_types (name, description) VALUES ('Arbeitszimmer', 'Haus G') ON CONFLICT (name) DO NOTHING;
INSERT INTO usage_types (name, description) VALUES ('Bad', 'Haus G') ON CONFLICT (name) DO NOTHING;
INSERT INTO usage_types (name, description) VALUES ('Flur', 'Haus G') ON CONFLICT (name) DO NOTHING;
INSERT INTO usage_types (name, description) VALUES ('Garage', 'Haus G') ON CONFLICT (name) DO NOTHING;
INSERT INTO usage_types (name, description) VALUES ('Hauswirtschaft', 'Haus G') ON CONFLICT (name) DO NOTHING;
INSERT INTO usage_types (name, description) VALUES ('Küche', 'Haus G') ON CONFLICT (name) DO NOTHING;
INSERT INTO usage_types (name, description) VALUES ('Schlafzimmer', 'Haus G') ON CONFLICT (name) DO NOTHING;
INSERT INTO usage_types (name, description) VALUES ('WC', 'Haus G') ON CONFLICT (name) DO NOTHING;
INSERT INTO usage_types (name, description) VALUES ('Wohnzimmer', 'Haus G') ON CONFLICT (name) DO NOTHING;

-- Räume (Namen global eindeutig, daher mit Geschoss-Präfix)
INSERT INTO rooms (name, area_m2, height_m, floor, location, usage_type_id, ventilation_type, desired_temperature, description)
  SELECT 'G UG Abstellraum', 10.52, 2.36, -1, 'Haus G', usage_type_id, 'NONE', 16, 'Haus G UG, Plan: Arrumos / Abstellraum; V=24.83 m³'
  FROM usage_types WHERE name = 'Abstellraum'
  ON CONFLICT (name) DO UPDATE SET area_m2 = EXCLUDED.area_m2, height_m = EXCLUDED.height_m, floor = EXCLUDED.floor, location = EXCLUDED.location, usage_type_id = EXCLUDED.usage_type_id, ventilation_type = EXCLUDED.ventilation_type, desired_temperature = EXCLUDED.desired_temperature, description = EXCLUDED.description;
INSERT INTO rooms (name, area_m2, height_m, floor, location, usage_type_id, ventilation_type, desired_temperature, description)
  SELECT 'G UG Waschküche', 12.73, 2.36, -1, 'Haus G', usage_type_id, 'EXHAUST', 18, 'Haus G UG, Plan: Lavandaria / Waschkueche; V=30.05 m³; NL 25, Intensiv 38, Min 8 m³/h; Verteiler V-UG'
  FROM usage_types WHERE name = 'Hauswirtschaft'
  ON CONFLICT (name) DO UPDATE SET area_m2 = EXCLUDED.area_m2, height_m = EXCLUDED.height_m, floor = EXCLUDED.floor, location = EXCLUDED.location, usage_type_id = EXCLUDED.usage_type_id, ventilation_type = EXCLUDED.ventilation_type, desired_temperature = EXCLUDED.desired_temperature, description = EXCLUDED.description;
INSERT INTO rooms (name, area_m2, height_m, floor, location, usage_type_id, ventilation_type, desired_temperature, description)
  SELECT 'G UG Flur', 3.85, 2.36, -1, 'Haus G', usage_type_id, 'TRANSFER', 16, 'Haus G UG, Plan: Flur UG; V=9.09 m³'
  FROM usage_types WHERE name = 'Flur'
  ON CONFLICT (name) DO UPDATE SET area_m2 = EXCLUDED.area_m2, height_m = EXCLUDED.height_m, floor = EXCLUDED.floor, location = EXCLUDED.location, usage_type_id = EXCLUDED.usage_type_id, ventilation_type = EXCLUDED.ventilation_type, desired_temperature = EXCLUDED.desired_temperature, description = EXCLUDED.description;
INSERT INTO rooms (name, area_m2, height_m, floor, location, usage_type_id, ventilation_type, desired_temperature, description)
  SELECT 'G UG WC', 1.35, 2.36, -1, 'Haus G', usage_type_id, 'EXHAUST', 18, 'Haus G UG, Plan: W.C.; V=3.18 m³; NL 25, Intensiv 38, Min 5 m³/h; Verteiler V-UG'
  FROM usage_types WHERE name = 'WC'
  ON CONFLICT (name) DO UPDATE SET area_m2 = EXCLUDED.area_m2, height_m = EXCLUDED.height_m, floor = EXCLUDED.floor, location = EXCLUDED.location, usage_type_id = EXCLUDED.usage_type_id, ventilation_type = EXCLUDED.ventilation_type, desired_temperature = EXCLUDED.desired_temperature, description = EXCLUDED.description;
INSERT INTO rooms (name, area_m2, height_m, floor, location, usage_type_id, ventilation_type, desired_temperature, description)
  SELECT 'G UG Nische Garage', 1.17, 2.36, -1, 'Haus G', usage_type_id, 'NONE', NULL, 'Haus G UG, Plan: Nische (Zugang Garage); V=2.77 m³'
  FROM usage_types WHERE name = 'Abstellraum'
  ON CONFLICT (name) DO UPDATE SET area_m2 = EXCLUDED.area_m2, height_m = EXCLUDED.height_m, floor = EXCLUDED.floor, location = EXCLUDED.location, usage_type_id = EXCLUDED.usage_type_id, ventilation_type = EXCLUDED.ventilation_type, desired_temperature = EXCLUDED.desired_temperature, description = EXCLUDED.description;
INSERT INTO rooms (name, area_m2, height_m, floor, location, usage_type_id, ventilation_type, desired_temperature, description)
  SELECT 'G UG Arrumos unter Treppe', 2.30, 2.36, -1, 'Haus G', usage_type_id, 'NONE', NULL, 'Haus G UG, Plan: Arrumos (unter Treppe); V=5.44 m³'
  FROM usage_types WHERE name = 'Abstellraum'
  ON CONFLICT (name) DO UPDATE SET area_m2 = EXCLUDED.area_m2, height_m = EXCLUDED.height_m, floor = EXCLUDED.floor, location = EXCLUDED.location, usage_type_id = EXCLUDED.usage_type_id, ventilation_type = EXCLUDED.ventilation_type, desired_temperature = EXCLUDED.desired_temperature, description = EXCLUDED.description;
INSERT INTO rooms (name, area_m2, height_m, floor, location, usage_type_id, ventilation_type, desired_temperature, description)
  SELECT 'G UG Garage', 29.65, 2.97, -1, 'Haus G', usage_type_id, 'NONE', NULL, 'Haus G UG, Plan: Estacionamento / Garage; V=88.05 m³'
  FROM usage_types WHERE name = 'Garage'
  ON CONFLICT (name) DO UPDATE SET area_m2 = EXCLUDED.area_m2, height_m = EXCLUDED.height_m, floor = EXCLUDED.floor, location = EXCLUDED.location, usage_type_id = EXCLUDED.usage_type_id, ventilation_type = EXCLUDED.ventilation_type, desired_temperature = EXCLUDED.desired_temperature, description = EXCLUDED.description;
INSERT INTO rooms (name, area_m2, height_m, floor, location, usage_type_id, ventilation_type, desired_temperature, description)
  SELECT 'G UG Abgang Garage', 1.57, 2.36, -1, 'Haus G', usage_type_id, 'NONE', NULL, 'Haus G UG, Plan: Abgang Garage (4 Stufen, 56 cm); V=3.70 m³'
  FROM usage_types WHERE name = 'Garage'
  ON CONFLICT (name) DO UPDATE SET area_m2 = EXCLUDED.area_m2, height_m = EXCLUDED.height_m, floor = EXCLUDED.floor, location = EXCLUDED.location, usage_type_id = EXCLUDED.usage_type_id, ventilation_type = EXCLUDED.ventilation_type, desired_temperature = EXCLUDED.desired_temperature, description = EXCLUDED.description;
INSERT INTO rooms (name, area_m2, height_m, floor, location, usage_type_id, ventilation_type, desired_temperature, description)
  SELECT 'G EG Küche', 14.26, 2.59, 0, 'Haus G', usage_type_id, 'EXHAUST', 20, 'Haus G EG, Plan: Cozinha / Kueche; V=36.94 m³; NL 45, Intensiv 68, Min 9 m³/h; Verteiler V-EG'
  FROM usage_types WHERE name = 'Küche'
  ON CONFLICT (name) DO UPDATE SET area_m2 = EXCLUDED.area_m2, height_m = EXCLUDED.height_m, floor = EXCLUDED.floor, location = EXCLUDED.location, usage_type_id = EXCLUDED.usage_type_id, ventilation_type = EXCLUDED.ventilation_type, desired_temperature = EXCLUDED.desired_temperature, description = EXCLUDED.description;
INSERT INTO rooms (name, area_m2, height_m, floor, location, usage_type_id, ventilation_type, desired_temperature, description)
  SELECT 'G EG Diele', 10.25, 2.59, 0, 'Haus G', usage_type_id, 'TRANSFER', 18, 'Haus G EG, Plan: Hall / Diele; V=26.54 m³'
  FROM usage_types WHERE name = 'Flur'
  ON CONFLICT (name) DO UPDATE SET area_m2 = EXCLUDED.area_m2, height_m = EXCLUDED.height_m, floor = EXCLUDED.floor, location = EXCLUDED.location, usage_type_id = EXCLUDED.usage_type_id, ventilation_type = EXCLUDED.ventilation_type, desired_temperature = EXCLUDED.desired_temperature, description = EXCLUDED.description;
INSERT INTO rooms (name, area_m2, height_m, floor, location, usage_type_id, ventilation_type, desired_temperature, description)
  SELECT 'G EG WC', 1.71, 2.59, 0, 'Haus G', usage_type_id, 'EXHAUST', 20, 'Haus G EG, Plan: W.C.; V=4.42 m³; NL 25, Intensiv 38, Min 5 m³/h; Verteiler V-EG'
  FROM usage_types WHERE name = 'WC'
  ON CONFLICT (name) DO UPDATE SET area_m2 = EXCLUDED.area_m2, height_m = EXCLUDED.height_m, floor = EXCLUDED.floor, location = EXCLUDED.location, usage_type_id = EXCLUDED.usage_type_id, ventilation_type = EXCLUDED.ventilation_type, desired_temperature = EXCLUDED.desired_temperature, description = EXCLUDED.description;
INSERT INTO rooms (name, area_m2, height_m, floor, location, usage_type_id, ventilation_type, desired_temperature, description)
  SELECT 'G EG Speisekammer', 0.68, 2.59, 0, 'Haus G', usage_type_id, 'TRANSFER', 16, 'Haus G EG, Plan: Speisekammer; V=1.76 m³'
  FROM usage_types WHERE name = 'Abstellraum'
  ON CONFLICT (name) DO UPDATE SET area_m2 = EXCLUDED.area_m2, height_m = EXCLUDED.height_m, floor = EXCLUDED.floor, location = EXCLUDED.location, usage_type_id = EXCLUDED.usage_type_id, ventilation_type = EXCLUDED.ventilation_type, desired_temperature = EXCLUDED.desired_temperature, description = EXCLUDED.description;
INSERT INTO rooms (name, area_m2, height_m, floor, location, usage_type_id, ventilation_type, desired_temperature, description)
  SELECT 'G EG Sala', 35.10, 2.59, 0, 'Haus G', usage_type_id, 'SUPPLY', 21, 'Haus G EG, Plan: Sala / Wohnen; V=90.91 m³; NL 73, Intensiv 146, Min 23 m³/h; Verteiler V-EG'
  FROM usage_types WHERE name = 'Wohnzimmer'
  ON CONFLICT (name) DO UPDATE SET area_m2 = EXCLUDED.area_m2, height_m = EXCLUDED.height_m, floor = EXCLUDED.floor, location = EXCLUDED.location, usage_type_id = EXCLUDED.usage_type_id, ventilation_type = EXCLUDED.ventilation_type, desired_temperature = EXCLUDED.desired_temperature, description = EXCLUDED.description;
INSERT INTO rooms (name, area_m2, height_m, floor, location, usage_type_id, ventilation_type, desired_temperature, description)
  SELECT 'G OG1 Zimmer Straße', 18.99, 2.63, 1, 'Haus G', usage_type_id, 'SUPPLY', 19, 'Haus G OG1, Plan: Quarto / Zimmer Strasse; V=49.95 m³; NL 49, Intensiv 63, Min 12 m³/h; Verteiler V-OG1'
  FROM usage_types WHERE name = 'Schlafzimmer'
  ON CONFLICT (name) DO UPDATE SET area_m2 = EXCLUDED.area_m2, height_m = EXCLUDED.height_m, floor = EXCLUDED.floor, location = EXCLUDED.location, usage_type_id = EXCLUDED.usage_type_id, ventilation_type = EXCLUDED.ventilation_type, desired_temperature = EXCLUDED.desired_temperature, description = EXCLUDED.description;
INSERT INTO rooms (name, area_m2, height_m, floor, location, usage_type_id, ventilation_type, desired_temperature, description)
  SELECT 'G OG1 Bad 1', 5.40, 2.63, 1, 'Haus G', usage_type_id, 'EXHAUST', 24, 'Haus G OG1, Plan: Banho 1 / Bad; V=14.19 m³; NL 45, Intensiv 68, Min 8 m³/h; Verteiler V-OG1'
  FROM usage_types WHERE name = 'Bad'
  ON CONFLICT (name) DO UPDATE SET area_m2 = EXCLUDED.area_m2, height_m = EXCLUDED.height_m, floor = EXCLUDED.floor, location = EXCLUDED.location, usage_type_id = EXCLUDED.usage_type_id, ventilation_type = EXCLUDED.ventilation_type, desired_temperature = EXCLUDED.desired_temperature, description = EXCLUDED.description;
INSERT INTO rooms (name, area_m2, height_m, floor, location, usage_type_id, ventilation_type, desired_temperature, description)
  SELECT 'G OG1 Flur', 6.05, 2.63, 1, 'Haus G', usage_type_id, 'TRANSFER', 18, 'Haus G OG1, Plan: Flur OG1; V=15.90 m³'
  FROM usage_types WHERE name = 'Flur'
  ON CONFLICT (name) DO UPDATE SET area_m2 = EXCLUDED.area_m2, height_m = EXCLUDED.height_m, floor = EXCLUDED.floor, location = EXCLUDED.location, usage_type_id = EXCLUDED.usage_type_id, ventilation_type = EXCLUDED.ventilation_type, desired_temperature = EXCLUDED.desired_temperature, description = EXCLUDED.description;
INSERT INTO rooms (name, area_m2, height_m, floor, location, usage_type_id, ventilation_type, desired_temperature, description)
  SELECT 'G OG1 Bad 2', 5.41, 2.63, 1, 'Haus G', usage_type_id, 'EXHAUST', 24, 'Haus G OG1, Plan: Banho 2 / Bad; V=14.23 m³; NL 45, Intensiv 68, Min 8 m³/h; Verteiler V-OG1'
  FROM usage_types WHERE name = 'Bad'
  ON CONFLICT (name) DO UPDATE SET area_m2 = EXCLUDED.area_m2, height_m = EXCLUDED.height_m, floor = EXCLUDED.floor, location = EXCLUDED.location, usage_type_id = EXCLUDED.usage_type_id, ventilation_type = EXCLUDED.ventilation_type, desired_temperature = EXCLUDED.desired_temperature, description = EXCLUDED.description;
INSERT INTO rooms (name, area_m2, height_m, floor, location, usage_type_id, ventilation_type, desired_temperature, description)
  SELECT 'G OG1 Zimmer Garten', 16.22, 2.63, 1, 'Haus G', usage_type_id, 'SUPPLY', 19, 'Haus G OG1, Plan: Quarto / Zimmer Garten; V=42.66 m³; NL 49, Intensiv 63, Min 11 m³/h; Verteiler V-OG1'
  FROM usage_types WHERE name = 'Schlafzimmer'
  ON CONFLICT (name) DO UPDATE SET area_m2 = EXCLUDED.area_m2, height_m = EXCLUDED.height_m, floor = EXCLUDED.floor, location = EXCLUDED.location, usage_type_id = EXCLUDED.usage_type_id, ventilation_type = EXCLUDED.ventilation_type, desired_temperature = EXCLUDED.desired_temperature, description = EXCLUDED.description;
INSERT INTO rooms (name, area_m2, height_m, floor, location, usage_type_id, ventilation_type, desired_temperature, description)
  SELECT 'G OG2 Zimmer Straße', 17.67, 2.63, 2, 'Haus G', usage_type_id, 'SUPPLY', 19, 'Haus G OG2, Plan: Quarto / Zimmer Strasse; V=46.46 m³; NL 49, Intensiv 63, Min 12 m³/h; Verteiler V-OG2'
  FROM usage_types WHERE name = 'Schlafzimmer'
  ON CONFLICT (name) DO UPDATE SET area_m2 = EXCLUDED.area_m2, height_m = EXCLUDED.height_m, floor = EXCLUDED.floor, location = EXCLUDED.location, usage_type_id = EXCLUDED.usage_type_id, ventilation_type = EXCLUDED.ventilation_type, desired_temperature = EXCLUDED.desired_temperature, description = EXCLUDED.description;
INSERT INTO rooms (name, area_m2, height_m, floor, location, usage_type_id, ventilation_type, desired_temperature, description)
  SELECT 'G OG2 Bad', 5.85, 2.63, 2, 'Haus G', usage_type_id, 'EXHAUST', 24, 'Haus G OG2, Plan: Banho / Bad; V=15.39 m³; NL 45, Intensiv 68, Min 8 m³/h; Verteiler V-OG2'
  FROM usage_types WHERE name = 'Bad'
  ON CONFLICT (name) DO UPDATE SET area_m2 = EXCLUDED.area_m2, height_m = EXCLUDED.height_m, floor = EXCLUDED.floor, location = EXCLUDED.location, usage_type_id = EXCLUDED.usage_type_id, ventilation_type = EXCLUDED.ventilation_type, desired_temperature = EXCLUDED.desired_temperature, description = EXCLUDED.description;
INSERT INTO rooms (name, area_m2, height_m, floor, location, usage_type_id, ventilation_type, desired_temperature, description)
  SELECT 'G OG2 Flur', 14.43, 2.63, 2, 'Haus G', usage_type_id, 'TRANSFER', 18, 'Haus G OG2, Plan: Flur OG2; V=37.95 m³'
  FROM usage_types WHERE name = 'Flur'
  ON CONFLICT (name) DO UPDATE SET area_m2 = EXCLUDED.area_m2, height_m = EXCLUDED.height_m, floor = EXCLUDED.floor, location = EXCLUDED.location, usage_type_id = EXCLUDED.usage_type_id, ventilation_type = EXCLUDED.ventilation_type, desired_temperature = EXCLUDED.desired_temperature, description = EXCLUDED.description;
INSERT INTO rooms (name, area_m2, height_m, floor, location, usage_type_id, ventilation_type, desired_temperature, description)
  SELECT 'G OG2 Arbeitszimmer (Zimmer Garten)', 15.08, 2.63, 2, 'Haus G', usage_type_id, 'SUPPLY', 20, 'Haus G OG2, Plan: Quarto / Zimmer Garten; V=39.66 m³; NL 36, Intensiv 47, Min 10 m³/h; Verteiler V-OG2'
  FROM usage_types WHERE name = 'Arbeitszimmer'
  ON CONFLICT (name) DO UPDATE SET area_m2 = EXCLUDED.area_m2, height_m = EXCLUDED.height_m, floor = EXCLUDED.floor, location = EXCLUDED.location, usage_type_id = EXCLUDED.usage_type_id, ventilation_type = EXCLUDED.ventilation_type, desired_temperature = EXCLUDED.desired_temperature, description = EXCLUDED.description;

-- Lüftungsanlage: max = maximale Intensivlüftung (alle Räume 130 %, Sala 200 %, balanciert),
-- fault = DIN-Nennlüftung (Rückfall bei Regelungsausfall), min = Untergrenze 0,20 1/h.
INSERT INTO ventilation_systems (name, min_airflow_m3h, max_airflow_m3h, fault_airflow_m3h, description)
VALUES ('KWL Haus G', 96, 382, 255, 'Zentrales KWL-Gerät auf dem Dach. DIN 1946-6: FL 47, NL 255, Intensiv 382 m³/h. Gerät ≥ 425 m³/h (NL bei 60 %).')
ON CONFLICT (name) DO UPDATE SET min_airflow_m3h = EXCLUDED.min_airflow_m3h, max_airflow_m3h = EXCLUDED.max_airflow_m3h,
  fault_airflow_m3h = EXCLUDED.fault_airflow_m3h, description = EXCLUDED.description;

COMMIT;
