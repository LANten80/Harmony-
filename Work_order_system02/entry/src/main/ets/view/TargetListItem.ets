/**
 * 工单项组件
 * 显示单个工单信息，支持展开/折叠和编辑模式
 */

import { TaskItemModel } from '../viewmodel/TaskItemModel';
import { formatDateTime } from '../common/utils/DateUtil';
import { ProgressEditPanel } from './ProgressEditPanel';
import { DataModel } from '../viewmodel/DataModel';

@Component
export struct TargetListItem {
  @Prop taskItem: TaskItemModel = new TaskItemModel('', '');
  @Prop isEditMode: boolean = false;
  @Prop isSelected: boolean = false;
  @Prop itemIndex: number = -1; // 当前项在列表中的索引
  @Link clickIndex: number;
  @State isExpanded: boolean = false;
  private lastClickIndex: number = -1;

  // 回调函数
  onSelectedChange: (selected: boolean) => void = () => {};
  onProgressChange: () => void = () => {};

  // 数据模型实例
  private dataModel: DataModel = DataModel.getInstance();

  /**
   * 监听点击索引变化，实现互斥展开
   */
  onClickIndexChanged(): void {
    // 如果点击的不是当前项，则折叠
    if (this.clickIndex !== this.itemIndex && this.isExpanded) {
      this.isExpanded = false;
    }
  }

  /**
   * 切换展开状态
   */
  toggleExpand(): void {
    if (this.isEditMode) {
      return; // 编辑模式下不允许展开
    }

    if (this.isExpanded) {
      this.isExpanded = false;
      this.clickIndex = -1;
      this.lastClickIndex = -1;
    } else {
      this.isExpanded = true;
      this.clickIndex = this.itemIndex;
      this.lastClickIndex = this.itemIndex;
    }
  }

  /**
   * 更新进度（异步，通过后端API）
   */
  async updateProgress(progress: number): Promise<void> {
    console.info('TargetListItem.updateProgress: 开始更新进度, taskId:', this.taskItem.id, 'progress:', progress);
    const success = await this.dataModel.updateProgress(this.taskItem.id, progress);
    console.info('TargetListItem.updateProgress: 更新结果:', success);
    if (success) {
      // 更新本地 taskItem 的进度值，确保UI立即显示新值
      this.taskItem.progressValue = progress;
      this.taskItem.updateDate = new Date().toISOString();
      console.info('TargetListItem.updateProgress: 本地数据已更新, 新进度值:', this.taskItem.progressValue);
      
      this.isExpanded = false;
      this.clickIndex = -1;
      this.lastClickIndex = -1;
      
      // 通知父组件数据已更新
      console.info('TargetListItem.updateProgress: 通知父组件数据已更新');
      this.onProgressChange();
    } else {
      console.error('TargetListItem.updateProgress: 更新失败');
    }
  }

  /**
   * 获取进度显示颜色
   */
  private getProgressColor(): string {
    if (this.taskItem.progressValue === 100) {
      return '#00C853';
    } else if (this.taskItem.progressValue > 0) {
      return '#FF9500';
    } else {
      return '#999999';
    }
  }

  /**
   * 获取透明度
   */
  private getOpacity(): number {
    return this.taskItem.progressValue === 100 ? 0.6 : 1.0;
  }

  build() {
    Stack() {
      Column() {
        // 工单信息行
        Row() {
          // 编辑模式下的复选框
          if (this.isEditMode) {
            Checkbox()
              .select(this.isSelected)
              .selectedColor('#007DFF')
              .onChange((checked: boolean) => {
                this.onSelectedChange(checked);
              })
              .margin({ right: 12 })
          } else {
            // 正常模式下的图标
            Image($r('app.media.foreground'))
              .width(24)
              .height(24)
              .margin({ right: 12 })
          }

          Column() {
            Text(this.taskItem?.taskName || '未命名工单')
              .fontSize(16)
              .fontWeight(FontWeight.Medium)
              .fontColor('#182431')
              .maxLines(2)
              .textOverflow({ overflow: TextOverflow.Ellipsis })
              .opacity(this.getOpacity())
              .width('100%')
              .textAlign(TextAlign.Start)
              .margin({ bottom: 4 })

            Text(`最后更新：${this.taskItem?.updateDate ? formatDateTime(this.taskItem.updateDate) : '未知'}`)
              .fontSize(12)
              .fontColor('#999999')
              .width('100%')
              .textAlign(TextAlign.Start)
          }
          .alignItems(HorizontalAlign.Start)
          .layoutWeight(1)
          .width('100%')
          .height('100%')
          .justifyContent(FlexAlign.Start)

          Text(`${this.taskItem?.progressValue ?? 0}%`)
            .fontSize(16)
            .fontWeight(FontWeight.Bold)
            .fontColor(this.getProgressColor())
        }
        .width('100%')
        .height(72)
        .padding({ left: 16, right: 16, top: 12, bottom: 12 })
        .alignItems(VerticalAlign.Center)
        .onClick(() => {
          if (!this.isEditMode) {
            this.toggleExpand();
          }
        })

        // 进度编辑面板（展开时显示）
        if (this.isExpanded && !this.isEditMode) {
          ProgressEditPanel({
            currentProgress: this.taskItem.progressValue,
            onCancel: () => {
              this.isExpanded = false;
              this.clickIndex = -1;
              this.lastClickIndex = -1;
            },
            onClickOK: async (progress: number) => {
              await this.updateProgress(progress);
            }
          })
        }
      }
      .width('100%')
      .backgroundColor('#FFFFFF')
      .onAppear(() => {
        // 组件出现时检查 clickIndex 是否变化
        if (this.lastClickIndex !== this.clickIndex) {
          this.onClickIndexChanged();
          this.lastClickIndex = this.clickIndex;
        }
      })
    }
    .width('100%')
  }
}

