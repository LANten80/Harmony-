/**
 * HTTP请求工具类
 * 用于发送HTTP请求到Java后端
 */

import http from '@ohos.net.http';
import { BASE_URL, REQUEST_TIMEOUT } from '../constants/CommonConstant';
import { logger } from './Logger';

/**
 * HTTP请求方法枚举
 */
export enum HttpMethod {
  GET = 'GET',
  POST = 'POST',
  PUT = 'PUT',
  DELETE = 'DELETE'
}

/**
 * HTTP请求配置接口
 */
export interface RequestConfig {
  url: string;
  method?: HttpMethod;
  headers?: Record<string, string>;
  params?: Record<string, string | number | boolean>;
  body?: object | string;
  timeout?: number;
}

/**
 * HTTP响应接口
 */
export interface HttpResponse<T = Record<string, Object | string | number | boolean | null>> {
  code: number;
  data: T;
  message?: string;
}

/**
 * 错误响应数据接口
 */
interface ErrorResponseData {
  result: Object | string | number | boolean | null;
}

/**
 * HTTP请求工具类
 */
export class HttpUtil {
  private static instance: HttpUtil;
  private defaultHeaders: Record<string, string> = {
    'Content-Type': 'application/json'
  };

  private constructor() {
  }

  /**
   * 获取单例实例
   */
  static getInstance(): HttpUtil {
    if (!HttpUtil.instance) {
      HttpUtil.instance = new HttpUtil();
    }
    return HttpUtil.instance;
  }

  /**
   * 获取对象的所有键
   */
  private getObjectKeys(obj: Record<string, string>): string[] {
    const keys: string[] = [];
    // 使用 Object.keys 替代 for..in
    const objKeys = Object.keys(obj);
    for (let i = 0; i < objKeys.length; i++) {
      keys.push(objKeys[i]);
    }
    return keys;
  }

  /**
   * 设置默认请求头
   */
  setDefaultHeaders(headers: Record<string, string>): void {
    const newHeaders: Record<string, string> = {};
    // 复制现有headers
    const defaultKeys = this.getObjectKeys(this.defaultHeaders);
    for (let i = 0; i < defaultKeys.length; i++) {
      const key = defaultKeys[i];
      newHeaders[key] = this.defaultHeaders[key];
    }
    // 添加新headers
    const headerKeys = this.getObjectKeys(headers);
    for (let i = 0; i < headerKeys.length; i++) {
      const key = headerKeys[i];
      newHeaders[key] = headers[key];
    }
    this.defaultHeaders = newHeaders;
  }

  /**
   * 设置认证Token
   */
  setAuthToken(token: string): void {
    this.defaultHeaders['Authorization'] = `Bearer ${token}`;
  }

  /**
   * 清除认证Token
   */
  clearAuthToken(): void {
    const newHeaders: Record<string, string> = {};
    const keys = this.getObjectKeys(this.defaultHeaders);
    for (let i = 0; i < keys.length; i++) {
      const key = keys[i];
      if (key !== 'Authorization') {
        newHeaders[key] = this.defaultHeaders[key];
      }
    }
    this.defaultHeaders = newHeaders;
  }

  /**
   * 合并请求头
   */
  private mergeHeaders(headers: Record<string, string>): Record<string, string> {
    const merged: Record<string, string> = {};
    // 先添加默认headers
    const defaultKeys = this.getObjectKeys(this.defaultHeaders);
    for (let i = 0; i < defaultKeys.length; i++) {
      const key = defaultKeys[i];
      merged[key] = this.defaultHeaders[key];
    }
    // 再添加传入的headers（会覆盖默认的）
    const headerKeys = this.getObjectKeys(headers);
    for (let i = 0; i < headerKeys.length; i++) {
      const key = headerKeys[i];
      merged[key] = headers[key];
    }
    return merged;
  }

  /**
   * 发送HTTP请求
   * @param config 请求配置
   * @returns Promise<HttpResponse<T>>
   */
  async request<T = Record<string, Object | string | number | boolean | null>>(config: RequestConfig): Promise<HttpResponse<T>> {
    const url = config.url;
    const method = config.method || HttpMethod.GET;
    const headers = config.headers || {};
    const params = config.params;
    const body = config.body;
    const timeout = config.timeout || REQUEST_TIMEOUT;

    try {
      // 构建完整URL
      let fullUrl = url.startsWith('http') ? url : `${BASE_URL}${url}`;
      
      // 添加查询参数
      if (params) {
        const paramKeys = Object.keys(params);
        if (paramKeys.length > 0) {
          const queryParts: string[] = [];
          for (let i = 0; i < paramKeys.length; i++) {
            const key = paramKeys[i];
            const value = params[key];
            queryParts.push(`${encodeURIComponent(key)}=${encodeURIComponent(String(value))}`);
          }
          const queryString = queryParts.join('&');
          fullUrl += (fullUrl.includes('?') ? '&' : '?') + queryString;
        }
      }

      logger.info(`HttpUtil.request: 准备发送请求 - ${method} ${fullUrl}`);
      logger.info(`HttpUtil.request: BASE_URL = ${BASE_URL}, 完整URL = ${fullUrl}`);

      // 创建HTTP请求
      const httpRequest = http.createHttp();
      
      // 合并请求头
      const requestHeaders = this.mergeHeaders(headers);
      
      // 记录请求头信息（用于调试）
      logger.info(`HttpUtil.request: 请求头信息: ${JSON.stringify(requestHeaders)}`);
      if (requestHeaders['Authorization']) {
        logger.info(`HttpUtil.request: 请求头包含Authorization: ${requestHeaders['Authorization'].substring(0, 20)}...`);
      } else {
        logger.warn('HttpUtil.request: 请求头不包含Authorization！');
      }

      // 构建请求选项
      const requestOptions: http.HttpRequestOptions = {
        method: this.getRequestMethod(method),
        header: requestHeaders,
        connectTimeout: timeout,
        readTimeout: timeout
      };

      // 添加请求体（POST、PUT等方法）
      if (body && (method === HttpMethod.POST || method === HttpMethod.PUT)) {
        if (typeof body === 'string') {
          requestOptions.extraData = body;
        } else {
          requestOptions.extraData = JSON.stringify(body);
        }
        logger.info(`HttpUtil.request: 请求体: ${requestOptions.extraData}`);
      }

      // 发送请求
      logger.info(`HttpUtil.request: 开始发送HTTP请求，超时时间: ${timeout}ms`);
      let response: http.HttpResponse;
      try {
        response = await httpRequest.request(fullUrl, requestOptions);
        logger.info(`HttpUtil.request: HTTP请求已发送，等待响应...`);
      } catch (requestError) {
        logger.error(`HttpUtil.request: 请求发送失败: ${JSON.stringify(requestError)}`);
        httpRequest.destroy();
        // ArkTS只允许throw Error对象
        if (requestError instanceof Error) {
          logger.error(`HttpUtil.request: 请求错误类型: ${requestError.constructor.name}, 错误消息: ${requestError.message}`);
          throw requestError;
        } else {
          logger.error(`HttpUtil.request: 请求错误不是Error类型: ${typeof requestError}`);
          throw new Error(`请求发送失败: ${JSON.stringify(requestError)}`);
        }
      }

      // 关闭HTTP请求
      httpRequest.destroy();

      logger.info(`HttpUtil.request: 响应状态码: ${response.responseCode}`);
      logger.info(`HttpUtil.request: 响应头: ${JSON.stringify(response.header)}`);

      // 解析响应数据
      let responseData: Record<string, Object | string | number | boolean | null> = {};
      if (response.result) {
        try {
          if (typeof response.result === 'string') {
            logger.info(`HttpUtil.request: 响应结果类型: string, 长度: ${response.result.length}`);
            responseData = JSON.parse(response.result) as Record<string, Object | string | number | boolean | null>;
          } else {
            logger.info(`HttpUtil.request: 响应结果类型: ${typeof response.result}`);
            responseData = response.result as Record<string, Object | string | number | boolean | null>;
          }
        } catch (e) {
          logger.error(`HttpUtil.request: 解析响应数据失败: ${JSON.stringify(e)}`);
          // 创建错误响应数据对象
          const errorData: Record<string, Object | string | number | boolean | null> = {};
          errorData['result'] = response.result;
          responseData = errorData;
        }
      } else {
        logger.warn(`HttpUtil.request: 响应结果为空`);
      }

      logger.info(`HttpUtil.request: 响应状态码 ${response.responseCode}, 数据:`, JSON.stringify(responseData));

      // 检查HTTP状态码
      if (response.responseCode >= 200 && response.responseCode < 300) {
        return {
          code: response.responseCode,
          data: responseData as T,
          message: '请求成功'
        };
      } else {
        const errorMsg = `HTTP错误: ${response.responseCode}`;
        logger.error(`HttpUtil.request: ${errorMsg}, 响应数据: ${JSON.stringify(responseData)}`);
        throw new Error(errorMsg);
      }
    } catch (error) {
      logger.error('HttpUtil.request: 请求失败');
      logger.error(`HttpUtil.request: 请求URL: ${url.startsWith('http') ? url : `${BASE_URL}${url}`}`);
      logger.error(`HttpUtil.request: BASE_URL配置: ${BASE_URL}`);
      logger.error(`HttpUtil.request: 请求方法: ${method}`);
      logger.error(`HttpUtil.request: 错误对象类型: ${typeof error}`);
      
      // 尝试获取更详细的错误信息
      if (error instanceof Error) {
        const errorMessage = error.message;
        const errorName = error.constructor.name;
        logger.error(`HttpUtil.request: 错误类型: ${errorName}, 错误消息: ${errorMessage}`);
        if (error.stack) {
          logger.error(`HttpUtil.request: 错误堆栈: ${error.stack}`);
        }
        
        if (errorMessage.includes('timeout') || errorMessage.includes('超时')) {
          logger.error('HttpUtil.request: 请求超时 - 请检查：1.后端服务是否运行 2.网络连接 3.BASE_URL配置是否正确');
          throw new Error('请求超时，请检查网络连接和后端服务');
        } else if (errorMessage.includes('Network') || errorMessage.includes('网络') || errorMessage.includes('连接')) {
          logger.error('HttpUtil.request: 网络连接失败 - 请检查：1.网络权限 2.BASE_URL配置 3.后端服务地址');
          throw new Error('网络连接失败，请检查网络设置和BASE_URL配置');
        } else if (errorMessage.includes('ECONNREFUSED') || errorMessage.includes('连接被拒绝')) {
          logger.error('HttpUtil.request: 连接被拒绝 - 后端服务可能未启动或地址错误');
          throw new Error('无法连接到后端服务，请确认后端服务已启动且地址正确');
        } else {
          logger.error(`HttpUtil.request: 其他错误: ${errorMessage}`);
          throw new Error(`请求失败: ${errorMessage}`);
        }
      } else {
        // 尝试序列化错误对象
        try {
          const errorStr = JSON.stringify(error);
          logger.error(`HttpUtil.request: 错误对象内容: ${errorStr}`);
        } catch (e) {
          logger.error(`HttpUtil.request: 无法序列化错误对象: ${JSON.stringify(e)}`);
        }
        logger.error(`HttpUtil.request: 未知错误类型: ${typeof error}`);
        throw new Error('请求失败，请稍后重试');
      }
    }
  }

  /**
   * 将HttpMethod转换为http.RequestMethod
   */
  private getRequestMethod(method: HttpMethod): http.RequestMethod {
    switch (method) {
      case HttpMethod.GET:
        return http.RequestMethod.GET;
      case HttpMethod.POST:
        return http.RequestMethod.POST;
      case HttpMethod.PUT:
        return http.RequestMethod.PUT;
      case HttpMethod.DELETE:
        return http.RequestMethod.DELETE;
      default:
        return http.RequestMethod.GET;
    }
  }

  /**
   * GET请求
   */
  async get<T = Record<string, Object | string | number | boolean | null>>(url: string, params?: Record<string, string | number | boolean>, headers?: Record<string, string>): Promise<HttpResponse<T>> {
    return this.request<T>({
      url,
      method: HttpMethod.GET,
      params,
      headers
    });
  }

  /**
   * POST请求
   */
  async post<T = Record<string, Object | string | number | boolean | null>>(url: string, body?: object, headers?: Record<string, string>): Promise<HttpResponse<T>> {
    return this.request<T>({
      url,
      method: HttpMethod.POST,
      body,
      headers
    });
  }

  /**
   * PUT请求
   */
  async put<T = Record<string, Object | string | number | boolean | null>>(url: string, body?: object, headers?: Record<string, string>): Promise<HttpResponse<T>> {
    return this.request<T>({
      url,
      method: HttpMethod.PUT,
      body,
      headers
    });
  }

  /**
   * DELETE请求
   */
  async delete<T = Record<string, Object | string | number | boolean | null>>(url: string, params?: Record<string, string | number | boolean>, headers?: Record<string, string>): Promise<HttpResponse<T>> {
    return this.request<T>({
      url,
      method: HttpMethod.DELETE,
      params,
      headers
    });
  }
}

// 导出单例实例
export const httpUtil = HttpUtil.getInstance();
