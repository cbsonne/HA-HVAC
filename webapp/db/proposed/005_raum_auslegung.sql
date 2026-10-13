-- =====================================================================
-- VORSCHLAG (Schemaänderung, noch nicht angewendet): Auslegungsluftmengen je Raum
-- Das Schema kennt Mindestluftmengen nur je Nutzungsart (minimum_airflow_rates).
-- Für die raumweise Regelung (RAV-Prinzip) braucht der Solver je Raum Min/Normal/Rückfall/Maximum.
-- Voraussetzung: 004_haus_g_raeume.sql ist eingespielt.
-- Rückgängig: 005_raum_auslegung_rollback.sql
-- =====================================================================

BEGIN;
SET LOCAL search_path = ventilation_milheiros;

CREATE TABLE IF NOT EXISTS room_design_airflows (
    room_id        bigint NOT NULL REFERENCES rooms (room_id) ON DELETE CASCADE,
    level          character varying(10) NOT NULL
                   CHECK (level IN ('MIN_ABS', 'MIN', 'NL', 'FAULT', 'IL')),
    airflow_m3h    numeric(10,3) NOT NULL CHECK (airflow_m3h >= 0),
    source         text,
    PRIMARY KEY (room_id, level)
);

INSERT INTO room_design_airflows (room_id, level, airflow_m3h, source)
SELECT r.room_id, v.level, v.q, v.src FROM rooms r JOIN (VALUES
  ('G UG Waschküche', 'MIN_ABS', 6.0, '0,20 1/h (EN 16798-1 unbelegt, strenger als DIN-FL)'),
  ('G UG Waschküche', 'MIN', 7.5, '0,25 1/h (Anforderung a/c)'),
  ('G UG Waschküche', 'NL', 12.5, 'Normalbetrieb: DIN-NL der Wohnung nach Raumbedarf verteilt'),
  ('G UG Waschküche', 'FAULT', 25.0, 'Rückfall: Nassräume DIN-Mindestabluft, Wohnräume 0,25 1/h'),
  ('G UG Waschküche', 'IL', 32.5, 'Maximum: 130 % Raumbedarf, Sala 200 %'),
  ('G UG WC', 'MIN_ABS', 0.6, '0,20 1/h (EN 16798-1 unbelegt, strenger als DIN-FL)'),
  ('G UG WC', 'MIN', 0.8, '0,25 1/h (Anforderung a/c)'),
  ('G UG WC', 'NL', 12.5, 'Normalbetrieb: DIN-NL der Wohnung nach Raumbedarf verteilt'),
  ('G UG WC', 'FAULT', 25.0, 'Rückfall: Nassräume DIN-Mindestabluft, Wohnräume 0,25 1/h'),
  ('G UG WC', 'IL', 32.5, 'Maximum: 130 % Raumbedarf, Sala 200 %'),
  ('G EG Küche', 'MIN_ABS', 7.4, '0,20 1/h (EN 16798-1 unbelegt, strenger als DIN-FL)'),
  ('G EG Küche', 'MIN', 9.2, '0,25 1/h (Anforderung a/c)'),
  ('G EG Küche', 'NL', 22.5, 'Normalbetrieb: DIN-NL der Wohnung nach Raumbedarf verteilt'),
  ('G EG Küche', 'FAULT', 45.0, 'Rückfall: Nassräume DIN-Mindestabluft, Wohnräume 0,25 1/h'),
  ('G EG Küche', 'IL', 58.5, 'Maximum: 130 % Raumbedarf, Sala 200 %'),
  ('G EG Diele', 'MIN_ABS', 33.1, '0,20 1/h (EN 16798-1 unbelegt, strenger als DIN-FL)'),
  ('G EG Diele', 'MIN', 41.4, '0,25 1/h (Anforderung a/c)'),
  ('G EG Diele', 'NL', 96.4, 'Normalbetrieb: DIN-NL der Wohnung nach Raumbedarf verteilt'),
  ('G EG Diele', 'FAULT', 142.7, 'Rückfall: Nassräume DIN-Mindestabluft, Wohnräume 0,25 1/h'),
  ('G EG Diele', 'IL', 301.7, 'Maximum: 130 % Raumbedarf, Sala 200 %'),
  ('G EG WC', 'MIN_ABS', 0.9, '0,20 1/h (EN 16798-1 unbelegt, strenger als DIN-FL)'),
  ('G EG WC', 'MIN', 1.1, '0,25 1/h (Anforderung a/c)'),
  ('G EG WC', 'NL', 12.5, 'Normalbetrieb: DIN-NL der Wohnung nach Raumbedarf verteilt'),
  ('G EG WC', 'FAULT', 25.0, 'Rückfall: Nassräume DIN-Mindestabluft, Wohnräume 0,25 1/h'),
  ('G EG WC', 'IL', 32.5, 'Maximum: 130 % Raumbedarf, Sala 200 %'),
  ('G EG Sala', 'MIN_ABS', 18.2, '0,20 1/h (EN 16798-1 unbelegt, strenger als DIN-FL)'),
  ('G EG Sala', 'MIN', 22.7, '0,25 1/h (Anforderung a/c)'),
  ('G EG Sala', 'NL', 36.4, 'Normalbetrieb: DIN-NL der Wohnung nach Raumbedarf verteilt'),
  ('G EG Sala', 'FAULT', 22.7, 'Rückfall: Nassräume DIN-Mindestabluft, Wohnräume 0,25 1/h'),
  ('G EG Sala', 'IL', 145.7, 'Maximum: 130 % Raumbedarf, Sala 200 %'),
  ('G OG1 Zimmer Straße', 'MIN_ABS', 10.0, '0,20 1/h (EN 16798-1 unbelegt, strenger als DIN-FL)'),
  ('G OG1 Zimmer Straße', 'MIN', 12.5, '0,25 1/h (Anforderung a/c)'),
  ('G OG1 Zimmer Straße', 'NL', 24.3, 'Normalbetrieb: DIN-NL der Wohnung nach Raumbedarf verteilt'),
  ('G OG1 Zimmer Straße', 'FAULT', 12.5, 'Rückfall: Nassräume DIN-Mindestabluft, Wohnräume 0,25 1/h'),
  ('G OG1 Zimmer Straße', 'IL', 63.1, 'Maximum: 130 % Raumbedarf, Sala 200 %'),
  ('G OG1 Bad 1', 'MIN_ABS', 2.8, '0,20 1/h (EN 16798-1 unbelegt, strenger als DIN-FL)'),
  ('G OG1 Bad 1', 'MIN', 3.5, '0,25 1/h (Anforderung a/c)'),
  ('G OG1 Bad 1', 'NL', 22.5, 'Normalbetrieb: DIN-NL der Wohnung nach Raumbedarf verteilt'),
  ('G OG1 Bad 1', 'FAULT', 45.0, 'Rückfall: Nassräume DIN-Mindestabluft, Wohnräume 0,25 1/h'),
  ('G OG1 Bad 1', 'IL', 58.5, 'Maximum: 130 % Raumbedarf, Sala 200 %'),
  ('G OG1 Flur', 'MIN_ABS', 24.2, '0,20 1/h (EN 16798-1 unbelegt, strenger als DIN-FL)'),
  ('G OG1 Flur', 'MIN', 30.3, '0,25 1/h (Anforderung a/c)'),
  ('G OG1 Flur', 'NL', 93.6, 'Normalbetrieb: DIN-NL der Wohnung nach Raumbedarf verteilt'),
  ('G OG1 Flur', 'FAULT', 113.2, 'Rückfall: Nassräume DIN-Mindestabluft, Wohnräume 0,25 1/h'),
  ('G OG1 Flur', 'IL', 243.3, 'Maximum: 130 % Raumbedarf, Sala 200 %'),
  ('G OG1 Bad 2', 'MIN_ABS', 2.8, '0,20 1/h (EN 16798-1 unbelegt, strenger als DIN-FL)'),
  ('G OG1 Bad 2', 'MIN', 3.6, '0,25 1/h (Anforderung a/c)'),
  ('G OG1 Bad 2', 'NL', 22.5, 'Normalbetrieb: DIN-NL der Wohnung nach Raumbedarf verteilt'),
  ('G OG1 Bad 2', 'FAULT', 45.0, 'Rückfall: Nassräume DIN-Mindestabluft, Wohnräume 0,25 1/h'),
  ('G OG1 Bad 2', 'IL', 58.5, 'Maximum: 130 % Raumbedarf, Sala 200 %'),
  ('G OG1 Zimmer Garten', 'MIN_ABS', 8.5, '0,20 1/h (EN 16798-1 unbelegt, strenger als DIN-FL)'),
  ('G OG1 Zimmer Garten', 'MIN', 10.7, '0,25 1/h (Anforderung a/c)'),
  ('G OG1 Zimmer Garten', 'NL', 24.3, 'Normalbetrieb: DIN-NL der Wohnung nach Raumbedarf verteilt'),
  ('G OG1 Zimmer Garten', 'FAULT', 10.7, 'Rückfall: Nassräume DIN-Mindestabluft, Wohnräume 0,25 1/h'),
  ('G OG1 Zimmer Garten', 'IL', 63.1, 'Maximum: 130 % Raumbedarf, Sala 200 %'),
  ('G OG2 Zimmer Straße', 'MIN_ABS', 9.3, '0,20 1/h (EN 16798-1 unbelegt, strenger als DIN-FL)'),
  ('G OG2 Zimmer Straße', 'MIN', 11.6, '0,25 1/h (Anforderung a/c)'),
  ('G OG2 Zimmer Straße', 'NL', 24.3, 'Normalbetrieb: DIN-NL der Wohnung nach Raumbedarf verteilt'),
  ('G OG2 Zimmer Straße', 'FAULT', 11.6, 'Rückfall: Nassräume DIN-Mindestabluft, Wohnräume 0,25 1/h'),
  ('G OG2 Zimmer Straße', 'IL', 63.1, 'Maximum: 130 % Raumbedarf, Sala 200 %'),
  ('G OG2 Bad', 'MIN_ABS', 3.1, '0,20 1/h (EN 16798-1 unbelegt, strenger als DIN-FL)'),
  ('G OG2 Bad', 'MIN', 3.8, '0,25 1/h (Anforderung a/c)'),
  ('G OG2 Bad', 'NL', 22.5, 'Normalbetrieb: DIN-NL der Wohnung nach Raumbedarf verteilt'),
  ('G OG2 Bad', 'FAULT', 45.0, 'Rückfall: Nassräume DIN-Mindestabluft, Wohnräume 0,25 1/h'),
  ('G OG2 Bad', 'IL', 58.5, 'Maximum: 130 % Raumbedarf, Sala 200 %'),
  ('G OG2 Flur', 'MIN_ABS', 20.3, '0,20 1/h (EN 16798-1 unbelegt, strenger als DIN-FL)'),
  ('G OG2 Flur', 'MIN', 25.4, '0,25 1/h (Anforderung a/c)'),
  ('G OG2 Flur', 'NL', 65.0, 'Normalbetrieb: DIN-NL der Wohnung nach Raumbedarf verteilt'),
  ('G OG2 Flur', 'FAULT', 66.5, 'Rückfall: Nassräume DIN-Mindestabluft, Wohnräume 0,25 1/h'),
  ('G OG2 Flur', 'IL', 169.0, 'Maximum: 130 % Raumbedarf, Sala 200 %'),
  ('G OG2 Arbeitszimmer (Zimmer Garten)', 'MIN_ABS', 7.9, '0,20 1/h (EN 16798-1 unbelegt, strenger als DIN-FL)'),
  ('G OG2 Arbeitszimmer (Zimmer Garten)', 'MIN', 9.9, '0,25 1/h (Anforderung a/c)'),
  ('G OG2 Arbeitszimmer (Zimmer Garten)', 'NL', 18.2, 'Normalbetrieb: DIN-NL der Wohnung nach Raumbedarf verteilt'),
  ('G OG2 Arbeitszimmer (Zimmer Garten)', 'FAULT', 9.9, 'Rückfall: Nassräume DIN-Mindestabluft, Wohnräume 0,25 1/h'),
  ('G OG2 Arbeitszimmer (Zimmer Garten)', 'IL', 47.4, 'Maximum: 130 % Raumbedarf, Sala 200 %')
) AS v(name, level, q, src) ON r.name = v.name
ON CONFLICT (room_id, level) DO UPDATE SET airflow_m3h = EXCLUDED.airflow_m3h, source = EXCLUDED.source;

COMMIT;
