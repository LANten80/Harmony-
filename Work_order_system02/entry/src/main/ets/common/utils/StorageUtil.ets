/**
 * 存储工具类
 * 使用 Preferences 进行数据持久化
 */

import { preferences } from '@kit.ArkData';
import { common } from '@kit.AbilityKit';
import { TaskData } from '../types/TaskData';

export class StorageUtil {
  private static readonly PREF_NAME = 'WorkOrderData';
  private static readonly DATA_KEY = 'taskList';

  /**
   * 保存工单数据列表
   * @param context 应用上下文
   * @param taskList 工单数据列表
   */
  static async saveTaskList(context: common.UIAbilityContext, taskList: TaskData[]): Promise<boolean> {
    try {
      const dataPreferences = await preferences.getPreferences(context, StorageUtil.PREF_NAME);
      const jsonString = JSON.stringify(taskList);
      await dataPreferences.put(StorageUtil.DATA_KEY, jsonString);
      await dataPreferences.flush();
      return true;
    } catch (err) {
      console.error('Failed to save task list:', JSON.stringify(err));
      return false;
    }
  }

  /**
   * 加载工单数据列表
   * @param context 应用上下文
   */
  static async loadTaskList(context: common.UIAbilityContext): Promise<TaskData[]> {
    try {
      const dataPreferences = await preferences.getPreferences(context, StorageUtil.PREF_NAME);
      const jsonString = await dataPreferences.get(StorageUtil.DATA_KEY, '[]') as string;
      const parsed: TaskData[] = JSON.parse(jsonString) as TaskData[];
      // 确保返回的是数组类型
      if (Array.isArray(parsed)) {
        return parsed;
      }
      return [];
    } catch (err) {
      console.error('Failed to load task list:', JSON.stringify(err));
      return [];
    }
  }

  /**
   * 清空所有数据
   * @param context 应用上下文
   */
  static async clearAll(context: common.UIAbilityContext): Promise<boolean> {
    try {
      const dataPreferences = await preferences.getPreferences(context, StorageUtil.PREF_NAME);
      await dataPreferences.clear();
      await dataPreferences.flush();
      return true;
    } catch (err) {
      console.error('Failed to clear data:', JSON.stringify(err));
      return false;
    }
  }
}

