package com.dashboard.controller;

import com.dashboard.filter.RequestCounterFilter;
import com.dashboard.repository.ItemRepository;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.data.redis.core.StringRedisTemplate;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RestController;

import java.lang.management.ManagementFactory;
import java.net.InetAddress;
import java.time.Instant;
import java.util.LinkedHashMap;
import java.util.Map;
import java.util.concurrent.TimeUnit;

@RestController
public class StatsController {

    private static final String STATS_CACHE_KEY = "dashboard:stats";
    private static final long STATS_TTL_SECONDS = 10;

    private final ItemRepository itemRepository;
    private final RequestCounterFilter requestCounter;
    private final StringRedisTemplate redisTemplate;
    private final ObjectMapper objectMapper;
    private final String instanceId;

    public StatsController(ItemRepository itemRepository,
                           RequestCounterFilter requestCounter,
                           StringRedisTemplate redisTemplate,
                           ObjectMapper objectMapper,
                           @Value("${INSTANCE_ID:#{null}}") String envInstanceId) {
        this.itemRepository = itemRepository;
        this.requestCounter = requestCounter;
        this.redisTemplate = redisTemplate;
        this.objectMapper = objectMapper;

        if (envInstanceId != null && !envInstanceId.isBlank()) {
            this.instanceId = envInstanceId;
        } else {
            String host;
            try { host = InetAddress.getLocalHost().getHostName(); } catch (Exception e) { host = "unknown"; }
            this.instanceId = host;
        }
    }

    @SuppressWarnings("null")
    @GetMapping("/stats")
    public ResponseEntity<Map<String, Object>> stats() {
        // Try cache first
        try {
            String cached = redisTemplate.opsForValue().get(STATS_CACHE_KEY);
            if (cached != null) {
                @SuppressWarnings("unchecked")
                Map<String, Object> data = objectMapper.readValue(cached, Map.class);
                return ResponseEntity.ok()
                        .header("X-Cache", "HIT")
                        .body(data);
            }
        } catch (Exception ignored) {}

        // Fetch fresh data
        int totalItems = 0;
        try {
            totalItems = itemRepository.count();
        } catch (Exception ignored) {}

        long uptimeSeconds = ManagementFactory.getRuntimeMXBean().getUptime() / 1000;

        Map<String, Object> data = new LinkedHashMap<>();
        data.put("instanceId", instanceId);
        data.put("totalItems", totalItems);
        data.put("totalRequests", requestCounter.getTotalRequests());
        data.put("uptimeSeconds", uptimeSeconds);
        data.put("serverTime", Instant.now().toString());

        // Store in cache
        try {
            String json = objectMapper.writeValueAsString(data);
            redisTemplate.opsForValue().set(STATS_CACHE_KEY, json, STATS_TTL_SECONDS, TimeUnit.SECONDS);
        } catch (Exception ignored) {}

        return ResponseEntity.ok()
                .header("X-Cache", "MISS")
                .body(data);
    }
}
