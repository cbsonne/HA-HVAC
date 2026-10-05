package de.lueftung.admin.data;

import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.ResponseStatus;
import org.springframework.web.bind.annotation.RestController;

/**
 * REST-Schnittstelle für Listen- und Kartenseiten.
 * Schlüssel werden als Query-Parameter "k.&lt;spalte&gt;" übergeben (auch zusammengesetzte Schlüssel),
 * Listenfilter als "f.&lt;spalte&gt;".
 */
@RestController
@RequestMapping("/api/data/{table}")
public class DataController {

    private final DataService data;

    public DataController(DataService data) {
        this.data = data;
    }

    @GetMapping
    public DataService.Page list(@PathVariable String table,
            @RequestParam Map<String, String> params,
            @RequestParam(required = false) String q,
            @RequestParam(required = false) String sort,
            @RequestParam(defaultValue = "false") boolean desc,
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "50") int size) {
        return data.list(table, prefixed(params, "f."), q, sort, desc, page, size);
    }

    @PostMapping
    @ResponseStatus(HttpStatus.CREATED)
    public Map<String, Object> create(@PathVariable String table, @RequestBody Map<String, Object> values) {
        return data.insert(table, values);
    }

    @GetMapping("/record")
    public Map<String, Object> get(@PathVariable String table, @RequestParam Map<String, String> params) {
        return data.get(table, prefixed(params, "k."));
    }

    @PutMapping("/record")
    public Map<String, Object> update(@PathVariable String table, @RequestParam Map<String, String> params,
            @RequestBody Map<String, Object> values) {
        return data.update(table, prefixed(params, "k."), values);
    }

    @DeleteMapping("/record")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    public void delete(@PathVariable String table, @RequestParam Map<String, String> params) {
        data.delete(table, prefixed(params, "k."));
    }

    @GetMapping("/lookup")
    public List<Map<String, Object>> lookup(@PathVariable String table) {
        return data.lookup(table);
    }

    @GetMapping("/count")
    public Map<String, Long> count(@PathVariable String table) {
        return Map.of("count", data.count(table));
    }

    private static Map<String, String> prefixed(Map<String, String> params, String prefix) {
        Map<String, String> out = new LinkedHashMap<>();
        params.forEach((k, v) -> {
            if (k.startsWith(prefix)) {
                out.put(k.substring(prefix.length()), v);
            }
        });
        return out;
    }
}
