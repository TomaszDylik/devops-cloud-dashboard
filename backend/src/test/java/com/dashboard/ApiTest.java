package com.dashboard;

import com.dashboard.filter.RequestCounterFilter;
import com.dashboard.repository.ItemRepository;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.data.redis.core.StringRedisTemplate;
import org.springframework.data.redis.core.ValueOperations;
import org.springframework.boot.test.autoconfigure.web.servlet.WebMvcTest;
import org.springframework.test.context.bean.override.mockito.MockitoBean;
import org.springframework.test.web.servlet.MockMvc;

import javax.sql.DataSource;
import java.sql.Connection;

import static org.mockito.Mockito.*;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

@WebMvcTest
class ApiTest {

    @Autowired
    private MockMvc mockMvc;

    @MockitoBean
    private ItemRepository itemRepository;

    @MockitoBean
    private DataSource dataSource;

    @MockitoBean
    private StringRedisTemplate redisTemplate;

    @Autowired
    private RequestCounterFilter requestCounter;

    @Test
    void healthReturnsStatusAndFields() throws Exception {
        Connection conn = mock(Connection.class);
        when(conn.isValid(anyInt())).thenReturn(false);
        when(dataSource.getConnection()).thenReturn(conn);

        mockMvc.perform(get("/health"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.status").isString())
                .andExpect(jsonPath("$.uptime").isNumber())
                .andExpect(jsonPath("$.postgres").isBoolean())
                .andExpect(jsonPath("$.redis").isBoolean());
    }

    @Test
    void statsReturnsTotalRequestsAndServerTime() throws Exception {
        @SuppressWarnings("unchecked")
        ValueOperations<String, String> valueOps = mock(ValueOperations.class);
        when(redisTemplate.opsForValue()).thenReturn(valueOps);
        when(valueOps.get(anyString())).thenReturn(null);

        mockMvc.perform(get("/stats"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.totalRequests").isNumber())
                .andExpect(jsonPath("$.uptimeSeconds").isNumber())
                .andExpect(jsonPath("$.serverTime").isString())
                .andExpect(header().exists("X-Cache"));
    }
}

