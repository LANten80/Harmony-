-- ============================================
-- 工单系统数据库初始化脚本
-- 数据库名称: work_order_system
-- 字符集: utf8mb4
-- 排序规则: utf8mb4_unicode_ci
-- ============================================

-- 创建数据库
CREATE DATABASE IF NOT EXISTS `work_order_system` 
DEFAULT CHARACTER SET utf8mb4 
DEFAULT COLLATE utf8mb4_unicode_ci;

USE `work_order_system`;

-- ============================================
-- 删除表（按依赖关系顺序：先删除有外键的表）
-- ============================================
DROP TABLE IF EXISTS `user_tokens`;
DROP TABLE IF EXISTS `tasks`;
DROP TABLE IF EXISTS `users`;

-- ============================================
-- 1. 用户表 (users)
-- ============================================
CREATE TABLE `users` (
  `id` VARCHAR(64) NOT NULL COMMENT '用户ID',
  `username` VARCHAR(50) NOT NULL COMMENT '用户名',
  `phone` VARCHAR(11) NOT NULL COMMENT '手机号',
  `password` VARCHAR(255) NOT NULL COMMENT '加密后的密码',
  `register_time` DATETIME NOT NULL COMMENT '注册时间',
  `last_login_time` DATETIME NULL COMMENT '最后登录时间',
  `create_time` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `update_time` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  `status` TINYINT(1) NOT NULL DEFAULT 1 COMMENT '状态（0:禁用 1:启用）',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_username` (`username`),
  UNIQUE KEY `uk_phone` (`phone`),
  KEY `idx_status` (`status`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='用户表';

-- ============================================
-- 2. 工单表 (tasks)
-- ============================================
CREATE TABLE `tasks` (
  `id` VARCHAR(64) NOT NULL COMMENT '工单ID',
  `task_name` VARCHAR(200) NOT NULL COMMENT '工单名称',
  `description` TEXT NULL COMMENT '工单描述',
  `progress_value` INT NOT NULL DEFAULT 0 COMMENT '进度值（0-100）',
  `status` VARCHAR(20) NOT NULL DEFAULT 'pending' COMMENT '状态（pending/in_progress/completed/cancelled）',
  `priority` VARCHAR(20) NOT NULL DEFAULT 'medium' COMMENT '优先级（low/medium/high/urgent）',
  `create_date` DATETIME NOT NULL COMMENT '创建日期',
  `update_date` DATETIME NOT NULL COMMENT '更新日期',
  `due_date` DATETIME NULL COMMENT '截止日期',
  `assignee` VARCHAR(64) NULL COMMENT '负责人（用户ID）',
  `category` VARCHAR(50) NULL COMMENT '分类',
  `tags` VARCHAR(500) NULL COMMENT '标签（JSON格式存储）',
  `user_id` VARCHAR(64) NOT NULL COMMENT '所属用户ID',
  `create_time` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `update_time` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  PRIMARY KEY (`id`),
  KEY `idx_user_id` (`user_id`),
  KEY `idx_status` (`status`),
  KEY `idx_priority` (`priority`),
  KEY `idx_create_date` (`create_date`),
  CONSTRAINT `fk_task_user` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='工单表';

-- ============================================
-- 3. 用户Token表 (user_tokens)
-- ============================================
CREATE TABLE `user_tokens` (
  `id` BIGINT NOT NULL AUTO_INCREMENT COMMENT '自增ID',
  `user_id` VARCHAR(64) NOT NULL COMMENT '用户ID',
  `token` VARCHAR(500) NOT NULL COMMENT 'Token值',
  `expire_time` DATETIME NOT NULL COMMENT '过期时间',
  `create_time` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  PRIMARY KEY (`id`),
  KEY `idx_user_id` (`user_id`),
  KEY `idx_token` (`token`),
  KEY `idx_expire_time` (`expire_time`),
  CONSTRAINT `fk_token_user` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='用户Token表';
