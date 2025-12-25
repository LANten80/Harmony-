# MySQL数据库设计文档

## 数据库概述

数据库名称：`work_order_system`

字符集：`utf8mb4`
排序规则：`utf8mb4_unicode_ci`

## 表结构设计

### 1. 用户表 (users)

| 字段名 | 类型 | 长度 | 是否为空 | 主键 | 说明 |
|--------|------|------|----------|------|------|
| id | VARCHAR | 64 | NOT NULL | 是 | 用户ID（主键） |
| username | VARCHAR | 50 | NOT NULL | 否 | 用户名（唯一） |
| phone | VARCHAR | 11 | NOT NULL | 否 | 手机号（唯一） |
| password | VARCHAR | 255 | NOT NULL | 否 | 加密后的密码 |
| register_time | DATETIME | - | NOT NULL | 否 | 注册时间 |
| last_login_time | DATETIME | - | NULL | 否 | 最后登录时间 |
| create_time | DATETIME | - | NOT NULL | 否 | 创建时间 |
| update_time | DATETIME | - | NOT NULL | 否 | 更新时间 |
| status | TINYINT | 1 | NOT NULL | 否 | 状态（0:禁用 1:启用） |

**索引：**
- PRIMARY KEY (`id`)
- UNIQUE KEY `uk_username` (`username`)
- UNIQUE KEY `uk_phone` (`phone`)
- KEY `idx_status` (`status`)

### 2. 工单表 (tasks)

| 字段名 | 类型 | 长度 | 是否为空 | 主键 | 说明 |
|--------|------|------|----------|------|------|
| id | VARCHAR | 64 | NOT NULL | 是 | 工单ID（主键） |
| task_name | VARCHAR | 200 | NOT NULL | 否 | 工单名称 |
| description | TEXT | - | NULL | 否 | 工单描述 |
| progress_value | INT | - | NOT NULL | 否 | 进度值（0-100） |
| status | VARCHAR | 20 | NOT NULL | 否 | 状态（pending/in_progress/completed/cancelled） |
| priority | VARCHAR | 20 | NOT NULL | 否 | 优先级（low/medium/high/urgent） |
| create_date | DATETIME | - | NOT NULL | 否 | 创建日期 |
| update_date | DATETIME | - | NOT NULL | 否 | 更新日期 |
| due_date | DATETIME | - | NULL | 否 | 截止日期 |
| assignee | VARCHAR | 64 | NULL | 否 | 负责人（用户ID） |
| category | VARCHAR | 50 | NULL | 否 | 分类 |
| tags | VARCHAR | 500 | NULL | 否 | 标签（JSON格式存储） |
| user_id | VARCHAR | 64 | NOT NULL | 否 | 所属用户ID（外键） |
| create_time | DATETIME | - | NOT NULL | 否 | 创建时间 |
| update_time | DATETIME | - | NOT NULL | 否 | 更新时间 |

**索引：**
- PRIMARY KEY (`id`)
- KEY `idx_user_id` (`user_id`)
- KEY `idx_status` (`status`)
- KEY `idx_priority` (`priority`)
- KEY `idx_create_date` (`create_date`)
- FOREIGN KEY `fk_task_user` (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE

### 3. 用户Token表 (user_tokens) - 可选

用于存储JWT Token或Session Token

| 字段名 | 类型 | 长度 | 是否为空 | 主键 | 说明 |
|--------|------|------|----------|------|------|
| id | BIGINT | - | NOT NULL | 是 | 自增ID |
| user_id | VARCHAR | 64 | NOT NULL | 否 | 用户ID |
| token | VARCHAR | 500 | NOT NULL | 否 | Token值 |
| expire_time | DATETIME | - | NOT NULL | 否 | 过期时间 |
| create_time | DATETIME | - | NOT NULL | 否 | 创建时间 |

**索引：**
- PRIMARY KEY (`id`)
- KEY `idx_user_id` (`user_id`)
- KEY `idx_token` (`token`)
- KEY `idx_expire_time` (`expire_time`)
- FOREIGN KEY `fk_token_user` (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE

## 数据库初始化SQL脚本

详见 `database/init.sql` 文件

## 字段说明

### 状态字段 (status)

**用户表状态：**
- 0: 禁用
- 1: 启用

**工单表状态：**
- pending: 待处理
- in_progress: 进行中
- completed: 已完成
- cancelled: 已取消

### 优先级字段 (priority)

- low: 低
- medium: 中
- high: 高
- urgent: 紧急

## 数据关系

```
users (1) ----< (N) tasks
  |                    |
  |                    |
  └----< (N) user_tokens
```

- 一个用户可以有多个工单
- 一个用户可以有多个Token（用于多设备登录）
- 删除用户时，相关的工单和Token会被级联删除

## 性能优化建议

1. **索引优化**
   - 在经常查询的字段上建立索引（如user_id, status, create_date）
   - 避免在频繁更新的字段上建立过多索引

2. **分页查询**
   - 使用LIMIT和OFFSET进行分页
   - 对于大数据量，考虑使用游标分页

3. **数据归档**
   - 定期归档已完成或已取消的旧工单
   - 考虑使用分区表（按时间分区）

4. **缓存策略**
   - 用户信息可以缓存到Redis
   - Token验证结果可以缓存

## 数据备份建议

1. 定期全量备份（每天）
2. 实时增量备份（binlog）
3. 备份保留周期：至少30天

