package de.lueftung.admin.objekt;

import java.util.Map;

import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/objekt")
public class ObjektController {

    private final ObjektService objekte;

    public ObjektController(ObjektService objekte) {
        this.objekte = objekte;
    }

    @GetMapping("/status")
    public Map<String, Object> status() {
        return objekte.status();
    }

    @PostMapping("/{id}/adresse-aendern")
    public Map<String, Object> changeAddress(@PathVariable long id, @RequestBody Map<String, Object> request) {
        return objekte.changeAddress(id, request);
    }
}
