package com.example.workordersystem.service;

import com.example.workordersystem.dto.LoginRequest;
import com.example.workordersystem.dto.RegisterRequest;
import com.example.workordersystem.dto.UserInfoResponse;
import com.example.workordersystem.entity.User;
import com.example.workordersystem.repository.UserRepository;
import com.example.workordersystem.util.IdGenerator;
import com.example.workordersystem.util.JwtUtil;
import lombok.RequiredArgsConstructor;
import org.springframework.lang.NonNull;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.Optional;

/**
 * 用户服务类
 */
@Service
@RequiredArgsConstructor
public class UserService {

    private final UserRepository userRepository;
    private final PasswordEncoder passwordEncoder;
    private final JwtUtil jwtUtil;

    /**
     * 用户注册
     */
    @Transactional
    public UserInfoResponse register(RegisterRequest request) {
        // 检查用户名是否已存在
        if (userRepository.existsByUsername(request.getUsername())) {
            throw new RuntimeException("用户名已存在");
        }

        // 检查手机号是否已注册
        if (userRepository.existsByPhone(request.getPhone())) {
            throw new RuntimeException("手机号已注册");
        }

        // 创建新用户
        User user = new User();
        user.setId(IdGenerator.generateUserId());
        user.setUsername(request.getUsername());
        user.setPhone(request.getPhone());
        user.setPassword(passwordEncoder.encode(request.getPassword()));
        user.setRegisterTime(LocalDateTime.now());
        user.setStatus(1);

        user = userRepository.save(user);

        // 生成Token
        String token = jwtUtil.generateToken(user.getId(), user.getUsername());

        // 构建响应
        return UserInfoResponse.builder()
                .id(user.getId())
                .username(user.getUsername())
                .phone(user.getPhone())
                .registerTime(user.getRegisterTime())
                .token(token)
                .build();
    }

    /**
     * 用户登录
     */
    @Transactional
    public UserInfoResponse login(LoginRequest request) {
        // 查找用户（支持用户名或手机号登录）
        Optional<User> userOpt = userRepository.findByUsernameOrPhone(
                request.getAccount(),
                request.getAccount()
        );

        if (userOpt.isEmpty()) {
            throw new RuntimeException("用户名或密码错误");
        }

        User user = userOpt.get();

        // 验证密码
        if (!passwordEncoder.matches(request.getPassword(), user.getPassword())) {
            throw new RuntimeException("用户名或密码错误");
        }

        // 检查用户状态
        if (user.getStatus() == 0) {
            throw new RuntimeException("用户已被禁用");
        }

        // 更新最后登录时间
        user.setLastLoginTime(LocalDateTime.now());
        userRepository.save(user);

        // 生成Token
        String token = jwtUtil.generateToken(user.getId(), user.getUsername());

        // 构建响应
        return UserInfoResponse.builder()
                .id(user.getId())
                .username(user.getUsername())
                .phone(user.getPhone())
                .registerTime(user.getRegisterTime())
                .lastLoginTime(user.getLastLoginTime())
                .token(token)
                .build();
    }

    /**
     * 根据ID获取用户信息
     */
    public UserInfoResponse getUserInfo(@NonNull String userId) {
        User user = userRepository.findById(userId)
                .orElseThrow(() -> new RuntimeException("用户不存在"));

        return UserInfoResponse.builder()
                .id(user.getId())
                .username(user.getUsername())
                .phone(user.getPhone())
                .registerTime(user.getRegisterTime())
                .lastLoginTime(user.getLastLoginTime())
                .build();
    }

    /**
     * 根据Token获取用户信息
     */
    public UserInfoResponse getUserInfoByToken(String token) {
        String userId = jwtUtil.getUserIdFromToken(token);
        if (userId == null) {
            throw new RuntimeException("无效的Token");
        }
        return getUserInfo(userId);
    }
}

