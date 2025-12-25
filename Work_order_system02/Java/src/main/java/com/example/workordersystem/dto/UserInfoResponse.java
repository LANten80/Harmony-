package com.example.workordersystem.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDateTime;

/**
 * 用户信息响应DTO
 */
@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class UserInfoResponse {
    private String id;
    private String username;
    private String phone;
    private LocalDateTime registerTime;
    private LocalDateTime lastLoginTime;
    private String token; // JWT Token（可选）
}

