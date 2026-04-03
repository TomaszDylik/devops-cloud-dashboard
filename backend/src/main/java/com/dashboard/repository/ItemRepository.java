package com.dashboard.repository;

import com.dashboard.model.Item;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.jdbc.core.RowMapper;
import org.springframework.stereotype.Repository;

import java.math.BigDecimal;
import java.sql.ResultSet;
import java.time.OffsetDateTime;
import java.util.List;

@Repository
public class ItemRepository {

    private final JdbcTemplate jdbc;

    public ItemRepository(JdbcTemplate jdbc) {
        this.jdbc = jdbc;
    }

    private static final RowMapper<Item> ROW_MAPPER = (ResultSet rs, int rowNum) -> {
        Item item = new Item();
        item.setId(rs.getLong("id"));
        item.setName(rs.getString("name"));
        BigDecimal price = rs.getBigDecimal("price");
        item.setPrice(rs.wasNull() ? null : price);
        item.setCreatedAt(rs.getObject("created_at", OffsetDateTime.class));
        return item;
    };

    public List<Item> findAll() {
        return jdbc.query("SELECT id, name, price, created_at FROM items ORDER BY id", ROW_MAPPER);
    }

    public Item save(String name, BigDecimal price) {
        return jdbc.queryForObject(
                "INSERT INTO items (name, price) VALUES (?, ?) RETURNING id, name, price, created_at",
                ROW_MAPPER,
                name, price
        );
    }

    public int count() {
        Integer c = jdbc.queryForObject("SELECT COUNT(*)::int FROM items", Integer.class);
        return c != null ? c : 0;
    }
}
