package com.example.workordersystem.util;

import java.util.UUID;

/**
 * ID生成工具类
 */
public class IdGenerator {

    /**
     * 生成用户ID
     */
    public static String generateUserId() {
        return "user_" + System.currentTimeMillis() + "_" + UUID.randomUUID().toString().substring(0, 8);
    }

    /**
     * 生成工单ID
     */
    public static String generateTaskId() {
        return "task_" + System.currentTimeMillis() + "_" + UUID.randomUUID().toString().substring(0, 8);
    }
}

