package com.pasadanow.FinalProject.controller;

import com.pasadanow.FinalProject.dto.*;
import com.pasadanow.FinalProject.model.*;
import com.pasadanow.FinalProject.repository.*;
import com.pasadanow.FinalProject.security.JwtUtils;
import jakarta.servlet.http.Cookie;
import jakarta.servlet.http.HttpServletResponse;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.*;
import org.springframework.security.authentication.*;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.web.bind.annotation.*;

import java.util.Map;

@RestController
@RequestMapping("/api/auth")
public class AuthController {

    @Autowired
    private AuthenticationManager authenticationManager;
    @Autowired
    private CommuterRepository commuterRepo;
    @Autowired
    private DriverRepository driverRepo;
    @Autowired
    private PasswordEncoder encoder;
    @Autowired
    private JwtUtils jwtUtils;

    @Value("${jwt.expiration}")
    private int jwtExpirationMs;
    @Value("${jwt.cookie.domain}")
    private String jwtDomain;

    private Cookie buildJwtCookie(String token) {
        Cookie cookie = new Cookie("jwt", token);
        cookie.setHttpOnly(true);
        cookie.setPath("/");
        cookie.setDomain(jwtDomain);
        cookie.setMaxAge(jwtExpirationMs / 1000);
        return cookie;
    }

    private Cookie expiredJwtCookie() {
        Cookie cookie = new Cookie("jwt", "");
        cookie.setHttpOnly(true);
        cookie.setPath("/");
        cookie.setDomain(jwtDomain);
        cookie.setMaxAge(0);
        return cookie;
    }

    @PostMapping("/login")
    public ResponseEntity<?> login(@RequestBody LoginRequest req,
            HttpServletResponse response) {
        try {
            Authentication auth = authenticationManager.authenticate(
                    new UsernamePasswordAuthenticationToken(req.getUsername(), req.getPassword()));

            // find which table they belong to and get verifiedStatus
            String role;
            String verifiedStatus;

            var commuter = commuterRepo.findByUsername(req.getUsername());
            if (commuter.isPresent()) {
                role = "ROLE_COMMUTER";
                verifiedStatus = commuter.get().getVerifiedStatus();
            } else {
                Driver d = driverRepo.findByUsername(req.getUsername()).orElseThrow();
                role = "ROLE_DRIVER";
                verifiedStatus = d.getVerifiedStatus();
            }

            String jwt = jwtUtils.generateToken(auth.getName());
            response.addCookie(buildJwtCookie(jwt));

            return ResponseEntity.ok(new JwtResponse(jwt, auth.getName(), role, verifiedStatus));

        } catch (BadCredentialsException e) {
            return ResponseEntity.status(HttpStatus.UNAUTHORIZED)
                    .body(Map.of("message", "Invalid username or password"));
        } catch (Exception e) {
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                    .body(Map.of("message", "Authentication failed"));
        }
    }

    @PostMapping("/register")
    public ResponseEntity<?> register(@RequestBody SignupRequest req,
            HttpServletResponse response) {

        // check username across both tables
        if (commuterRepo.existsByUsername(req.getUsername()) ||
                driverRepo.existsByUsername(req.getUsername())) {
            return ResponseEntity.status(HttpStatus.BAD_REQUEST)
                    .body(Map.of("message", "Username is already taken"));
        }

        String jwt;

        if ("driver".equalsIgnoreCase(req.getRole())) {
            if (req.getLicenseNo() == null || req.getPlateNo() == null) {
                return ResponseEntity.status(HttpStatus.BAD_REQUEST)
                        .body(Map.of("message", "License and plate number are required for drivers"));
            }
            Driver driver = new Driver(
                    req.getUsername(), encoder.encode(req.getPassword()),
                    req.getFullName(), req.getPhone(), req.getEmail(),
                    req.getLicenseNo(), req.getPlateNo(), req.getTodaNo());
            driverRepo.save(driver);
        } else {
            Commuter commuter = new Commuter(
                    req.getUsername(), encoder.encode(req.getPassword()),
                    req.getFullName(), req.getPhone(), req.getEmail());
            commuterRepo.save(commuter);
        }

        jwt = jwtUtils.generateToken(req.getUsername());
        response.addCookie(buildJwtCookie(jwt));

        return ResponseEntity.ok(Map.of(
                "username", req.getUsername(),
                "role", "driver".equalsIgnoreCase(req.getRole()) ? "ROLE_DRIVER" : "ROLE_COMMUTER",
                "verifiedStatus", "pending"));
    }

    @PostMapping("/logout")
    public ResponseEntity<?> logout(HttpServletResponse response) {
        response.addCookie(expiredJwtCookie());
        return ResponseEntity.ok(Map.of("message", "Logged out"));
    }

    @GetMapping("/me")
    public ResponseEntity<?> me() {
        Authentication auth = SecurityContextHolder.getContext().getAuthentication();
        if (auth == null || !auth.isAuthenticated()
                || auth.getPrincipal().equals("anonymousUser")) {
            return ResponseEntity.status(HttpStatus.UNAUTHORIZED).build();
        }

        String username = auth.getName();
        var commuter = commuterRepo.findByUsername(username);
        if (commuter.isPresent()) {
            return ResponseEntity.ok(Map.of(
                    "username", username,
                    "role", "ROLE_COMMUTER",
                    "verifiedStatus", commuter.get().getVerifiedStatus()));
        }

        Driver d = driverRepo.findByUsername(username).orElseThrow();
        return ResponseEntity.ok(Map.of(
                "username", username,
                "role", "ROLE_DRIVER",
                "verifiedStatus", d.getVerifiedStatus()));
    }
}