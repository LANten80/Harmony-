package com.example.workordersystem.controller;

import com.example.workordersystem.common.ApiResponse;
import com.example.workordersystem.dto.UserInfoResponse;
import com.example.workordersystem.service.UserService;
import com.example.workordersystem.util.JwtUtil;
import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.*;

/**
 * 用户控制器
 */
@RestController
@RequestMapping("/user")
@RequiredArgsConstructor
public class UserController {

    private final UserService userService;
    private final JwtUtil jwtUtil;

    /**
     * 获取当前用户信息（通过Token）
     */
    @GetMapping("/info")
    public ApiResponse<UserInfoResponse> getUserInfo(@RequestHeader(value = "Authorization", required = false) String token) {
        try {
            // 从Token中提取用户信息
            if (token != null && token.startsWith("Bearer ")) {
                token = token.substring(7);
                if (jwtUtil.validateToken(token)) {
                    UserInfoResponse response = userService.getUserInfoByToken(token);
                    return ApiResponse.success(response);
                }
            }
            return ApiResponse.error(401, "未授权，请先登录");
        } catch (Exception e) {
            return ApiResponse.error("获取用户信息失败");
        }
    }

    /**
     * 根据用户ID获取用户信息
     */
    @GetMapping("/{userId}")
    public ApiResponse<UserInfoResponse> getUserById(@PathVariable String userId) {
        try {
            UserInfoResponse response = userService.getUserInfo(userId);
            return ApiResponse.success(response);
        } catch (RuntimeException e) {
            return ApiResponse.error(404, e.getMessage());
        } catch (Exception e) {
            return ApiResponse.error("获取用户信息失败");
        }
    }
}

