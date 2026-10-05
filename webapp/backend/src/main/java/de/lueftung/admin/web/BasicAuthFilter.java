package de.lueftung.admin.web;

import java.io.IOException;
import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.util.Base64;

import org.springframework.stereotype.Component;
import org.springframework.web.filter.OncePerRequestFilter;

import de.lueftung.admin.AppProperties;
import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;

/** Einfacher HTTP-Basic-Schutz für /api, aktiv sobald APP_PASSWORD gesetzt ist. */
@Component
public class BasicAuthFilter extends OncePerRequestFilter {

    private final AppProperties props;

    public BasicAuthFilter(AppProperties props) {
        this.props = props;
    }

    @Override
    protected boolean shouldNotFilter(HttpServletRequest request) {
        return !props.auth().enabled() || !request.getRequestURI().startsWith("/api/");
    }

    @Override
    protected void doFilterInternal(HttpServletRequest req, HttpServletResponse res, FilterChain chain)
            throws ServletException, IOException {
        String header = req.getHeader("Authorization");
        if (header != null && header.startsWith("Basic ")) {
            String decoded;
            try {
                decoded = new String(Base64.getDecoder().decode(header.substring(6)), StandardCharsets.UTF_8);
            } catch (IllegalArgumentException e) {
                decoded = "";
            }
            String expected = props.auth().user() + ":" + props.auth().password();
            if (MessageDigest.isEqual(decoded.getBytes(StandardCharsets.UTF_8), expected.getBytes(StandardCharsets.UTF_8))) {
                chain.doFilter(req, res);
                return;
            }
        }
        res.setHeader("WWW-Authenticate", "Basic realm=\"Lueftung\"");
        res.sendError(HttpServletResponse.SC_UNAUTHORIZED);
    }
}
