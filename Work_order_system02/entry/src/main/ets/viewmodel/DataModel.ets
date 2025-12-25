/**
 * 数据操作模型
 * 单例模式管理工单数据
 * 使用后端API进行数据操作
 */

import { TaskItemModel, TaskStatus, TaskPriority } from './TaskItemModel';
import { StatisticsModel } from './StatisticsModel';
import { apiService, TaskData as ApiTaskData } from '../common/api/ApiService';
import { TaskData } from '../common/types/TaskData';
import { common } from '@kit.AbilityKit';
import { logger } from '../common/utils/Logger';
import { UserStorageUtil } from '../common/utils/UserStorageUtil';
import { httpUtil } from '../common/utils/HttpUtil';

/**
 * 数据模型单例类
 */
export class DataModel {
  private static instance: DataModel;
  private targetData: TaskItemModel[] = [];
  private context: common.UIAbilityContext | null = null;
  
  // 标记是否已经从后端加载过数据（避免重复加载）
  private dataLoadedFromApi: boolean = false;
  
  // 是否正在加载数据（防止并发请求）
  private isLoading: boolean = false;

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
   * 初始化空数据
   */
  private initEmptyData(): void {
    this.targetData = [];
  }

  /**
   * 清除数据状态（退出登录时调用）
   */
  clearData(): void {
    const beforeCount = this.targetData.length;
    logger.error('⚠️⚠️⚠️ DataModel.clearData: 开始清除数据状态，当前工单数: ' + String(beforeCount));
    logger.error('⚠️⚠️⚠️ DataModel.clearData: 清除前的数据ID列表: ' + JSON.stringify(this.targetData.map(item => item.id)));
    this.targetData = [];
    this.dataLoadedFromApi = false;
    this.isLoading = false;
    logger.error('⚠️⚠️⚠️ DataModel.clearData: 数据状态已清除，dataLoadedFromApi=false, isLoading=false');
    logger.error('⚠️⚠️⚠️ DataModel.clearData: 清除后的工单数: ' + String(this.targetData.length));
  }

  /**
   * 将API返回的TaskData转换为TaskItemModel
   */
  private convertApiTaskToModel(apiTask: ApiTaskData): TaskItemModel | null {
    try {
      if (!apiTask) {
        logger.warn('DataModel.convertApiTaskToModel: apiTask为空');
        return null;
      }
      
      if (!apiTask.taskName) {
        logger.warn('DataModel.convertApiTaskToModel: taskName为空', JSON.stringify(apiTask));
        return null;
      }

      const progressValue = apiTask.progressValue !== undefined ? apiTask.progressValue : 0;
      const priority = apiTask.priority ? (apiTask.priority as TaskPriority) : TaskPriority.MEDIUM;
      
      const task = new TaskItemModel(
        apiTask.taskName,
        apiTask.description || '',
        progressValue,
        priority
      );
      
      if (apiTask.id) {
        task.id = apiTask.id;
      }
      
      if (apiTask.status) {
        task.status = apiTask.status as TaskStatus;
      }
      
      if (apiTask.createDate) {
        task.createDate = apiTask.createDate;
      }
      
      if (apiTask.updateDate) {
        task.updateDate = apiTask.updateDate;
      }
      
      task.dueDate = apiTask.dueDate || '';
      task.assignee = apiTask.assignee || '';
      task.category = apiTask.category || '';
      task.tags = apiTask.tags || [];
      
      logger.info('DataModel.convertApiTaskToModel: 转换成功, taskId: ' + task.id + ', taskName: ' + task.taskName);
      return task;
    } catch (err) {
      logger.error('DataModel.convertApiTaskToModel: 转换失败', JSON.stringify(err));
      return null;
    }
  }

  /**
   * 将TaskItemModel转换为API请求的TaskData
   */
  private convertModelToApiTask(task: TaskItemModel): ApiTaskData {
    return {
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
  }

  /**
   * 从后端API加载数据（只在首次调用时加载，避免重复加载）
   */
  async loadDataFromStorage(): Promise<void> {
    logger.error('🔵🔵🔵 DataModel.loadDataFromStorage: 开始加载数据');
    logger.error('🔵🔵🔵 DataModel.loadDataFromStorage: dataLoadedFromApi=' + String(this.dataLoadedFromApi));
    logger.error('🔵🔵🔵 DataModel.loadDataFromStorage: isLoading=' + String(this.isLoading));
    logger.error('🔵🔵🔵 DataModel.loadDataFromStorage: 当前内存中的工单数=' + String(this.targetData.length));
    
    // 如果已经加载过，直接返回，避免重复加载
    if (this.dataLoadedFromApi) {
      logger.error('⚠️⚠️⚠️ DataModel.loadDataFromStorage: 数据已加载过，跳过重复加载！当前工单数: ' + String(this.targetData.length));
      logger.error('⚠️⚠️⚠️ DataModel.loadDataFromStorage: 如果数据为空，这可能是问题所在！');
      return;
    }
    
    // 如果正在加载，等待完成
    if (this.isLoading) {
      logger.info('DataModel.loadDataFromStorage: 正在加载中，跳过重复请求');
      return;
    }
    
    this.isLoading = true;
    logger.error('🔵🔵🔵 DataModel.loadDataFromStorage: 开始从后端API加载数据');
    
    // 确保token已设置（从session恢复）
    if (this.context) {
      try {
        const session = await UserStorageUtil.loadSession(this.context);
        if (session && session.token) {
          httpUtil.setAuthToken(session.token);
          logger.error('🔵🔵🔵 DataModel.loadDataFromStorage: 已从session恢复token: ' + session.token.substring(0, 20) + '...');
          logger.error('🔵🔵🔵 DataModel.loadDataFromStorage: session.currentUserId=' + (session.currentUserId || '空'));
        } else {
          logger.error('❌❌❌ DataModel.loadDataFromStorage: session中没有token，可能未登录！');
          logger.error('❌❌❌ DataModel.loadDataFromStorage: session内容=' + JSON.stringify(session));
        }
      } catch (err) {
        logger.error('❌❌❌ DataModel.loadDataFromStorage: 恢复token失败: ' + JSON.stringify(err));
      }
    } else {
      logger.error('❌❌❌ DataModel.loadDataFromStorage: context为空，无法恢复token！');
    }
    
    try {
      logger.error('🔵🔵🔵 DataModel.loadDataFromStorage: 准备调用 apiService.getTaskList()');
      const response = await apiService.getTaskList();
      logger.error('🔵🔵🔵 DataModel.loadDataFromStorage: API响应code=' + String(response.code));
      logger.error('🔵🔵🔵 DataModel.loadDataFromStorage: API响应data=' + JSON.stringify(response.data).substring(0, 200) + '...');
      
      if (response.code >= 200 && response.code < 300 && response.data) {
        // 处理后端可能返回的嵌套响应格式：{code: 200, message: "...", data: {list: [...]}}
        // 使用JSON序列化/反序列化来安全地处理类型转换
        const responseDataStr = JSON.stringify(response.data);
        const responseDataParsed = JSON.parse(responseDataStr) as Record<string, string | number | boolean | null | undefined | ApiTaskData[] | Record<string, ApiTaskData[]>>;
        
        // 检查是否是嵌套格式（有code和message属性）
        const hasCode = responseDataParsed['code'] !== undefined;
        const hasMessage = responseDataParsed['message'] !== undefined;
        const hasData = responseDataParsed['data'] !== undefined;
        
        let taskList: ApiTaskData[] = [];
        
        if (hasCode && hasMessage && hasData) {
          // 嵌套格式：从 data 字段中提取列表数据
          const nestedData = responseDataParsed['data'];
          if (nestedData && typeof nestedData === 'object') {
            const nestedDataStr = JSON.stringify(nestedData);
            const nestedDataParsed = JSON.parse(nestedDataStr) as Record<string, ApiTaskData[]>;
            // 兼容不同的后端响应格式：list 或 data
            taskList = (nestedDataParsed['list'] || nestedDataParsed['data'] || []) as ApiTaskData[];
            logger.info('DataModel.loadDataFromStorage: 检测到嵌套格式，从data字段提取列表数据');
          }
        } else {
          // 非嵌套格式：直接使用response.data
          // 兼容不同的后端响应格式：list 或 data
          taskList = (responseDataParsed['list'] || responseDataParsed['data'] || []) as ApiTaskData[];
          logger.info('DataModel.loadDataFromStorage: 使用非嵌套格式的响应数据');
        }
        
        logger.info('DataModel.loadDataFromStorage: 从后端加载的数据数量:', String(taskList.length));
        
        if (taskList.length > 0) {
          const validTasks: TaskItemModel[] = [];
          
          taskList.forEach((item: ApiTaskData, index: number) => {
            const task = this.convertApiTaskToModel(item);
            if (task) {
              validTasks.push(task);
            } else {
              logger.warn(`DataModel.loadDataFromStorage: 跳过无效数据项 ${index}`);
            }
          });

          if (validTasks.length > 0) {
            this.targetData = validTasks;
            logger.error('✅✅✅ DataModel.loadDataFromStorage: 成功加载 ' + String(validTasks.length) + ' 个工单');
            logger.error('✅✅✅ DataModel.loadDataFromStorage: 加载的工单ID列表: ' + JSON.stringify(validTasks.map(item => item.id)));
            this.dataLoadedFromApi = true;
          } else {
            logger.error('⚠️⚠️⚠️ DataModel.loadDataFromStorage: 没有有效的工单数据，使用空数组！');
            logger.error('⚠️⚠️⚠️ DataModel.loadDataFromStorage: taskList.length=' + String(taskList.length) + ', validTasks.length=0');
            this.initEmptyData();
            this.dataLoadedFromApi = true;
          }
        } else {
          logger.error('⚠️⚠️⚠️ DataModel.loadDataFromStorage: 后端没有数据，使用空数组！');
          logger.error('⚠️⚠️⚠️ DataModel.loadDataFromStorage: taskList.length=0');
          this.initEmptyData();
          this.dataLoadedFromApi = true;
        }
      } else {
        logger.error('❌❌❌ DataModel.loadDataFromStorage: 获取数据失败，响应码: ' + String(response.code));
        logger.error('❌❌❌ DataModel.loadDataFromStorage: 响应数据: ' + JSON.stringify(response.data));
        this.initEmptyData();
        this.dataLoadedFromApi = true;
      }
    } catch (err) {
      logger.error('❌❌❌ DataModel.loadDataFromStorage: 加载数据失败: ' + JSON.stringify(err));
      logger.error('❌❌❌ DataModel.loadDataFromStorage: 错误类型: ' + (err instanceof Error ? err.constructor.name : typeof err));
      if (err instanceof Error) {
        logger.error('❌❌❌ DataModel.loadDataFromStorage: 错误消息: ' + err.message);
        if (err.stack) {
          logger.error('❌❌❌ DataModel.loadDataFromStorage: 错误堆栈: ' + err.stack);
        }
      }
      // 加载失败时使用空数组
      this.initEmptyData();
      this.dataLoadedFromApi = true;
    } finally {
      this.isLoading = false;
    }
    
    logger.error('🔵🔵🔵 DataModel.loadDataFromStorage: 数据加载完成，当前工单数: ' + String(this.targetData.length));
    logger.error('🔵🔵🔵 DataModel.loadDataFromStorage: dataLoadedFromApi=' + String(this.dataLoadedFromApi));
    logger.error('🔵🔵🔵 DataModel.loadDataFromStorage: 最终工单ID列表: ' + JSON.stringify(this.targetData.map(item => item.id)));
  }
  
  /**
   * 强制从后端API重新加载数据（用于刷新场景）
   */
  async reloadDataFromStorage(): Promise<void> {
    logger.info('DataModel.reloadDataFromStorage: 强制重新加载数据');
    this.dataLoadedFromApi = false;
    this.isLoading = false;
    await this.loadDataFromStorage();
  }

  // 注意：已移除saveDataToStorage方法，所有数据操作都通过后端API完成

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
   * 添加工单（通过后端API）
   */
  async addData(taskName: string, description: string = ''): Promise<boolean> {
    if (!taskName || taskName.trim().length === 0) {
      logger.warn('DataModel.addData: 工单名称为空');
      return false;
    }

    logger.info('DataModel.addData: 开始添加工单: ' + taskName);
    
    // 确保token已设置（从session恢复）
    let tokenRestored = false;
    if (this.context) {
      try {
        const session = await UserStorageUtil.loadSession(this.context);
        if (session && session.token) {
          httpUtil.setAuthToken(session.token);
          logger.info('DataModel.addData: 已从session恢复token: ' + session.token.substring(0, 20) + '...');
          tokenRestored = true;
        } else {
          logger.warn('DataModel.addData: session中没有token，可能未登录');
          logger.warn('DataModel.addData: session内容: ' + JSON.stringify(session));
        }
      } catch (err) {
        logger.error('DataModel.addData: 恢复token失败: ' + JSON.stringify(err));
      }
    } else {
      logger.error('DataModel.addData: context为空，无法恢复token');
    }
    
    if (!tokenRestored) {
      logger.error('DataModel.addData: ⚠️ 警告：token未恢复，请求可能会失败！');
    }
    
    try {
      const apiTaskData: ApiTaskData = {
        taskName: taskName.trim(),
        description: description || '',
        progressValue: 0,
        status: TaskStatus.PENDING as string,
        priority: TaskPriority.MEDIUM as string
      };
      
      logger.info('DataModel.addData: 准备发送API请求，数据: ' + JSON.stringify(apiTaskData));
      logger.info('DataModel.addData: 调用 apiService.createTask...');
      
      const response = await apiService.createTask(apiTaskData);
      
      logger.info('DataModel.addData: ✅ API请求已完成，响应code: ' + String(response.code));
      logger.info('DataModel.addData: API响应数据: ' + JSON.stringify(response.data));
      
      // 处理后端可能返回的嵌套响应格式：{code: 200, message: "创建成功", data: {...}}
      if (response.code >= 200 && response.code < 300 && response.data) {
        // 使用JSON序列化/反序列化来安全地处理类型转换（ArkTS不允许unknown和any）
        const responseDataStr = JSON.stringify(response.data);
        const responseDataParsed = JSON.parse(responseDataStr) as Record<string, string | number | boolean | null | undefined | Record<string, string | number | boolean | null | undefined>>;
        
        // 检查是否是嵌套格式（有code和message属性）
        // ArkTS不支持in操作符，使用检查undefined的方式来判断属性是否存在
        const hasCode = responseDataParsed['code'] !== undefined;
        const hasMessage = responseDataParsed['message'] !== undefined;
        const hasData = responseDataParsed['data'] !== undefined;
        
        let actualTaskData: ApiTaskData | null = null;
        
        if (hasCode && hasMessage && hasData) {
          // 嵌套格式：从 data 字段中提取工单数据
          const nestedData = responseDataParsed['data'];
          if (nestedData && typeof nestedData === 'object') {
            const nestedDataStr = JSON.stringify(nestedData);
            actualTaskData = JSON.parse(nestedDataStr) as ApiTaskData;
            logger.info('DataModel.addData: 检测到嵌套格式，从data字段提取工单数据');
          } else {
            logger.error('DataModel.addData: 嵌套格式的data字段不是对象: ' + JSON.stringify(nestedData));
            return false;
          }
        } else {
          // 非嵌套格式：直接使用response.data
          actualTaskData = response.data as ApiTaskData;
          logger.info('DataModel.addData: 使用非嵌套格式的响应数据');
        }
        
        if (actualTaskData) {
          const newTask = this.convertApiTaskToModel(actualTaskData);
          if (newTask) {
            this.targetData.push(newTask);
            logger.info('DataModel.addData: 工单已添加到内存，当前工单数: ' + String(this.targetData.length));
            
            // 通知变更
            this.notifyChange();
            logger.info('DataModel.addData: 工单创建成功');
            return true;
          } else {
            logger.error('DataModel.addData: 转换工单数据失败，actualTaskData: ' + JSON.stringify(actualTaskData));
            return false;
          }
        } else {
          logger.error('DataModel.addData: 无法提取工单数据');
          return false;
        }
      } else {
        logger.error('DataModel.addData: 创建工单失败，响应码: ' + String(response.code) + ', message: ' + (response.message || ''));
        return false;
      }
    } catch (err) {
      logger.error('DataModel.addData: ❌ 创建工单异常！');
      logger.error('DataModel.addData: 异常类型: ' + (err instanceof Error ? err.constructor.name : typeof err));
      logger.error('DataModel.addData: 异常内容: ' + JSON.stringify(err));
      if (err instanceof Error) {
        logger.error('DataModel.addData: 错误消息: ' + err.message);
        logger.error('DataModel.addData: 错误堆栈: ' + (err.stack || '无堆栈信息'));
      }
      return false;
    }
  }

  /**
   * 更新工单进度（通过后端API）
   */
  async updateProgress(taskId: string, progressValue: number): Promise<boolean> {
    logger.info('DataModel.updateProgress: 开始更新进度, taskId: ' + taskId + ', progressValue: ' + String(progressValue));
    
    // 确保进度值在有效范围内
    const validProgress = Math.max(0, Math.min(100, Math.round(progressValue)));
    logger.info('DataModel.updateProgress: 验证后的进度值: ' + String(validProgress));
    
    const task = this.targetData.find(item => item.id === taskId);
    if (!task) {
      logger.error('DataModel.updateProgress: 未找到工单, taskId:', taskId);
      return false;
    }

    logger.info('DataModel.updateProgress: 找到工单, 当前进度: ' + String(task.progressValue));
    
    try {
      // 更新本地数据
      task.updateProgress(validProgress);
      task.updateDate = new Date().toISOString();
      
      // 同步到后端
      const apiTaskData = this.convertModelToApiTask(task);
      const response = await apiService.updateTask(taskId, apiTaskData);
      
      if (response.code >= 200 && response.code < 300) {
        logger.info('DataModel.updateProgress: 工单进度已更新, 新进度值: ' + String(task.progressValue));
        
        // 通知变更
        this.notifyChange();
        logger.info('DataModel.updateProgress: 进度更新成功');
        return true;
      } else {
        logger.error('DataModel.updateProgress: 更新失败，响应码:', String(response.code));
        // 回滚本地更改
        await this.reloadDataFromStorage();
        return false;
      }
    } catch (err) {
      logger.error('DataModel.updateProgress: 更新进度异常:', JSON.stringify(err));
      // 回滚本地更改
      await this.reloadDataFromStorage();
      return false;
    }
  }

  /**
   * 删除单个工单（通过后端API）
   */
  async deleteTask(taskId: string): Promise<boolean> {
    logger.info('DataModel.deleteTask 开始删除工单:', taskId);
    
    const index = this.targetData.findIndex(item => item.id === taskId);
    if (index === -1) {
      logger.warn('DataModel.deleteTask: 工单ID不存在:', taskId);
      return false;
    }

    const deletedTask = this.targetData[index];
    
    // 确保token已设置（从session恢复）
    let tokenRestored = false;
    if (this.context) {
      try {
        const session = await UserStorageUtil.loadSession(this.context);
        if (session && session.token) {
          httpUtil.setAuthToken(session.token);
          logger.info('DataModel.deleteTask: 已从session恢复token: ' + session.token.substring(0, 20) + '...');
          tokenRestored = true;
        } else {
          logger.warn('DataModel.deleteTask: session中没有token，可能未登录');
          logger.warn('DataModel.deleteTask: session内容: ' + JSON.stringify(session));
        }
      } catch (err) {
        logger.error('DataModel.deleteTask: 恢复token失败: ' + JSON.stringify(err));
      }
    } else {
      logger.error('DataModel.deleteTask: context为空，无法恢复token');
    }
    
    if (!tokenRestored) {
      logger.error('DataModel.deleteTask: ⚠️ 警告：token未恢复，请求可能会失败！');
    }
    
    try {
      // 调用后端API删除
      const response = await apiService.deleteTask(taskId);
      
      if (response.code >= 200 && response.code < 300) {
        // 从内存中删除
        this.targetData.splice(index, 1);
        logger.info('DataModel.deleteTask: 工单已删除:', deletedTask.taskName);
        
        // 通知变更
        this.notifyChange();
        logger.info('DataModel.deleteTask: 删除成功');
        return true;
      } else {
        logger.error('DataModel.deleteTask: 删除失败，响应码:', String(response.code));
        return false;
      }
    } catch (err) {
      logger.error('DataModel.deleteTask: 删除工单异常:', JSON.stringify(err));
      if (err instanceof Error) {
        throw err;
      } else {
        throw new Error(`删除工单失败: ${JSON.stringify(err)}`);
      }
    }
  }

  /**
   * 批量删除工单（通过后端API）
   */
  async deleteTasks(taskIds: string[]): Promise<number> {
    // 校验输入参数
    if (!taskIds || taskIds.length === 0) {
      logger.warn('DataModel.deleteTasks: 删除ID列表为空');
      return 0;
    }

    // 校验数据源有效性
    if (!this.targetData || this.targetData.length === 0) {
      logger.warn('DataModel.deleteTasks: 数据源为空，无法删除');
      return 0;
    }

    logger.info('DataModel.deleteTasks 开始删除: ' + JSON.stringify(taskIds) + ', 当前数据长度: ' + String(this.targetData.length));
    
    // 确保token已设置（从session恢复）
    let tokenRestored = false;
    if (this.context) {
      try {
        const session = await UserStorageUtil.loadSession(this.context);
        if (session && session.token) {
          httpUtil.setAuthToken(session.token);
          logger.info('DataModel.deleteTasks: 已从session恢复token: ' + session.token.substring(0, 20) + '...');
          tokenRestored = true;
        } else {
          logger.warn('DataModel.deleteTasks: session中没有token，可能未登录');
          logger.warn('DataModel.deleteTasks: session内容: ' + JSON.stringify(session));
        }
      } catch (err) {
        logger.error('DataModel.deleteTasks: 恢复token失败: ' + JSON.stringify(err));
      }
    } else {
      logger.error('DataModel.deleteTasks: context为空，无法恢复token');
    }
    
    if (!tokenRestored) {
      logger.error('DataModel.deleteTasks: ⚠️ 警告：token未恢复，请求可能会失败！');
    }
    
    try {
      // 校验要删除的ID是否存在于数据源中
      const validIds: string[] = [];
      taskIds.forEach(id => {
        const exists = this.targetData.some(item => item.id === id);
        if (exists) {
          validIds.push(id);
        } else {
          logger.warn(`DataModel.deleteTasks: 工单ID ${id} 不存在于数据源中`);
        }
      });

      if (validIds.length === 0) {
        logger.warn('DataModel.deleteTasks: 没有有效的工单ID可删除');
        return 0;
      }

      // 后端没有批量删除接口，改为循环调用单个删除接口
      logger.info('DataModel.deleteTasks: 开始逐个删除工单，共 ' + String(validIds.length) + ' 个');
      let deletedCount = 0;
      const failedIds: string[] = [];
      
      // 记录删除前的工单数量
      const beforeCount = this.targetData.length;
      
      for (let i = 0; i < validIds.length; i++) {
        const taskId = validIds[i];
        try {
          logger.info(`DataModel.deleteTasks: 正在删除第 ${i + 1}/${validIds.length} 个工单: ${taskId}`);
          
          // 检查工单是否还在内存中（可能在之前的删除中已经被移除）
          const currentIndex = this.targetData.findIndex(item => item.id === taskId);
          if (currentIndex === -1) {
            // 工单已经不在内存中，可能是之前已经删除成功，或者已经被其他操作删除
            logger.warn(`DataModel.deleteTasks: 工单 ${taskId} 不在内存中，可能已删除，跳过`);
            deletedCount++;
            continue;
          }
          
          // 调用后端API删除
          const response = await apiService.deleteTask(taskId);
          
          if (response.code >= 200 && response.code < 300) {
            // 从内存中删除
            this.targetData.splice(currentIndex, 1);
            deletedCount++;
            logger.info(`DataModel.deleteTasks: 工单 ${taskId} 删除成功`);
          } else {
            failedIds.push(taskId);
            logger.warn(`DataModel.deleteTasks: 工单 ${taskId} 删除失败，响应码: ${response.code}`);
          }
        } catch (err) {
          failedIds.push(taskId);
          logger.error(`DataModel.deleteTasks: 工单 ${taskId} 删除异常: ${JSON.stringify(err)}`);
        }
      }
      
      logger.info(`DataModel.deleteTasks: 删除完成，成功: ${deletedCount}, 失败: ${failedIds.length}`);
      
      if (deletedCount > 0) {
        // 通知变更
        this.notifyChange();
        logger.info('DataModel.deleteTasks: 批量删除完成，成功删除了 ' + String(deletedCount) + ' 个工单');
      }
      
      if (failedIds.length > 0) {
        logger.warn('DataModel.deleteTasks: 部分工单删除失败: ' + JSON.stringify(failedIds));
        // 如果有失败的，抛出异常
        throw new Error(`部分工单删除失败，成功: ${deletedCount}, 失败: ${failedIds.length}`);
      }
      
      return deletedCount;
    } catch (err) {
      logger.error('DataModel.deleteTasks 删除操作异常:', JSON.stringify(err));
      // 重新抛出异常，让调用方知道删除失败
      if (err instanceof Error) {
        throw err;
      } else {
        throw new Error(`删除工单失败: ${JSON.stringify(err)}`);
      }
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

