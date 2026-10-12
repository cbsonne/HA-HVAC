-- =====================================================================
-- VORSCHLAG (Schemaänderung, noch nicht angewendet): Auslegungsluftmengen je Raum
-- Das Schema kennt Mindestluftmengen nur je Nutzungsart (minimum_airflow_rates).
-- Für die raumweise Regelung braucht der Solver je Raum Min/FL/NL/Intensiv.
-- Voraussetzung: 004_haus_g_raeume.sql ist eingespielt.
-- Rückgängig: DROP TABLE ventilation_milheiros.room_design_airflows;
-- =====================================================================

BEGIN;
SET LOCAL search_path = ventilation_milheiros;

CREATE TABLE IF NOT EXISTS room_design_airflows (
    room_id        bigint NOT NULL REFERENCES rooms (room_id) ON DELETE CASCADE,
    level          character varying(10) NOT NULL
                   CHECK (level IN ('MIN_ABS', 'MIN', 'FL', 'NL', 'IL')),
    airflow_m3h    numeric(10,3) NOT NULL CHECK (airflow_m3h >= 0),
    source         text,
    PRIMARY KEY (room_id, level)
);

INSERT INTO room_design_airflows (room_id, level, airflow_m3h, source)
SELECT r.room_id, v.level, v.q, v.src FROM rooms r JOIN (VALUES
  ('G UG Waschküche', 'MIN_ABS', 6.0, '0,20 1/h (EN 16798-1 unbelegt, strenger als DIN-FL)'),
  ('G UG Waschküche', 'MIN', 7.5, '0,25 1/h (Anforderung a/c)'),
  ('G UG Waschküche', 'FL', 4.6, 'DIN 1946-6 Feuchteschutz, Raumanteil'),
  ('G UG Waschküche', 'NL', 25.0, 'DIN 1946-6 Nennlüftung, Raumanteil'),
  ('G UG Waschküche', 'IL', 37.5, 'Intensiv 130 % / Sala 200 %, balanciert'),
  ('G UG WC', 'MIN_ABS', 4.6, '0,20 1/h (EN 16798-1 unbelegt, strenger als DIN-FL)'),
  ('G UG WC', 'MIN', 4.6, '0,25 1/h (Anforderung a/c)'),
  ('G UG WC', 'FL', 4.6, 'DIN 1946-6 Feuchteschutz, Raumanteil'),
  ('G UG WC', 'NL', 25.0, 'DIN 1946-6 Nennlüftung, Raumanteil'),
  ('G UG WC', 'IL', 37.5, 'Intensiv 130 % / Sala 200 %, balanciert'),
  ('G EG Küche', 'MIN_ABS', 8.2, '0,20 1/h (EN 16798-1 unbelegt, strenger als DIN-FL)'),
  ('G EG Küche', 'MIN', 9.2, '0,25 1/h (Anforderung a/c)'),
  ('G EG Küche', 'FL', 8.2, 'DIN 1946-6 Feuchteschutz, Raumanteil'),
  ('G EG Küche', 'NL', 45.0, 'DIN 1946-6 Nennlüftung, Raumanteil'),
  ('G EG Küche', 'IL', 67.5, 'Intensiv 130 % / Sala 200 %, balanciert'),
  ('G EG WC', 'MIN_ABS', 4.6, '0,20 1/h (EN 16798-1 unbelegt, strenger als DIN-FL)'),
  ('G EG WC', 'MIN', 4.6, '0,25 1/h (Anforderung a/c)'),
  ('G EG WC', 'FL', 4.6, 'DIN 1946-6 Feuchteschutz, Raumanteil'),
  ('G EG WC', 'NL', 25.0, 'DIN 1946-6 Nennlüftung, Raumanteil'),
  ('G EG WC', 'IL', 37.5, 'Intensiv 130 % / Sala 200 %, balanciert'),
  ('G EG Sala', 'MIN_ABS', 18.2, '0,20 1/h (EN 16798-1 unbelegt, strenger als DIN-FL)'),
  ('G EG Sala', 'MIN', 22.7, '0,25 1/h (Anforderung a/c)'),
  ('G EG Sala', 'FL', 13.3, 'DIN 1946-6 Feuchteschutz, Raumanteil'),
  ('G EG Sala', 'NL', 72.9, 'DIN 1946-6 Nennlüftung, Raumanteil'),
  ('G EG Sala', 'IL', 145.7, 'Intensiv 130 % / Sala 200 %, balanciert'),
  ('G OG1 Zimmer Straße', 'MIN_ABS', 10.0, '0,20 1/h (EN 16798-1 unbelegt, strenger als DIN-FL)'),
  ('G OG1 Zimmer Straße', 'MIN', 12.5, '0,25 1/h (Anforderung a/c)'),
  ('G OG1 Zimmer Straße', 'FL', 8.9, 'DIN 1946-6 Feuchteschutz, Raumanteil'),
  ('G OG1 Zimmer Straße', 'NL', 48.6, 'DIN 1946-6 Nennlüftung, Raumanteil'),
  ('G OG1 Zimmer Straße', 'IL', 63.1, 'Intensiv 130 % / Sala 200 %, balanciert'),
  ('G OG1 Bad 1', 'MIN_ABS', 8.2, '0,20 1/h (EN 16798-1 unbelegt, strenger als DIN-FL)'),
  ('G OG1 Bad 1', 'MIN', 8.2, '0,25 1/h (Anforderung a/c)'),
  ('G OG1 Bad 1', 'FL', 8.2, 'DIN 1946-6 Feuchteschutz, Raumanteil'),
  ('G OG1 Bad 1', 'NL', 45.0, 'DIN 1946-6 Nennlüftung, Raumanteil'),
  ('G OG1 Bad 1', 'IL', 67.5, 'Intensiv 130 % / Sala 200 %, balanciert'),
  ('G OG1 Bad 2', 'MIN_ABS', 8.2, '0,20 1/h (EN 16798-1 unbelegt, strenger als DIN-FL)'),
  ('G OG1 Bad 2', 'MIN', 8.2, '0,25 1/h (Anforderung a/c)'),
  ('G OG1 Bad 2', 'FL', 8.2, 'DIN 1946-6 Feuchteschutz, Raumanteil'),
  ('G OG1 Bad 2', 'NL', 45.0, 'DIN 1946-6 Nennlüftung, Raumanteil'),
  ('G OG1 Bad 2', 'IL', 67.5, 'Intensiv 130 % / Sala 200 %, balanciert'),
  ('G OG1 Zimmer Garten', 'MIN_ABS', 8.9, '0,20 1/h (EN 16798-1 unbelegt, strenger als DIN-FL)'),
  ('G OG1 Zimmer Garten', 'MIN', 10.7, '0,25 1/h (Anforderung a/c)'),
  ('G OG1 Zimmer Garten', 'FL', 8.9, 'DIN 1946-6 Feuchteschutz, Raumanteil'),
  ('G OG1 Zimmer Garten', 'NL', 48.6, 'DIN 1946-6 Nennlüftung, Raumanteil'),
  ('G OG1 Zimmer Garten', 'IL', 63.1, 'Intensiv 130 % / Sala 200 %, balanciert'),
  ('G OG2 Zimmer Straße', 'MIN_ABS', 9.3, '0,20 1/h (EN 16798-1 unbelegt, strenger als DIN-FL)'),
  ('G OG2 Zimmer Straße', 'MIN', 11.6, '0,25 1/h (Anforderung a/c)'),
  ('G OG2 Zimmer Straße', 'FL', 8.9, 'DIN 1946-6 Feuchteschutz, Raumanteil'),
  ('G OG2 Zimmer Straße', 'NL', 48.6, 'DIN 1946-6 Nennlüftung, Raumanteil'),
  ('G OG2 Zimmer Straße', 'IL', 63.1, 'Intensiv 130 % / Sala 200 %, balanciert'),
  ('G OG2 Bad', 'MIN_ABS', 8.2, '0,20 1/h (EN 16798-1 unbelegt, strenger als DIN-FL)'),
  ('G OG2 Bad', 'MIN', 8.2, '0,25 1/h (Anforderung a/c)'),
  ('G OG2 Bad', 'FL', 8.2, 'DIN 1946-6 Feuchteschutz, Raumanteil'),
  ('G OG2 Bad', 'NL', 45.0, 'DIN 1946-6 Nennlüftung, Raumanteil'),
  ('G OG2 Bad', 'IL', 67.5, 'Intensiv 130 % / Sala 200 %, balanciert'),
  ('G OG2 Arbeitszimmer (Zimmer Garten)', 'MIN_ABS', 7.9, '0,20 1/h (EN 16798-1 unbelegt, strenger als DIN-FL)'),
  ('G OG2 Arbeitszimmer (Zimmer Garten)', 'MIN', 9.9, '0,25 1/h (Anforderung a/c)'),
  ('G OG2 Arbeitszimmer (Zimmer Garten)', 'FL', 6.7, 'DIN 1946-6 Feuchteschutz, Raumanteil'),
  ('G OG2 Arbeitszimmer (Zimmer Garten)', 'NL', 36.4, 'DIN 1946-6 Nennlüftung, Raumanteil'),
  ('G OG2 Arbeitszimmer (Zimmer Garten)', 'IL', 47.4, 'Intensiv 130 % / Sala 200 %, balanciert')
) AS v(name, level, q, src) ON r.name = v.name
ON CONFLICT (room_id, level) DO UPDATE SET airflow_m3h = EXCLUDED.airflow_m3h, source = EXCLUDED.source;

COMMIT;
