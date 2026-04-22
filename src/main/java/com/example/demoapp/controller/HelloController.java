package com.example.demoapp.controller;

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
        response.put("message", "Welcome to Rahul's Spring Boot Demo App - Learning GitHub PRs!");
        response.put("timestamp", LocalDateTime.now().toString());
        response.put("status", "Running");
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
