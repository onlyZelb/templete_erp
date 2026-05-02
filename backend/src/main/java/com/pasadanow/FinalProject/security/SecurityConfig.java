package com.pasadanow.FinalProject.security;

import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.http.HttpMethod;
import org.springframework.security.authentication.AuthenticationManager;
import org.springframework.security.config.annotation.authentication.configuration.AuthenticationConfiguration;
import org.springframework.security.config.annotation.web.builders.HttpSecurity;
import org.springframework.security.config.annotation.web.configuration.EnableWebSecurity;
import org.springframework.security.config.http.SessionCreationPolicy;
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.security.web.SecurityFilterChain;
import org.springframework.security.web.authentication.UsernamePasswordAuthenticationFilter;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.cors.CorsConfiguration;
import org.springframework.web.cors.CorsConfigurationSource;
import org.springframework.web.cors.UrlBasedCorsConfigurationSource;
import org.springframework.security.config.Customizer;

import java.util.Arrays;
import java.util.List;

@Configuration
@EnableWebSecurity
public class SecurityConfig {

    @Autowired
    private JwtAuthenticationFilter jwtAuthFilter;

    @Bean
    public AuthenticationManager authenticationManager(
            AuthenticationConfiguration authConfig) throws Exception {
        return authConfig.getAuthenticationManager();
    }

    @Bean
    public SecurityFilterChain filterChain(HttpSecurity http) throws Exception {
        http
                .cors(Customizer.withDefaults())
                .csrf(csrf -> csrf.disable())
                .sessionManagement(session -> session.sessionCreationPolicy(SessionCreationPolicy.STATELESS))
                .authorizeHttpRequests(auth -> auth
                        // ── CORS pre-flight ───────────────────────────────────────
                        .requestMatchers(HttpMethod.OPTIONS, "/**").permitAll()

                        // ── Auth endpoints ────────────────────────────────────────
                        .requestMatchers(
                                "/api/auth/login",
                                "/api/auth/register",
                                "/api/auth/logout")
                        .permitAll()

                        // ── WebSocket handshake + SockJS negotiation ──────────────
                        // SockJS uses these paths during its transport negotiation:
                        // /ws/chat (raw WebSocket upgrade)
                        // /ws/chat/websocket (SockJS WebSocket transport)
                        // /ws/chat/info (SockJS info endpoint)
                        // /ws/chat/** (SockJS polling fallbacks)
                        .requestMatchers("/ws/chat", "/ws/chat/**").permitAll()

                        // ── Chat REST history endpoint ─────────────────────────────
                        .requestMatchers("/api/chat/**").permitAll()

                        // ── Actuator / error ──────────────────────────────────────
                        .requestMatchers("/error", "/actuator/**").permitAll()

                        // ── Everything else requires a valid JWT ──────────────────
                        .anyRequest().authenticated());

        http.addFilterBefore(jwtAuthFilter, UsernamePasswordAuthenticationFilter.class);

        return http.build();
    }

    @Bean
    public PasswordEncoder passwordEncoder() {
        return new BCryptPasswordEncoder();
    }

    @Bean
    public CorsConfigurationSource corsConfigurationSource() {
        CorsConfiguration config = new CorsConfiguration();

        // Allow all local origins — covers emulator (10.0.2.2), real device
        // (192.168.x.x), web (localhost), and Docker networking
        config.setAllowedOriginPatterns(List.of("*"));

        config.setAllowedMethods(Arrays.asList(
                "GET", "POST", "PUT", "PATCH", "DELETE", "OPTIONS"));

        config.setAllowedHeaders(Arrays.asList(
                "Authorization", "Cache-Control", "Content-Type",
                // SockJS / STOMP headers
                "Upgrade", "Connection", "Sec-WebSocket-Key",
                "Sec-WebSocket-Version", "Sec-WebSocket-Extensions",
                "Sec-WebSocket-Protocol"));

        config.setAllowCredentials(true);

        UrlBasedCorsConfigurationSource source = new UrlBasedCorsConfigurationSource();
        source.registerCorsConfiguration("/**", config);
        return source;
    }
}