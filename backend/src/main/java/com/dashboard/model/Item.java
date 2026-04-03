package com.dashboard.model;

import java.math.BigDecimal;
import java.time.OffsetDateTime;

public class Item {

    private Long id;
    private String name;
    private BigDecimal price;
    private OffsetDateTime createdAt;

    public Item() {}

    public Item(Long id, String name, BigDecimal price, OffsetDateTime createdAt) {
        this.id = id;
        this.name = name;
        this.price = price;
        this.createdAt = createdAt;
    }

    public Long getId() { return id; }
    public void setId(Long id) { this.id = id; }

    public String getName() { return name; }
    public void setName(String name) { this.name = name; }

    public BigDecimal getPrice() { return price; }
    public void setPrice(BigDecimal price) { this.price = price; }

    public OffsetDateTime getCreatedAt() { return createdAt; }
    public void setCreatedAt(OffsetDateTime createdAt) { this.createdAt = createdAt; }
}
