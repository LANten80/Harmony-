/**
 * 存储工具类
 * 使用 Preferences 进行数据持久化
 * 
 * 注意：工单数据已改为使用后端API，本地存储方法已移除
 */

import { preferences } from '@kit.ArkData';
import { common } from '@kit.AbilityKit';

export class StorageUtil {
  /**
   * 清空所有数据（保留此方法用于其他用途）
   * @param context 应用上下文
   * @param prefName Preferences名称（可选）
   */
  static async clearAll(context: common.UIAbilityContext, prefName?: string): Promise<boolean> {
    try {
      const name = prefName || 'WorkOrderData';
      const dataPreferences = await preferences.getPreferences(context, name);
      await dataPreferences.clear();
      await dataPreferences.flush();
      return true;
    } catch (err) {
      console.error('Failed to clear data:', JSON.stringify(err));
      return false;
    }
  }
}

