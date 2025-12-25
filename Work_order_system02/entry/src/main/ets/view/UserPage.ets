/**
 * 用户页面组件
 * 显示用户信息和账户管理
 * 注意：这是一个组件，不是独立页面，不需要 @Entry 装饰器
 */

import { AuthService } from '../viewmodel/AuthService';
import { UserModel } from '../viewmodel/UserModel';
import { formatDateTime, formatDate } from '../common/utils/DateUtil';
import { router } from '@kit.ArkUI';
import { common } from '@kit.AbilityKit';

/**
 * getContext 函数类型定义
 */
type GetContextFunction = () => common.UIAbilityContext | undefined;

@Component
export struct UserPage {
  // 当前登录用户
  @State currentUser: UserModel | null = null;

  // 认证服务实例
  private authService: AuthService = AuthService.getInstance();

  // 应用上下文（使用声明式方式获取）
  private context: common.UIAbilityContext | null = null;

  /**
   * 页面即将显示时调用
   */
  async aboutToAppear(): Promise<void> {
    console.info('UserPage.aboutToAppear: 页面初始化');
    this.initContext();
    await this.checkLoginStatus();
  }

  /**
   * 检查登录状态
   */
  private async checkLoginStatus(): Promise<void> {
    try {
      const user = await this.authService.checkLoginStatus();
      if (user) {
        this.currentUser = user;
      } else {
        // 未登录，跳转到登录页
        try {
          router.replaceUrl({
            url: 'pages/LoginPage'
          });
        } catch (routeErr) {
          console.error('UserPage: 跳转登录页失败:', JSON.stringify(routeErr));
        }
      }
    } catch (err) {
      console.error('UserPage.checkLoginStatus: 检查登录状态失败:', JSON.stringify(err));
      try {
        router.replaceUrl({
          url: 'pages/LoginPage'
        });
      } catch (routeErr) {
        console.error('UserPage: 跳转登录页失败:', JSON.stringify(routeErr));
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
        console.error('UserPage: 跳转登录页失败:', JSON.stringify(routeErr));
      }
    } catch (err) {
      console.error('UserPage.handleLogout: 退出登录失败:', JSON.stringify(err));
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
      const contextGetter = getContext as GetContextFunction;
      const contextValue: common.UIAbilityContext | undefined = contextGetter();

      if (contextValue) {
        this.context = contextValue;
        this.authService.setContext(contextValue);
        console.info('UserPage.initContext: 获取上下文成功');
      } else {
        console.warn('UserPage.initContext: 获取上下文失败');
      }
    } catch (err) {
      console.error('UserPage.initContext: 初始化上下文失败:', JSON.stringify(err));
    }
  }

  build() {
    Column() {
      // 标题栏
      Row() {
        Text('我的')
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
          .fontColor('#182431')

        Blank()
      }
      .width('100%')
      .height(56)
      .padding({ left: 16, right: 16 })
      .backgroundColor('#FFFFFF')

      // 用户信息卡片
      if (this.currentUser) {
        Scroll() {
          Column() {
            // 欢迎区域
            Row() {
              Image($r('app.media.foreground'))
                .width(64)
                .height(64)
                .borderRadius(32)
                .margin({ right: 16 })

              Column() {
                Text('欢迎回来！')
                  .fontSize(14)
                  .fontColor('#666666')
                  .margin({ bottom: 8 })

                Text(this.currentUser.username)
                  .fontSize(24)
                  .fontWeight(FontWeight.Bold)
                  .fontColor('#182431')
              }
              .alignItems(HorizontalAlign.Start)
              .layoutWeight(1)
            }
            .width('100%')
            .padding(20)
            .margin({ top: 12, bottom: 12 })

            // 账户信息
            Column() {
              Text('账户信息')
                .fontSize(18)
                .fontWeight(FontWeight.Bold)
                .fontColor('#182431')
                .alignSelf(ItemAlign.Start)
                .margin({ bottom: 20 })

              // 用户名
              Row() {
                Text('用户名')
                  .fontSize(14)
                  .fontColor('#666666')
                Blank()
                Text(this.currentUser.username)
                  .fontSize(14)
                  .fontColor('#182431')
              }
              .width('100%')
              .height(48)
              .justifyContent(FlexAlign.SpaceBetween)
              .alignItems(VerticalAlign.Center)

              Divider()
                .color('#F0F0F0')
                .margin({ top: 8, bottom: 8 })

              // 手机号（脱敏）
              Row() {
                Text('手机号')
                  .fontSize(14)
                  .fontColor('#666666')
                Blank()
                Text(this.formatPhone(this.currentUser.phone))
                  .fontSize(14)
                  .fontColor('#182431')
              }
              .width('100%')
              .height(48)
              .justifyContent(FlexAlign.SpaceBetween)
              .alignItems(VerticalAlign.Center)

              Divider()
                .color('#F0F0F0')
                .margin({ top: 8, bottom: 8 })

              // 注册时间
              Row() {
                Text('注册时间')
                  .fontSize(14)
                  .fontColor('#666666')
                Blank()
                Text(formatDate(this.currentUser.registerTime))
                  .fontSize(14)
                  .fontColor('#182431')
              }
              .width('100%')
              .height(48)
              .justifyContent(FlexAlign.SpaceBetween)
              .alignItems(VerticalAlign.Center)

              Divider()
                .color('#F0F0F0')
                .margin({ top: 8, bottom: 8 })

              // 最后登录时间
              Row() {
                Text('最后登录')
                  .fontSize(14)
                  .fontColor('#666666')
                Blank()
                Text(formatDateTime(this.currentUser.lastLoginTime))
                  .fontSize(14)
                  .fontColor('#182431')
              }
              .width('100%')
              .height(48)
              .justifyContent(FlexAlign.SpaceBetween)
              .alignItems(VerticalAlign.Center)
            }
            .width('100%')
            .padding(20)
            .backgroundColor('#FFFFFF')
            .borderRadius(12)
            .margin({ left: 16, right: 16, bottom: 24 })

            // 退出登录按钮
            Button('退出登录')
              .type(ButtonType.Normal)
              .backgroundColor('#FF3B30')
              .fontColor('#FFFFFF')
              .fontSize(16)
              .width('100%')
              .height(48)
              .borderRadius(8)
              .margin({ left: 16, right: 16, bottom: 24 })
              .onClick(() => {
                this.handleLogout();
              })
          }
          .width('100%')
        }
        .layoutWeight(1)
        .scrollBar(BarState.Auto)
      }
    }
    .width('100%')
    .layoutWeight(1)
    .backgroundColor('#F5F5F5')
    .onAppear(() => {
      // 如果上下文未初始化，再次尝试初始化
      if (!this.context) {
        this.initContext();
      }
      // 刷新用户信息
      this.checkLoginStatus();
    })
  }
}



