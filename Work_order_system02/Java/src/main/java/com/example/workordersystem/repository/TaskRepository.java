package com.example.workordersystem.repository;

import com.example.workordersystem.entity.Task;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.time.LocalDateTime;
import java.util.List;

/**
 * 工单数据访问层
 */
@Repository
public interface TaskRepository extends JpaRepository<Task, String> {

    /**
     * 根据用户ID查找工单列表（分页）
     */
    Page<Task> findByUserId(String userId, Pageable pageable);

    /**
     * 根据用户ID和状态查找工单列表
     */
    List<Task> findByUserIdAndStatus(String userId, String status);

    /**
     * 根据用户ID和优先级查找工单列表
     */
    List<Task> findByUserIdAndPriority(String userId, String priority);

    /**
     * 根据用户ID查找指定日期范围内的工单
     */
    @Query("SELECT t FROM Task t WHERE t.userId = :userId AND t.createDate BETWEEN :startDate AND :endDate")
    List<Task> findByUserIdAndDateRange(
            @Param("userId") String userId,
            @Param("startDate") LocalDateTime startDate,
            @Param("endDate") LocalDateTime endDate
    );

    /**
     * 统计用户工单数量
     */
    long countByUserId(String userId);

    /**
     * 统计用户指定状态的工单数量
     */
    long countByUserIdAndStatus(String userId, String status);
}

