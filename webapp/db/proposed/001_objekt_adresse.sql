-- =====================================================================
-- VORSCHLAG (noch nicht angewendet): Objekt mit änderbarer Adresse
-- =====================================================================
-- Ausgangslage im Schema ventilation_milheiros (Stand 2026-10-05):
--   * Es gibt keine Tabelle für das Objekt/Gebäude und keine Adressfelder.
--   * Der Ort steckt nur im Schemanamen "ventilation_milheiros".
--   * Kein Primär- oder Fremdschlüssel hängt an einer Adresse -> die Adresse
--     kann ohne Schlüsseländerungen ergänzt werden.
--
-- Lösung:
--   * objects:          das Objekt mit fester, technischer ID (object_id) und
--                       einer frei wählbaren Objektnummer (object_no, wie "Nr." in BC).
--   * object_addresses: Adressen mit Gültigkeitszeitraum. Eine Adressänderung
--                       beendet die alte Adresse (valid_to) und legt eine neue an.
--                       Genau eine Adresse je Objekt ist "aktuell" (valid_to IS NULL).
--   * ventilation_systems.object_id: optionale Zuordnung der Anlage zum Objekt.
--   Alle Bezüge laufen über object_id, nie über Adresse oder Schemanamen.
--
-- Der Schemaname bleibt unverändert. Die Weboberfläche liest ihn aus DB_SCHEMA,
-- ein späteres Umbenennen (ALTER SCHEMA ... RENAME TO ...) ist damit nur eine
-- Konfigurationsänderung.
--
-- Anwenden (nach Backup!):
--   psql -h <host> -U admin -d solver -v ON_ERROR_STOP=1 -f 001_objekt_adresse.sql
-- Rückgängig: 001_objekt_adresse_rollback.sql
-- =====================================================================

BEGIN;

SET LOCAL search_path = ventilation_milheiros;

CREATE TABLE objects (
    object_id   bigserial PRIMARY KEY,
    object_no   character varying(20)  NOT NULL UNIQUE,
    name        character varying(150) NOT NULL,
    description text,
    active      boolean DEFAULT true NOT NULL
);

CREATE TABLE object_addresses (
    address_id   bigserial PRIMARY KEY,
    object_id    bigint NOT NULL REFERENCES objects (object_id) ON DELETE CASCADE,
    street       character varying(150),
    house_number character varying(20),
    postal_code  character varying(20),
    city         character varying(100),
    district     character varying(100),
    country_code character(2) DEFAULT 'PT',
    latitude     numeric(9,6),
    longitude    numeric(9,6),
    valid_from   date DEFAULT current_date NOT NULL,
    valid_to     date,
    note         text,
    CONSTRAINT object_addresses_valid_range CHECK (valid_to IS NULL OR valid_to >= valid_from)
);

-- höchstens eine aktuelle Adresse je Objekt
CREATE UNIQUE INDEX object_addresses_one_current ON object_addresses (object_id) WHERE valid_to IS NULL;
CREATE INDEX object_addresses_object ON object_addresses (object_id, valid_from);

ALTER TABLE ventilation_systems
    ADD COLUMN object_id bigint REFERENCES objects (object_id);

COMMENT ON TABLE objects IS 'Objekt/Gebäude. Schlüssel ist object_id, nie die Adresse.';
COMMENT ON TABLE object_addresses IS 'Adresshistorie je Objekt; aktuelle Adresse hat valid_to IS NULL.';

-- Startdatensatz für das bestehende Objekt (Adresse bitte in der Oberfläche ergänzen)
INSERT INTO objects (object_no, name) VALUES ('OBJ-001', 'Milheiros');

COMMIT;
