package de.lueftung.admin.objekt;

import java.time.LocalDate;
import java.time.format.DateTimeParseException;
import java.util.HashMap;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

import org.springframework.jdbc.core.namedparam.MapSqlParameterSource;
import org.springframework.jdbc.core.namedparam.NamedParameterJdbcTemplate;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import de.lueftung.admin.data.DataService;
import de.lueftung.admin.meta.MetaService;
import de.lueftung.admin.web.ApiException;

/**
 * Objekt (Gebäude) mit historisierter Adresse.
 * Eine Adressänderung beendet die bisherige Adresse zum Vortag und legt eine neue an,
 * damit Messdaten aus der Vergangenheit weiterhin der damals gültigen Adresse zugeordnet werden können.
 * Benötigt die Tabellen aus db/proposed/001_objekt_adresse.sql.
 */
@Service
public class ObjektService {

    static final String OBJECTS = "objects";
    static final String ADDRESSES = "object_addresses";

    private final NamedParameterJdbcTemplate jdbc;
    private final MetaService meta;
    private final DataService data;

    public ObjektService(NamedParameterJdbcTemplate jdbc, MetaService meta, DataService data) {
        this.jdbc = jdbc;
        this.meta = meta;
        this.data = data;
    }

    public boolean available() {
        return meta.exists(OBJECTS) && meta.exists(ADDRESSES);
    }

    /** Alle Objekte mit ihrer aktuell gültigen Adresse (für Kopfzeile und Rollencenter). */
    public Map<String, Object> status() {
        Map<String, Object> out = new LinkedHashMap<>();
        out.put("available", available());
        out.put("schema", meta.schema());
        if (!available()) {
            out.put("objects", List.of());
            return out;
        }
        String s = q(meta.schema());
        List<Map<String, Object>> rows = jdbc.queryForList("""
                SELECT o.*, a.address_id, a.street, a.house_number, a.postal_code, a.city, a.country_code, a.valid_from
                  FROM %s.objects o
                  LEFT JOIN %s.object_addresses a ON a.object_id = o.object_id AND a.valid_to IS NULL
                 ORDER BY o.object_id
                """.formatted(s, s), Map.of());
        out.put("objects", rows.stream().map(r -> {
            Map<String, Object> m = new HashMap<>(r);
            m.replaceAll((k, v) -> v instanceof java.sql.Date d ? d.toLocalDate().toString() : v);
            return m;
        }).toList());
        return out;
    }

    @Transactional
    public Map<String, Object> changeAddress(long objectId, Map<String, Object> request) {
        if (!available()) {
            throw ApiException.badRequest("objekt.migrationMissing");
        }
        LocalDate validFrom = parseDate(request.get("valid_from"));
        String s = q(meta.schema());
        MapSqlParameterSource p = new MapSqlParameterSource("id", objectId);

        if (jdbc.queryForList("SELECT 1 FROM %s.objects WHERE object_id = :id FOR UPDATE".formatted(s), p).isEmpty()) {
            throw ApiException.notFound("objekt.notFound", objectId);
        }
        List<Map<String, Object>> current = jdbc.queryForList(
                "SELECT address_id, valid_from FROM %s.object_addresses WHERE object_id = :id AND valid_to IS NULL FOR UPDATE".formatted(s), p);
        if (!current.isEmpty()) {
            LocalDate curFrom = ((java.sql.Date) current.get(0).get("valid_from")).toLocalDate();
            if (!validFrom.isAfter(curFrom)) {
                throw ApiException.badRequest("objekt.validFromTooEarly", curFrom.toString());
            }
            jdbc.update("UPDATE %s.object_addresses SET valid_to = :to WHERE address_id = :aid".formatted(s),
                    new MapSqlParameterSource("to", java.sql.Date.valueOf(validFrom.minusDays(1)))
                            .addValue("aid", current.get(0).get("address_id")));
        }

        Map<String, Object> values = new LinkedHashMap<>(request);
        values.remove("address_id");
        values.remove("valid_to");
        values.put("object_id", objectId);
        values.put("valid_from", validFrom.toString());
        return data.insert(ADDRESSES, values);
    }

    private static LocalDate parseDate(Object v) {
        if (v == null || v.toString().isBlank()) {
            return LocalDate.now();
        }
        try {
            return LocalDate.parse(v.toString().substring(0, Math.min(10, v.toString().length())));
        } catch (DateTimeParseException e) {
            throw ApiException.badRequest("date.invalid", v);
        }
    }

    private static String q(String identifier) {
        return "\"" + identifier.replace("\"", "\"\"") + "\"";
    }
}
