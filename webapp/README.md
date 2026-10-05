# Verwaltungsoberfläche Lüftungsanlage

Weboberfläche zur Pflege der Stammdaten im PostgreSQL-Schema `ventilation_milheiros`:
Räume, Sensoren, Aktoren, Busse, Normwerte, Regel- und Simulationsparameter.
Aufbau und Bedienung orientieren sich an Microsoft Dynamics 365 Business Central:
Rollencenter mit Stapeln, Listenseiten mit Aktionsleiste, Kartenseiten mit Inforegistern,
Zeilen-Unterseiten und Infoboxen rechts.

- Backend: Java 21, Spring Boot 4.1.1, Spring JDBC (kein JPA)
- Frontend: Angular 22 (Signals, Standalone-Komponenten), ausgeliefert über nginx
- Betrieb: Docker Compose, Images bauen auf arm64 (Raspberry Pi 5) und amd64

## Schnellstart auf dem Raspberry Pi

```bash
cp .env.example .env     # Zugangsdaten der bestehenden Datenbank eintragen
docker compose up -d --build
```

Oberfläche danach unter `http://<pi>:8088`.

Die Datenbank wird nicht mitgestartet und nicht verändert. Es wird ausschließlich
auf die vorhandene Instanz zugegriffen, mit dem Benutzer aus `.env`.
Für Nur-Lese-Betrieb reicht ein Datenbankbenutzer mit `SELECT`-Rechten.

## Entwicklung

```bash
cd backend  && DB_URL=jdbc:postgresql://localhost:5432/solver DB_USER=admin mvn spring-boot:run
cd frontend && npm install && npm start     # http://localhost:4200, /api wird an 8080 weitergereicht
```

## Die Objektadresse

Das übergebene Schema hat bisher **keine Tabelle für das Objekt und keine Adressfelder**;
der Ort steckt allein im Schemanamen `ventilation_milheiros`. Eine Adresse ist dort also
nicht änderbar, weil sie nicht existiert.

Gut daran: kein Schlüssel und kein Fremdschlüssel hängt an einer Adresse. Die Adresse lässt
sich deshalb sauber ergänzen, ohne bestehende Daten anzufassen. Der Vorschlag liegt in
[`db/proposed/001_objekt_adresse.sql`](db/proposed/001_objekt_adresse.sql) und ist **noch nicht angewendet**:

| Tabelle | Zweck |
|---|---|
| `objects` | Objekt/Gebäude mit technischer `object_id` und frei wählbarer `object_no` |
| `object_addresses` | Adressen mit `valid_from`/`valid_to`; genau eine aktuelle Adresse je Objekt |
| `ventilation_systems.object_id` | ordnet eine Anlage dem Objekt zu (neue, optionale Spalte) |

Alle Bezüge laufen über `object_id`, nie über die Adresse. Eine Adressänderung in der
Oberfläche (Objektkarte, Aktion **Adresse ändern**) beendet die bisherige Adresse zum Vortag
und legt die neue an. Damit bleiben Messdaten aus der Vergangenheit der damals gültigen
Adresse zugeordnet. Reine Tippfehler werden stattdessen in der Adresshistorie direkt korrigiert.

Solange die Tabellen fehlen, läuft die Oberfläche vollständig, zeigt an diesen Stellen aber
einen Hinweis. Nach dem Einspielen genügt in der Kopfzeile **↻ Metadaten**.

### Zum Schemanamen

Der Schemaname bleibt unverändert, auch wenn das Objekt einmal umzieht. Die Oberfläche liest
ihn aus `DB_SCHEMA`; ein späteres `ALTER SCHEMA ventilation_milheiros RENAME TO ...` wäre
also nur eine Änderung in `.env`. Empfehlenswert ist das trotzdem nicht: der Schemaname ist
in Home Assistant, ESPHome und Auswertungen verdrahtet. Der Ortsbezug gehört in `objects`.

## Wie die Oberfläche aufgebaut ist

Das Backend liest Tabellen, Spalten, Schlüssel, Fremdschlüssel und `CHECK`-Regeln direkt aus
dem PostgreSQL-Katalog (`/api/meta`). Daraus entstehen Eingabefelder, Auswahllisten und
Nachschlagefelder automatisch:

- `boolean` wird zum Schalter, `CHECK (... = ANY (ARRAY[...]))` zur Auswahlliste
  (`ventilation_type` etwa zu Zuluft/Abluft/Zu- und Abluft/Überströmung/Keine),
- jeder Fremdschlüssel wird zu einem Nachschlagefeld mit Sprung auf die Zielkarte,
- jede Sequenz-Spalte wird als „(automatisch)“ angezeigt statt abgefragt.

**Eine neue Spalte in der Datenbank erscheint nach „↻ Metadaten“ von selbst** – auf der Karte
im Inforegister „Weitere Felder“, in der Liste über den Filterbereich. Nur wenn sie an einer
bestimmten Stelle stehen oder anders heißen soll, wird sie in `frontend/src/app/pages.ts`
eingetragen; dort liegen Seitenaufbau (`PAGES`) und deutsche Feldbeschriftungen (`CAPTIONS`).
Eine ganz neue Tabelle erscheint ohne jede Anpassung unter „Weitere Tabellen“.

Tabellen aus `READ_ONLY_TABLES` (standardmäßig Messreihen und Solver-Ergebnisse) sind in der
Oberfläche schreibgeschützt; die Aktionen Neu/Bearbeiten/Löschen fehlen dort.

## Mehrsprachigkeit (DE / EN / PT)

Die Sprache wird oben rechts umgeschaltet und im Browser gemerkt. Beim ersten Aufruf gilt die
Browsersprache, sonst Englisch. Zahlen und Datumswerte erscheinen im Format der Sprache
(`1.234,5` in DE/PT, `1,234.5` in EN), Eingaben werden entsprechend gelesen.

- **Oberflächentexte** stehen in `frontend/public/i18n/de.json`, `en.json`, `pt.json`
  (Menüs, Seiten- und Feldnamen, Aktionen, Meldungen). Fehlt ein Schlüssel, gilt Englisch.
- **Fehlermeldungen des Backends** stehen in `backend/src/main/resources/i18n/messages_*.properties`;
  die Oberfläche schickt die gewählte Sprache per `Accept-Language` mit.
- **Weitere Sprache** (z. B. Französisch): `fr.json` neben die anderen legen, in
  `frontend/src/app/i18n.service.ts` unter `LANGUAGES` eintragen und optional
  `messages_fr.properties` anlegen. Ein neuer Build genügt, die Datenbank ist nicht betroffen.
- **Neue Spalte beschriften:** Schlüssel `field.<spaltenname>` in jede Sprachdatei eintragen.

**Inhalte aus der Datenbank** (Raumnamen, Nutzungsarten, Beschreibungen …) bleiben vorerst so,
wie sie gespeichert sind. Wie sie übersetzbar würden, zeigt der Vorschlag
[`db/proposed/002_mehrsprachigkeit.sql`](db/proposed/002_mehrsprachigkeit.sql): eine generische
Tabelle `translations` (Tabelle, Spalte, Datensatzschlüssel, Sprache, Text) plus `languages`,
ohne die bestehenden Tabellen zu verändern. Er ist noch nicht angewendet.

## Sicherheit

- Tabellen- und Spaltennamen stammen ausschließlich aus den Metadaten der Datenbank, Werte
  werden immer als Parameter übergeben (keine zusammengebauten Werte im SQL).
- `APP_PASSWORD` schaltet HTTP-Basic für `/api` ein. Ohne Passwort ist die Oberfläche
  ungeschützt und gehört dann ausschließlich ins eigene Netz, nicht ins Internet.
- Für eine Veröffentlichung nach außen gehört ein Reverse Proxy mit TLS davor.

## Aufbau des Projekts

```
backend/   Spring Boot: /api/meta (Schema), /api/data/{tabelle} (CRUD), /api/objekt (Adresse ändern)
frontend/  Angular: Rollencenter, Listenseite, Kartenseite, Infoboxen, Dialoge
db/        proposed/001_objekt_adresse.sql, 002_mehrsprachigkeit.sql (Vorschläge) + Rollbacks
           schema_ventilation_milheiros.sql (rekonstruierte DDL, nur für lokale Tests)
```
