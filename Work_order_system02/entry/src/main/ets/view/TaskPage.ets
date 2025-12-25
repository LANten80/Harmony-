/**
 * 工单管理页面组件
 * 显示工单列表和进度管理
 * 注意：这是一个组件，不是独立页面，不需要 @Entry 装饰器
 */

import { TaskItemModel } from '../viewmodel/TaskItemModel';
import { DataModel } from '../viewmodel/DataModel';
import { TargetInformation } from './TargetInformation';
import { TargetList } from './TargetList';
import { AddTargetDialog } from './AddTargetDialog';
import { common } from '@kit.AbilityKit';

/**
 * getContext 函数类型定义
 */
type GetContextFunction = () => common.UIAbilityContext | undefined;

@Component
export struct TaskPage {
  // 页面级状态
  @State targetData: TaskItemModel[] = [];
  @State totalTasksNumber: number = 0;
  @State completedTasksNumber: number = 0;
  @State overallProgress: number = 0;

  // 全局状态提供
  @Provide overAllProgressChanged: number = 0;

  // 弹窗控制器（在 aboutToAppear 中初始化）
  dialogController?: CustomDialogController;

  // 数据模型实例
  private dataModel: DataModel = DataModel.getInstance();

  // 应用上下文（使用声明式方式获取）
  private context: common.UIAbilityContext | null = null;
  
  // 标记是否已经初始化过数据
  private dataInitialized: boolean = false;

  /**
   * 页面即将显示时调用
   */
  async aboutToAppear(): Promise<void> {
    console.info('TaskPage.aboutToAppear: 页面初始化开始');
    
    try {
      // 初始化弹窗控制器（必须在 aboutToAppear 中初始化，避免循环引用）
      this.dialogController = new CustomDialogController({
        builder: AddTargetDialog({
          controller: this.dialogController,
          onClickOk: (taskName: string) => {
            this.saveTask(taskName);
          }
        }),
        alignment: DialogAlignment.Bottom,
        customStyle: true,
        autoCancel: true
      });
      console.info('TaskPage.aboutToAppear: 弹窗控制器初始化完成');
    } catch (err) {
      console.error('TaskPage.aboutToAppear: 弹窗控制器初始化失败:', JSON.stringify(err));
    }

    // 初始化上下文（使用声明式方式）
    this.initContext();
    
    // 注册数据变更监听器
    this.dataModel.addChangeListener(() => {
      console.info('TaskPage: 数据变更监听器触发，刷新数据');
      this.loadData();
      this.calculateStatistics();
    });
  }

  /**
   * 初始化上下文（使用声明式方式）
   */
  private initContext(): void {
    try {
      // 使用声明式方式获取上下文
      const contextGetter = getContext as GetContextFunction;
      const contextValue: common.UIAbilityContext | undefined = contextGetter();

      if (contextValue) {
        this.context = contextValue;
        this.dataModel.setContext(contextValue);
        console.info('TaskPage.initContext: 获取上下文成功');
        // 只在首次初始化时从存储加载数据
        if (!this.dataInitialized) {
          // 从存储加载数据
          this.dataModel.loadDataFromStorage().then(() => {
            this.loadData();
            this.calculateStatistics();
            this.dataInitialized = true;
          }).catch(() => {
            console.warn('TaskPage.initContext: 从存储加载数据失败，使用默认数据');
            this.loadData();
            this.calculateStatistics();
            this.dataInitialized = true;
          });
        } else {
          // 已经初始化过，只使用内存中的数据
          this.loadData();
          this.calculateStatistics();
        }
      } else {
        console.warn('TaskPage.initContext: 获取上下文失败，使用默认数据');
        if (!this.dataInitialized) {
          this.loadData();
          this.calculateStatistics();
          this.dataInitialized = true;
        } else {
          this.loadData();
          this.calculateStatistics();
        }
      }
    } catch (err) {
      console.error('TaskPage.initContext: 初始化上下文失败:', JSON.stringify(err));
      if (!this.dataInitialized) {
        this.loadData();
        this.calculateStatistics();
        this.dataInitialized = true;
      } else {
        this.loadData();
        this.calculateStatistics();
      }
    }
  }

  /**
   * 加载数据
   */
  loadData(): void {
    try {
      const data = this.dataModel.getData();
      console.info('TaskPage.loadData 加载数据，工单数:', data.length);
      
      // 校验数据有效性
      if (!data || !Array.isArray(data)) {
        console.warn('TaskPage.loadData: 数据无效，使用空数组');
        this.targetData = [];
        this.calculateStatistics();
        return;
      }

      // 确保数据正确更新，使用深拷贝触发UI更新
      this.targetData = [...data.map(item => {
        try {
          // 创建新对象，确保每个属性都被正确复制
          const newItem = new TaskItemModel(item.taskName, item.description, item.progressValue, item.priority);
          newItem.id = item.id;
          newItem.status = item.status;
          newItem.createDate = item.createDate;
          newItem.updateDate = item.updateDate;
          newItem.dueDate = item.dueDate;
          newItem.assignee = item.assignee;
          newItem.category = item.category;
          newItem.tags = [...item.tags];
          return newItem;
        } catch (err) {
          console.error('TaskPage.loadData: 创建工单对象失败:', JSON.stringify(err));
          return item;
        }
      })];
      
      this.calculateStatistics();
      console.info('TaskPage.loadData: 数据加载完成，工单数:', this.targetData.length);
    } catch (err) {
      console.error('TaskPage.loadData: 加载数据异常:', JSON.stringify(err));
      this.targetData = [];
      this.calculateStatistics();
    }
  }

  /**
   * 计算统计数据
   */
  calculateStatistics(): void {
    try {
      const stats = this.dataModel.getStatistics();
      this.totalTasksNumber = stats.total;
      this.completedTasksNumber = stats.completed;
      this.overallProgress = stats.averageProgress;
      console.info('TaskPage.calculateStatistics: 统计计算完成', stats);
    } catch (err) {
      console.error('TaskPage.calculateStatistics: 统计计算异常:', JSON.stringify(err));
    }
  }

  /**
   * 刷新数据
   */
  refreshData(): void {
    console.info('TaskPage.refreshData: 刷新数据');
    this.loadData();
  }

  /**
   * 保存工单
   */
  saveTask(taskName: string): void {
    console.info('TaskPage.saveTask: 方法被调用，工单名称:', taskName);
    if (!taskName || taskName.trim().length === 0) {
      console.warn('TaskPage.saveTask: 工单名称为空，取消添加');
      return;
    }

    console.info('TaskPage.saveTask: 开始添加工单:', taskName, '当前工单数:', this.targetData.length);
    const success = this.dataModel.addData(taskName);
    console.info('TaskPage.saveTask: addData 返回结果:', success);
    
    if (success) {
      console.info('TaskPage.saveTask: 工单添加成功，开始刷新数据');
      // 立即刷新数据，确保UI更新
      this.loadData();
      this.calculateStatistics();
      this.overAllProgressChanged++;
      console.info('TaskPage.saveTask: 数据刷新完成，当前工单数:', this.targetData.length);
      console.info('TaskPage.saveTask: 当前工单ID列表:', this.targetData.map(item => item.id));
    } else {
      console.warn('TaskPage.saveTask: 工单添加失败');
    }
  }

  /**
   * 打开添加工单弹窗
   */
  openAddDialog(): void {
    console.info('TaskPage.openAddDialog: 准备打开添加弹窗');
    if (this.dialogController) {
      console.info('TaskPage.openAddDialog: 弹窗控制器存在，打开弹窗');
      this.dialogController.open();
    } else {
      console.error('TaskPage.openAddDialog: 弹窗控制器不存在，无法打开弹窗');
    }
  }

  /**
   * 删除工单
   */
  async deleteTasks(taskIds: string[]): Promise<void> {
    console.info('TaskPage.deleteTasks: 开始删除工单, taskIds:', taskIds);
    try {
      await this.dataModel.deleteTasks(taskIds);
      // 删除后刷新数据
      this.loadData();
      this.calculateStatistics();
      this.overAllProgressChanged++;
      console.info('TaskPage.deleteTasks: 删除完成，当前工单数:', this.targetData.length);
    } catch (err) {
      console.error('TaskPage.deleteTasks 删除操作异常:', JSON.stringify(err));
    }
  }

  build() {
    Column() {
      // 标题栏
      Row() {
        Text('工单管理')
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
          .fontColor('#182431')

        Blank()

        Image($r('app.media.foreground'))
          .width(24)
          .height(24)
          .onClick(() => {
            this.refreshData();
          })
      }
      .width('100%')
      .height(56)
      .padding({ left: 16, right: 16 })
      .backgroundColor('#FFFFFF')

      // 整体进度展示区
      TargetInformation({
        totalTasksNumber: this.totalTasksNumber,
        completedTasksNumber: this.completedTasksNumber,
        overallProgress: this.overallProgress
      })

      // 工单列表区
      TargetList({
        targetData: $targetData,
        onAddClick: () => {
          this.openAddDialog();
        },
        onProgressChange: () => {
          console.info('TaskPage.onProgressChange: 进度变化回调被触发');
          // 强制刷新数据
          this.loadData();
          this.calculateStatistics();
          this.overAllProgressChanged++;
          console.info('TaskPage.onProgressChange: 数据刷新完成, 当前工单数:', this.targetData.length);
        },
        onDeleteTasks: async (taskIds: string[]) => {
          console.info('TaskPage onDeleteTasks 回调被触发:', taskIds);
          await this.deleteTasks(taskIds);
          // 删除后强制刷新列表（deleteTasks内部已刷新，这里确保再次刷新）
          this.loadData();
        }
      })

      // 底部操作提示
      Text('提示：点击工单项展开进度设置面板')
        .fontSize(12)
        .fontColor('#999999')
        .margin({ top: 16, bottom: 16 })
    }
    .width('100%')
    .layoutWeight(1)
    .backgroundColor('#F5F5F5')
    .onAppear(() => {
      // 如果上下文未初始化，再次尝试初始化
      if (!this.context) {
        this.initContext();
      } else {
        // 上下文已存在，只刷新内存中的数据（不重新从存储加载，避免覆盖删除操作）
        this.loadData();
        this.calculateStatistics();
      }
    })
  }
}



