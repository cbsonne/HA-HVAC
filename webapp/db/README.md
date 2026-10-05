# Datenbankdateien

| Datei | Status |
|---|---|
| `proposed/001_objekt_adresse.sql` | **Vorschlag, noch nicht angewendet.** Legt `objects` und `object_addresses` an und ergänzt `ventilation_systems.object_id`. |
| `proposed/001_objekt_adresse_rollback.sql` | macht die Migration rückgängig (löscht die neuen Tabellen samt Inhalt) |
| `proposed/002_mehrsprachigkeit.sql` | **Vorschlag, noch nicht angewendet.** Legt `languages` und `translations` für übersetzbare Stammdaten an; bestehende Tabellen bleiben unverändert. |
| `proposed/002_mehrsprachigkeit_rollback.sql` | macht 002 rückgängig (löscht alle Übersetzungen) |
| `schema_ventilation_milheiros.sql` | aus dem gelieferten Dump rekonstruierte DDL, **nur** zum Aufbau einer lokalen Testdatenbank |

An der bestehenden Datenbank wurde nichts verändert.

## Hinweis zum gelieferten Dump

`ventilation_milheiros_schema20261005.sql` ist trotz der Endung `.sql` ein `pg_dump` im
Custom-Format (Archivversion 1.16, erzeugt mit pg_dump 17.4, Server 15.18, Datenbank `solver`).
Einspielen geht damit nur mit `pg_restore` ab Version 17:

```bash
pg_restore -d solver ventilation_milheiros_schema20261005.sql
```

Für die Tests hier wurde die reine DDL daraus extrahiert (`schema_ventilation_milheiros.sql`),
weil die vorhandene Werkzeugversion das Format nicht lesen konnte. Tabellendaten enthält diese
Datei nicht.

## Migration anwenden

```bash
# Immer zuerst sichern
pg_dump -Fc -d solver -f solver-$(date +%F).dump

psql -d solver -v ON_ERROR_STOP=1 -f proposed/001_objekt_adresse.sql
```

Danach in der Oberfläche **↻ Metadaten** wählen; Objekt- und Adressseiten sind dann aktiv.
