package de.lueftung.admin.meta;

import java.util.Collection;
import java.util.Map;

import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/meta")
public class MetaController {

    private final MetaService meta;

    public MetaController(MetaService meta) {
        this.meta = meta;
    }

    @GetMapping
    public Map<String, Object> all() {
        Collection<TableMeta> tables = meta.tables().values();
        return Map.of("schema", meta.schema(), "tables", tables);
    }

    /** Nach einer Schemaänderung aufrufen (Aktion "Metadaten neu laden"). */
    @PostMapping("/refresh")
    public Map<String, Object> refresh() {
        meta.refresh();
        return all();
    }
}
