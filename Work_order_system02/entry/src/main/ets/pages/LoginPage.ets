/**
 * 登录页
 * 用户登录功能
 */

import { router } from '@kit.ArkUI';
import { AuthServiceWithHttp } from '../viewmodel/AuthServiceWithHttp';
import { common } from '@kit.AbilityKit';

/**
 * getContext 函数类型定义
 */
type GetContextFunction = () => common.UIAbilityContext | undefined;

@Entry
@Component
struct LoginPage {
  @State account: string = '';
  @State password: string = '';
  @State showPassword: boolean = false;
  @State rememberMe: boolean = false;
  @State errorMessage: string = '';
  @State isLoading: boolean = false;

  private authService: AuthServiceWithHttp = AuthServiceWithHttp.getInstance();

  /**
   * 页面即将显示时调用
   */
  aboutToAppear(): void {
    console.info('LoginPage.aboutToAppear: 登录页初始化');
    this.initContext();
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
        this.authService.setUseHttp(true); // 启用HTTP请求
        console.info('LoginPage.initContext: 获取上下文成功');
      } else {
        console.warn('LoginPage.initContext: 获取上下文失败');
      }
    } catch (err) {
      console.error('LoginPage.initContext: 初始化上下文失败:', JSON.stringify(err));
    }
  }

  /**
   * 处理登录
   */
  private async handleLogin(): Promise<void> {
    // 清空错误信息
    this.errorMessage = '';

    // 输入验证
    if (!this.account || this.account.trim().length === 0) {
      this.errorMessage = '请输入用户名或手机号';
      return;
    }

    if (!this.password || this.password.trim().length === 0) {
      this.errorMessage = '请输入密码';
      return;
    }

    this.isLoading = true;

    try {
      const result = await this.authService.login(this.account, this.password, this.rememberMe);

      if (result.success && result.user) {
        console.info('LoginPage: 登录成功，跳转到主页面');
        // 登录成功，跳转到主页面
        try {
          router.replaceUrl({
            url: 'pages/HomePage'
          });
        } catch (err) {
          console.error('LoginPage: 跳转主页面失败:', JSON.stringify(err));
        }
      } else {
        // 登录失败，显示错误信息
        this.errorMessage = result.error || '登录失败，请重试';
        this.password = ''; // 清空密码框
      }
    } catch (err) {
      console.error('LoginPage.handleLogin: 登录异常:', JSON.stringify(err));
      this.errorMessage = '登录失败，请稍后重试';
      this.password = '';
    } finally {
      this.isLoading = false;
    }
  }

  /**
   * 切换密码显示/隐藏
   */
  private togglePasswordVisibility(): void {
    this.showPassword = !this.showPassword;
  }

  /**
   * 跳转到注册页
   */
  private navigateToRegister(): void {
    try {
      router.pushUrl({
        url: 'pages/RegisterPage'
      });
    } catch (err) {
      console.error('LoginPage: 跳转注册页失败:', JSON.stringify(err));
    }
  }

  build() {
    Column() {
      // 头部区域
      Column() {
        Text('用户登录')
          .fontSize(28)
          .fontWeight(FontWeight.Bold)
          .fontColor('#182431')
      }
      .width('100%')
      .padding({ top: 80, bottom: 48 })
      .alignItems(HorizontalAlign.Center)

      // 表单区域
      Column() {
        // 账号输入框
        Column() {
          Text('账号')
            .fontSize(14)
            .fontColor('#666666')
            .alignSelf(ItemAlign.Start)
            .margin({ bottom: 8 })

          TextInput({ placeholder: '请输入用户名或手机号' })
            .type(InputType.Normal)
            .backgroundColor('#F5F5F5')
            .borderRadius(8)
            .height(48)
            .fontSize(16)
            .fontColor('#182431')
            .onChange((value: string) => {
              this.account = value;
              this.errorMessage = ''; // 输入时清空错误信息
            })
        }
        .width('100%')
        .margin({ bottom: 24 })

        // 密码输入框
        Column() {
          Text('密码')
            .fontSize(14)
            .fontColor('#666666')
            .alignSelf(ItemAlign.Start)
            .margin({ bottom: 8 })

          Row() {
            TextInput({ placeholder: '请输入密码' })
              .type(this.showPassword ? InputType.Normal : InputType.Password)
              .backgroundColor('#F5F5F5')
              .borderRadius(8)
              .height(48)
              .fontSize(16)
              .fontColor('#182431')
              .layoutWeight(1)
              .onChange((value: string) => {
                this.password = value;
                this.errorMessage = ''; // 输入时清空错误信息
              })

            Image(this.showPassword ? $r('app.media.foreground') : $r('app.media.foreground'))
              .width(24)
              .height(24)
              .margin({ left: 12 })
              .onClick(() => {
                this.togglePasswordVisibility();
              })
          }
          .width('100%')
        }
        .width('100%')
        .margin({ bottom: 16 })

        // 记住密码选项
        Row() {
          Checkbox()
            .select(this.rememberMe)
            .selectedColor('#007DFF')
            .onChange((checked: boolean) => {
              this.rememberMe = checked;
            })

          Text('记住密码')
            .fontSize(14)
            .fontColor('#666666')
            .margin({ left: 8 })
        }
        .width('100%')
        .justifyContent(FlexAlign.Start)
        .margin({ bottom: 24 })

        // 错误提示
        if (this.errorMessage) {
          Text(this.errorMessage)
            .fontSize(12)
            .fontColor('#FF3B30')
            .width('100%')
            .textAlign(TextAlign.Start)
            .margin({ bottom: 16 })
        }

        // 登录按钮
        Button('登录')
          .type(ButtonType.Normal)
          .backgroundColor('#007DFF')
          .fontColor('#FFFFFF')
          .fontSize(16)
          .width('100%')
          .height(48)
          .borderRadius(8)
          .enabled(!this.isLoading && this.account.trim().length > 0 && this.password.length > 0)
          .onClick(() => {
            this.handleLogin();
          })
      }
      .width('100%')
      .padding({ left: 24, right: 24 })
      .layoutWeight(1)

      // 底部区域
      Row() {
        Text('还没有账号？')
          .fontSize(14)
          .fontColor('#999999')

        Text('立即注册')
          .fontSize(14)
          .fontColor('#007DFF')
          .margin({ left: 4 })
          .onClick(() => {
            this.navigateToRegister();
          })
      }
      .width('100%')
      .justifyContent(FlexAlign.Center)
      .padding({ bottom: 48 })
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#FFFFFF')
  }
}

