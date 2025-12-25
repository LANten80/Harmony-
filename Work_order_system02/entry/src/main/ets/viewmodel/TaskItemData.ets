/**
 * 工单数据接口（用于JSON解析）
 */

export interface TaskItemData {
  id: string;
  taskName: string;
  description: string;
  progressValue: number;
  status: string; // TaskStatus 枚举值
  priority: string; // TaskPriority 枚举值
  createDate: string;
  updateDate: string;
  dueDate?: string;
  assignee?: string;
  category?: string;
  tags?: string[];
}

