package de.lueftung.admin.web;

import org.springframework.http.HttpStatus;

/**
 * Fachlicher Fehler. {@code code} ist ein Schlüssel aus messages*.properties,
 * die Meldung wird in der Sprache der Anfrage (Accept-Language) übersetzt.
 */
public class ApiException extends RuntimeException {

    private final HttpStatus status;
    private final String code;
    private final transient Object[] args;

    public ApiException(HttpStatus status, String code, Object... args) {
        super(code);
        this.status = status;
        this.code = code;
        this.args = args;
    }

    public HttpStatus status() {
        return status;
    }

    public String code() {
        return code;
    }

    public Object[] args() {
        return args;
    }

    public static ApiException notFound(String code, Object... args) {
        return new ApiException(HttpStatus.NOT_FOUND, code, args);
    }

    public static ApiException badRequest(String code, Object... args) {
        return new ApiException(HttpStatus.BAD_REQUEST, code, args);
    }
}
