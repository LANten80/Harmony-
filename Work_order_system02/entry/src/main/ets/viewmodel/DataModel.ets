/**
 * 数据操作模型
 * 单例模式管理工单数据
 */

import { TaskItemModel, TaskStatus, TaskPriority } from './TaskItemModel';
import { StatisticsModel } from './StatisticsModel';
import { StorageUtil } from '../common/utils/StorageUtil';
import { TaskData } from '../common/types/TaskData';
import { common } from '@kit.AbilityKit';

/**
 * 数据模型单例类
 */
export class DataModel {
  private static instance: DataModel;
  private targetData: TaskItemModel[] = [];
  private context: common.UIAbilityContext | null = null;
  
  // 标记是否已经从存储加载过数据（避免重复加载）
  private dataLoadedFromStorage: boolean = false;

  // 数据变更监听器
  private changeListeners: Array<() => void> = [];

  /**
   * 私有构造函数，实现单例模式
   */
  private constructor() {
    // 不在这里初始化数据，等待 loadData 调用
  }

  /**
   * 设置应用上下文
   */
  setContext(context: common.UIAbilityContext): void {
    this.context = context;
  }

  /**
   * 获取单例实例
   */
  static getInstance(): DataModel {
    if (!DataModel.instance) {
      DataModel.instance = new DataModel();
    }
    return DataModel.instance;
  }

  /**
   * 初始化空数据（不再使用默认示例数据）
   */
  private initEmptyData(): void {
    this.targetData = [];
  }

  /**
   * 从存储加载数据（只在首次调用时加载，避免重复加载）
   */
  async loadDataFromStorage(): Promise<void> {
    // 如果已经加载过，直接返回，避免重复加载
    if (this.dataLoadedFromStorage) {
      console.info('DataModel.loadDataFromStorage: 数据已加载过，跳过重复加载');
      return;
    }
    
    console.info('DataModel.loadDataFromStorage: 开始从存储加载数据');
    
    if (!this.context) {
      console.warn('DataModel.loadDataFromStorage: 上下文不存在，使用空数据');
      this.initEmptyData();
      this.dataLoadedFromStorage = true;
      return;
    }
    
    try {
      const savedData = await StorageUtil.loadTaskList(this.context);
      console.info('DataModel.loadDataFromStorage: 从存储加载的数据数量:', savedData ? savedData.length : 0);
      
      if (savedData && Array.isArray(savedData) && savedData.length > 0) {
        // 校验数据有效性并转换
        const validTasks: TaskItemModel[] = [];
        
        savedData.forEach((item: TaskData, index: number) => {
          try {
            // 校验必要字段
            if (!item || !item.id || !item.taskName) {
              console.warn(`DataModel.loadDataFromStorage: 跳过无效数据项 ${index}:`, item);
              return;
            }

            // 确保 progressValue 是数字类型
            let progressValue: number = 0;
            const progress = item.progressValue;
            if (typeof progress === 'number') {
              progressValue = progress;
            } else if (typeof progress === 'string') {
              const parsed = parseInt(progress, 10);
              progressValue = isNaN(parsed) ? 0 : parsed;
            } else {
              progressValue = 0;
            }
            
            const task = new TaskItemModel(item.taskName || '', item.description || '', progressValue);
            task.id = item.id || task.id;
            task.status = item.status as TaskStatus || task.status;
            // 将字符串转换为 TaskPriority 枚举
            task.priority = (item.priority as TaskPriority) || task.priority;
            task.createDate = item.createDate || task.createDate;
            task.updateDate = item.updateDate || task.updateDate;
            task.dueDate = item.dueDate || '';
            task.assignee = item.assignee || '';
            task.category = item.category || '';
            task.tags = item.tags || [];
            // 确保进度值正确设置
            if (task.progressValue === undefined || task.progressValue === null) {
              task.progressValue = 0;
            }
            
            validTasks.push(task);
          } catch (err) {
            console.error(`DataModel.loadDataFromStorage: 转换数据项 ${index} 失败:`, JSON.stringify(err));
          }
        });

        if (validTasks.length > 0) {
          this.targetData = validTasks;
          console.info('DataModel.loadDataFromStorage: 成功加载', validTasks.length, '个工单');
          this.dataLoadedFromStorage = true;
        } else {
          // 没有有效的工单数据，使用空数组
          console.info('DataModel.loadDataFromStorage: 没有有效的工单数据，使用空数组');
          this.initEmptyData();
          // 保存空数组到存储
          await this.saveDataToStorage();
          this.dataLoadedFromStorage = true;
        }
      } else {
        // 如果没有保存的数据，使用空数组
        console.info('DataModel.loadDataFromStorage: 存储中没有数据，使用空数组');
        this.initEmptyData();
        // 保存空数组到存储
        await this.saveDataToStorage();
        this.dataLoadedFromStorage = true;
      }
    } catch (err) {
      console.error('DataModel.loadDataFromStorage: 加载数据失败:', JSON.stringify(err));
      // 加载失败时使用空数组
      this.initEmptyData();
      this.dataLoadedFromStorage = true;
    }
    
    console.info('DataModel.loadDataFromStorage: 数据加载完成，当前工单数:', this.targetData.length);
  }
  
  /**
   * 强制从存储重新加载数据（用于刷新场景）
   */
  async reloadDataFromStorage(): Promise<void> {
    console.info('DataModel.reloadDataFromStorage: 强制重新加载数据');
    this.dataLoadedFromStorage = false;
    await this.loadDataFromStorage();
  }

  /**
   * 保存数据到存储（物理保存，确保删除的数据不会重新出现）
   */
  private async saveDataToStorage(): Promise<void> {
    if (!this.context) {
      console.warn('DataModel.saveDataToStorage: 上下文不存在，无法保存');
      return;
    }

    try {
      console.info('DataModel.saveDataToStorage: 开始保存数据，当前工单数:', this.targetData.length);
      
      // 将工单对象转换为可序列化的格式
      const dataToSave: TaskData[] = this.targetData.map(task => {
        const taskData: TaskData = {
          id: task.id,
          taskName: task.taskName,
          description: task.description,
          progressValue: task.progressValue,
          status: task.status as string,
          priority: task.priority as string,
          createDate: task.createDate,
          updateDate: task.updateDate,
          dueDate: task.dueDate,
          assignee: task.assignee,
          category: task.category,
          tags: task.tags
        };
        return taskData;
      });

      console.info('DataModel.saveDataToStorage: 准备保存的数据ID列表:', dataToSave.map(item => item.id));
      
      // 执行物理保存（确保数据立即写入磁盘）
      const saveResult = await StorageUtil.saveTaskList(this.context, dataToSave);
      
      if (saveResult) {
        console.info('DataModel.saveDataToStorage: 数据保存成功，保存了', dataToSave.length, '个工单');
        console.info('DataModel.saveDataToStorage: 保存的工单ID列表:', dataToSave.map(item => item.id));
        
        // 验证保存结果：重新加载数据确认
        const verifyData = await StorageUtil.loadTaskList(this.context);
        console.info('DataModel.saveDataToStorage: 验证保存结果，存储中的工单数:', verifyData.length);
        console.info('DataModel.saveDataToStorage: 存储中的数据ID列表:', verifyData.map(item => item.id));
        
        if (verifyData.length !== dataToSave.length) {
          console.error('DataModel.saveDataToStorage: 警告！保存的数据数量不匹配，期望:', dataToSave.length, '实际:', verifyData.length);
          // 如果数量不匹配，尝试再次保存
          const retryResult = await StorageUtil.saveTaskList(this.context, dataToSave);
          if (!retryResult) {
            throw new Error('重试保存数据到存储失败');
          }
        } else {
          console.info('DataModel.saveDataToStorage: 验证通过，数据已正确保存');
        }
      } else {
        console.error('DataModel.saveDataToStorage: 数据保存失败');
        throw new Error('保存数据到存储失败');
      }
    } catch (err) {
      console.error('DataModel.saveDataToStorage: 保存数据异常:', JSON.stringify(err));
      // 确保抛出Error对象，符合ArkTS规范
      if (err instanceof Error) {
        throw err;
      } else {
        throw new Error(`保存数据到存储失败: ${JSON.stringify(err)}`);
      }
    }
  }

  /**
   * 获取所有工单数据
   */
  getData(): TaskItemModel[] {
    console.info('DataModel.getData: 获取数据，当前工单数:', this.targetData.length);
    // 返回数组的深拷贝，确保每次调用都返回新数组
    const result = this.targetData.map(item => {
      const newItem = new TaskItemModel(item.taskName, item.description, item.progressValue, item.priority);
      newItem.id = item.id;
      newItem.status = item.status;
      newItem.createDate = item.createDate;
      newItem.updateDate = item.updateDate;
      newItem.dueDate = item.dueDate;
      newItem.assignee = item.assignee;
      newItem.category = item.category;
      newItem.tags = [...item.tags];
      return newItem;
    });
    console.info('DataModel.getData: 返回数据，工单数:', result.length);
    return result;
  }

  /**
   * 添加工单
   */
  addData(taskName: string, description: string = ''): boolean {
    if (!taskName || taskName.trim().length === 0) {
      console.warn('DataModel.addData: 工单名称为空');
      return false;
    }

    console.info('DataModel.addData: 开始添加工单:', taskName, '当前工单数:', this.targetData.length);
    const newTask = new TaskItemModel(taskName.trim(), description);
    this.targetData.push(newTask);
    console.info('DataModel.addData: 工单已添加到内存，当前工单数:', this.targetData.length);
    
    // 先通知变更，再保存
    this.notifyChange();
    console.info('DataModel.addData: 已通知变更监听器');
    
    // 异步保存到存储，不阻塞UI更新
    this.saveDataToStorage().then(() => {
      console.info('DataModel.addData: 工单已保存到存储');
    }).catch(() => {
      console.error('DataModel.addData: 保存到存储失败');
    });
    return true;
  }

  /**
   * 更新工单进度
   */
  updateProgress(taskId: string, progressValue: number): boolean {
    console.info('DataModel.updateProgress: 开始更新进度, taskId:', taskId, 'progressValue:', progressValue);
    
    // 确保进度值在有效范围内
    const validProgress = Math.max(0, Math.min(100, Math.round(progressValue)));
    console.info('DataModel.updateProgress: 验证后的进度值:', validProgress);
    
    const task = this.targetData.find(item => item.id === taskId);
    if (!task) {
      console.error('DataModel.updateProgress: 未找到工单, taskId:', taskId);
      return false;
    }

    console.info('DataModel.updateProgress: 找到工单, 当前进度:', task.progressValue);
    task.updateProgress(validProgress);
    task.updateDate = new Date().toISOString();
    console.info('DataModel.updateProgress: 工单进度已更新, 新进度值:', task.progressValue);
    
    // 先通知变更，再保存
    this.notifyChange();
    console.info('DataModel.updateProgress: 已通知变更监听器');
    
    // 异步保存到存储，不阻塞UI更新
    this.saveDataToStorage().then(() => {
      console.info('DataModel.updateProgress: 进度已保存到存储');
    }).catch(() => {
      console.error('DataModel.updateProgress: 保存到存储失败');
    });
    return true;
  }

  /**
   * 删除单个工单（物理删除，真正从存储中移除）
   */
  async deleteTask(taskId: string): Promise<boolean> {
    console.info('DataModel.deleteTask 开始删除工单:', taskId);
    
    const index = this.targetData.findIndex(item => item.id === taskId);
    if (index === -1) {
      console.warn('DataModel.deleteTask: 工单ID不存在:', taskId);
      return false;
    }

    // 从内存中删除
    const deletedTask = this.targetData[index];
    this.targetData.splice(index, 1);
    console.info('DataModel.deleteTask: 从内存删除工单:', deletedTask.taskName);
    
    // 先通知变更
    this.notifyChange();
    
    // 立即同步保存到存储，确保物理删除（等待保存完成）
    try {
      await this.saveDataToStorage();
      console.info('DataModel.deleteTask: 工单已从存储中物理删除，保存成功');
      
      // 验证删除结果
      if (this.context) {
        const verifyData = await StorageUtil.loadTaskList(this.context);
        const stillExists = verifyData.some(item => item.id === taskId);
        if (stillExists) {
          console.error('DataModel.deleteTask: 警告！删除的工单仍在存储中:', taskId);
        } else {
          console.info('DataModel.deleteTask: 验证通过，工单已从存储中移除');
        }
      }
      return true;
    } catch (err) {
      console.error('DataModel.deleteTask: 保存删除结果到存储失败:', JSON.stringify(err));
      // 确保抛出Error对象，符合ArkTS规范
      if (err instanceof Error) {
        throw err;
      } else {
        throw new Error(`删除工单失败: ${JSON.stringify(err)}`);
      }
    }
  }

  /**
   * 批量删除工单（物理删除，真正从存储中移除）
   */
  async deleteTasks(taskIds: string[]): Promise<number> {
    // 校验输入参数
    if (!taskIds || taskIds.length === 0) {
      console.warn('DataModel.deleteTasks: 删除ID列表为空');
      return 0;
    }

    // 校验数据源有效性
    if (!this.targetData || this.targetData.length === 0) {
      console.warn('DataModel.deleteTasks: 数据源为空，无法删除');
      return 0;
    }

    console.info('DataModel.deleteTasks 开始删除:', taskIds, '当前数据长度:', this.targetData.length);
    console.info('DataModel.deleteTasks 删除前数据:', this.targetData.map(item => item.id));
    
    try {
      let deletedCount = 0;
      const idsToDelete = [...taskIds];
      
      // 校验要删除的ID是否存在于数据源中
      const validIds: string[] = [];
      idsToDelete.forEach(id => {
        const exists = this.targetData.some(item => item.id === id);
        if (exists) {
          validIds.push(id);
        } else {
          console.warn(`DataModel.deleteTasks: 工单ID ${id} 不存在于数据源中`);
        }
      });

      if (validIds.length === 0) {
        console.warn('DataModel.deleteTasks: 没有有效的工单ID可删除');
        return 0;
      }

      // 创建新数组，避免直接修改原数组导致响应式更新问题
      const newTargetData: TaskItemModel[] = [];
      
      // 过滤掉要删除的工单（物理删除，不保留数据）
      this.targetData.forEach(item => {
        if (!validIds.includes(item.id)) {
          newTargetData.push(item);
        } else {
          deletedCount++;
          console.info('DataModel.deleteTasks 删除工单:', item.id, item.taskName);
        }
      });
      
      // 校验删除结果
      if (deletedCount === 0) {
        console.warn('DataModel.deleteTasks: 删除操作未删除任何工单');
        return 0;
      }

      // 重新赋值数组，触发响应式更新
      this.targetData = newTargetData;
      console.info('DataModel.deleteTasks 内存删除完成，剩余工单数:', this.targetData.length);
      console.info('DataModel.deleteTasks 删除后数据:', this.targetData.map(item => item.id));
      
      // 删除完成后统一通知一次
      if (deletedCount > 0) {
        // 先通知变更
        this.notifyChange();
        
        // 立即同步保存到存储，确保物理删除（等待保存完成）
        try {
          await this.saveDataToStorage();
          console.info('DataModel.deleteTasks: 工单已从存储中物理删除，保存成功');
          
          // 验证删除结果：重新加载数据确认删除成功
          if (this.context) {
            const verifyData = await StorageUtil.loadTaskList(this.context);
            const remainingIds = verifyData.map(item => item.id);
            const deletedIdsStillExist = validIds.filter(id => remainingIds.includes(id));
            
            if (deletedIdsStillExist.length > 0) {
              console.error('DataModel.deleteTasks: 警告！删除的工单ID仍在存储中:', deletedIdsStillExist);
            } else {
              console.info('DataModel.deleteTasks: 验证通过，删除的工单已从存储中移除');
            }
          }
        } catch (err) {
          console.error('DataModel.deleteTasks: 保存删除结果到存储失败:', JSON.stringify(err));
          // 保存失败时，恢复内存数据（回滚）
          console.warn('DataModel.deleteTasks: 保存失败，尝试恢复内存数据');
          // 注意：这里不恢复，因为用户已经看到删除效果，回滚会造成困惑
          // 可以选择提示用户删除失败，或者重试保存
          // 确保抛出Error对象，符合ArkTS规范
          if (err instanceof Error) {
            throw err;
          } else {
            throw new Error(`批量删除工单失败: ${JSON.stringify(err)}`);
          }
        }
      }
      
      return deletedCount;
    } catch (err) {
      console.error('DataModel.deleteTasks 删除操作异常:', JSON.stringify(err));
      return 0;
    }
  }

  /**
   * 获取统计数据
   */
  getStatistics(): StatisticsModel {
    const total = this.targetData.length;
    const completed = this.targetData.filter(item => item.status === TaskStatus.COMPLETED).length;
    const inProgress = this.targetData.filter(item => item.status === TaskStatus.IN_PROGRESS).length;
    const notStarted = this.targetData.filter(item => item.status === TaskStatus.PENDING).length;
    
    const completionRate = total > 0 ? Math.round((completed / total) * 100) : 0;
    const totalProgress = this.targetData.reduce((sum, item) => sum + item.progressValue, 0);
    const averageProgress = total > 0 ? Math.round(totalProgress / total) : 0;

    return {
      total,
      completed,
      inProgress,
      notStarted,
      completionRate,
      averageProgress
    };
  }

  /**
   * 注册数据变更监听器
   */
  addChangeListener(listener: () => void): void {
    this.changeListeners.push(listener);
  }

  /**
   * 移除数据变更监听器
   */
  removeChangeListener(listener: () => void): void {
    const index = this.changeListeners.indexOf(listener);
    if (index > -1) {
      this.changeListeners.splice(index, 1);
    }
  }

  /**
   * 通知所有监听器数据已变更
   */
  private notifyChange(): void {
    this.changeListeners.forEach(listener => {
      try {
        listener();
      } catch (err) {
        console.error('Error in change listener:', JSON.stringify(err));
      }
    });
  }
}

