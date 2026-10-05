package de.lueftung.admin.data;

import java.math.BigDecimal;
import java.sql.Timestamp;
import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

import org.postgresql.util.PGobject;
import org.springframework.http.HttpStatus;
import org.springframework.jdbc.core.namedparam.MapSqlParameterSource;
import org.springframework.jdbc.core.namedparam.NamedParameterJdbcTemplate;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import de.lueftung.admin.meta.ColumnMeta;
import de.lueftung.admin.meta.MetaService;
import de.lueftung.admin.meta.TableMeta;
import de.lueftung.admin.web.ApiException;

/**
 * Generischer Datenzugriff auf die Tabellen des Schemas.
 * Tabellen- und Spaltennamen kommen ausschließlich aus den Metadaten (Whitelist),
 * Werte werden immer als Parameter übergeben und in der Datenbank per CAST in den Spaltentyp gewandelt.
 */
@Service
public class DataService {

    public static final int MAX_PAGE_SIZE = 500;

    private final NamedParameterJdbcTemplate jdbc;
    private final MetaService meta;

    public DataService(NamedParameterJdbcTemplate jdbc, MetaService meta) {
        this.jdbc = jdbc;
        this.meta = meta;
    }

    public record Page(List<Map<String, Object>> rows, long total) {
    }

    public Page list(String table, Map<String, String> filters, String search, String sort, boolean desc, int page, int size) {
        TableMeta t = meta.table(table);
        MapSqlParameterSource p = new MapSqlParameterSource();
        List<String> where = new ArrayList<>();
        int i = 0;
        for (Map.Entry<String, String> f : filters.entrySet()) {
            ColumnMeta c = column(t, f.getKey());
            String name = "f" + i++;
            if (f.getValue() == null || f.getValue().isEmpty()) {
                where.add(q(c.name()) + " IS NULL");
            } else {
                where.add(q(c.name()) + " = CAST(:" + name + " AS " + c.baseType() + ")");
                p.addValue(name, f.getValue());
            }
        }
        if (search != null && !search.isBlank()) {
            List<String> or = new ArrayList<>();
            for (ColumnMeta c : t.columns()) {
                if (c.baseType().startsWith("character") || c.baseType().equals("text") || c.primaryKey()) {
                    or.add("CAST(" + q(c.name()) + " AS text) ILIKE :search");
                }
            }
            if (!or.isEmpty()) {
                where.add("(" + String.join(" OR ", or) + ")");
                p.addValue("search", "%" + search.trim().replace("\\", "\\\\").replace("%", "\\%").replace("_", "\\_") + "%");
            }
        }
        String whereSql = where.isEmpty() ? "" : " WHERE " + String.join(" AND ", where);

        String order;
        if (sort != null && !sort.isBlank()) {
            order = q(column(t, sort).name()) + (desc ? " DESC" : " ASC") + " NULLS LAST";
        } else if (t.hypertable()) {
            order = "1 DESC";
        } else if (!t.primaryKey().isEmpty()) {
            order = String.join(", ", t.primaryKey().stream().map(DataService::q).toList());
        } else {
            order = "1";
        }
        int limit = Math.max(1, Math.min(size, MAX_PAGE_SIZE));
        p.addValue("limit", limit).addValue("offset", (long) Math.max(0, page) * limit);

        long total = jdbc.queryForObject("SELECT count(*) FROM " + qt(t) + whereSql, p, Long.class);
        List<Map<String, Object>> rows = jdbc.queryForList(
                "SELECT * FROM " + qt(t) + whereSql + " ORDER BY " + order + " LIMIT :limit OFFSET :offset", p);
        return new Page(rows.stream().map(DataService::toJson).toList(), total);
    }

    public Map<String, Object> get(String table, Map<String, String> key) {
        TableMeta t = meta.table(table);
        MapSqlParameterSource p = new MapSqlParameterSource();
        List<Map<String, Object>> rows = jdbc.queryForList(
                "SELECT * FROM " + qt(t) + " WHERE " + keyWhere(t, key, p), p);
        if (rows.isEmpty()) {
            throw ApiException.notFound("record.notFound");
        }
        return toJson(rows.get(0));
    }

    /** Kurzliste für Nachschlagefelder: Schlüssel + Bezeichnung. */
    public List<Map<String, Object>> lookup(String table) {
        TableMeta t = meta.table(table);
        if (t.primaryKey().size() != 1) {
            throw ApiException.badRequest("lookup.singleKeyOnly");
        }
        String pk = q(t.primaryKey().get(0));
        String display = q(t.displayColumn());
        return jdbc.queryForList("SELECT " + pk + " AS key, CAST(" + display + " AS text) AS label FROM " + qt(t)
                + " ORDER BY 2 NULLS LAST LIMIT " + MAX_PAGE_SIZE, Map.of())
                .stream().map(DataService::toJson).toList();
    }

    public long count(String table) {
        TableMeta t = meta.table(table);
        return jdbc.queryForObject("SELECT count(*) FROM " + qt(t), Map.of(), Long.class);
    }

    @Transactional
    public Map<String, Object> insert(String table, Map<String, Object> values) {
        TableMeta t = writable(table);
        MapSqlParameterSource p = new MapSqlParameterSource();
        List<String> names = new ArrayList<>();
        List<String> exprs = new ArrayList<>();
        int i = 0;
        for (ColumnMeta c : t.columns()) {
            if (!values.containsKey(c.name())) {
                continue;
            }
            String v = toDbString(values.get(c.name()));
            if (v == null && c.hasDefault()) {
                continue; // Datenbank-Default (Sequenz, active = true, ...) greifen lassen
            }
            String param = "v" + i++;
            names.add(q(c.name()));
            exprs.add("CAST(:" + param + " AS " + c.baseType() + ")");
            p.addValue(param, v);
        }
        String sql = names.isEmpty()
                ? "INSERT INTO " + qt(t) + " DEFAULT VALUES RETURNING *"
                : "INSERT INTO " + qt(t) + " (" + String.join(", ", names) + ") VALUES (" + String.join(", ", exprs) + ") RETURNING *";
        return toJson(jdbc.queryForList(sql, p).get(0));
    }

    @Transactional
    public Map<String, Object> update(String table, Map<String, String> key, Map<String, Object> values) {
        TableMeta t = writable(table);
        MapSqlParameterSource p = new MapSqlParameterSource();
        List<String> sets = new ArrayList<>();
        int i = 0;
        for (ColumnMeta c : t.columns()) {
            if (!values.containsKey(c.name())) {
                continue;
            }
            String param = "v" + i++;
            sets.add(q(c.name()) + " = CAST(:" + param + " AS " + c.baseType() + ")");
            p.addValue(param, toDbString(values.get(c.name())));
        }
        if (sets.isEmpty()) {
            return get(table, key);
        }
        List<Map<String, Object>> rows = jdbc.queryForList("UPDATE " + qt(t) + " SET " + String.join(", ", sets)
                + " WHERE " + keyWhere(t, key, p) + " RETURNING *", p);
        if (rows.isEmpty()) {
            throw ApiException.notFound("record.notFound");
        }
        return toJson(rows.get(0));
    }

    @Transactional
    public void delete(String table, Map<String, String> key) {
        TableMeta t = writable(table);
        MapSqlParameterSource p = new MapSqlParameterSource();
        int n = jdbc.update("DELETE FROM " + qt(t) + " WHERE " + keyWhere(t, key, p), p);
        if (n == 0) {
            throw ApiException.notFound("record.notFound");
        }
    }

    private TableMeta writable(String table) {
        TableMeta t = meta.table(table);
        if (t.readOnly()) {
            throw new ApiException(HttpStatus.FORBIDDEN, "table.readOnly", table);
        }
        return t;
    }

    private String keyWhere(TableMeta t, Map<String, String> key, MapSqlParameterSource p) {
        if (t.primaryKey().isEmpty()) {
            throw ApiException.badRequest("table.noPrimaryKey", t.name());
        }
        List<String> parts = new ArrayList<>();
        int i = 0;
        for (String k : t.primaryKey()) {
            String v = key.get(k);
            if (v == null || v.isEmpty()) {
                throw ApiException.badRequest("key.missing", k);
            }
            ColumnMeta c = column(t, k);
            String param = "k" + i++;
            parts.add(q(k) + " = CAST(:" + param + " AS " + c.baseType() + ")");
            p.addValue(param, v);
        }
        return String.join(" AND ", parts);
    }

    private static ColumnMeta column(TableMeta t, String name) {
        return t.column(name).orElseThrow(() -> ApiException.badRequest("column.unknown", name, t.name()));
    }

    private String qt(TableMeta t) {
        return q(meta.schema()) + "." + q(t.name());
    }

    static String q(String identifier) {
        return "\"" + identifier.replace("\"", "\"\"") + "\"";
    }

    static String toDbString(Object v) {
        if (v == null) {
            return null;
        }
        if (v instanceof BigDecimal b) {
            return b.toPlainString();
        }
        String s = v.toString();
        return s.isEmpty() ? null : s;
    }

    static Map<String, Object> toJson(Map<String, Object> row) {
        Map<String, Object> out = new LinkedHashMap<>();
        row.forEach((k, v) -> out.put(k, switch (v) {
            case Timestamp ts -> ts.toInstant().toString();
            case java.sql.Date d -> d.toLocalDate().toString();
            case java.sql.Time tm -> tm.toLocalTime().toString();
            case PGobject o -> o.getValue();
            case null -> null;
            default -> v;
        }));
        return out;
    }
}
