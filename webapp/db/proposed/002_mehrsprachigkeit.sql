-- =====================================================================
-- VORSCHLAG (noch nicht angewendet): übersetzbare Stammdaten
-- =====================================================================
-- Die Oberflächentexte (Menüs, Feldnamen, Meldungen) sind bereits in
-- frontend/public/i18n/<sprache>.json übersetzt und brauchen keine Datenbank.
--
-- Dieses Skript betrifft nur INHALTE aus der Datenbank, z. B.
--   usage_types.name        "Wohnen"   / "Living"   / "Sala"
--   sensor_classes.name     "CO2"      / ...
--   rooms.name, *.description
--
-- Ansatz: eine generische Übersetzungstabelle statt zusätzlicher Spalten
-- (name_de, name_en, name_pt) in jeder Tabelle.
--   + bestehende Tabellen bleiben unverändert
--   + jede Textspalte jeder Tabelle ist übersetzbar, auch künftige
--   + eine weitere Sprache ist nur ein Eintrag in languages
--   - kein Fremdschlüssel auf den Datensatz: beim Löschen eines Datensatzes
--     räumt der Trigger unten die Übersetzungen mit auf
--
-- Die Originalspalte (z. B. rooms.name) bleibt der Wert der Standardsprache.
-- Fehlt eine Übersetzung, wird der Originalwert angezeigt.
--
-- Anwenden (nach Backup!):
--   psql -d solver -v ON_ERROR_STOP=1 -f 002_mehrsprachigkeit.sql
-- Rückgängig: 002_mehrsprachigkeit_rollback.sql
-- =====================================================================

BEGIN;

SET LOCAL search_path = ventilation_milheiros;

CREATE TABLE languages (
    language_code character varying(5)  PRIMARY KEY,   -- ISO 639-1, z. B. de, en, pt
    name          character varying(50) NOT NULL,
    is_default    boolean DEFAULT false NOT NULL,
    active        boolean DEFAULT true  NOT NULL
);

-- genau eine Standardsprache
CREATE UNIQUE INDEX languages_one_default ON languages ((true)) WHERE is_default;

INSERT INTO languages (language_code, name, is_default) VALUES
    ('de', 'Deutsch',   true),
    ('en', 'English',   false),
    ('pt', 'Português', false);

CREATE TABLE translations (
    table_name    character varying(63) NOT NULL,
    column_name   character varying(63) NOT NULL,
    -- Primärschlüssel des Datensatzes als Text; zusammengesetzte Schlüssel mit '|' verbunden
    record_key    text                  NOT NULL,
    language_code character varying(5)  NOT NULL REFERENCES languages (language_code),
    value         text                  NOT NULL,
    PRIMARY KEY (table_name, column_name, record_key, language_code)
);

COMMENT ON TABLE translations IS 'Übersetzungen von Textspalten beliebiger Tabellen; Originalspalte = Standardsprache.';

-- Übersetzungen beim Löschen eines Datensatzes mit entfernen
-- (für Tabellen mit einspaltigem Schlüssel; Argument = Name der Schlüsselspalte)
CREATE FUNCTION translations_cleanup() RETURNS trigger LANGUAGE plpgsql AS $$
BEGIN
    DELETE FROM ventilation_milheiros.translations
     WHERE table_name = TG_TABLE_NAME
       AND record_key = (to_jsonb(OLD) ->> TG_ARGV[0]);
    RETURN OLD;
END $$;

-- Für die Tabellen, deren Texte übersetzt werden sollen:
CREATE TRIGGER usage_types_translations_cleanup    AFTER DELETE ON usage_types    FOR EACH ROW EXECUTE FUNCTION translations_cleanup('usage_type_id');
CREATE TRIGGER sensor_classes_translations_cleanup AFTER DELETE ON sensor_classes FOR EACH ROW EXECUTE FUNCTION translations_cleanup('sensor_class_id');
CREATE TRIGGER bus_types_translations_cleanup      AFTER DELETE ON bus_types      FOR EACH ROW EXECUTE FUNCTION translations_cleanup('bus_type_id');
CREATE TRIGGER rooms_translations_cleanup          AFTER DELETE ON rooms          FOR EACH ROW EXECUTE FUNCTION translations_cleanup('room_id');

COMMIT;

-- Beispiel:
--   INSERT INTO ventilation_milheiros.translations VALUES
--     ('usage_types', 'name', '1', 'en', 'Living'),
--     ('usage_types', 'name', '1', 'pt', 'Sala');
--
-- Lesen mit Rückfall auf den Originalwert:
--   SELECT u.usage_type_id, COALESCE(t.value, u.name) AS name
--     FROM ventilation_milheiros.usage_types u
--     LEFT JOIN ventilation_milheiros.translations t
--       ON t.table_name = 'usage_types' AND t.column_name = 'name'
--      AND t.record_key = u.usage_type_id::text AND t.language_code = 'en';
