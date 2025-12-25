package com.example.workordersystem.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDateTime;
import java.util.List;

/**
 * 工单响应DTO
 */
@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class TaskResponse {
    private String id;
    private String taskName;
    private String description;
    private Integer progressValue;
    private String status;
    private String priority;
    private LocalDateTime createDate;
    private LocalDateTime updateDate;
    private LocalDateTime dueDate;
    private String assignee;
    private String category;
    private List<String> tags;
    private String userId;
    private LocalDateTime createTime;
    private LocalDateTime updateTime;
}

