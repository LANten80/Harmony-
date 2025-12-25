/**
 * 用户认证服务
 * 管理用户注册、登录、退出等认证相关功能
 */

import { UserModel, UserData, SessionData } from './UserModel';
import { UserStorageUtil } from '../common/utils/UserStorageUtil';
import { common } from '@kit.AbilityKit';

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
 * 认证服务单例类
 */
export class AuthService {
  private static instance: AuthService;
  private currentUser: UserModel | null = null;
  private context: common.UIAbilityContext | null = null;

  /**
   * 私有构造函数，实现单例模式
   */
  private constructor() {
  }

  /**
   * 获取单例实例
   */
  static getInstance(): AuthService {
    if (!AuthService.instance) {
      AuthService.instance = new AuthService();
    }
    return AuthService.instance;
  }

  /**
   * 设置应用上下文
   */
  setContext(context: common.UIAbilityContext): void {
    this.context = context;
  }

  /**
   * 用户注册
   * @param username 用户名
   * @param phone 手机号
   * @param password 密码
   * @returns 注册结果和错误信息
   */
  async register(username: string, phone: string, password: string): Promise<RegisterResult> {
    console.info('AuthService.register: 开始注册, username:', username, 'phone:', phone);

    // 输入验证
    const usernameValidation: ValidationResult = this.validateUsername(username);
    if (!usernameValidation.valid) {
      const result: RegisterResult = { success: false, error: usernameValidation.error };
      return result;
    }

    const phoneValidation: ValidationResult = this.validatePhone(phone);
    if (!phoneValidation.valid) {
      const result: RegisterResult = { success: false, error: phoneValidation.error };
      return result;
    }

    const passwordValidation: ValidationResult = this.validatePassword(password);
    if (!passwordValidation.valid) {
      const result: RegisterResult = { success: false, error: passwordValidation.error };
      return result;
    }

    if (!this.context) {
      const result: RegisterResult = { success: false, error: '系统错误：上下文未初始化' };
      return result;
    }

    try {
      // 检查用户名是否已存在
      const existingUsers = await UserStorageUtil.loadUsers(this.context);
      const usernameExists = existingUsers.some(user => user.username === username.trim());
      if (usernameExists) {
        const result: RegisterResult = { success: false, error: '用户名已存在' };
        return result;
      }

      // 检查手机号是否已注册
      const phoneExists = existingUsers.some(user => user.phone === phone.trim());
      if (phoneExists) {
        const result: RegisterResult = { success: false, error: '手机号已注册' };
        return result;
      }

      // 创建新用户
      const encryptedPassword = this.encryptPassword(password);
      const newUser = new UserModel(username.trim(), phone.trim(), encryptedPassword);

      // 保存用户
      existingUsers.push(newUser.toJSON());
      const saveSuccess = await UserStorageUtil.saveUsers(this.context, existingUsers);
      if (!saveSuccess) {
        const result: RegisterResult = { success: false, error: '注册失败，请重试' };
        return result;
      }

      console.info('AuthService.register: 注册成功, userId:', newUser.id);
      const result: RegisterResult = { success: true };
      return result;
    } catch (err) {
      console.error('AuthService.register: 注册异常:', JSON.stringify(err));
      const result: RegisterResult = { success: false, error: '注册失败，请稍后重试' };
      return result;
    }
  }

  /**
   * 用户登录
   * @param account 账号（用户名或手机号）
   * @param password 密码
   * @param rememberMe 是否记住密码
   * @returns 登录结果和错误信息
   */
  async login(account: string, password: string, rememberMe: boolean = false): Promise<LoginResult> {
    console.info('AuthService.login: 开始登录, account:', account, 'rememberMe:', rememberMe);

    // 输入验证
    if (!account || account.trim().length === 0) {
      const result: LoginResult = { success: false, error: '请输入用户名或手机号' };
      return result;
    }

    if (!password || password.trim().length === 0) {
      const result: LoginResult = { success: false, error: '请输入密码' };
      return result;
    }

    if (!this.context) {
      const result: LoginResult = { success: false, error: '系统错误：上下文未初始化' };
      return result;
    }

    try {
      // 加载用户数据
      const users = await UserStorageUtil.loadUsers(this.context);
      const accountTrimmed = account.trim();

      // 查找用户（支持用户名或手机号登录）
      const userData = users.find(user =>
        user.username === accountTrimmed || user.phone === accountTrimmed
      );

      if (!userData) {
        const result: LoginResult = { success: false, error: '用户名或密码错误' };
        return result;
      }

      // 验证密码
      const encryptedPassword = this.encryptPassword(password);
      if (userData.password !== encryptedPassword) {
        const result: LoginResult = { success: false, error: '用户名或密码错误' };
        return result;
      }

      // 登录成功
      const user = UserModel.fromJSON(userData);
      user.updateLastLoginTime();

      // 更新最后登录时间
      const userIndex = users.findIndex(u => u.id === user.id);
      if (userIndex >= 0) {
        users[userIndex] = user.toJSON();
        await UserStorageUtil.saveUsers(this.context, users);
      }

      // 保存登录状态
      this.currentUser = user;
      await this.saveSession(user.id, rememberMe);

      console.info('AuthService.login: 登录成功, userId:', user.id);
      const result: LoginResult = { success: true, user: user };
      return result;
    } catch (err) {
      console.error('AuthService.login: 登录异常:', JSON.stringify(err));
      const result: LoginResult = { success: false, error: '登录失败，请稍后重试' };
      return result;
    }
  }

  /**
   * 退出登录
   */
  async logout(): Promise<void> {
    console.info('AuthService.logout: 退出登录');
    this.currentUser = null;
    if (this.context) {
      await UserStorageUtil.clearSession(this.context);
    }
  }

  /**
   * 检查登录状态
   * @returns 当前登录用户，如果未登录返回null
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

      // 如果记住密码，加载用户信息
      if (session.rememberMe) {
        const users = await UserStorageUtil.loadUsers(this.context);
        const userData = users.find(user => user.id === session.currentUserId);
        if (userData) {
          this.currentUser = UserModel.fromJSON(userData);
          return this.currentUser;
        }
      }

      return null;
    } catch (err) {
      console.error('AuthService.checkLoginStatus: 检查登录状态异常:', JSON.stringify(err));
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
   * 保存会话状态
   */
  private async saveSession(userId: string, rememberMe: boolean): Promise<void> {
    if (!this.context) {
      return;
    }

    const session: SessionData = {
      currentUserId: userId,
      rememberMe: rememberMe,
      loginTime: new Date().toISOString()
    };

    await UserStorageUtil.saveSession(this.context, session);
  }

  /**
   * 验证用户名
   */
  private validateUsername(username: string): ValidationResult {
    const trimmed = username.trim();

    if (!trimmed || trimmed.length === 0) {
      const result: ValidationResult = { valid: false, error: '请输入用户名' };
      return result;
    }

    if (trimmed.length < 3 || trimmed.length > 20) {
      const result: ValidationResult = { valid: false, error: '用户名需要3-20个字符' };
      return result;
    }

    // 只能包含字母、数字、下划线
    const usernameRegex = /^[a-zA-Z0-9_]+$/;
    if (!usernameRegex.test(trimmed)) {
      const result: ValidationResult = { valid: false, error: '用户名只能包含字母、数字和下划线' };
      return result;
    }

    const result: ValidationResult = { valid: true };
    return result;
  }

  /**
   * 验证手机号
   */
  private validatePhone(phone: string): ValidationResult {
    const trimmed = phone.trim();

    if (!trimmed || trimmed.length === 0) {
      const result: ValidationResult = { valid: false, error: '请输入手机号' };
      return result;
    }

    if (trimmed.length !== 11) {
      const result: ValidationResult = { valid: false, error: '手机号必须是11位数字' };
      return result;
    }

    // 验证手机号格式（13/14/15/16/17/18/19开头）
    const phoneRegex = /^1[3-9]\d{9}$/;
    if (!phoneRegex.test(trimmed)) {
      const result: ValidationResult = { valid: false, error: '请输入有效的手机号' };
      return result;
    }

    const result: ValidationResult = { valid: true };
    return result;
  }

  /**
   * 验证密码
   */
  private validatePassword(password: string): ValidationResult {
    if (!password || password.length === 0) {
      const result: ValidationResult = { valid: false, error: '请输入密码' };
      return result;
    }

    if (password.length < 6 || password.length > 20) {
      const result: ValidationResult = { valid: false, error: '密码需要6-20个字符' };
      return result;
    }

    // 必须包含字母和数字
    const hasLetter = /[a-zA-Z]/.test(password);
    const hasNumber = /\d/.test(password);
    if (!hasLetter || !hasNumber) {
      const result: ValidationResult = { valid: false, error: '密码需包含字母和数字' };
      return result;
    }

    const result: ValidationResult = { valid: true };
    return result;
  }

  /**
   * 加密密码（Base64编码，实际项目中应使用更安全的加密方式）
   */
  private encryptPassword(password: string): string {
    // 使用Base64编码（实际项目中应使用更安全的加密方式，如SHA-256）
    try {
      // 简单的Base64编码实现
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
      console.error('AuthService.encryptPassword: 密码加密失败:', JSON.stringify(err));
      return password; // 失败时返回原密码（不推荐，但作为fallback）
    }
  }
}

