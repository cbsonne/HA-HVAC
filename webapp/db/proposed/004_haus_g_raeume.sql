-- =====================================================================
-- Haus G: Räume und Lüftungsanlage (Daten, keine Schemaänderung)
-- Erzeugt von planung-haus-g/01_lueftung/luftmengen.py (Stand 2026-10-13, RAV-Prinzip).
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
  SELECT 'G UG Waschküche', 12.73, 2.36, -1, 'Haus G', usage_type_id, 'EXHAUST', 18, 'Haus G UG, Plan: Lavandaria / Waschkueche; V=30.05 m³; Normal 12, Max 32, Rückfall 25, Min 8 m³/h; Verteiler V-UG'
  FROM usage_types WHERE name = 'Hauswirtschaft'
  ON CONFLICT (name) DO UPDATE SET area_m2 = EXCLUDED.area_m2, height_m = EXCLUDED.height_m, floor = EXCLUDED.floor, location = EXCLUDED.location, usage_type_id = EXCLUDED.usage_type_id, ventilation_type = EXCLUDED.ventilation_type, desired_temperature = EXCLUDED.desired_temperature, description = EXCLUDED.description;
INSERT INTO rooms (name, area_m2, height_m, floor, location, usage_type_id, ventilation_type, desired_temperature, description)
  SELECT 'G UG Flur', 3.85, 2.36, -1, 'Haus G', usage_type_id, 'TRANSFER', 16, 'Haus G UG, Plan: Flur UG; V=9.09 m³'
  FROM usage_types WHERE name = 'Flur'
  ON CONFLICT (name) DO UPDATE SET area_m2 = EXCLUDED.area_m2, height_m = EXCLUDED.height_m, floor = EXCLUDED.floor, location = EXCLUDED.location, usage_type_id = EXCLUDED.usage_type_id, ventilation_type = EXCLUDED.ventilation_type, desired_temperature = EXCLUDED.desired_temperature, description = EXCLUDED.description;
INSERT INTO rooms (name, area_m2, height_m, floor, location, usage_type_id, ventilation_type, desired_temperature, description)
  SELECT 'G UG WC', 1.35, 2.36, -1, 'Haus G', usage_type_id, 'EXHAUST', 18, 'Haus G UG, Plan: W.C.; V=3.18 m³; Normal 12, Max 32, Rückfall 25, Min 1 m³/h; Verteiler V-UG'
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
  SELECT 'G EG Küche', 14.26, 2.59, 0, 'Haus G', usage_type_id, 'EXHAUST', 20, 'Haus G EG, Plan: Cozinha / Kueche; V=36.94 m³; Normal 22, Max 58, Rückfall 45, Min 9 m³/h; Verteiler V-EG'
  FROM usage_types WHERE name = 'Küche'
  ON CONFLICT (name) DO UPDATE SET area_m2 = EXCLUDED.area_m2, height_m = EXCLUDED.height_m, floor = EXCLUDED.floor, location = EXCLUDED.location, usage_type_id = EXCLUDED.usage_type_id, ventilation_type = EXCLUDED.ventilation_type, desired_temperature = EXCLUDED.desired_temperature, description = EXCLUDED.description;
INSERT INTO rooms (name, area_m2, height_m, floor, location, usage_type_id, ventilation_type, desired_temperature, description)
  SELECT 'G EG Diele', 10.25, 2.59, 0, 'Haus G', usage_type_id, 'SUPPLY', 18, 'Haus G EG, Plan: Hall / Diele; V=26.54 m³; Normal 96, Max 302, Rückfall 143, Min 41 m³/h; Verteiler V-EG'
  FROM usage_types WHERE name = 'Flur'
  ON CONFLICT (name) DO UPDATE SET area_m2 = EXCLUDED.area_m2, height_m = EXCLUDED.height_m, floor = EXCLUDED.floor, location = EXCLUDED.location, usage_type_id = EXCLUDED.usage_type_id, ventilation_type = EXCLUDED.ventilation_type, desired_temperature = EXCLUDED.desired_temperature, description = EXCLUDED.description;
INSERT INTO rooms (name, area_m2, height_m, floor, location, usage_type_id, ventilation_type, desired_temperature, description)
  SELECT 'G EG WC', 1.71, 2.59, 0, 'Haus G', usage_type_id, 'EXHAUST', 20, 'Haus G EG, Plan: W.C.; V=4.42 m³; Normal 12, Max 32, Rückfall 25, Min 1 m³/h; Verteiler V-EG'
  FROM usage_types WHERE name = 'WC'
  ON CONFLICT (name) DO UPDATE SET area_m2 = EXCLUDED.area_m2, height_m = EXCLUDED.height_m, floor = EXCLUDED.floor, location = EXCLUDED.location, usage_type_id = EXCLUDED.usage_type_id, ventilation_type = EXCLUDED.ventilation_type, desired_temperature = EXCLUDED.desired_temperature, description = EXCLUDED.description;
INSERT INTO rooms (name, area_m2, height_m, floor, location, usage_type_id, ventilation_type, desired_temperature, description)
  SELECT 'G EG Speisekammer', 0.68, 2.59, 0, 'Haus G', usage_type_id, 'TRANSFER', 16, 'Haus G EG, Plan: Speisekammer; V=1.76 m³'
  FROM usage_types WHERE name = 'Abstellraum'
  ON CONFLICT (name) DO UPDATE SET area_m2 = EXCLUDED.area_m2, height_m = EXCLUDED.height_m, floor = EXCLUDED.floor, location = EXCLUDED.location, usage_type_id = EXCLUDED.usage_type_id, ventilation_type = EXCLUDED.ventilation_type, desired_temperature = EXCLUDED.desired_temperature, description = EXCLUDED.description;
INSERT INTO rooms (name, area_m2, height_m, floor, location, usage_type_id, ventilation_type, desired_temperature, description)
  SELECT 'G EG Sala', 35.10, 2.59, 0, 'Haus G', usage_type_id, 'EXHAUST', 21, 'Haus G EG, Plan: Sala / Wohnen; V=90.91 m³; Normal 36, Max 146, Rückfall 23, Min 23 m³/h; Verteiler V-EG'
  FROM usage_types WHERE name = 'Wohnzimmer'
  ON CONFLICT (name) DO UPDATE SET area_m2 = EXCLUDED.area_m2, height_m = EXCLUDED.height_m, floor = EXCLUDED.floor, location = EXCLUDED.location, usage_type_id = EXCLUDED.usage_type_id, ventilation_type = EXCLUDED.ventilation_type, desired_temperature = EXCLUDED.desired_temperature, description = EXCLUDED.description;
INSERT INTO rooms (name, area_m2, height_m, floor, location, usage_type_id, ventilation_type, desired_temperature, description)
  SELECT 'G OG1 Zimmer Straße', 18.99, 2.63, 1, 'Haus G', usage_type_id, 'EXHAUST', 19, 'Haus G OG1, Plan: Quarto / Zimmer Strasse; V=49.95 m³; Normal 24, Max 63, Rückfall 12, Min 12 m³/h; Verteiler V-OG1'
  FROM usage_types WHERE name = 'Schlafzimmer'
  ON CONFLICT (name) DO UPDATE SET area_m2 = EXCLUDED.area_m2, height_m = EXCLUDED.height_m, floor = EXCLUDED.floor, location = EXCLUDED.location, usage_type_id = EXCLUDED.usage_type_id, ventilation_type = EXCLUDED.ventilation_type, desired_temperature = EXCLUDED.desired_temperature, description = EXCLUDED.description;
INSERT INTO rooms (name, area_m2, height_m, floor, location, usage_type_id, ventilation_type, desired_temperature, description)
  SELECT 'G OG1 Bad 1', 5.40, 2.63, 1, 'Haus G', usage_type_id, 'EXHAUST', 24, 'Haus G OG1, Plan: Banho 1 / Bad; V=14.19 m³; Normal 22, Max 58, Rückfall 45, Min 4 m³/h; Verteiler V-OG1'
  FROM usage_types WHERE name = 'Bad'
  ON CONFLICT (name) DO UPDATE SET area_m2 = EXCLUDED.area_m2, height_m = EXCLUDED.height_m, floor = EXCLUDED.floor, location = EXCLUDED.location, usage_type_id = EXCLUDED.usage_type_id, ventilation_type = EXCLUDED.ventilation_type, desired_temperature = EXCLUDED.desired_temperature, description = EXCLUDED.description;
INSERT INTO rooms (name, area_m2, height_m, floor, location, usage_type_id, ventilation_type, desired_temperature, description)
  SELECT 'G OG1 Flur', 6.05, 2.63, 1, 'Haus G', usage_type_id, 'SUPPLY', 18, 'Haus G OG1, Plan: Flur OG1; V=15.90 m³; Normal 94, Max 243, Rückfall 113, Min 30 m³/h; Verteiler V-OG1'
  FROM usage_types WHERE name = 'Flur'
  ON CONFLICT (name) DO UPDATE SET area_m2 = EXCLUDED.area_m2, height_m = EXCLUDED.height_m, floor = EXCLUDED.floor, location = EXCLUDED.location, usage_type_id = EXCLUDED.usage_type_id, ventilation_type = EXCLUDED.ventilation_type, desired_temperature = EXCLUDED.desired_temperature, description = EXCLUDED.description;
INSERT INTO rooms (name, area_m2, height_m, floor, location, usage_type_id, ventilation_type, desired_temperature, description)
  SELECT 'G OG1 Bad 2', 5.41, 2.63, 1, 'Haus G', usage_type_id, 'EXHAUST', 24, 'Haus G OG1, Plan: Banho 2 / Bad; V=14.23 m³; Normal 22, Max 58, Rückfall 45, Min 4 m³/h; Verteiler V-OG1'
  FROM usage_types WHERE name = 'Bad'
  ON CONFLICT (name) DO UPDATE SET area_m2 = EXCLUDED.area_m2, height_m = EXCLUDED.height_m, floor = EXCLUDED.floor, location = EXCLUDED.location, usage_type_id = EXCLUDED.usage_type_id, ventilation_type = EXCLUDED.ventilation_type, desired_temperature = EXCLUDED.desired_temperature, description = EXCLUDED.description;
INSERT INTO rooms (name, area_m2, height_m, floor, location, usage_type_id, ventilation_type, desired_temperature, description)
  SELECT 'G OG1 Zimmer Garten', 16.22, 2.63, 1, 'Haus G', usage_type_id, 'EXHAUST', 19, 'Haus G OG1, Plan: Quarto / Zimmer Garten; V=42.66 m³; Normal 24, Max 63, Rückfall 11, Min 11 m³/h; Verteiler V-OG1'
  FROM usage_types WHERE name = 'Schlafzimmer'
  ON CONFLICT (name) DO UPDATE SET area_m2 = EXCLUDED.area_m2, height_m = EXCLUDED.height_m, floor = EXCLUDED.floor, location = EXCLUDED.location, usage_type_id = EXCLUDED.usage_type_id, ventilation_type = EXCLUDED.ventilation_type, desired_temperature = EXCLUDED.desired_temperature, description = EXCLUDED.description;
INSERT INTO rooms (name, area_m2, height_m, floor, location, usage_type_id, ventilation_type, desired_temperature, description)
  SELECT 'G OG2 Zimmer Straße', 17.67, 2.63, 2, 'Haus G', usage_type_id, 'EXHAUST', 19, 'Haus G OG2, Plan: Quarto / Zimmer Strasse; V=46.46 m³; Normal 24, Max 63, Rückfall 12, Min 12 m³/h; Verteiler V-OG2'
  FROM usage_types WHERE name = 'Schlafzimmer'
  ON CONFLICT (name) DO UPDATE SET area_m2 = EXCLUDED.area_m2, height_m = EXCLUDED.height_m, floor = EXCLUDED.floor, location = EXCLUDED.location, usage_type_id = EXCLUDED.usage_type_id, ventilation_type = EXCLUDED.ventilation_type, desired_temperature = EXCLUDED.desired_temperature, description = EXCLUDED.description;
INSERT INTO rooms (name, area_m2, height_m, floor, location, usage_type_id, ventilation_type, desired_temperature, description)
  SELECT 'G OG2 Bad', 5.85, 2.63, 2, 'Haus G', usage_type_id, 'EXHAUST', 24, 'Haus G OG2, Plan: Banho / Bad; V=15.39 m³; Normal 22, Max 58, Rückfall 45, Min 4 m³/h; Verteiler V-OG2'
  FROM usage_types WHERE name = 'Bad'
  ON CONFLICT (name) DO UPDATE SET area_m2 = EXCLUDED.area_m2, height_m = EXCLUDED.height_m, floor = EXCLUDED.floor, location = EXCLUDED.location, usage_type_id = EXCLUDED.usage_type_id, ventilation_type = EXCLUDED.ventilation_type, desired_temperature = EXCLUDED.desired_temperature, description = EXCLUDED.description;
INSERT INTO rooms (name, area_m2, height_m, floor, location, usage_type_id, ventilation_type, desired_temperature, description)
  SELECT 'G OG2 Flur', 14.43, 2.63, 2, 'Haus G', usage_type_id, 'SUPPLY', 18, 'Haus G OG2, Plan: Flur OG2; V=37.95 m³; Normal 65, Max 169, Rückfall 67, Min 25 m³/h; Verteiler V-OG2'
  FROM usage_types WHERE name = 'Flur'
  ON CONFLICT (name) DO UPDATE SET area_m2 = EXCLUDED.area_m2, height_m = EXCLUDED.height_m, floor = EXCLUDED.floor, location = EXCLUDED.location, usage_type_id = EXCLUDED.usage_type_id, ventilation_type = EXCLUDED.ventilation_type, desired_temperature = EXCLUDED.desired_temperature, description = EXCLUDED.description;
INSERT INTO rooms (name, area_m2, height_m, floor, location, usage_type_id, ventilation_type, desired_temperature, description)
  SELECT 'G OG2 Arbeitszimmer (Zimmer Garten)', 15.08, 2.63, 2, 'Haus G', usage_type_id, 'EXHAUST', 20, 'Haus G OG2, Plan: Quarto / Zimmer Garten; V=39.66 m³; Normal 18, Max 47, Rückfall 10, Min 10 m³/h; Verteiler V-OG2'
  FROM usage_types WHERE name = 'Arbeitszimmer'
  ON CONFLICT (name) DO UPDATE SET area_m2 = EXCLUDED.area_m2, height_m = EXCLUDED.height_m, floor = EXCLUDED.floor, location = EXCLUDED.location, usage_type_id = EXCLUDED.usage_type_id, ventilation_type = EXCLUDED.ventilation_type, desired_temperature = EXCLUDED.desired_temperature, description = EXCLUDED.description;

-- Lüftungsanlage: max = Gerät bei 100 % (NL bei 60 %), fault = Rückfall (Nassräume DIN, Wohnräume 0,25 1/h),
-- min = Untergrenze 0,20 1/h.
INSERT INTO ventilation_systems (name, min_airflow_m3h, max_airflow_m3h, fault_airflow_m3h, description)
VALUES ('KWL Haus G', 96, 425, 322, 'Zentrales KWL-Gerät, RAV-Prinzip (Zuluft Flure, Abluft je Raum mit Klappe+Sensor). DIN 1946-6: FL 47, NL 255 m³/h (60 % Lüfter). Rückfall 322 m³/h. Summe Raum-Maxima 714 m³/h > Gerät, Verteilung nach Priorität.')
ON CONFLICT (name) DO UPDATE SET min_airflow_m3h = EXCLUDED.min_airflow_m3h, max_airflow_m3h = EXCLUDED.max_airflow_m3h,
  fault_airflow_m3h = EXCLUDED.fault_airflow_m3h, description = EXCLUDED.description;

COMMIT;
