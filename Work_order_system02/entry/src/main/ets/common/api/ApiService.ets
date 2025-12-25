/**
 * API服务类
 * 封装所有与后端API交互的方法
 */

import { httpUtil, HttpResponse } from '../utils/HttpUtil';
import { logger } from '../utils/Logger';

/**
 * 用户登录请求参数
 */
export interface LoginRequest {
  account: string;  // 用户名或手机号
  password: string;
  rememberMe?: boolean;
}

/**
 * 用户注册请求参数
 */
export interface RegisterRequest {
  username: string;
  phone: string;
  password: string;
}

/**
 * 用户信息响应
 */
export interface UserInfoResponse {
  id: string;
  username: string;
  phone: string;
  token?: string;
  registerTime?: string;
  lastLoginTime?: string;
}

/**
 * 任务数据接口（与后端API匹配）
 */
export interface TaskData {
  id?: string;
  taskName: string;
  description?: string;
  progressValue?: number;
  status?: string;
  priority?: string;
  createDate?: string;
  updateDate?: string;
  dueDate?: string;
  assignee?: string;
  category?: string;
  tags?: string[];
}

/**
 * 任务列表响应接口
 */
export interface TaskListResponse {
  list?: TaskData[];
  data?: TaskData[];  // 兼容不同的后端响应格式
  total?: number;
  page?: number;
  pageSize?: number;
}

/**
 * 退出登录响应接口
 */
export interface LogoutResponse {
  success: boolean;
  message?: string;
}

/**
 * 删除工单响应接口
 */
export interface DeleteTaskResponse {
  success: boolean;
  message?: string;
}

/**
 * 批量删除工单响应接口
 */
export interface BatchDeleteTasksResponse {
  success: boolean;
  deletedCount: number;
  message?: string;
}

/**
 * 批量删除工单请求接口
 */
interface BatchDeleteTasksRequest {
  taskIds: string[];
}

/**
 * 登录请求体接口
 */
interface LoginRequestBody {
  account: string;
  password: string;
  rememberMe: boolean;
}

/**
 * 注册请求体接口
 */
interface RegisterRequestBody {
  username: string;
  phone: string;
  password: string;
}

/**
 * 任务列表查询参数接口
 */
interface TaskListParams {
  page: number;
  pageSize: number;
}

/**
 * 日志数据接口
 */
interface LogData {
  page: string;
  pageSize: string;
}

/**
 * API服务类
 */
export class ApiService {
  private static instance: ApiService;

  private constructor() {
  }

  /**
   * 获取单例实例
   */
  static getInstance(): ApiService {
    if (!ApiService.instance) {
      ApiService.instance = new ApiService();
    }
    return ApiService.instance;
  }

  /**
   * 用户登录
   * @param loginData 登录数据
   * @returns Promise<HttpResponse<UserInfoResponse>>
   */
  async login(loginData: LoginRequest): Promise<HttpResponse<UserInfoResponse>> {
    try {
      logger.info('ApiService.login: 发送登录请求', JSON.stringify(loginData));
      
      const requestBody: LoginRequestBody = {
        account: loginData.account,
        password: loginData.password,
        rememberMe: loginData.rememberMe || false
      };
      
      const response = await httpUtil.post<UserInfoResponse>('/auth/login', requestBody);

      // 记录完整的响应数据
      logger.info('ApiService.login: 登录响应完整数据: ' + JSON.stringify(response));
      logger.info('ApiService.login: response.data: ' + JSON.stringify(response.data));
      logger.info('ApiService.login: response.data.token: ' + (response.data?.token || '未找到token'));

      // 如果后端返回了token，设置到HTTP工具类中
      if (response.data && response.data.token) {
        httpUtil.setAuthToken(response.data.token);
        logger.info('ApiService.login: ✅ 已设置token到HttpUtil');
      } else {
        logger.error('ApiService.login: ⚠️ 响应中没有token！');
        logger.error('ApiService.login: response.data类型: ' + typeof response.data);
        logger.error('ApiService.login: response.data内容: ' + JSON.stringify(response.data));
      }

      return response;
    } catch (error) {
      logger.error('ApiService.login: 登录请求失败', JSON.stringify(error));
      if (error instanceof Error) {
        throw error;
      } else {
        throw new Error('登录请求失败');
      }
    }
  }

  /**
   * 用户注册
   * @param registerData 注册数据
   * @returns Promise<HttpResponse<UserInfoResponse>>
   */
  async register(registerData: RegisterRequest): Promise<HttpResponse<UserInfoResponse>> {
    try {
      logger.info('ApiService.register: 发送注册请求', JSON.stringify(registerData));
      
      const requestBody: RegisterRequestBody = {
        username: registerData.username,
        phone: registerData.phone,
        password: registerData.password
      };
      
      const response = await httpUtil.post<UserInfoResponse>('/auth/register', requestBody);

      // 如果后端返回了token，设置到HTTP工具类中
      if (response.data && response.data.token) {
        httpUtil.setAuthToken(response.data.token);
      }

      return response;
    } catch (error) {
      logger.error('ApiService.register: 注册请求失败', JSON.stringify(error));
      if (error instanceof Error) {
        throw error;
      } else {
        throw new Error('注册请求失败');
      }
    }
  }

  /**
   * 获取当前用户信息（通过Token）
   * @returns Promise<HttpResponse<UserInfoResponse>>
   */
  async getCurrentUserInfo(): Promise<HttpResponse<UserInfoResponse>> {
    try {
      logger.info('ApiService.getCurrentUserInfo: 获取当前用户信息');
      
      const response = await httpUtil.get<UserInfoResponse>('/user/info');
      return response;
    } catch (error) {
      logger.error('ApiService.getCurrentUserInfo: 获取当前用户信息失败', JSON.stringify(error));
      if (error instanceof Error) {
        throw error;
      } else {
        throw new Error('获取当前用户信息失败');
      }
    }
  }

  /**
   * 获取用户信息
   * @param userId 用户ID
   * @returns Promise<HttpResponse<UserInfoResponse>>
   */
  async getUserInfo(userId: string): Promise<HttpResponse<UserInfoResponse>> {
    try {
      logger.info('ApiService.getUserInfo: 获取用户信息', userId);
      
      const response = await httpUtil.get<UserInfoResponse>(`/user/${userId}`);
      return response;
    } catch (error) {
      logger.error('ApiService.getUserInfo: 获取用户信息失败', JSON.stringify(error));
      if (error instanceof Error) {
        throw error;
      } else {
        throw new Error('获取用户信息失败');
      }
    }
  }

  /**
   * 退出登录
   * @returns Promise<HttpResponse<LogoutResponse>>
   */
  async logout(): Promise<HttpResponse<LogoutResponse>> {
    try {
      logger.info('ApiService.logout: 退出登录');
      
      const response = await httpUtil.post<LogoutResponse>('/auth/logout');
      
      // 清除认证token
      httpUtil.clearAuthToken();
      
      return response;
    } catch (error) {
      logger.error('ApiService.logout: 退出登录失败', JSON.stringify(error));
      // 即使请求失败，也清除本地token
      httpUtil.clearAuthToken();
      if (error instanceof Error) {
        throw error;
      } else {
        throw new Error('退出登录失败');
      }
    }
  }

  /**
   * 获取工单列表
   * @param page 页码（可选，默认获取全部）
   * @param pageSize 每页数量（可选）
   * @returns Promise<HttpResponse<TaskListResponse>>
   */
  async getTaskList(page?: number, pageSize?: number): Promise<HttpResponse<TaskListResponse>> {
    try {
      const logData: LogData = {
        page: page ? String(page) : 'all',
        pageSize: pageSize ? String(pageSize) : 'all'
      };
      logger.info('ApiService.getTaskList: 获取工单列表', JSON.stringify(logData));
      
      // 如果有分页参数，创建查询参数对象
      const params: Record<string, string | number | boolean> = {};
      if (page !== undefined) {
        params['page'] = page;
      }
      if (pageSize !== undefined) {
        params['pageSize'] = pageSize;
      }
      
      const response = await httpUtil.get<TaskListResponse>('/task/list', Object.keys(params).length > 0 ? params : undefined);
      
      return response;
    } catch (error) {
      logger.error('ApiService.getTaskList: 获取工单列表失败', JSON.stringify(error));
      if (error instanceof Error) {
        throw error;
      } else {
        throw new Error('获取工单列表失败');
      }
    }
  }

  /**
   * 创建工单
   * @param taskData 工单数据
   * @returns Promise<HttpResponse<TaskData>>
   */
  async createTask(taskData: TaskData): Promise<HttpResponse<TaskData>> {
    try {
      logger.info('ApiService.createTask: 开始创建工单');
      logger.info('ApiService.createTask: 工单数据: ' + JSON.stringify(taskData));
      logger.info('ApiService.createTask: 准备调用 httpUtil.post /task/create');
      
      const response = await httpUtil.post<TaskData>('/task/create', taskData);
      
      logger.info('ApiService.createTask: ✅ 请求成功，响应code: ' + String(response.code));
      return response;
    } catch (error) {
      logger.error('ApiService.createTask: ❌ 创建工单失败！');
      logger.error('ApiService.createTask: 错误类型: ' + (error instanceof Error ? error.constructor.name : typeof error));
      logger.error('ApiService.createTask: 错误内容: ' + JSON.stringify(error));
      if (error instanceof Error) {
        logger.error('ApiService.createTask: 错误消息: ' + error.message);
        throw error;
      } else {
        throw new Error('创建工单失败: ' + JSON.stringify(error));
      }
    }
  }

  /**
   * 更新工单
   * @param taskId 工单ID
   * @param taskData 工单数据
   * @returns Promise<HttpResponse<TaskData>>
   */
  async updateTask(taskId: string, taskData: TaskData): Promise<HttpResponse<TaskData>> {
    try {
      logger.info('ApiService.updateTask: 更新工单', taskId, JSON.stringify(taskData));
      
      const response = await httpUtil.put<TaskData>(`/task/${taskId}`, taskData);
      return response;
    } catch (error) {
      logger.error('ApiService.updateTask: 更新工单失败', JSON.stringify(error));
      if (error instanceof Error) {
        throw error;
      } else {
        throw new Error('更新工单失败');
      }
    }
  }

  /**
   * 删除工单
   * @param taskId 工单ID
   * @returns Promise<HttpResponse<DeleteTaskResponse>>
   */
  async deleteTask(taskId: string): Promise<HttpResponse<DeleteTaskResponse>> {
    try {
      logger.info('ApiService.deleteTask: 删除工单', taskId);
      
      const response = await httpUtil.delete<DeleteTaskResponse>(`/task/${taskId}`);
      return response;
    } catch (error) {
      logger.error('ApiService.deleteTask: 删除工单失败', JSON.stringify(error));
      if (error instanceof Error) {
        throw error;
      } else {
        throw new Error('删除工单失败');
      }
    }
  }

  /**
   * 批量删除工单
   * @param taskIds 工单ID数组
   * @returns Promise<HttpResponse<BatchDeleteTasksResponse>>
   */
  async deleteTasks(taskIds: string[]): Promise<HttpResponse<BatchDeleteTasksResponse>> {
    try {
      logger.info('ApiService.deleteTasks: 批量删除工单', JSON.stringify(taskIds));
      
      const requestBody: BatchDeleteTasksRequest = {
        taskIds: taskIds
      };
      const response = await httpUtil.post<BatchDeleteTasksResponse>('/task/batch-delete', requestBody);
      return response;
    } catch (error) {
      logger.error('ApiService.deleteTasks: 批量删除工单失败', JSON.stringify(error));
      if (error instanceof Error) {
        throw error;
      } else {
        throw new Error('批量删除工单失败');
      }
    }
  }
}

// 导出单例实例
export const apiService = ApiService.getInstance();
