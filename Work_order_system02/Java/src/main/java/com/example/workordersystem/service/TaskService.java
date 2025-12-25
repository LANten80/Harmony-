package com.example.workordersystem.service;

import com.example.workordersystem.dto.TaskRequest;
import com.example.workordersystem.dto.TaskResponse;
import com.example.workordersystem.entity.Task;
import com.example.workordersystem.repository.TaskRepository;
import com.example.workordersystem.util.IdGenerator;
import com.fasterxml.jackson.core.type.TypeReference;
import com.fasterxml.jackson.databind.ObjectMapper;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.stream.Collectors;

/**
 * 工单服务类
 */
@Service
@RequiredArgsConstructor
public class TaskService {

    private final TaskRepository taskRepository;
    private final ObjectMapper objectMapper;

    /**
     * 创建工单
     */
    @Transactional
    public TaskResponse createTask(String userId, TaskRequest request) {
        Task task = new Task();
        task.setId(IdGenerator.generateTaskId());
        task.setUserId(userId);
        task.setTaskName(request.getTaskName());
        task.setDescription(request.getDescription());
        task.setProgressValue(request.getProgressValue());
        task.setStatus(request.getStatus());
        task.setPriority(request.getPriority());
        task.setDueDate(request.getDueDate());
        task.setAssignee(request.getAssignee());
        task.setCategory(request.getCategory());
        
        // 将标签列表转换为JSON字符串
        if (request.getTags() != null && !request.getTags().isEmpty()) {
            try {
                task.setTags(objectMapper.writeValueAsString(request.getTags()));
            } catch (Exception e) {
                throw new RuntimeException("标签格式错误");
            }
        }

        // 根据进度值自动设置状态
        updateTaskStatus(task);

        task = taskRepository.save(task);
        return convertToResponse(task);
    }

    /**
     * 更新工单
     */
    @Transactional
    public TaskResponse updateTask(String taskId, String userId, TaskRequest request) {
        if (taskId == null) {
            throw new IllegalArgumentException("工单ID不能为空");
        }
        Task task = taskRepository.findById(taskId)
                .orElseThrow(() -> new RuntimeException("工单不存在"));

        // 验证工单是否属于该用户
        if (!task.getUserId().equals(userId)) {
            throw new RuntimeException("无权访问该工单");
        }

        task.setTaskName(request.getTaskName());
        task.setDescription(request.getDescription());
        task.setProgressValue(request.getProgressValue());
        task.setStatus(request.getStatus());
        task.setPriority(request.getPriority());
        task.setDueDate(request.getDueDate());
        task.setAssignee(request.getAssignee());
        task.setCategory(request.getCategory());

        // 将标签列表转换为JSON字符串
        if (request.getTags() != null && !request.getTags().isEmpty()) {
            try {
                task.setTags(objectMapper.writeValueAsString(request.getTags()));
            } catch (Exception e) {
                throw new RuntimeException("标签格式错误");
            }
        } else {
            task.setTags(null);
        }

        // 根据进度值自动设置状态
        updateTaskStatus(task);

        task = taskRepository.save(task);
        return convertToResponse(task);
    }

    /**
     * 删除工单
     */
    @Transactional
    public void deleteTask(String taskId, String userId) {
        if (taskId == null) {
            throw new IllegalArgumentException("工单ID不能为空");
        }
        Task task = taskRepository.findById(taskId)
                .orElseThrow(() -> new RuntimeException("工单不存在"));

        // 验证工单是否属于该用户
        if (!task.getUserId().equals(userId)) {
            throw new RuntimeException("无权访问该工单");
        }

        taskRepository.delete(task);
    }

    /**
     * 获取工单详情
     */
    public TaskResponse getTaskById(String taskId, String userId) {
        if (taskId == null) {
            throw new IllegalArgumentException("工单ID不能为空");
        }
        Task task = taskRepository.findById(taskId)
                .orElseThrow(() -> new RuntimeException("工单不存在"));

        // 验证工单是否属于该用户
        if (!task.getUserId().equals(userId)) {
            throw new RuntimeException("无权访问该工单");
        }

        return convertToResponse(task);
    }

    /**
     * 获取用户工单列表（分页）
     */
    public Page<TaskResponse> getTaskList(String userId, Pageable pageable) {
        return taskRepository.findByUserId(userId, pageable)
                .map(this::convertToResponse);
    }

    /**
     * 根据状态获取工单列表
     */
    public List<TaskResponse> getTasksByStatus(String userId, String status) {
        return taskRepository.findByUserIdAndStatus(userId, status)
                .stream()
                .map(this::convertToResponse)
                .collect(Collectors.toList());
    }

    /**
     * 根据优先级获取工单列表
     */
    public List<TaskResponse> getTasksByPriority(String userId, String priority) {
        return taskRepository.findByUserIdAndPriority(userId, priority)
                .stream()
                .map(this::convertToResponse)
                .collect(Collectors.toList());
    }

    /**
     * 根据进度值自动更新状态
     */
    private void updateTaskStatus(Task task) {
        if (task.getProgressValue() == 0) {
            task.setStatus("pending");
        } else if (task.getProgressValue() == 100) {
            task.setStatus("completed");
        } else if (!"cancelled".equals(task.getStatus())) {
            task.setStatus("in_progress");
        }
    }

    /**
     * 转换为响应DTO
     */
    private TaskResponse convertToResponse(Task task) {
        List<String> tags = null;
        if (task.getTags() != null && !task.getTags().isEmpty()) {
            try {
                tags = objectMapper.readValue(task.getTags(), new TypeReference<List<String>>() {});
            } catch (Exception e) {
                // 忽略解析错误
            }
        }

        return TaskResponse.builder()
                .id(task.getId())
                .taskName(task.getTaskName())
                .description(task.getDescription())
                .progressValue(task.getProgressValue())
                .status(task.getStatus())
                .priority(task.getPriority())
                .createDate(task.getCreateDate())
                .updateDate(task.getUpdateDate())
                .dueDate(task.getDueDate())
                .assignee(task.getAssignee())
                .category(task.getCategory())
                .tags(tags)
                .userId(task.getUserId())
                .createTime(task.getCreateTime())
                .updateTime(task.getUpdateTime())
                .build();
    }
}

