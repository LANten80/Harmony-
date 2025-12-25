/**
 * 工单列表组件
 * 显示工单列表，支持编辑模式和添加操作
 */

import { TaskItemModel } from '../viewmodel/TaskItemModel';
import { TargetListItem } from './TargetListItem';
import { AlertDialog } from '@kit.ArkUI';

@Component
export struct TargetList {
  @Link targetData: TaskItemModel[];
  @State isEditMode: boolean = false;
  @State selectArray: boolean[] = [];
  @State clickIndex: number = -1;
  @State deleteDialogVisible: boolean = false;
  @State pendingDeleteIds: string[] = [];

  // 回调函数
  onAddClick: () => void = () => {};
  onProgressChange: () => void = () => {};
  onDeleteTasks: (taskIds: string[]) => Promise<void> = async () => {};

  /**
   * 切换编辑模式
   */
  toggleEditMode(): void {
    this.isEditMode = !this.isEditMode;
    // 切换模式时更新选中数组
    this.updateSelectArray();
  }

  /**
   * 初始化选中数组
   */
  aboutToAppear(): void {
    this.updateSelectArray();
  }

  /**
   * 更新选中数组
   */
  private updateSelectArray(): void {
    // 确保数组长度与数据长度一致
    const newLength = this.targetData.length;
    console.info('TargetList.updateSelectArray 更新选中数组，数据长度:', newLength);
    // 创建新数组，确保触发响应式更新
    this.selectArray = new Array<boolean>(newLength).fill(false);
    console.info('TargetList.updateSelectArray 选中数组已更新，长度:', this.selectArray.length);
  }

  /**
   * 获取选中的工单ID列表
   */
  private getSelectedTaskIds(): string[] {
    const selectedIds: string[] = [];
    this.targetData.forEach((item, index) => {
      if (index < this.selectArray.length && this.selectArray[index]) {
        selectedIds.push(item.id);
      }
    });
    return selectedIds;
  }

  /**
   * 是否有选中的工单
   */
  private hasSelectedTasks(): boolean {
    return this.selectArray.some(selected => selected);
  }

  /**
   * 确认删除选中的工单（内部方法，异步处理）
   */
  private async confirmDelete(idsToDelete: string[]): Promise<void> {
    console.info('TargetList.confirmDelete 确认删除工单:', idsToDelete);
    if (idsToDelete.length > 0) {
      try {
        // 先调用删除回调（异步，等待物理删除完成）
        await this.onDeleteTasks(idsToDelete);
        // 等待数据更新后，再更新UI状态
        // 清空选中状态
        this.updateSelectArray();
        // 退出编辑模式
        this.isEditMode = false;
        console.info('TargetList.confirmDelete UI状态已更新，删除完成');
      } catch (err) {
        console.error('TargetList.confirmDelete 删除操作失败:', JSON.stringify(err));
        // 删除失败时，不清空选中状态，保持编辑模式，让用户可以重试
        // 可以在这里添加用户提示，比如显示错误消息
        // 注意：不更新UI状态，让用户知道删除失败
      }
    }
  }

  /**
   * 显示删除确认对话框
   */
  showDeleteDialog(): void {
    const selectedIds = this.getSelectedTaskIds();
    if (selectedIds.length === 0) {
      return;
    }

    // 保存待删除的ID，并显示对话框
    this.pendingDeleteIds = [...selectedIds];
    this.deleteDialogVisible = true;
  }

  /**
   * 确认删除操作
   */
  handleDeleteConfirm(): void {
    if (this.pendingDeleteIds.length > 0) {
      this.confirmDelete(this.pendingDeleteIds);
      this.deleteDialogVisible = false;
      this.pendingDeleteIds = [];
    }
  }

  /**
   * 取消删除操作
   */
  handleDeleteCancel(): void {
    this.deleteDialogVisible = false;
    this.pendingDeleteIds = [];
  }

  /**
   * 全选/取消全选
   */
  toggleSelectAll(): void {
    const allSelected = this.selectArray.every(selected => selected);
    this.selectArray = new Array(this.targetData.length).fill(!allSelected);
  }

  build() {
    // 使用 Stack 作为根容器，包含主内容和对话框
    Stack() {
      Column() {
        // 列表标题区域
        Row() {
          if (this.isEditMode) {
            // 编辑模式下显示全选复选框
            Checkbox()
              .select(this.selectArray.length > 0 && this.selectArray.every(selected => selected))
              .selectedColor('#007DFF')
              .onChange((checked: boolean) => {
                this.toggleSelectAll();
              })
              .margin({ right: 8 })

            Text(`已选择 ${this.getSelectedTaskIds().length} 项`)
              .fontSize(14)
              .fontColor('#182431')
          } else {
            Text(`子目标 (${this.targetData.length})`)
              .fontSize(16)
              .fontWeight(FontWeight.Bold)
              .fontColor('#182431')
          }

          Blank()

          if (this.isEditMode) {
            // 编辑模式下显示删除按钮
            if (this.hasSelectedTasks()) {
              Text('删除')
                .fontSize(14)
                .fontColor('#FF3B30')
                .onClick(() => {
                  this.showDeleteDialog();
                })
                .margin({ right: 16 })
            }
          }

          Text(this.isEditMode ? '取消' : '编辑')
            .fontSize(14)
            .fontColor('#007DFF')
            .onClick(() => {
              this.toggleEditMode();
            })
        }
        .width('100%')
        .height(48)
        .padding({ left: 16, right: 16 })
        .backgroundColor('#FFFFFF')
        .borderRadius({ topLeft: 12, topRight: 12 })

        // 列表内容区域
        if (this.targetData.length > 0) {
          List() {
            ForEach(this.targetData, (item: TaskItemModel, index: number) => {
              ListItem() {
                TargetListItem({
                  taskItem: item,
                  isEditMode: this.isEditMode,
                  isSelected: (index < this.selectArray.length) ? this.selectArray[index] : false,
                  itemIndex: index,
                  clickIndex: $clickIndex,
                  onSelectedChange: (selected: boolean) => {
                    try {
                      // 校验索引有效性
                      if (index < 0 || index >= this.targetData.length) {
                        console.warn(`TargetList: 无效的选中索引 ${index}, 数据长度: ${this.targetData.length}`);
                        return;
                      }
                      // 确保数组长度足够
                      if (this.selectArray.length <= index) {
                        const newArray: boolean[] = new Array<boolean>(index + 1).fill(false);
                        this.selectArray.forEach((val, i) => {
                          newArray[i] = val;
                        });
                        this.selectArray = newArray;
                      }
                      this.selectArray[index] = selected;
                    } catch (err) {
                      console.error('TargetList: 选中状态更新异常:', JSON.stringify(err));
                    }
                  },
                  onProgressChange: () => {
                    this.onProgressChange();
                  }
                })
              }
            }, (item: TaskItemModel) => {
              // 确保唯一标识符有效
              if (!item || !item.id) {
                console.warn('TargetList: 工单项ID无效:', item);
                return `invalid-${Math.random()}`;
              }
              return item.id;
            })
          }
          .onAppear(() => {
            // 列表出现时检查并更新选中数组长度
            if (this.selectArray.length !== this.targetData.length) {
              this.updateSelectArray();
            }
          })
          .width('100%')
          .layoutWeight(1)
          .divider({ strokeWidth: 1, color: '#F0F0F0', startMargin: 16, endMargin: 16 })
          .edgeEffect(EdgeEffect.None)
        } else {
          Column() {
            Text('暂无工单')
              .fontSize(14)
              .fontColor('#999999')
          }
          .width('100%')
          .layoutWeight(1)
          .justifyContent(FlexAlign.Center)
        }

        // 底部操作区域
        if (!this.isEditMode) {
          Row() {
            Button('+ 添加问题单')
              .type(ButtonType.Normal)
              .backgroundColor('#007DFF')
              .fontColor('#FFFFFF')
              .fontSize(16)
              .width('100%')
              .height(48)
              .borderRadius(8)
              .onClick(() => {
                console.info('TargetList: 添加按钮被点击');
                this.onAddClick();
              })
          }
          .width('100%')
          .padding(16)
          .backgroundColor('#FFFFFF')
          .borderRadius({ bottomLeft: 12, bottomRight: 12 })
        } else {
          // 编辑模式下显示删除按钮
          Row() {
            Button('删除选中项')
              .type(ButtonType.Normal)
              .backgroundColor(this.hasSelectedTasks() ? '#FF3B30' : '#CCCCCC')
              .fontColor('#FFFFFF')
              .fontSize(16)
              .width('100%')
              .height(48)
              .borderRadius(8)
              .enabled(this.hasSelectedTasks())
              .onClick(() => {
                this.showDeleteDialog();
              })
          }
          .width('100%')
          .padding(16)
          .backgroundColor('#FFFFFF')
          .borderRadius({ bottomLeft: 12, bottomRight: 12 })
        }
      }
      .width('100%')
      .layoutWeight(1)
      .margin({ left: 16, right: 16, top: 12 })
      .backgroundColor('#FFFFFF')
      .borderRadius(12)

      // 删除确认对话框（带遮罩层）
      if (this.deleteDialogVisible) {
        // 半透明遮罩层，遮挡后面的内容
        Column()
          .width('100%')
          .height('100%')
          .backgroundColor('#000000')
          .opacity(0.6)
          .onClick(() => {
            // 点击遮罩层关闭对话框
            this.handleDeleteCancel();
          })
        
        // 自定义对话框内容（在遮罩层之上显示）
        Column() {
          Column() {
            // 标题
            Text('确认删除')
              .fontSize(20)
              .fontWeight(FontWeight.Bold)
              .fontColor('#182431')
              .margin({ top: 24, bottom: 16 })
            
            // 内容
            Text(`确定要删除选中的 ${this.pendingDeleteIds.length} 个工单吗？\n此操作不可恢复。`)
              .fontSize(16)
              .fontColor('#666666')
              .textAlign(TextAlign.Center)
              .lineHeight(24)
              .margin({ bottom: 32 })
            
            // 按钮区域
            Row() {
              // 取消按钮
              Button('取消')
                .type(ButtonType.Normal)
                .backgroundColor('#F0F0F0')
                .fontColor('#182431')
                .fontSize(16)
                .width('48%')
                .height(48)
                .borderRadius(8)
                .onClick(() => {
                  this.handleDeleteCancel();
                })
              
              // 删除按钮（更明显）
              Button('删除')
                .type(ButtonType.Normal)
                .backgroundColor('#FF3B30')
                .fontColor('#FFFFFF')
                .fontSize(16)
                .fontWeight(FontWeight.Bold)
                .width('48%')
                .height(48)
                .borderRadius(8)
                .onClick(() => {
                  this.handleDeleteConfirm();
                })
            }
            .width('100%')
            .justifyContent(FlexAlign.SpaceBetween)
            .margin({ bottom: 24 })
          }
          .width('80%')
          .backgroundColor('#FFFFFF')
          .borderRadius(16)
          .padding({ left: 24, right: 24 })
          .shadow({ radius: 24, color: '#33000000', offsetX: 0, offsetY: 8 })
        }
        .width('100%')
        .height('100%')
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center)
      }
    }
    .width('100%')
    .layoutWeight(1)
  }
}

