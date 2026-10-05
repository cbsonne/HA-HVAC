package de.lueftung.admin.meta;

import java.util.List;

/**
 * Eine Spalte, wie sie die Oberfläche zum Aufbau von Listen und Karten braucht.
 *
 * @param baseType   Postgres-Typ ohne Längenangabe (für CAST beim Schreiben)
 * @param fullType   Typ mit Länge/Präzision (für Anzeige und Eingabelänge)
 * @param enumValues erlaubte Werte aus einer CHECK ... ANY (ARRAY[...])-Regel, sonst leer
 */
public record ColumnMeta(
        String name,
        int position,
        String baseType,
        String fullType,
        boolean nullable,
        String defaultExpr,
        boolean primaryKey,
        String fkTable,
        String fkColumn,
        List<String> enumValues,
        String comment) {

    public boolean hasDefault() {
        return defaultExpr != null;
    }

    public boolean serial() {
        return defaultExpr != null && defaultExpr.startsWith("nextval(");
    }
}
