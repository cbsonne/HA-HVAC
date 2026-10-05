package de.lueftung.admin.meta;

import java.util.List;
import java.util.Optional;

/**
 * @param displayColumn Spalte, die als Bezeichnung in Nachschlagefeldern erscheint
 * @param references    eingehende Fremdschlüssel (Tabelle.Spalte, die auf diese Tabelle zeigen)
 */
public record TableMeta(
        String name,
        List<ColumnMeta> columns,
        List<String> primaryKey,
        String displayColumn,
        boolean hypertable,
        boolean readOnly,
        List<Reference> references,
        String comment) {

    public Optional<ColumnMeta> column(String name) {
        return columns.stream().filter(c -> c.name().equals(name)).findFirst();
    }

    public record Reference(String table, String column) {
    }
}
