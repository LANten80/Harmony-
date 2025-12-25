/**
 * 用户存储工具类
 * 使用 Preferences 进行用户数据和会话状态持久化
 */

import { preferences } from '@kit.ArkData';
import { common } from '@kit.AbilityKit';
import { UserData, SessionData } from '../../viewmodel/UserModel';

export class UserStorageUtil {
  private static readonly PREF_NAME = 'UserData';
  private static readonly USERS_KEY = 'users';
  private static readonly SESSION_KEY = 'session';

  /**
   * 保存用户数据列表
   * @param context 应用上下文
   * @param users 用户数据列表
   */
  static async saveUsers(context: common.UIAbilityContext, users: UserData[]): Promise<boolean> {
    try {
      const dataPreferences = await preferences.getPreferences(context, UserStorageUtil.PREF_NAME);
      const jsonString = JSON.stringify(users);
      await dataPreferences.put(UserStorageUtil.USERS_KEY, jsonString);
      await dataPreferences.flush();
      console.info('UserStorageUtil.saveUsers: 保存用户数据成功, 用户数:', users.length);
      return true;
    } catch (err) {
      console.error('UserStorageUtil.saveUsers: 保存用户数据失败:', JSON.stringify(err));
      return false;
    }
  }

  /**
   * 加载用户数据列表
   * @param context 应用上下文
   */
  static async loadUsers(context: common.UIAbilityContext): Promise<UserData[]> {
    try {
      const dataPreferences = await preferences.getPreferences(context, UserStorageUtil.PREF_NAME);
      const jsonString = await dataPreferences.get(UserStorageUtil.USERS_KEY, '[]') as string;
      const parsed: UserData[] = JSON.parse(jsonString) as UserData[];
      
      if (Array.isArray(parsed)) {
        console.info('UserStorageUtil.loadUsers: 加载用户数据成功, 用户数:', parsed.length);
        return parsed;
      }
      return [];
    } catch (err) {
      console.error('UserStorageUtil.loadUsers: 加载用户数据失败:', JSON.stringify(err));
      return [];
    }
  }

  /**
   * 保存会话状态
   * @param context 应用上下文
   * @param session 会话数据
   */
  static async saveSession(context: common.UIAbilityContext, session: SessionData): Promise<boolean> {
    try {
      const dataPreferences = await preferences.getPreferences(context, UserStorageUtil.PREF_NAME);
      const jsonString = JSON.stringify(session);
      await dataPreferences.put(UserStorageUtil.SESSION_KEY, jsonString);
      await dataPreferences.flush();
      console.info('UserStorageUtil.saveSession: 保存会话状态成功');
      return true;
    } catch (err) {
      console.error('UserStorageUtil.saveSession: 保存会话状态失败:', JSON.stringify(err));
      return false;
    }
  }

  /**
   * 加载会话状态
   * @param context 应用上下文
   */
  static async loadSession(context: common.UIAbilityContext): Promise<SessionData | null> {
    try {
      const dataPreferences = await preferences.getPreferences(context, UserStorageUtil.PREF_NAME);
      const jsonString = await dataPreferences.get(UserStorageUtil.SESSION_KEY, '') as string;
      
      if (!jsonString || jsonString.length === 0) {
        return null;
      }

      const parsed: SessionData = JSON.parse(jsonString) as SessionData;
      console.info('UserStorageUtil.loadSession: 加载会话状态成功');
      return parsed;
    } catch (err) {
      console.error('UserStorageUtil.loadSession: 加载会话状态失败:', JSON.stringify(err));
      return null;
    }
  }

  /**
   * 清除会话状态
   * @param context 应用上下文
   */
  static async clearSession(context: common.UIAbilityContext): Promise<boolean> {
    try {
      const dataPreferences = await preferences.getPreferences(context, UserStorageUtil.PREF_NAME);
      await dataPreferences.delete(UserStorageUtil.SESSION_KEY);
      await dataPreferences.flush();
      console.info('UserStorageUtil.clearSession: 清除会话状态成功');
      return true;
    } catch (err) {
      console.error('UserStorageUtil.clearSession: 清除会话状态失败:', JSON.stringify(err));
      return false;
    }
  }
}



