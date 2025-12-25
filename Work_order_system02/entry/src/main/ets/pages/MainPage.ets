/**
 * 主页面
 * 应用入口页面，集成所有功能组件
 */

import { TaskItemModel } from '../viewmodel/TaskItemModel';
import { DataModel } from '../viewmodel/DataModel';
import { TargetList } from '../view/TargetList';
import { AddTargetDialog } from '../view/AddTargetDialog';
import { AuthServiceWithHttp } from '../viewmodel/AuthServiceWithHttp';
import { UserModel } from '../viewmodel/UserModel';
import { formatDateTime, formatDate } from '../common/utils/DateUtil';
import { router } from '@kit.ArkUI';
import { common } from '@kit.AbilityKit';

/**
 * getContext 函数类型定义
 */
type GetContextFunction = () => common.UIAbilityContext | undefined;

@Entry
@Component
struct MainPage {
  // 页面级状态
  @State targetData: TaskItemModel[] = [];

  // 全局状态提供
  @Provide overAllProgressChanged: number = 0;

  // 弹窗控制器（在 aboutToAppear 中初始化）
  dialogController?: CustomDialogController;

  // 数据模型实例
  private dataModel: DataModel = DataModel.getInstance();

  // 认证服务实例
  private authService: AuthServiceWithHttp = AuthServiceWithHttp.getInstance();

  // 当前登录用户
  @State currentUser: UserModel | null = null;

  // 应用上下文（使用声明式方式获取）
  private context: common.UIAbilityContext | null = null;
  
  // 标记是否已经初始化过数据
  private dataInitialized: boolean = false;

  /**
   * 页面即将显示时调用
   */
  async aboutToAppear(): Promise<void> {
    console.info('MainPage.aboutToAppear: 页面初始化开始');
    
    try {
      // 初始化弹窗控制器（必须在 aboutToAppear 中初始化，避免循环引用）
      this.dialogController = new CustomDialogController({
        builder: AddTargetDialog({
          controller: this.dialogController,
          onClickOk: async (taskName: string) => {
            await this.saveTask(taskName);
          }
        }),
        alignment: DialogAlignment.Bottom,
        customStyle: true,
        autoCancel: true
      });
      console.info('MainPage.aboutToAppear: 弹窗控制器初始化完成');
    } catch (err) {
      console.error('MainPage.aboutToAppear: 弹窗控制器初始化失败:', JSON.stringify(err));
    }

    // 初始化上下文（使用声明式方式）
    this.initContext();

    // 检查登录状态（必须等待完成，确保token已恢复）
    await this.checkLoginStatus();
    
    // 只在首次初始化时从存储加载数据
    if (!this.dataInitialized) {
      // 加载数据并注册监听器
      await this.dataModel.loadDataFromStorage();
      this.loadData();
      console.info('MainPage.aboutToAppear: 初始数据加载完成，工单数:', this.targetData.length);
      this.dataInitialized = true;
    } else {
      // 已经初始化过，只刷新内存中的数据（不重新从存储加载）
      this.loadData();
      console.info('MainPage.aboutToAppear: 页面重新显示，刷新内存数据，工单数:', this.targetData.length);
    }
    
    // 注册数据变更监听器（避免重复注册）
    this.dataModel.addChangeListener(() => {
      console.info('MainPage: 数据变更监听器触发，刷新数据');
      this.loadData();
    });
    
    console.info('MainPage.aboutToAppear: 页面初始化完成');
  }

  /**
   * 检查登录状态（同时恢复token）
   */
  private async checkLoginStatus(): Promise<void> {
    try {
      // checkLoginStatus 内部会恢复 token
      const user = await this.authService.checkLoginStatus();
      if (user) {
        this.currentUser = user;
        console.info('MainPage.checkLoginStatus: 登录状态检查成功，用户已登录');
      } else {
        console.warn('MainPage.checkLoginStatus: 用户未登录，跳转到登录页');
        // 未登录，跳转到登录页
        try {
          router.replaceUrl({
            url: 'pages/LoginPage'
          });
        } catch (routeErr) {
          console.error('MainPage: 跳转登录页失败:', JSON.stringify(routeErr));
        }
      }
    } catch (err) {
      console.error('MainPage.checkLoginStatus: 检查登录状态失败:', JSON.stringify(err));
      try {
        router.replaceUrl({
          url: 'pages/LoginPage'
        });
      } catch (routeErr) {
        console.error('MainPage: 跳转登录页失败:', JSON.stringify(routeErr));
      }
    }
  }

  /**
   * 处理退出登录
   */
  private async handleLogout(): Promise<void> {
    try {
      await this.authService.logout();
      // 跳转到登录页
      try {
        router.replaceUrl({
          url: 'pages/LoginPage'
        });
      } catch (routeErr) {
        console.error('MainPage: 跳转登录页失败:', JSON.stringify(routeErr));
      }
    } catch (err) {
      console.error('MainPage.handleLogout: 退出登录失败:', JSON.stringify(err));
    }
  }

  /**
   * 格式化手机号（中间4位隐藏）
   */
  private formatPhone(phone: string): string {
    if (!phone || phone.length !== 11) {
      return phone;
    }
    return `${phone.substring(0, 3)}****${phone.substring(7)}`;
  }

  /**
   * 初始化上下文（使用声明式方式）
   */
  private initContext(): void {
    try {
      // 使用声明式方式获取上下文
      // 在 @Entry 组件中，尝试使用 getContext（作为备用方案）
      // 注意：getContext() 已弃用，但当前版本仍可使用
      const contextGetter = getContext as GetContextFunction;
      const contextValue: common.UIAbilityContext | undefined = contextGetter();
      
      if (contextValue) {
        this.context = contextValue;
        this.dataModel.setContext(contextValue);
        this.authService.setContext(contextValue);
        console.info('MainPage.initContext: 获取上下文成功');
        // 只在首次初始化时从存储加载数据
        if (!this.dataInitialized) {
          // 从存储加载数据
          this.dataModel.loadDataFromStorage().then(() => {
            this.loadData();
            this.dataInitialized = true;
          }).catch(() => {
            console.warn('MainPage.initContext: 从存储加载数据失败，使用默认数据');
            this.loadData();
            this.dataInitialized = true;
          });
        } else {
          // 已经初始化过，只使用内存中的数据
          this.loadData();
        }
      } else {
        console.warn('MainPage.initContext: 获取上下文失败，使用默认数据');
        if (!this.dataInitialized) {
          this.loadData();
          this.dataInitialized = true;
        }
      }
    } catch (err) {
      console.error('MainPage.initContext: 初始化上下文失败:', JSON.stringify(err));
      this.loadData();
    }
  }

  /**
   * 加载数据
   */
  loadData(): void {
    try {
      const data = this.dataModel.getData();
      console.info('MainPage.loadData 加载数据，工单数:', data.length);
      
      // 校验数据有效性
      if (!data || !Array.isArray(data)) {
        console.warn('MainPage.loadData: 数据无效，使用空数组');
        this.targetData = [];
        return;
      }

      // 确保数据正确更新，使用深拷贝触发UI更新
      // 使用展开运算符创建新数组，确保触发响应式更新
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
          console.error('MainPage.loadData: 创建工单对象失败:', JSON.stringify(err));
          return null;
        }
      }).filter(item => item !== null) as TaskItemModel[]];
      
      console.info('MainPage.loadData 数据加载完成，targetData长度:', this.targetData.length);
    } catch (err) {
      console.error('MainPage.loadData 加载数据异常:', JSON.stringify(err));
      this.targetData = [];
    }
  }

  /**
   * 保存工单（异步，通过后端API）
   */
  async saveTask(taskName: string): Promise<void> {
    console.info('MainPage.saveTask: 方法被调用，工单名称: ' + taskName);
    if (!taskName || taskName.trim().length === 0) {
      console.warn('MainPage.saveTask: 工单名称为空，取消添加');
      return;
    }

    console.info('MainPage.saveTask: 开始添加工单: ' + taskName + ', 当前工单数: ' + String(this.targetData.length));
    try {
      const success = await this.dataModel.addData(taskName);
      console.info('MainPage.saveTask: addData 返回结果: ' + String(success));
      
      if (success) {
        console.info('MainPage.saveTask: 工单添加成功，开始刷新数据');
        // 立即刷新数据，确保UI更新
        await this.dataModel.reloadDataFromStorage();
        this.loadData();
        this.overAllProgressChanged++;
        console.info('MainPage.saveTask: 数据刷新完成，当前工单数: ' + String(this.targetData.length));
        console.info('MainPage.saveTask: 当前工单ID列表: ' + JSON.stringify(this.targetData.map(item => item.id)));
      } else {
        console.error('MainPage.saveTask: 工单添加失败，请检查网络连接和后端服务');
        // 可以在这里添加用户提示，比如显示错误消息
      }
    } catch (err) {
      console.error('MainPage.saveTask: 添加工单异常: ' + JSON.stringify(err));
      if (err instanceof Error) {
        console.error('MainPage.saveTask: 错误信息: ' + err.message);
      }
    }
  }

  /**
   * 刷新数据
   */
  refreshData(): void {
    this.loadData();
    this.overAllProgressChanged++;
  }

  /**
   * 打开添加工单弹窗
   */
  openAddDialog(): void {
    console.info('MainPage.openAddDialog: 准备打开添加弹窗');
    if (this.dialogController) {
      console.info('MainPage.openAddDialog: 弹窗控制器存在，打开弹窗');
      this.dialogController.open();
    } else {
      console.error('MainPage.openAddDialog: 弹窗控制器不存在，无法打开弹窗');
    }
  }

  /**
   * 删除工单（异步操作，确保物理删除完成）
   */
  async deleteTasks(taskIds: string[]): Promise<void> {
    // 校验输入参数
    if (!taskIds || taskIds.length === 0) {
      console.warn('MainPage.deleteTasks: 删除ID列表为空');
      return;
    }

    // 校验数据源有效性
    if (!this.targetData || this.targetData.length === 0) {
      console.warn('MainPage.deleteTasks: 当前没有工单数据');
      return;
    }

    console.info('MainPage.deleteTasks 准备删除工单:', taskIds, '当前工单数:', this.targetData.length);
    console.info('MainPage.deleteTasks 删除前数据:', this.targetData.map(item => item.id));
    
    try {
      // 执行删除操作（异步，等待物理删除完成）
      const deletedCount = await this.dataModel.deleteTasks(taskIds);
      console.info('MainPage.deleteTasks 删除结果:', deletedCount, '个工单');
      
      if (deletedCount > 0) {
        // 立即刷新数据，使用深拷贝触发UI更新
        this.loadData();
        // 触发全局状态更新
        this.overAllProgressChanged++;
        console.info('MainPage.deleteTasks 删除完成，数据已刷新，当前工单数:', this.targetData.length);
        console.info('MainPage.deleteTasks 删除后数据:', this.targetData.map(item => item.id));
        
        // 验证删除结果：确保删除的工单不再出现在数据中
        const deletedStillExist = taskIds.filter(id => this.targetData.some(item => item.id === id));
        if (deletedStillExist.length > 0) {
          console.error('MainPage.deleteTasks: 警告！删除的工单仍在数据中:', deletedStillExist);
        } else {
          console.info('MainPage.deleteTasks: 验证通过，删除的工单已从数据中移除');
        }
      } else {
        console.warn('MainPage.deleteTasks 删除失败，未找到要删除的工单');
      }
    } catch (err) {
      console.error('MainPage.deleteTasks 删除操作异常:', JSON.stringify(err));
      // 删除失败时，可以选择提示用户或重试
      // 这里不恢复UI，因为用户已经看到删除效果
    }
  }

  /**
   * 监听进度变化
   * 注意：@Watch 不能直接装饰方法，需要在状态变化时手动调用
   */

  build() {
    Column() {
      // 标题栏
      Row() {
        Text('工单管理系统')
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
          .fontColor('#182431')

        Blank()

        // 统计页面入口
        Image($r('app.media.foreground'))
          .width(24)
          .height(24)
          .onClick(() => {
            router.pushUrl({
              url: 'pages/StatisticsPage'
            }).catch((err: Error) => {
              console.error('MainPage: 跳转统计页面失败:', JSON.stringify(err));
            });
          })
          .margin({ right: 16 })

        // 刷新按钮
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

      // 用户信息卡片
      if (this.currentUser) {
        Column() {
          // 欢迎区域
          Row() {
            Image($r('app.media.foreground'))
              .width(48)
              .height(48)
              .borderRadius(24)
              .margin({ right: 12 })

            Column() {
              Text('欢迎回来！')
                .fontSize(14)
                .fontColor('#666666')
                .margin({ bottom: 4 })

              Text(this.currentUser.username)
                .fontSize(18)
                .fontWeight(FontWeight.Bold)
                .fontColor('#182431')
            }
            .alignItems(HorizontalAlign.Start)
            .layoutWeight(1)
          }
          .width('100%')
          .padding(16)
          .margin({ top: 12, bottom: 12 })

          // 账户信息
          Column() {
            Text('账户信息')
              .fontSize(16)
              .fontWeight(FontWeight.Bold)
              .fontColor('#182431')
              .alignSelf(ItemAlign.Start)
              .margin({ bottom: 16 })

            // 用户名
            Row() {
              Text('用户名：')
                .fontSize(14)
                .fontColor('#666666')
              Text(this.currentUser.username)
                .fontSize(14)
                .fontColor('#182431')
            }
            .width('100%')
            .justifyContent(FlexAlign.SpaceBetween)
            .margin({ bottom: 12 })

            // 手机号（脱敏）
            Row() {
              Text('手机号：')
                .fontSize(14)
                .fontColor('#666666')
              Text(this.formatPhone(this.currentUser.phone))
                .fontSize(14)
                .fontColor('#182431')
            }
            .width('100%')
            .justifyContent(FlexAlign.SpaceBetween)
            .margin({ bottom: 12 })

            // 注册时间
            Row() {
              Text('注册时间：')
                .fontSize(14)
                .fontColor('#666666')
              Text(formatDate(this.currentUser.registerTime))
                .fontSize(14)
                .fontColor('#182431')
            }
            .width('100%')
            .justifyContent(FlexAlign.SpaceBetween)
            .margin({ bottom: 12 })

            // 最后登录时间
            Row() {
              Text('最后登录：')
                .fontSize(14)
                .fontColor('#666666')
              Text(formatDateTime(this.currentUser.lastLoginTime))
                .fontSize(14)
                .fontColor('#182431')
            }
            .width('100%')
            .justifyContent(FlexAlign.SpaceBetween)
            .margin({ bottom: 16 })

            // 退出登录按钮
            Button('退出登录')
              .type(ButtonType.Normal)
              .backgroundColor('#FF3B30')
              .fontColor('#FFFFFF')
              .fontSize(16)
              .width('100%')
              .height(48)
              .borderRadius(8)
              .onClick(() => {
                this.handleLogout();
              })
          }
          .width('100%')
          .padding(16)
          .backgroundColor('#FFFFFF')
          .borderRadius(12)
          .margin({ left: 16, right: 16, bottom: 12 })
        }
        .width('100%')
      }

      // 工单列表区
      TargetList({
        targetData: $targetData,
        onAddClick: () => {
          this.openAddDialog();
        },
        onProgressChange: () => {
          console.info('MainPage.onProgressChange: 进度变化回调被触发');
          // 强制刷新数据
          this.loadData();
          this.overAllProgressChanged++;
          console.info('MainPage.onProgressChange: 数据刷新完成, 当前工单数:', this.targetData.length);
        },
        onDeleteTasks: async (taskIds: string[]) => {
          console.info('MainPage onDeleteTasks 回调被触发:', taskIds);
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
    .height('100%')
    .backgroundColor('#F5F5F5')
    .onAppear(() => {
      // 如果上下文未初始化，再次尝试初始化
      if (!this.context) {
        this.initContext();
      } else {
        // 上下文已存在，只刷新内存中的数据（不重新从存储加载，避免覆盖删除操作）
        this.loadData();
      }
    })
  }
}

