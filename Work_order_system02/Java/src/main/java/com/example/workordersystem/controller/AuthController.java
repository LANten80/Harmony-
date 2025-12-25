package com.example.workordersystem.controller;

import com.example.workordersystem.common.ApiResponse;
import com.example.workordersystem.dto.LoginRequest;
import com.example.workordersystem.dto.RegisterRequest;
import com.example.workordersystem.dto.UserInfoResponse;
import com.example.workordersystem.service.UserService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.*;

/**
 * 认证控制器
 */
@RestController
@RequestMapping("/auth")
@RequiredArgsConstructor
public class AuthController {

    private final UserService userService;

    /**
     * 用户注册
     */
    @PostMapping("/register")
    public ApiResponse<UserInfoResponse> register(@Valid @RequestBody RegisterRequest request) {
        try {
            UserInfoResponse response = userService.register(request);
            return ApiResponse.success("注册成功", response);
        } catch (RuntimeException e) {
            return ApiResponse.error(400, e.getMessage());
        } catch (Exception e) {
            return ApiResponse.error("注册失败，请稍后重试");
        }
    }

    /**
     * 用户登录
     */
    @PostMapping("/login")
    public ApiResponse<UserInfoResponse> login(@Valid @RequestBody LoginRequest request) {
        try {
            UserInfoResponse response = userService.login(request);
            return ApiResponse.success("登录成功", response);
        } catch (RuntimeException e) {
            return ApiResponse.error(401, e.getMessage());
        } catch (Exception e) {
            return ApiResponse.error("登录失败，请稍后重试");
        }
    }

    /**
     * 退出登录（可选，如果使用JWT，客户端删除Token即可）
     */
    @PostMapping("/logout")
    public ApiResponse<Void> logout() {
        return ApiResponse.success("退出成功", null);
    }
}

