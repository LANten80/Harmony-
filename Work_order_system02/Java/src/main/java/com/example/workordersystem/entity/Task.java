package com.example.workordersystem.entity;

import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDateTime;

/**
 * 工单实体类
 */
@Entity
@Table(name = "tasks", indexes = {
    @Index(name = "idx_user_id", columnList = "user_id"),
    @Index(name = "idx_status", columnList = "status"),
    @Index(name = "idx_priority", columnList = "priority"),
    @Index(name = "idx_create_date", columnList = "create_date")
})
@Data
@NoArgsConstructor
@AllArgsConstructor
public class Task {

    @Id
    @Column(name = "id", length = 64)
    private String id;

    @Column(name = "task_name", length = 200, nullable = false)
    private String taskName;

    @Column(name = "description", columnDefinition = "TEXT")
    private String description;

    @Column(name = "progress_value", nullable = false)
    private Integer progressValue = 0;

    @Column(name = "status", length = 20, nullable = false)
    private String status = "pending"; // pending/in_progress/completed/cancelled

    @Column(name = "priority", length = 20, nullable = false)
    private String priority = "medium"; // low/medium/high/urgent

    @Column(name = "create_date", nullable = false)
    private LocalDateTime createDate;

    @Column(name = "update_date", nullable = false)
    private LocalDateTime updateDate;

    @Column(name = "due_date")
    private LocalDateTime dueDate;

    @Column(name = "assignee", length = 64)
    private String assignee;

    @Column(name = "category", length = 50)
    private String category;

    @Column(name = "tags", length = 500)
    private String tags; // JSON格式存储

    @Column(name = "user_id", length = 64, nullable = false)
    private String userId;

    @Column(name = "create_time", nullable = false, updatable = false)
    private LocalDateTime createTime;

    @Column(name = "update_time", nullable = false)
    private LocalDateTime updateTime;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "user_id", insertable = false, updatable = false)
    private User user;

    @PrePersist
    protected void onCreate() {
        LocalDateTime now = LocalDateTime.now();
        if (createTime == null) {
            createTime = now;
        }
        if (updateTime == null) {
            updateTime = now;
        }
        if (createDate == null) {
            createDate = now;
        }
        if (updateDate == null) {
            updateDate = now;
        }
    }

    @PreUpdate
    protected void onUpdate() {
        updateTime = LocalDateTime.now();
        updateDate = LocalDateTime.now();
    }
}

