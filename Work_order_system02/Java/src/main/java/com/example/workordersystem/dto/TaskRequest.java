package com.example.workordersystem.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.Max;
import lombok.Data;

import java.time.LocalDateTime;
import java.util.List;

/**
 * 工单请求DTO
 */
@Data
public class TaskRequest {
    @NotBlank(message = "工单名称不能为空")
    private String taskName;

    private String description;

    @NotNull(message = "进度值不能为空")
    @Min(value = 0, message = "进度值不能小于0")
    @Max(value = 100, message = "进度值不能大于100")
    private Integer progressValue = 0;

    private String status = "pending"; // pending/in_progress/completed/cancelled

    private String priority = "medium"; // low/medium/high/urgent

    private LocalDateTime dueDate;

    private String assignee;

    private String category;

    private List<String> tags;
}

