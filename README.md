# HA-HVAC – Lüftungsanlage

Parametergesteuerte Planung und Automatisierung einer kontrollierten Wohnraumlüftung
mit Home Assistant und ESPHome (Docker auf Raspberry Pi 5).

## Ziele

1. Flexible Datenbank für Standardparameter der Lüftungstechnik (PostgreSQL)
2. Erfassung der Sensoren und ihrer Zuordnungen
3. Erfassung der Aktoren (motorisierte Klappen, Ventilatoren) und ihrer Zuordnungen
4. Flexibles, parametergesteuertes Lüftungskonzept
5. Umsetzung in Home Assistant
6. KI-gestützte Analyse der Messdaten zur Reduktion energetischer Verluste

## Aufbau

| Ordner | Inhalt |
|---|---|
| `webapp/` | Verwaltungsoberfläche (Angular + Spring Boot, DE/EN/PT) für das Schema `ventilation_milheiros` |
| `webapp/db/proposed/` | Vorgeschlagene Schemaänderungen. Werden **nicht** automatisch eingespielt. |
| `dimensionierung/` | Luftmengen nach DIN 1946-6 (Python-Skript, Raum- und Gebäudedaten) |
