package com.example.demoapp.controller;

// Version 4.0 - Pipeline Test May 2026

import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import java.time.LocalDateTime;
import java.util.HashMap;
import java.util.Map;

@RestController
public class HelloController {

    private static final String VERSION = "4.0.0";

    @GetMapping("/")
    public Map<String, Object> home() {
        Map<String, Object> response = new HashMap<>();
        response.put("message", "Pipeline Test - Version " + VERSION);
        response.put("version", VERSION);
        response.put("feature", "Full Pipeline Flow Test");
        response.put("timestamp", LocalDateTime.now().toString());
        response.put("status", "Deployed Successfully");
        return response;
    }

    @GetMapping("/hello")
    public Map<String, String> hello(@RequestParam(value = "name", defaultValue = "World") String name) {
        Map<String, String> response = new HashMap<>();
        response.put("message", "Hello, " + name + "! (v" + VERSION + ")");
        return response;
    }

    @GetMapping("/api/info")
    public Map<String, Object> info() {
        Map<String, Object> response = new HashMap<>();
        response.put("application", "Spring Boot Demo App");
        response.put("version", VERSION);
        response.put("author", "Rahul Nair");
        response.put("java_version", System.getProperty("java.version"));
        response.put("platform", "Azure Web App");
        response.put("workflows", "CI, Infrastructure, Deploy-Dev, Deploy-Prod");
        return response;
    }
}
