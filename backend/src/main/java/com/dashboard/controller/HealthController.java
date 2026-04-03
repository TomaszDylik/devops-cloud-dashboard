package com.dashboard.controller;

import org.springframework.data.redis.core.StringRedisTemplate;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RestController;

import javax.sql.DataSource;
import java.lang.management.ManagementFactory;
import java.sql.Connection;
import java.util.Map;

@RestController
public class HealthController {

    private final DataSource dataSource;
    private final StringRedisTemplate redisTemplate;

    public HealthController(DataSource dataSource, StringRedisTemplate redisTemplate) {
        this.dataSource = dataSource;
        this.redisTemplate = redisTemplate;
    }

    @GetMapping("/health")
    public ResponseEntity<Map<String, Object>> health() {
        boolean pgStatus = false;
        try (Connection conn = dataSource.getConnection()) {
            pgStatus = conn.isValid(3);
        } catch (Exception ignored) {}

        boolean redisStatus = false;
        try {
            String pong = redisTemplate.getConnectionFactory().getConnection().ping();
            redisStatus = "PONG".equals(pong);
        } catch (Exception ignored) {}

        long uptime = ManagementFactory.getRuntimeMXBean().getUptime() / 1000;

        String status = (pgStatus && redisStatus) ? "ok" : "degraded";

        return ResponseEntity.ok(Map.of(
                "status", status,
                "uptime", uptime,
                "postgres", pgStatus,
                "redis", redisStatus
        ));
    }
}
