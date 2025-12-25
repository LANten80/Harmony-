package com.example.workordersystem.controller;

import com.example.workordersystem.common.ApiResponse;
import com.example.workordersystem.dto.TaskRequest;
import com.example.workordersystem.dto.TaskResponse;
import com.example.workordersystem.service.TaskService;
import com.example.workordersystem.util.JwtUtil;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Pageable;
import org.springframework.web.bind.annotation.*;

import java.util.List;

/**
 * 工单控制器
 */
@RestController
@RequestMapping("/task")
@RequiredArgsConstructor
public class TaskController {

    private final TaskService taskService;
    private final JwtUtil jwtUtil;

    /**
     * 获取当前用户ID（从Token中提取）
     */
    private String getUserIdFromToken(String token) {
        if (token != null && token.startsWith("Bearer ")) {
            token = token.substring(7);
            if (jwtUtil.validateToken(token)) {
                return jwtUtil.getUserIdFromToken(token);
            }
        }
        throw new RuntimeException("未授权，请先登录");
    }

    /**
     * 创建工单
     */
    @PostMapping("/create")
    public ApiResponse<TaskResponse> createTask(
            @RequestHeader(value = "Authorization", required = false) String token,
            @Valid @RequestBody TaskRequest request) {
        try {
            String userId = getUserIdFromToken(token);
            TaskResponse response = taskService.createTask(userId, request);
            return ApiResponse.success("创建成功", response);
        } catch (RuntimeException e) {
            return ApiResponse.error(401, e.getMessage());
        } catch (Exception e) {
            return ApiResponse.error("创建工单失败");
        }
    }

    /**
     * 更新工单
     */
    @PutMapping("/{taskId}")
    public ApiResponse<TaskResponse> updateTask(
            @RequestHeader(value = "Authorization", required = false) String token,
            @PathVariable String taskId,
            @Valid @RequestBody TaskRequest request) {
        try {
            String userId = getUserIdFromToken(token);
            TaskResponse response = taskService.updateTask(taskId, userId, request);
            return ApiResponse.success("更新成功", response);
        } catch (RuntimeException e) {
            return ApiResponse.error(400, e.getMessage());
        } catch (Exception e) {
            return ApiResponse.error("更新工单失败");
        }
    }

    /**
     * 删除工单
     */
    @DeleteMapping("/{taskId}")
    public ApiResponse<Void> deleteTask(
            @RequestHeader(value = "Authorization", required = false) String token,
            @PathVariable String taskId) {
        try {
            String userId = getUserIdFromToken(token);
            taskService.deleteTask(taskId, userId);
            return ApiResponse.success("删除成功", null);
        } catch (RuntimeException e) {
            return ApiResponse.error(400, e.getMessage());
        } catch (Exception e) {
            return ApiResponse.error("删除工单失败");
        }
    }

    /**
     * 获取工单详情
     */
    @GetMapping("/{taskId}")
    public ApiResponse<TaskResponse> getTaskById(
            @RequestHeader(value = "Authorization", required = false) String token,
            @PathVariable String taskId) {
        try {
            String userId = getUserIdFromToken(token);
            TaskResponse response = taskService.getTaskById(taskId, userId);
            return ApiResponse.success(response);
        } catch (RuntimeException e) {
            return ApiResponse.error(404, e.getMessage());
        } catch (Exception e) {
            return ApiResponse.error("获取工单失败");
        }
    }

    /**
     * 获取工单列表（分页）
     */
    @GetMapping("/list")
    public ApiResponse<Page<TaskResponse>> getTaskList(
            @RequestHeader(value = "Authorization", required = false) String token,
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "10") int size) {
        try {
            String userId = getUserIdFromToken(token);
            Pageable pageable = PageRequest.of(page, size);
            Page<TaskResponse> response = taskService.getTaskList(userId, pageable);
            return ApiResponse.success(response);
        } catch (RuntimeException e) {
            return ApiResponse.error(401, e.getMessage());
        } catch (Exception e) {
            return ApiResponse.error("获取工单列表失败");
        }
    }

    /**
     * 根据状态获取工单列表
     */
    @GetMapping("/status/{status}")
    public ApiResponse<List<TaskResponse>> getTasksByStatus(
            @RequestHeader(value = "Authorization", required = false) String token,
            @PathVariable String status) {
        try {
            String userId = getUserIdFromToken(token);
            List<TaskResponse> response = taskService.getTasksByStatus(userId, status);
            return ApiResponse.success(response);
        } catch (RuntimeException e) {
            return ApiResponse.error(401, e.getMessage());
        } catch (Exception e) {
            return ApiResponse.error("获取工单列表失败");
        }
    }

    /**
     * 根据优先级获取工单列表
     */
    @GetMapping("/priority/{priority}")
    public ApiResponse<List<TaskResponse>> getTasksByPriority(
            @RequestHeader(value = "Authorization", required = false) String token,
            @PathVariable String priority) {
        try {
            String userId = getUserIdFromToken(token);
            List<TaskResponse> response = taskService.getTasksByPriority(userId, priority);
            return ApiResponse.success(response);
        } catch (RuntimeException e) {
            return ApiResponse.error(401, e.getMessage());
        } catch (Exception e) {
            return ApiResponse.error("获取工单列表失败");
        }
    }
}

