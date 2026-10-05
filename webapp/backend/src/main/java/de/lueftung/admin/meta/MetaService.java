package de.lueftung.admin.meta;

import java.sql.Array;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.HashMap;
import java.util.HashSet;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.dao.DataAccessException;
import org.springframework.http.HttpStatus;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Service;

import de.lueftung.admin.AppProperties;
import de.lueftung.admin.web.ApiException;

/**
 * Liest Tabellen, Spalten, Schlüssel und Prüfregeln direkt aus dem Postgres-Katalog.
 * Dadurch passt sich die Oberfläche an Schemaänderungen an, ohne dass Java-Code angepasst werden muss.
 */
@Service
public class MetaService {

    private static final Logger log = LoggerFactory.getLogger(MetaService.class);
    private static final List<String> DISPLAY_CANDIDATES =
            List.of("name", "short_name", "device_name", "object_no", "parameter", "model", "product_family");
    private static final Pattern ENUM_VALUE = Pattern.compile("'((?:[^']|'')*)'::");

    private final JdbcTemplate jdbc;
    private final AppProperties props;
    private volatile Map<String, TableMeta> tables;

    public MetaService(JdbcTemplate jdbc, AppProperties props) {
        this.jdbc = jdbc;
        this.props = props;
    }

    public String schema() {
        return props.schema();
    }

    public Map<String, TableMeta> tables() {
        Map<String, TableMeta> t = tables;
        if (t == null) {
            synchronized (this) {
                if (tables == null) {
                    tables = load();
                }
                t = tables;
            }
        }
        return t;
    }

    public void refresh() {
        synchronized (this) {
            tables = load();
        }
    }

    public TableMeta table(String name) {
        TableMeta t = tables().get(name);
        if (t == null) {
            throw ApiException.notFound("table.notFound", name, schema());
        }
        return t;
    }

    public boolean exists(String name) {
        return tables().containsKey(name);
    }

    private record RawColumn(String table, String name, int pos, String baseType, String fullType,
            boolean notNull, String def, String comment) {
    }

    private record RawConstraint(String table, String type, String def, List<String> cols, String fTable, List<String> fCols) {
    }

    private Map<String, TableMeta> load() {
        String schema = schema();
        List<RawColumn> cols = jdbc.query("""
                SELECT c.relname, a.attname, a.attnum,
                       format_type(a.atttypid, NULL) AS base_type,
                       format_type(a.atttypid, a.atttypmod) AS full_type,
                       a.attnotnull, pg_get_expr(d.adbin, d.adrelid) AS def,
                       col_description(c.oid, a.attnum) AS cmt
                  FROM pg_attribute a
                  JOIN pg_class c ON c.oid = a.attrelid
                  JOIN pg_namespace n ON n.oid = c.relnamespace
                  LEFT JOIN pg_attrdef d ON d.adrelid = a.attrelid AND d.adnum = a.attnum
                 WHERE n.nspname = ? AND c.relkind IN ('r', 'p') AND a.attnum > 0 AND NOT a.attisdropped
                 ORDER BY c.relname, a.attnum
                """, (rs, i) -> new RawColumn(rs.getString(1), rs.getString(2), rs.getInt(3), rs.getString(4),
                rs.getString(5), rs.getBoolean(6), rs.getString(7), rs.getString(8)), schema);

        List<RawConstraint> cons = jdbc.query("""
                SELECT c.relname, con.contype::text, pg_get_constraintdef(con.oid),
                       ARRAY(SELECT a.attname FROM unnest(con.conkey) WITH ORDINALITY k(n, o)
                               JOIN pg_attribute a ON a.attrelid = con.conrelid AND a.attnum = k.n ORDER BY k.o)::text[],
                       fc.relname,
                       ARRAY(SELECT a.attname FROM unnest(con.confkey) WITH ORDINALITY k(n, o)
                               JOIN pg_attribute a ON a.attrelid = con.confrelid AND a.attnum = k.n ORDER BY k.o)::text[]
                  FROM pg_constraint con
                  JOIN pg_class c ON c.oid = con.conrelid
                  JOIN pg_namespace n ON n.oid = c.relnamespace
                  LEFT JOIN pg_class fc ON fc.oid = con.confrelid
                 WHERE n.nspname = ? AND con.contype IN ('p', 'f', 'c')
                """, (rs, i) -> new RawConstraint(rs.getString(1), rs.getString(2), rs.getString(3),
                strings(rs, 4), rs.getString(5), strings(rs, 6)), schema);

        Map<String, String> tableComments = new HashMap<>();
        jdbc.query("""
                SELECT c.relname, obj_description(c.oid, 'pg_class') FROM pg_class c
                  JOIN pg_namespace n ON n.oid = c.relnamespace
                 WHERE n.nspname = ? AND c.relkind IN ('r', 'p')
                """, rs -> {
            tableComments.put(rs.getString(1), rs.getString(2));
        }, schema);

        Set<String> hypertables = new HashSet<>();
        try {
            hypertables.addAll(jdbc.queryForList(
                    "SELECT hypertable_name FROM timescaledb_information.hypertables WHERE hypertable_schema = ?",
                    String.class, schema));
        } catch (DataAccessException e) {
            log.debug("TimescaleDB nicht verfügbar: {}", e.getMessage());
        }

        Map<String, List<String>> pks = new HashMap<>();
        Map<String, String[]> fks = new HashMap<>(); // "tbl.col" -> [ftable, fcol]
        Map<String, List<String>> enums = new HashMap<>(); // "tbl.col" -> values
        Map<String, List<TableMeta.Reference>> refs = new HashMap<>();
        for (RawConstraint c : cons) {
            switch (c.type()) {
                case "p" -> pks.put(c.table(), c.cols());
                case "f" -> {
                    if (c.cols().size() == 1) {
                        fks.put(c.table() + "." + c.cols().get(0), new String[] {c.fTable(), c.fCols().get(0)});
                    }
                    refs.computeIfAbsent(c.fTable(), k -> new ArrayList<>())
                            .add(new TableMeta.Reference(c.table(), String.join(",", c.cols())));
                }
                case "c" -> {
                    if (c.cols().size() == 1 && c.def().contains("ARRAY[")) {
                        List<String> values = new ArrayList<>();
                        Matcher m = ENUM_VALUE.matcher(c.def());
                        while (m.find()) {
                            values.add(m.group(1).replace("''", "'"));
                        }
                        if (!values.isEmpty()) {
                            enums.put(c.table() + "." + c.cols().get(0), values);
                        }
                    }
                }
                default -> { }
            }
        }

        Map<String, List<ColumnMeta>> byTable = new LinkedHashMap<>();
        for (RawColumn r : cols) {
            List<String> pk = pks.getOrDefault(r.table(), List.of());
            String[] fk = fks.get(r.table() + "." + r.name());
            // "character" ohne Länge wäre char(1) und würde beim CAST kürzen
            String baseType = r.baseType().equals("character") ? "bpchar" : r.baseType();
            byTable.computeIfAbsent(r.table(), k -> new ArrayList<>()).add(new ColumnMeta(
                    r.name(), r.pos(), baseType, r.fullType(), !r.notNull(), r.def(), pk.contains(r.name()),
                    fk == null ? null : fk[0], fk == null ? null : fk[1],
                    enums.getOrDefault(r.table() + "." + r.name(), List.of()), r.comment()));
        }

        Map<String, TableMeta> result = new LinkedHashMap<>();
        byTable.forEach((name, columns) -> {
            List<String> pk = pks.getOrDefault(name, List.of());
            result.put(name, new TableMeta(name, List.copyOf(columns), pk, displayColumn(columns, pk),
                    hypertables.contains(name), props.readOnlyTables().contains(name) || pk.isEmpty(),
                    List.copyOf(refs.getOrDefault(name, List.of())), tableComments.get(name)));
        });
        log.info("Schema {}: {} Tabellen geladen", schema, result.size());
        return result;
    }

    private static String displayColumn(List<ColumnMeta> columns, List<String> pk) {
        for (String candidate : DISPLAY_CANDIDATES) {
            if (columns.stream().anyMatch(c -> c.name().equals(candidate))) {
                return candidate;
            }
        }
        return columns.stream()
                .filter(c -> c.baseType().startsWith("character") && !c.primaryKey())
                .map(ColumnMeta::name).findFirst()
                .orElse(pk.isEmpty() ? columns.get(0).name() : pk.get(0));
    }

    private static List<String> strings(ResultSet rs, int idx) throws SQLException {
        Array a = rs.getArray(idx);
        return a == null ? List.of() : Arrays.asList((String[]) a.getArray());
    }
}
