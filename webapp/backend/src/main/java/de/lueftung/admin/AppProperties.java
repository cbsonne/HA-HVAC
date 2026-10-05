package de.lueftung.admin;

import java.util.List;

import org.springframework.boot.context.properties.ConfigurationProperties;

@ConfigurationProperties(prefix = "app")
public record AppProperties(String schema, List<String> readOnlyTables, Auth auth) {

    public AppProperties {
        readOnlyTables = readOnlyTables == null ? List.of() : readOnlyTables.stream().map(String::trim).filter(s -> !s.isEmpty()).toList();
        auth = auth == null ? new Auth(null, null) : auth;
    }

    public record Auth(String user, String password) {
        public boolean enabled() {
            return password != null && !password.isBlank();
        }
    }
}
