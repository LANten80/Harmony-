/**
 * 用户数据模型
 * 定义用户的基本属性和数据结构
 */

/**
 * 用户实体类
 */
export class UserModel {
  // 基础信息
  id: string = '';
  username: string = '';
  phone: string = '';
  password: string = ''; // 加密后的密码

  // 时间信息
  registerTime: string = '';
  lastLoginTime: string = '';

  /**
   * 构造函数
   */
  constructor(username: string, phone: string, password: string) {
    this.id = this.generateId();
    this.username = username;
    this.phone = phone;
    this.password = password; // 实际使用时应该加密
    this.registerTime = new Date().toISOString();
    this.lastLoginTime = new Date().toISOString();
  }

  /**
   * 生成唯一ID
   */
  private generateId(): string {
    return `user_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`;
  }

  /**
   * 更新最后登录时间
   */
  updateLastLoginTime(): void {
    this.lastLoginTime = new Date().toISOString();
  }

  /**
   * 转换为可序列化的对象
   */
  toJSON(): UserData {
    return {
      id: this.id,
      username: this.username,
      phone: this.phone,
      password: this.password,
      registerTime: this.registerTime,
      lastLoginTime: this.lastLoginTime
    };
  }

  /**
   * 从JSON对象创建UserModel
   */
  static fromJSON(data: UserData): UserModel {
    const user = new UserModel(data.username, data.phone, data.password);
    user.id = data.id;
    user.registerTime = data.registerTime;
    user.lastLoginTime = data.lastLoginTime;
    return user;
  }
}

/**
 * 用户数据接口（用于序列化）
 */
export interface UserData {
  id: string;
  username: string;
  phone: string;
  password: string;
  registerTime: string;
  lastLoginTime: string;
}

/**
 * 会话状态接口
 */
export interface SessionData {
  currentUserId: string;
  rememberMe: boolean;
  loginTime: string;
  token?: string; // 认证token（可选）
}



