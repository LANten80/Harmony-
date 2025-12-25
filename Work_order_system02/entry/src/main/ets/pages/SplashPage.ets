/**
 * 启动页
 * 检查登录状态，自动跳转到相应页面
 */

import { router } from '@kit.ArkUI';
import { AuthService } from '../viewmodel/AuthService';
import { common } from '@kit.AbilityKit';

/**
 * getContext 函数类型定义
 */
type GetContextFunction = () => common.UIAbilityContext | undefined;

@Entry
@Component
struct SplashPage {
  @State showLogo: boolean = false;
  @State canSkip: boolean = false;

  private authService: AuthService = AuthService.getInstance();
  private navigateTimer: number | null = null;

  /**
   * 页面即将显示时调用
   */
  async aboutToAppear(): Promise<void> {
    console.info('SplashPage.aboutToAppear: 启动页初始化');

    // Logo渐入动画
    setTimeout(() => {
      this.showLogo = true;
    }, 100);

    // 初始化上下文
    this.initContext();

    // 1秒后允许跳过
    setTimeout(() => {
      this.canSkip = true;
    }, 1000);

    // 2秒后检查登录状态并跳转
    this.navigateTimer = setTimeout(async () => {
      await this.checkAndNavigate();
    }, 2000) as number;
  }

  /**
   * 初始化上下文
   */
  private initContext(): void {
    try {
      const contextGetter = getContext as GetContextFunction;
      const contextValue: common.UIAbilityContext | undefined = contextGetter();

      if (contextValue) {
        this.authService.setContext(contextValue);
        console.info('SplashPage.initContext: 获取上下文成功');
      } else {
        console.warn('SplashPage.initContext: 获取上下文失败');
      }
    } catch (err) {
      console.error('SplashPage.initContext: 初始化上下文失败:', JSON.stringify(err));
    }
  }

  /**
   * 检查登录状态并跳转
   */
  private async checkAndNavigate(): Promise<void> {
    // 清除定时器
    if (this.navigateTimer !== null) {
      clearTimeout(this.navigateTimer);
      this.navigateTimer = null;
    }

    try {
      const user = await this.authService.checkLoginStatus();
      
      if (user) {
        // 已登录且记住密码，跳转到主页面
        console.info('SplashPage: 用户已登录，跳转到主页面');
        try {
          router.replaceUrl({
            url: 'pages/HomePage'
          });
        } catch (err) {
          console.error('SplashPage: 跳转主页面失败:', JSON.stringify(err));
        }
      } else {
        // 未登录或未记住密码，跳转到登录页
        console.info('SplashPage: 用户未登录，跳转到登录页');
        try {
          router.replaceUrl({
            url: 'pages/LoginPage'
          });
        } catch (err) {
          console.error('SplashPage: 跳转登录页失败:', JSON.stringify(err));
        }
      }
    } catch (err) {
      console.error('SplashPage.checkAndNavigate: 检查登录状态失败:', JSON.stringify(err));
      // 出错时跳转到登录页
      try {
        router.replaceUrl({
          url: 'pages/LoginPage'
        });
      } catch (routeErr) {
        console.error('SplashPage: 跳转登录页失败:', JSON.stringify(routeErr));
      }
    }
  }

  /**
   * 点击跳过启动页
   */
  private handleSkip(): void {
    if (this.canSkip) {
      console.info('SplashPage: 用户点击跳过启动页');
      this.checkAndNavigate();
    }
  }

  build() {
    Stack() {
      Column() {
        // Logo和品牌展示
        Column() {
          Image($r('app.media.foreground'))
            .width(120)
            .height(120)
            .opacity(this.showLogo ? 1 : 0)
            .transition(TransitionEffect.OPACITY.animation({ duration: 500, curve: Curve.EaseInOut }))

          Text('工单管理系统')
            .fontSize(24)
            .fontWeight(FontWeight.Bold)
            .fontColor('#182431')
            .margin({ top: 24 })
            .opacity(this.showLogo ? 1 : 0)
            .transition(TransitionEffect.OPACITY.animation({ duration: 500, curve: Curve.EaseInOut, delay: 200 }))
        }
        .layoutWeight(1)
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center)

        // 底部提示
        Text('正在加载...')
          .fontSize(14)
          .fontColor('#999999')
          .margin({ bottom: 48 })
      }
      .width('100%')
      .height('100%')
      .backgroundColor('#F5F5F5')

      // 跳过按钮（1秒后显示）
      if (this.canSkip) {
        Button('跳过')
          .type(ButtonType.Normal)
          .fontSize(14)
          .fontColor('#007DFF')
          .backgroundColor('#FFFFFF')
          .borderRadius(20)
          .width(64)
          .height(32)
          .opacity(0.9)
          .margin({ top: 40, right: 20 })
          .onClick(() => {
            this.handleSkip();
          })
          .align(Alignment.TopEnd)
      }
    }
    .width('100%')
    .height('100%')
  }
}

