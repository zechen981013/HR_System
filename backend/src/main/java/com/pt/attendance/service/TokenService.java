package com.pt.attendance.service;

import org.springframework.stereotype.Service;

import java.util.Map;
import java.util.UUID;
import java.util.concurrent.ConcurrentHashMap;

/**
 * 简易内存 Token 服务（演示用，重启后需重新登录）
 */
@Service
public class TokenService {

    private final Map<String, Long> tokens = new ConcurrentHashMap<>();

    public String createToken(Long employeeId) {
        String token = UUID.randomUUID().toString().replace("-", "");
        tokens.put(token, employeeId);
        return token;
    }

    public Long getEmployeeId(String token) {
        return tokens.get(token);
    }

    public void removeToken(String token) {
        tokens.remove(token);
    }
}
