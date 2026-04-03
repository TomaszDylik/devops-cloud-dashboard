package com.dashboard.controller;

import com.dashboard.model.Item;
import com.dashboard.repository.ItemRepository;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.math.BigDecimal;
import java.util.List;
import java.util.Map;

@RestController
public class ItemController {

    private final ItemRepository itemRepository;

    public ItemController(ItemRepository itemRepository) {
        this.itemRepository = itemRepository;
    }

    @GetMapping("/items")
    public ResponseEntity<?> getItems() {
        try {
            List<Item> items = itemRepository.findAll();
            return ResponseEntity.ok(items);
        } catch (Exception e) {
            return ResponseEntity.status(HttpStatus.SERVICE_UNAVAILABLE)
                    .body(Map.of("error", "Database unavailable", "details", e.getMessage()));
        }
    }

    @PostMapping("/items")
    public ResponseEntity<?> createItem(@RequestBody(required = false) Map<String, Object> body) {
        if (body == null || !body.containsKey("name") || !(body.get("name") instanceof String name) || name.isBlank()) {
            return ResponseEntity.badRequest()
                    .body(Map.of("error", "Field \"name\" is required and must be a string."));
        }

        BigDecimal price = null;
        if (body.get("price") instanceof Number num) {
            price = new BigDecimal(num.toString());
        }

        try {
            Item created = itemRepository.save(name.trim(), price);
            return ResponseEntity.status(HttpStatus.CREATED).body(created);
        } catch (Exception e) {
            return ResponseEntity.status(HttpStatus.SERVICE_UNAVAILABLE)
                    .body(Map.of("error", "Database unavailable", "details", e.getMessage()));
        }
    }
}
