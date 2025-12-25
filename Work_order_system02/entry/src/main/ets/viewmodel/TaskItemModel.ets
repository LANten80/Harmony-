/**
 * 工单实体模型
 * 定义工单数据结构和相关枚举
 */

/**
 * 工单状态枚举
 */
export enum TaskStatus {
  PENDING = 'pending',        // 待处理
  IN_PROGRESS = 'in_progress', // 进行中
  COMPLETED = 'completed',    // 已完成
  CANCELLED = 'cancelled'      // 已取消
}

/**
 * 工单优先级枚举
 */
export enum TaskPriority {
  LOW = 'low',           // 低
  MEDIUM = 'medium',     // 中
  HIGH = 'high',         // 高
  URGENT = 'urgent'      // 紧急
}

/**
 * 工单实体类
 */
export class TaskItemModel {
  // 基础信息
  id: string = '';
  taskName: string = '';
  description: string = '';

  // 进度信息
  progressValue: number = 0;
  status: TaskStatus = TaskStatus.PENDING;
  priority: TaskPriority = TaskPriority.MEDIUM;

  // 时间信息
  createDate: string = '';
  updateDate: string = '';
  dueDate: string = '';

  // 关联信息
  assignee: string = '';
  category: string = '';
  tags: string[] = [];

  /**
   * 构造函数
   * @param taskName 工单名称
   * @param description 工单描述
   * @param progressValue 进度值（0-100）
   * @param priority 优先级
   */
  constructor(
    taskName: string,
    description: string = '',
    progressValue: number = 0,
    priority: TaskPriority = TaskPriority.MEDIUM
  ) {
    this.taskName = taskName;
    this.description = description;
    this.progressValue = progressValue;
    this.priority = priority;

    // 生成唯一ID
    this.id = this.generateId();

    // 初始化时间
    const now = new Date().toISOString();
    this.createDate = now;
    this.updateDate = now;

    // 根据进度值自动计算状态
    this.updateStatus();
  }

  /**
   * 生成唯一ID
   */
  private generateId(): string {
    return `task_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`;
  }

  /**
   * 根据进度值更新状态
   */
  updateStatus(): void {
    if (this.progressValue === 0) {
      this.status = TaskStatus.PENDING;
    } else if (this.progressValue === 100) {
      this.status = TaskStatus.COMPLETED;
    } else {
      this.status = TaskStatus.IN_PROGRESS;
    }
  }

  /**
   * 更新进度值
   * @param progressValue 新的进度值（0-100）
   */
  setProgress(progressValue: number): void {
    this.progressValue = Math.max(0, Math.min(100, progressValue));
    this.updateStatus();
    this.updateDate = new Date().toISOString();
  }

  /**
   * 更新进度值（别名方法，与 setProgress 功能相同）
   * @param progressValue 新的进度值（0-100）
   */
  updateProgress(progressValue: number): void {
    this.setProgress(progressValue);
  }

  /**
   * 更新工单信息
   * @param taskName 工单名称
   * @param description 工单描述
   */
  updateInfo(taskName: string, description: string = ''): void {
    this.taskName = taskName;
    this.description = description;
    this.updateDate = new Date().toISOString();
  }
}
