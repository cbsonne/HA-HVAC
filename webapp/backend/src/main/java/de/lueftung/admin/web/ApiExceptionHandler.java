package de.lueftung.admin.web;

import java.sql.SQLException;
import java.util.Locale;
import java.util.Map;

import org.springframework.context.MessageSource;
import org.springframework.context.i18n.LocaleContextHolder;
import org.springframework.dao.DataAccessException;
import org.springframework.dao.DataIntegrityViolationException;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.bind.annotation.RestControllerAdvice;

/**
 * Übersetzt Fehler in {"code": ..., "message": ...}, damit die Oberfläche sie wie BC als Fehlerdialog zeigt.
 * Die Meldung kommt in der Sprache aus Accept-Language (de, en, pt); die Originalmeldung der Datenbank
 * wird bei Datenbankfehlern als Detail angehängt.
 */
@RestControllerAdvice
public class ApiExceptionHandler {

    private final MessageSource messages;

    public ApiExceptionHandler(MessageSource messages) {
        this.messages = messages;
    }

    @ExceptionHandler(ApiException.class)
    ResponseEntity<Map<String, String>> api(ApiException e) {
        return body(e.status(), e.code(), msg(e.code(), e.args()));
    }

    @ExceptionHandler(DataIntegrityViolationException.class)
    ResponseEntity<Map<String, String>> integrity(DataIntegrityViolationException e) {
        String detail = rootMessage(e);
        String code = classify(detail);
        return body(HttpStatus.CONFLICT, code, msg(code) + "\n\n" + detail);
    }

    @ExceptionHandler(DataAccessException.class)
    ResponseEntity<Map<String, String>> dataAccess(DataAccessException e) {
        return body(HttpStatus.BAD_REQUEST, "db.error", rootMessage(e));
    }

    private String msg(String code, Object... args) {
        Locale locale = LocaleContextHolder.getLocale();
        return messages.getMessage(code, args, code, locale);
    }

    private static ResponseEntity<Map<String, String>> body(HttpStatus status, String code, String message) {
        return ResponseEntity.status(status).body(Map.of("code", code, "message", message));
    }

    private static String rootMessage(Throwable e) {
        Throwable t = e;
        while (t.getCause() != null && !(t instanceof SQLException)) {
            t = t.getCause();
        }
        String msg = t.getMessage() == null ? e.toString() : t.getMessage();
        return msg.startsWith("ERROR: ") ? msg.substring(7) : msg;
    }

    /** Postgres-Meldungen (englisch, lc_messages=C) einer verständlichen Kategorie zuordnen. */
    private static String classify(String msg) {
        if (msg.contains("violates foreign key constraint") && msg.contains("is still referenced")) {
            return "db.stillReferenced";
        }
        if (msg.contains("violates foreign key constraint")) {
            return "db.foreignKeyMissing";
        }
        if (msg.contains("duplicate key")) {
            return "db.duplicate";
        }
        if (msg.contains("violates not-null constraint")) {
            return "db.notNull";
        }
        if (msg.contains("violates check constraint")) {
            return "db.check";
        }
        return "db.error";
    }
}
