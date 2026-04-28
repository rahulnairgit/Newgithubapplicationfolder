package com.example.demoapp.controller;

// Test 1: CI Workflow Test - Build and Test Only (no deployment)

import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import java.time.LocalDateTime;
import java.util.HashMap;
import java.util.Map;

@RestController
public class HelloController {

    @GetMapping("/")
    public Map<String, Object> home() {
        Map<String, Object> response = new HashMap<>();
        response.put("message", "Multi-Environment Deployment Working!");
        response.put("version", "2.0.0");
        response.put("environment", "Dev");
        response.put("timestamp", LocalDateTime.now().toString());
        response.put("status", "Healthy");
        return response;
    }

    @GetMapping("/hello")
    public Map<String, String> hello(@RequestParam(value = "name", defaultValue = "World") String name) {
        Map<String, String> response = new HashMap<>();
        response.put("message", "Hello, " + name + "!");
        return response;
    }

    @GetMapping("/api/info")
    public Map<String, Object> info() {
        Map<String, Object> response = new HashMap<>();
        response.put("application", "Spring Boot Demo App");
        response.put("version", "1.0.0");
        response.put("author", "Rahul Nair");
        response.put("java_version", System.getProperty("java.version"));
        response.put("platform", "Azure Web App");
        return response;
    }
}
