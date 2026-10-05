-- =====================================================================
-- VORSCHLAG (noch nicht angewendet): Referenzwerte Luftqualität
-- =====================================================================
-- Nur Daten, keine Schemaänderung. Befüllt:
--   air_quality_sources      Quellen (Normen, Leitlinien)
--   air_quality_references   Einzelwerte je Quelle, Kategorie und Mittelungszeit
--   air_quality_corridors    Korridor je Parameter für die Berechnung
--
-- Regel (Vorgabe Nutzer 2026-10-05): DIN/EN-Normwerte eintragen, konkurrierende
-- WHO-Werte zusätzlich. Für die Berechnung gilt immer der strengere Wert;
-- deshalb steht im Korridor bei max_value der niedrigste Grenzwert aller
-- Quellen, bei min_value die höchste Untergrenze. Woher der Wert kommt,
-- steht in reasoning_source.
--
-- Zusätzlich aufgenommen: UBA-Ausschuss für Innenraumrichtwerte (AIR). Das ist
-- weder DIN/EN noch WHO, aber die in Deutschland übliche Bewertung für CO2 und
-- TVOC. Wer sie nicht will: in air_quality_sources active = false setzen und
-- die Korridore CO2/TVOC anpassen.
--
-- EN 16798-1 nennt CO2 als Differenz zur Außenluft (Kat. I/II/III: 550/800/1350 ppm).
-- Hier umgerechnet auf absolute Werte mit 400 ppm Außenluft, damit sie mit den
-- Sensorwerten und dem UBA-Wert vergleichbar sind.
-- Für EN 16798-1 gilt Kategorie II (Wohnen, normales Maß an Erwartungen) als
-- Grundlage der Korridore; Kat. I und III stehen zum Umstellen in den Referenzen.
--
-- Die Zahlen stammen aus Fachwissen und sind NICHT gegen die Normtexte geprüft.
-- Bitte vor produktiver Nutzung mit den Originaldokumenten abgleichen.
--
-- Mehrfach ausführbar: vorhandene Quellen, Referenzen und Korridore
-- (gleicher Parameter + Einheit) bleiben unverändert.
--
-- Anwenden (nach Backup!): in pgAdmin im Query Tool öffnen und ausführen,
-- oder: psql -d solver -v ON_ERROR_STOP=1 -f 003_luftqualitaet_referenzwerte.sql
-- Rückgängig: 003_luftqualitaet_referenzwerte_rollback.sql
-- =====================================================================

BEGIN;

SET LOCAL search_path = ventilation_milheiros;

-- ---------------------------------------------------------------------
-- Quellen
-- ---------------------------------------------------------------------
INSERT INTO air_quality_sources
    (short_name, full_name, authority, document_reference, version, publication_year, is_norm, is_guideline)
VALUES
    ('DIN EN 16798-1',
     'Energetische Bewertung von Gebäuden – Lüftung von Gebäuden – Teil 1: Eingangsparameter für das Innenraumklima',
     'DIN / CEN', 'DIN EN 16798-1:2022-03 (EN 16798-1:2019)', '2022-03', 2022, true, false),
    ('WHO AQG 2021',
     'WHO global air quality guidelines: particulate matter (PM2.5 and PM10), ozone, nitrogen dioxide, sulfur dioxide and carbon monoxide',
     'WHO', 'ISBN 978-92-4-003422-8', '2021', 2021, false, true),
    ('WHO IAQ 2010',
     'WHO guidelines for indoor air quality: selected pollutants',
     'WHO Regional Office for Europe', 'ISBN 978-92-890-0213-4', '2010', 2010, false, true),
    ('WHO Radon 2009',
     'WHO handbook on indoor radon: a public health perspective',
     'WHO', 'ISBN 978-92-4-154767-3', '2009', 2009, false, true),
    ('UBA AIR',
     'Richtwerte und Leitwerte für die Innenraumluft des Ausschusses für Innenraumrichtwerte',
     'Umweltbundesamt (AIR)', 'Bundesgesundheitsblatt, laufende Veröffentlichungen', 'Stand 2024', 2024, false, true)
ON CONFLICT (short_name) DO NOTHING;

-- ---------------------------------------------------------------------
-- Referenzwerte
-- ---------------------------------------------------------------------
INSERT INTO air_quality_references (source_id, parameter, unit, averaging_time, value, category, notes)
SELECT s.source_id, v.parameter, v.unit, v.averaging_time, v.value, v.category, v.notes
FROM (VALUES
    -- DIN EN 16798-1: CO2 (absolut bei 400 ppm Außenluft)
    ('DIN EN 16798-1', 'CO2', 'ppm', 'Aufenthaltszeit', 950,  'Kat. I',   'Norm: 550 ppm über Außenluft'),
    ('DIN EN 16798-1', 'CO2', 'ppm', 'Aufenthaltszeit', 1200, 'Kat. II',  'Norm: 800 ppm über Außenluft'),
    ('DIN EN 16798-1', 'CO2', 'ppm', 'Aufenthaltszeit', 1750, 'Kat. III', 'Norm: 1350 ppm über Außenluft'),
    -- DIN EN 16798-1: relative Feuchte (Auslegung Be-/Entfeuchtung)
    ('DIN EN 16798-1', 'Relative Luftfeuchte', '%', 'Aufenthaltszeit', 30, 'Kat. I, untere Grenze',   NULL),
    ('DIN EN 16798-1', 'Relative Luftfeuchte', '%', 'Aufenthaltszeit', 50, 'Kat. I, obere Grenze',    NULL),
    ('DIN EN 16798-1', 'Relative Luftfeuchte', '%', 'Aufenthaltszeit', 25, 'Kat. II, untere Grenze',  NULL),
    ('DIN EN 16798-1', 'Relative Luftfeuchte', '%', 'Aufenthaltszeit', 60, 'Kat. II, obere Grenze',   NULL),
    ('DIN EN 16798-1', 'Relative Luftfeuchte', '%', 'Aufenthaltszeit', 20, 'Kat. III, untere Grenze', NULL),
    ('DIN EN 16798-1', 'Relative Luftfeuchte', '%', 'Aufenthaltszeit', 70, 'Kat. III, obere Grenze',  NULL),
    -- DIN EN 16798-1: operative Temperatur Wohnräume
    ('DIN EN 16798-1', 'Operative Temperatur', '°C', 'Heizperiode',  21,   'Kat. I, untere Grenze',   'Wohnräume'),
    ('DIN EN 16798-1', 'Operative Temperatur', '°C', 'Kühlperiode',  25.5, 'Kat. I, obere Grenze',    'Wohnräume'),
    ('DIN EN 16798-1', 'Operative Temperatur', '°C', 'Heizperiode',  20,   'Kat. II, untere Grenze',  'Wohnräume'),
    ('DIN EN 16798-1', 'Operative Temperatur', '°C', 'Kühlperiode',  26,   'Kat. II, obere Grenze',   'Wohnräume'),
    ('DIN EN 16798-1', 'Operative Temperatur', '°C', 'Heizperiode',  18,   'Kat. III, untere Grenze', 'Wohnräume'),
    ('DIN EN 16798-1', 'Operative Temperatur', '°C', 'Kühlperiode',  27,   'Kat. III, obere Grenze',  'Wohnräume'),

    -- WHO 2021 (Außenluft-Leitwerte, für Innenräume übertragbar)
    ('WHO AQG 2021', 'PM2.5', 'µg/m³', 'Jahr',  5,   'AQG-Leitwert', NULL),
    ('WHO AQG 2021', 'PM2.5', 'µg/m³', '24 h',  15,  'AQG-Leitwert', '99. Perzentil'),
    ('WHO AQG 2021', 'PM10',  'µg/m³', 'Jahr',  15,  'AQG-Leitwert', NULL),
    ('WHO AQG 2021', 'PM10',  'µg/m³', '24 h',  45,  'AQG-Leitwert', '99. Perzentil'),
    ('WHO AQG 2021', 'NO2',   'µg/m³', 'Jahr',  10,  'AQG-Leitwert', NULL),
    ('WHO AQG 2021', 'NO2',   'µg/m³', '24 h',  25,  'AQG-Leitwert', '99. Perzentil'),
    ('WHO AQG 2021', 'O3',    'µg/m³', '8 h',   100, 'AQG-Leitwert', 'höchster täglicher 8-h-Mittelwert'),
    ('WHO AQG 2021', 'O3',    'µg/m³', 'Spitzensaison', 60, 'AQG-Leitwert', 'Mittel der täglichen 8-h-Maxima über 6 Monate'),
    ('WHO AQG 2021', 'SO2',   'µg/m³', '24 h',  40,  'AQG-Leitwert', '99. Perzentil'),
    ('WHO AQG 2021', 'CO',    'mg/m³', '24 h',  4,   'AQG-Leitwert', NULL),

    -- WHO 2010 Innenraum
    ('WHO IAQ 2010', 'Formaldehyd', 'µg/m³', '30 min', 100,  'Leitwert', '0,1 mg/m³'),
    ('WHO IAQ 2010', 'NO2',         'µg/m³', '1 h',    200,  'Leitwert', NULL),
    ('WHO IAQ 2010', 'NO2',         'µg/m³', 'Jahr',   40,   'Leitwert', 'durch WHO AQG 2021 (10 µg/m³) verschärft'),
    ('WHO IAQ 2010', 'CO',          'mg/m³', '15 min', 100,  'Leitwert', NULL),
    ('WHO IAQ 2010', 'CO',          'mg/m³', '1 h',    35,   'Leitwert', NULL),
    ('WHO IAQ 2010', 'CO',          'mg/m³', '8 h',    10,   'Leitwert', NULL),
    ('WHO IAQ 2010', 'CO',          'mg/m³', '24 h',   7,    'Leitwert', 'durch WHO AQG 2021 (4 mg/m³) verschärft'),
    ('WHO IAQ 2010', 'Naphthalin',  'µg/m³', 'Jahr',   10,   'Leitwert', '0,01 mg/m³'),
    ('WHO IAQ 2010', 'Benzol',      'µg/m³', 'Jahr',   NULL, 'kein sicherer Wert', 'Einheitsrisiko 6·10⁻⁶ je µg/m³; Belastung so gering wie möglich'),

    -- WHO Radon
    ('WHO Radon 2009', 'Radon', 'Bq/m³', 'Jahr', 100, 'Referenzwert', 'wo nicht erreichbar höchstens 300 Bq/m³'),

    -- UBA AIR
    ('UBA AIR', 'CO2',         'ppm',   'Aufenthaltszeit', 1000, 'Leitwert: hygienisch unbedenklich', NULL),
    ('UBA AIR', 'CO2',         'ppm',   'Aufenthaltszeit', 2000, 'Leitwert: hygienisch inakzeptabel', 'zwischen 1000 und 2000 ppm: auffällig'),
    ('UBA AIR', 'TVOC',        'mg/m³', 'Aufenthaltszeit', 0.3,  'Stufe 1: hygienisch unbedenklich', NULL),
    ('UBA AIR', 'TVOC',        'mg/m³', 'Aufenthaltszeit', 1,    'Stufe 2: noch unbedenklich',      NULL),
    ('UBA AIR', 'TVOC',        'mg/m³', 'Aufenthaltszeit', 3,    'Stufe 3: auffällig',              NULL),
    ('UBA AIR', 'TVOC',        'mg/m³', 'Aufenthaltszeit', 10,   'Stufe 4: bedenklich',             'über 10 mg/m³ Stufe 5: inakzeptabel'),
    ('UBA AIR', 'Formaldehyd', 'µg/m³', '30 min',          100,  'Richtwert',                       '0,1 mg/m³')
) AS v(source, parameter, unit, averaging_time, value, category, notes)
JOIN air_quality_sources s ON s.short_name = v.source
WHERE NOT EXISTS (
    SELECT 1 FROM air_quality_references r
    WHERE r.source_id = s.source_id
      AND r.parameter = v.parameter
      AND r.unit = v.unit
      AND r.averaging_time IS NOT DISTINCT FROM v.averaging_time
      AND r.category IS NOT DISTINCT FROM v.category
);

-- ---------------------------------------------------------------------
-- Korridore für die Berechnung: jeweils der strengere Wert
-- ---------------------------------------------------------------------
INSERT INTO air_quality_corridors (parameter, unit, min_value, target_value, max_value, source_id, reasoning_source)
SELECT v.parameter, v.unit, v.min_value, v.target_value, v.max_value, s.source_id, v.reasoning
FROM (VALUES
    ('CO2', 'ppm', NULL::numeric, 800::numeric, 1000::numeric, 'UBA AIR',
     '[003] max: UBA-Leitwert 1000 ppm, strenger als DIN EN 16798-1 Kat. II (1200 ppm absolut). Ziel 800 ppm liegt unter Kat. I (950 ppm).'),
    ('Relative Luftfeuchte', '%', 25, 45, 60, 'DIN EN 16798-1',
     '[003] DIN EN 16798-1 Kat. II 25–60 %. Keine konkurrierenden WHO-Werte.'),
    ('Operative Temperatur', '°C', 20, 22, 26, 'DIN EN 16798-1',
     '[003] DIN EN 16798-1 Kat. II Wohnräume: min Heizperiode 20 °C, max Kühlperiode 26 °C. Keine konkurrierenden WHO-Werte.'),
    ('PM2.5', 'µg/m³', NULL, 5, 15, 'WHO AQG 2021',
     '[003] WHO AQG 2021: max = 24-h-Leitwert 15, Ziel = Jahresleitwert 5. Keine DIN/EN-Werte.'),
    ('PM10', 'µg/m³', NULL, 15, 45, 'WHO AQG 2021',
     '[003] WHO AQG 2021: max = 24-h-Leitwert 45, Ziel = Jahresleitwert 15. Keine DIN/EN-Werte.'),
    ('NO2', 'µg/m³', NULL, 10, 25, 'WHO AQG 2021',
     '[003] WHO AQG 2021: max = 24-h-Leitwert 25, Ziel = Jahresleitwert 10; strenger als WHO IAQ 2010 (1 h 200, Jahr 40).'),
    ('O3', 'µg/m³', NULL, 60, 100, 'WHO AQG 2021',
     '[003] WHO AQG 2021: max = 8-h-Leitwert 100, Ziel = Spitzensaison 60.'),
    ('SO2', 'µg/m³', NULL, 40, 40, 'WHO AQG 2021',
     '[003] WHO AQG 2021: 24-h-Leitwert 40.'),
    ('CO', 'mg/m³', NULL, 4, 4, 'WHO AQG 2021',
     '[003] WHO AQG 2021 24 h 4 mg/m³, strenger als WHO IAQ 2010 (24 h 7, 8 h 10).'),
    ('Formaldehyd', 'µg/m³', NULL, 100, 100, 'WHO IAQ 2010',
     '[003] WHO IAQ 2010 und UBA-Richtwert gleich: 100 µg/m³ (30 min).'),
    ('TVOC', 'mg/m³', NULL, 0.3, 1, 'UBA AIR',
     '[003] UBA: Ziel Stufe 1 (0,3), max Stufe 2 (1,0). Keine DIN/EN- oder WHO-Werte.'),
    ('Radon', 'Bq/m³', NULL, 100, 100, 'WHO Radon 2009',
     '[003] WHO-Referenzwert 100 Bq/m³ (Jahresmittel).')
) AS v(parameter, unit, min_value, target_value, max_value, source, reasoning)
JOIN air_quality_sources s ON s.short_name = v.source
ON CONFLICT (parameter, unit) DO NOTHING;

COMMIT;

-- ---------------------------------------------------------------------
-- Kontrolle (optional): Korridor gegen den strengsten Referenzwert je
-- Parameter. Bei Parametern mit Untergrenze (Feuchte, Temperatur) ist die
-- Spalte strengster_wert nicht aussagekräftig.
-- ---------------------------------------------------------------------
-- SELECT c.parameter, c.unit, c.min_value, c.target_value, c.max_value,
--        min(r.value) AS strengster_wert,
--        string_agg(s.short_name || ' ' || coalesce(r.category,'') || ' ' || coalesce(r.averaging_time,'') || ': ' || r.value, '; ' ORDER BY r.value) AS referenzen
-- FROM ventilation_milheiros.air_quality_corridors c
-- JOIN ventilation_milheiros.air_quality_references r ON r.parameter = c.parameter AND r.unit = c.unit AND r.active
-- JOIN ventilation_milheiros.air_quality_sources s ON s.source_id = r.source_id AND s.active
-- GROUP BY c.parameter, c.unit, c.min_value, c.target_value, c.max_value
-- ORDER BY c.parameter;
