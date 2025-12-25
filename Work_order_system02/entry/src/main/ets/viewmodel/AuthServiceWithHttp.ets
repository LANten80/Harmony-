/**
 * 用户认证服务（使用HTTP请求版本）
 * 这是一个示例文件，展示如何将AuthService改为使用HTTP请求连接Java后端
 * 
 * 使用方法：
 * 1. 将本文件中的方法复制到AuthService.ets中
 * 2. 或者直接使用本文件替换AuthService.ets
 */

import { UserModel, UserData, SessionData } from './UserModel';
import { UserStorageUtil } from '../common/utils/UserStorageUtil';
import { apiService, UserInfoResponse } from '../common/api/ApiService';
import { httpUtil } from '../common/utils/HttpUtil';
import { common } from '@kit.AbilityKit';
import { logger } from '../common/utils/Logger';
import { DataModel } from './DataModel';

/**
 * 注册结果接口
 */
export interface RegisterResult {
  success: boolean;
  error?: string;
}

/**
 * 登录结果接口
 */
export interface LoginResult {
  success: boolean;
  error?: string;
  user?: UserModel;
}

/**
 * 验证结果接口
 */
export interface ValidationResult {
  valid: boolean;
  error?: string;
}

/**
 * 注册日志数据接口
 */
interface RegisterLogData {
  username: string;
  phone: string;
}

/**
 * 登录日志数据接口
 */
interface LoginLogData {
  account: string;
  rememberMe: boolean;
}

/**
 * 嵌套响应数据接口（用于处理后端可能返回的嵌套格式）
 */
interface NestedResponseData {
  code?: number | string;
  message?: string;
  data?: Record<string, string | number | boolean | null | undefined>;
}

/**
 * 认证服务单例类（使用HTTP请求）
 */
export class AuthServiceWithHttp {
  private static instance: AuthServiceWithHttp;
  private currentUser: UserModel | null = null;
  private context: common.UIAbilityContext | null = null;
  // 是否使用HTTP请求（可以通过配置切换）
  private useHttp: boolean = true;

  /**
   * 私有构造函数，实现单例模式
   */
  private constructor() {
  }

  /**
   * 获取单例实例
   */
  static getInstance(): AuthServiceWithHttp {
    if (!AuthServiceWithHttp.instance) {
      AuthServiceWithHttp.instance = new AuthServiceWithHttp();
    }
    return AuthServiceWithHttp.instance;
  }

  /**
   * 设置应用上下文
   */
  setContext(context: common.UIAbilityContext): void {
    this.context = context;
  }

  /**
   * 设置是否使用HTTP请求
   */
  setUseHttp(useHttp: boolean): void {
    this.useHttp = useHttp;
  }

  /**
   * 用户注册（使用HTTP请求）
   * @param username 用户名
   * @param phone 手机号
   * @param password 密码
   * @returns 注册结果和错误信息
   */
  async register(username: string, phone: string, password: string): Promise<RegisterResult> {
    const logData: RegisterLogData = { username: username, phone: phone };
    logger.info('AuthServiceWithHttp.register: 开始注册', JSON.stringify(logData));

    // 输入验证
    const usernameValidation: ValidationResult = this.validateUsername(username);
    if (!usernameValidation.valid) {
      return { success: false, error: usernameValidation.error };
    }

    const phoneValidation: ValidationResult = this.validatePhone(phone);
    if (!phoneValidation.valid) {
      return { success: false, error: phoneValidation.error };
    }

    const passwordValidation: ValidationResult = this.validatePassword(password);
    if (!passwordValidation.valid) {
      return { success: false, error: passwordValidation.error };
    }

    // 如果使用HTTP请求
    if (this.useHttp) {
      try {
        const response = await apiService.register({
          username: username.trim(),
          phone: phone.trim(),
          password: password
        });

        if (response.code >= 200 && response.code < 300) {
          // 注册成功，可以保存用户信息到本地（可选）
          if (response.data && this.context) {
            const userData: UserData = {
              id: response.data.id || this.generateUserId(),
              username: response.data.username,
              phone: response.data.phone,
              password: '', // 不保存密码
              registerTime: new Date().toISOString(),
              lastLoginTime: ''
            };
            
            // 可选：保存到本地存储
            const existingUsers = await UserStorageUtil.loadUsers(this.context);
            existingUsers.push(userData);
            await UserStorageUtil.saveUsers(this.context, existingUsers);
          }

          logger.info('AuthServiceWithHttp.register: 注册成功');
          return { success: true };
        } else {
          return { 
            success: false, 
            error: response.message || '注册失败，请重试' 
          };
        }
      } catch (error) {
        logger.error('AuthServiceWithHttp.register: 注册请求失败', error);
        const errorMessage = error instanceof Error ? error.message : '注册失败，请稍后重试';
        return { success: false, error: errorMessage };
      }
    } else {
      // 使用本地存储（原有逻辑）
      return this.registerLocal(username, phone, password);
    }
  }

  /**
   * 用户登录（使用HTTP请求）
   * @param account 账号（用户名或手机号）
   * @param password 密码
   * @param rememberMe 是否记住密码
   * @returns 登录结果和错误信息
   */
  async login(account: string, password: string, rememberMe: boolean = false): Promise<LoginResult> {
    const logData: LoginLogData = { account: account, rememberMe: rememberMe };
    logger.info('AuthServiceWithHttp.login: 开始登录', JSON.stringify(logData));

    // 输入验证
    if (!account || account.trim().length === 0) {
      return { success: false, error: '请输入用户名或手机号' };
    }

    if (!password || password.trim().length === 0) {
      return { success: false, error: '请输入密码' };
    }

    // 如果使用HTTP请求
    if (this.useHttp) {
      try {
        const response = await apiService.login({
          account: account.trim(),
          password: password,
          rememberMe: rememberMe
        });

        if (response.code >= 200 && response.code < 300 && response.data) {
          // 记录完整的响应数据，用于调试
          logger.info('AuthServiceWithHttp.login: 登录响应完整数据: ' + JSON.stringify(response.data));
          
          // 后端返回的格式可能是嵌套的：{code: 200, message: "登录成功", data: {id, username, token, ...}}
          // 使用JSON序列化/反序列化来安全地处理类型转换（ArkTS不允许unknown和any）
          const responseDataStr = JSON.stringify(response.data);
          const responseDataParsed = JSON.parse(responseDataStr) as Record<string, string | number | boolean | null | undefined>;
          
          // 检查是否是嵌套格式（有code和message属性）
          // ArkTS不支持in操作符，使用检查undefined的方式来判断属性是否存在
          let actualUserData: Record<string, string | number | boolean | null | undefined>;
          const hasCode = responseDataParsed['code'] !== undefined;
          const hasMessage = responseDataParsed['message'] !== undefined;
          const hasData = responseDataParsed['data'] !== undefined;
          
          if (hasCode && hasMessage && hasData) {
            // 嵌套格式：从 data 字段中提取用户信息
            const nestedData = responseDataParsed['data'];
            if (nestedData && typeof nestedData === 'object') {
              const nestedDataStr = JSON.stringify(nestedData);
              actualUserData = JSON.parse(nestedDataStr) as Record<string, string | number | boolean | null | undefined>;
              logger.info('AuthServiceWithHttp.login: 检测到嵌套格式，从data字段提取用户信息');
            } else {
              // 如果data字段不是对象，直接使用response.data
              actualUserData = responseDataParsed;
            }
          } else {
            // 非嵌套格式：直接使用response.data
            actualUserData = responseDataParsed;
          }
          
          logger.info('AuthServiceWithHttp.login: 实际用户数据: ' + JSON.stringify(actualUserData));
          
          // 提取用户ID和token（确保不为空）
          const userId = String(actualUserData['id'] || '');
          const token = String(actualUserData['token'] || '');
          
          logger.info('AuthServiceWithHttp.login: 提取的用户ID: ' + (userId || '空'));
          logger.info('AuthServiceWithHttp.login: 提取的token: ' + (token ? token.substring(0, 20) + '...' : '空'));
          
          // 验证必要字段
          if (!userId || userId.trim().length === 0) {
            logger.error('AuthServiceWithHttp.login: ⚠️ 错误：用户ID为空！');
            logger.error('AuthServiceWithHttp.login: 实际用户数据: ' + JSON.stringify(actualUserData));
            return { success: false, error: '登录失败：无法获取用户信息' };
          }
          
          if (!token || token.trim().length === 0) {
            logger.error('AuthServiceWithHttp.login: ⚠️ 错误：token为空！');
            logger.error('AuthServiceWithHttp.login: 实际用户数据: ' + JSON.stringify(actualUserData));
            return { success: false, error: '登录失败：无法获取认证token' };
          }
          
          // 登录成功，创建用户模型
          const userData: UserData = {
            id: userId,
            username: String(actualUserData['username'] || ''),
            phone: String(actualUserData['phone'] || ''),
            password: '', // 不保存密码
            registerTime: String(actualUserData['registerTime'] || new Date().toISOString()),
            lastLoginTime: String(actualUserData['lastLoginTime'] || new Date().toISOString())
          };

          const user = UserModel.fromJSON(userData);
          this.currentUser = user;

          // 保存登录状态到本地（包括token）
          if (this.context) {
            // 立即设置token到HttpUtil，确保后续API调用可以使用
            httpUtil.setAuthToken(token);
            logger.info('AuthServiceWithHttp.login: ✅ 已设置token到HttpUtil');
            
            // 保存session（确保user.id和token都不为空）
            await this.saveSession(user.id, rememberMe, token);
            logger.info('AuthServiceWithHttp.login: ✅ 已保存session，userId: ' + user.id + ', token长度: ' + token.length);
            
            // 可选：更新本地用户信息
            const existingUsers = await UserStorageUtil.loadUsers(this.context);
            const userIndex = existingUsers.findIndex(u => u.id === user.id);
            if (userIndex >= 0) {
              existingUsers[userIndex] = user.toJSON();
            } else {
              existingUsers.push(user.toJSON());
            }
            await UserStorageUtil.saveUsers(this.context, existingUsers);
          }

          logger.error('✅✅✅ AuthServiceWithHttp.login: 登录成功，用户ID: ' + user.id);
          logger.error('✅✅✅ AuthServiceWithHttp.login: 登录成功，用户名: ' + user.username);
          logger.error('✅✅✅ AuthServiceWithHttp.login: 登录成功，token长度: ' + String(token.length));
          
          // 登录成功后，确保DataModel会重新加载数据
          const dataModel = DataModel.getInstance();
          const currentDataCount = dataModel.getData().length;
          logger.error('✅✅✅ AuthServiceWithHttp.login: 登录成功时，DataModel当前工单数: ' + String(currentDataCount));
          logger.error('✅✅✅ AuthServiceWithHttp.login: 登录成功，建议立即调用 reloadDataFromStorage() 重新加载数据');
          
          return { success: true, user: user };
        } else {
          return { 
            success: false, 
            error: response.message || '用户名或密码错误' 
          };
        }
      } catch (error) {
        logger.error('AuthServiceWithHttp.login: 登录请求失败', error);
        const errorMessage = error instanceof Error ? error.message : '登录失败，请稍后重试';
        return { success: false, error: errorMessage };
      }
    } else {
      // 使用本地存储（原有逻辑）
      return this.loginLocal(account, password, rememberMe);
    }
  }

  /**
   * 退出登录
   */
  async logout(): Promise<void> {
    logger.info('AuthServiceWithHttp.logout: 退出登录');

    if (this.useHttp) {
      try {
        await apiService.logout();
      } catch (error) {
        logger.error('AuthServiceWithHttp.logout: 退出登录请求失败', error);
        // 即使请求失败，也清除本地状态
      }
      // 清除HttpUtil中的token
      httpUtil.clearAuthToken();
      logger.info('AuthServiceWithHttp.logout: 已清除HttpUtil中的token');
    }

    this.currentUser = null;
    if (this.context) {
      await UserStorageUtil.clearSession(this.context);
      logger.info('AuthServiceWithHttp.logout: 已清除session');
    } else {
      logger.warn('AuthServiceWithHttp.logout: context为空，无法清除session');
    }
    
    // 注意：不清除DataModel中的数据，因为数据保存在后端数据库
    // 退出登录只是清除本地的session和token，数据应该保留在内存中
    // 如果用户重新登录，数据会从后端重新加载
    logger.info('AuthServiceWithHttp.logout: 退出登录完成，DataModel数据保持不变（数据保存在后端）');
  }

  /**
   * 检查登录状态
   */
  async checkLoginStatus(): Promise<UserModel | null> {
    if (this.currentUser) {
      return this.currentUser;
    }

    if (!this.context) {
      return null;
    }

    try {
      const session = await UserStorageUtil.loadSession(this.context);
      if (!session || !session.currentUserId) {
        return null;
      }

      // 如果使用HTTP请求，可以从服务器验证token
      if (this.useHttp) {
        // 首先从session中恢复token
        if (session.token) {
          httpUtil.setAuthToken(session.token);
          logger.info('AuthServiceWithHttp.checkLoginStatus: 已从session恢复token');
        }
        
        try {
          // 使用 /user/info 端点，通过 token 获取用户信息
          const response = await apiService.getCurrentUserInfo();
          if (response.code >= 200 && response.code < 300 && response.data) {
            // 验证必要字段是否存在
            if (!response.data.username || !response.data.phone) {
              logger.warn('AuthServiceWithHttp.checkLoginStatus: 用户信息不完整', JSON.stringify({
                hasUsername: !!response.data.username,
                hasPhone: !!response.data.phone,
                responseData: response.data
              }));
              
              // 尝试从本地存储获取完整信息
              const users = await UserStorageUtil.loadUsers(this.context);
              const localUserData = users.find(user => user.id === response.data.id);
              if (localUserData && localUserData.username && localUserData.phone) {
                logger.info('AuthServiceWithHttp.checkLoginStatus: 从本地存储补充用户信息');
                const userData: UserData = {
                  id: response.data.id || localUserData.id,
                  username: response.data.username || localUserData.username,
                  phone: response.data.phone || localUserData.phone,
                  password: '',
                  registerTime: response.data.registerTime || localUserData.registerTime || new Date().toISOString(),
                  lastLoginTime: response.data.lastLoginTime || localUserData.lastLoginTime || new Date().toISOString()
                };
                this.currentUser = UserModel.fromJSON(userData);
                logger.info('AuthServiceWithHttp.checkLoginStatus: 获取用户信息成功（已补充）', JSON.stringify({
                  id: userData.id,
                  username: userData.username,
                  phone: userData.phone
                }));
                return this.currentUser;
              }
            }
            
            const userData: UserData = {
              id: response.data.id,
              username: response.data.username || '',
              phone: response.data.phone || '',
              password: '',
              registerTime: response.data.registerTime || new Date().toISOString(),
              lastLoginTime: response.data.lastLoginTime || new Date().toISOString()
            };
            this.currentUser = UserModel.fromJSON(userData);
            logger.info('AuthServiceWithHttp.checkLoginStatus: 获取用户信息成功', JSON.stringify({
              id: userData.id,
              username: userData.username,
              phone: userData.phone
            }));
            return this.currentUser;
          } else {
            logger.warn('AuthServiceWithHttp.checkLoginStatus: 获取用户信息失败，响应码:', String(response.code));
            // token无效，清除本地session
            await UserStorageUtil.clearSession(this.context);
            return null;
          }
        } catch (error) {
          logger.error('AuthServiceWithHttp.checkLoginStatus: 验证token失败', JSON.stringify(error));
          // token无效，清除本地session
          await UserStorageUtil.clearSession(this.context);
          return null;
        }
      } else {
        // 使用本地存储
        if (session.rememberMe) {
          const users = await UserStorageUtil.loadUsers(this.context);
          const userData = users.find(user => user.id === session.currentUserId);
          if (userData) {
            this.currentUser = UserModel.fromJSON(userData);
            return this.currentUser;
          }
        }
      }

      return null;
    } catch (err) {
      logger.error('AuthServiceWithHttp.checkLoginStatus: 检查登录状态异常', err);
      return null;
    }
  }

  /**
   * 获取当前登录用户
   */
  getCurrentUser(): UserModel | null {
    return this.currentUser;
  }

  /**
   * 强制从后端刷新用户信息
   * @returns Promise<UserModel | null>
   */
  async refreshUserInfo(): Promise<UserModel | null> {
    if (!this.context) {
      logger.warn('AuthServiceWithHttp.refreshUserInfo: 上下文未初始化');
      return null;
    }

    if (!this.useHttp) {
      logger.warn('AuthServiceWithHttp.refreshUserInfo: 未启用HTTP请求');
      return this.currentUser;
    }

    try {
      // 检查是否有session
      const session = await UserStorageUtil.loadSession(this.context);
      if (!session || !session.currentUserId) {
        logger.warn('AuthServiceWithHttp.refreshUserInfo: 未找到登录session');
        return null;
      }

      // 从session中恢复token
      if (session.token) {
        httpUtil.setAuthToken(session.token);
        logger.info('AuthServiceWithHttp.refreshUserInfo: 已从session恢复token');
      }

      // 从服务器获取最新用户信息
      const response = await apiService.getCurrentUserInfo();
      if (response.code >= 200 && response.code < 300 && response.data) {
        // 验证必要字段
        if (!response.data.username || !response.data.phone) {
          logger.warn('AuthServiceWithHttp.refreshUserInfo: 用户信息不完整', JSON.stringify({
            hasUsername: !!response.data.username,
            hasPhone: !!response.data.phone,
            responseData: response.data
          }));
        }

        const userData: UserData = {
          id: response.data.id,
          username: response.data.username || '',
          phone: response.data.phone || '',
          password: '',
          registerTime: response.data.registerTime || new Date().toISOString(),
          lastLoginTime: response.data.lastLoginTime || new Date().toISOString()
        };

        // 更新本地存储的用户信息
        const users = await UserStorageUtil.loadUsers(this.context);
        const userIndex = users.findIndex(u => u.id === userData.id);
        if (userIndex >= 0) {
          users[userIndex] = userData;
        } else {
          users.push(userData);
        }
        await UserStorageUtil.saveUsers(this.context, users);

        this.currentUser = UserModel.fromJSON(userData);
        logger.info('AuthServiceWithHttp.refreshUserInfo: 刷新用户信息成功', JSON.stringify({
          id: userData.id,
          username: userData.username,
          phone: userData.phone
        }));
        return this.currentUser;
      } else {
        logger.warn('AuthServiceWithHttp.refreshUserInfo: 获取用户信息失败，响应码:', String(response.code));
        return null;
      }
    } catch (error) {
      logger.error('AuthServiceWithHttp.refreshUserInfo: 刷新用户信息失败', JSON.stringify(error));
      return null;
    }
  }

  // ========== 私有方法 ==========

  /**
   * 本地注册（原有逻辑）
   */
  private async registerLocal(username: string, phone: string, password: string): Promise<RegisterResult> {
    if (!this.context) {
      return { success: false, error: '系统错误：上下文未初始化' };
    }

    try {
      const existingUsers = await UserStorageUtil.loadUsers(this.context);
      const usernameExists = existingUsers.some(user => user.username === username.trim());
      if (usernameExists) {
        return { success: false, error: '用户名已存在' };
      }

      const phoneExists = existingUsers.some(user => user.phone === phone.trim());
      if (phoneExists) {
        return { success: false, error: '手机号已注册' };
      }

      const encryptedPassword = this.encryptPassword(password);
      const newUser = new UserModel(username.trim(), phone.trim(), encryptedPassword);

      existingUsers.push(newUser.toJSON());
      const saveSuccess = await UserStorageUtil.saveUsers(this.context, existingUsers);
      if (!saveSuccess) {
        return { success: false, error: '注册失败，请重试' };
      }

      return { success: true };
    } catch (err) {
      logger.error('AuthServiceWithHttp.registerLocal: 注册异常', err);
      return { success: false, error: '注册失败，请稍后重试' };
    }
  }

  /**
   * 本地登录（原有逻辑）
   */
  private async loginLocal(account: string, password: string, rememberMe: boolean): Promise<LoginResult> {
    if (!this.context) {
      return { success: false, error: '系统错误：上下文未初始化' };
    }

    try {
      const users = await UserStorageUtil.loadUsers(this.context);
      const accountTrimmed = account.trim();

      const userData = users.find(user =>
        user.username === accountTrimmed || user.phone === accountTrimmed
      );

      if (!userData) {
        return { success: false, error: '用户名或密码错误' };
      }

      const encryptedPassword = this.encryptPassword(password);
      if (userData.password !== encryptedPassword) {
        return { success: false, error: '用户名或密码错误' };
      }

      const user = UserModel.fromJSON(userData);
      user.updateLastLoginTime();

      const userIndex = users.findIndex(u => u.id === user.id);
      if (userIndex >= 0) {
        users[userIndex] = user.toJSON();
        await UserStorageUtil.saveUsers(this.context, users);
      }

      this.currentUser = user;
      await this.saveSession(user.id, rememberMe);

      return { success: true, user: user };
    } catch (err) {
      logger.error('AuthServiceWithHttp.loginLocal: 登录异常', err);
      return { success: false, error: '登录失败，请稍后重试' };
    }
  }

  /**
   * 保存会话状态
   */
  private async saveSession(userId: string, rememberMe: boolean, token?: string): Promise<void> {
    if (!this.context) {
      logger.error('AuthServiceWithHttp.saveSession: context为空，无法保存session');
      return;
    }

    logger.info('AuthServiceWithHttp.saveSession: 准备保存session，userId: ' + userId + ', token: ' + (token ? token.substring(0, 20) + '...' : '空'));
    
    const session: SessionData = {
      currentUserId: userId,
      rememberMe: rememberMe,
      loginTime: new Date().toISOString(),
      token: token || '' // 保存token到session
    };

    await UserStorageUtil.saveSession(this.context, session);
    logger.info('AuthServiceWithHttp.saveSession: ✅ session已保存，内容: ' + JSON.stringify(session));
  }

  /**
   * 生成用户ID
   */
  private generateUserId(): string {
    return `user_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`;
  }

  /**
   * 验证用户名
   */
  private validateUsername(username: string): ValidationResult {
    const trimmed = username.trim();

    if (!trimmed || trimmed.length === 0) {
      return { valid: false, error: '请输入用户名' };
    }

    if (trimmed.length < 3 || trimmed.length > 20) {
      return { valid: false, error: '用户名需要3-20个字符' };
    }

    const usernameRegex = /^[a-zA-Z0-9_]+$/;
    if (!usernameRegex.test(trimmed)) {
      return { valid: false, error: '用户名只能包含字母、数字和下划线' };
    }

    return { valid: true };
  }

  /**
   * 验证手机号
   */
  private validatePhone(phone: string): ValidationResult {
    const trimmed = phone.trim();

    if (!trimmed || trimmed.length === 0) {
      return { valid: false, error: '请输入手机号' };
    }

    if (trimmed.length !== 11) {
      return { valid: false, error: '手机号必须是11位数字' };
    }

    const phoneRegex = /^1[3-9]\d{9}$/;
    if (!phoneRegex.test(trimmed)) {
      return { valid: false, error: '请输入有效的手机号' };
    }

    return { valid: true };
  }

  /**
   * 验证密码
   */
  private validatePassword(password: string): ValidationResult {
    if (!password || password.length === 0) {
      return { valid: false, error: '请输入密码' };
    }

    if (password.length < 6 || password.length > 20) {
      return { valid: false, error: '密码需要6-20个字符' };
    }

    const hasLetter = /[a-zA-Z]/.test(password);
    const hasNumber = /\d/.test(password);
    if (!hasLetter || !hasNumber) {
      return { valid: false, error: '密码需包含字母和数字' };
    }

    return { valid: true };
  }

  /**
   * 加密密码（Base64编码）
   */
  private encryptPassword(password: string): string {
    try {
      // Base64字符集
      const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/';
      let result = '';
      let i = 0;
      
      while (i < password.length) {
        const a = password.charCodeAt(i++);
        const b = i < password.length ? password.charCodeAt(i++) : 0;
        const c = i < password.length ? password.charCodeAt(i++) : 0;
        
        const bitmap = (a << 16) | (b << 8) | c;
        
        result += chars.charAt((bitmap >> 18) & 63);
        result += chars.charAt((bitmap >> 12) & 63);
        result += i - 2 < password.length ? chars.charAt((bitmap >> 6) & 63) : '=';
        result += i - 1 < password.length ? chars.charAt(bitmap & 63) : '=';
      }
      
      return result;
    } catch (err) {
      logger.error('AuthServiceWithHttp.encryptPassword: 密码加密失败', err);
      return password;
    }
  }
}

