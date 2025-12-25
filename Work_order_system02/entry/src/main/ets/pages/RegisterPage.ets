/**
 * 注册页
 * 用户注册功能
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
struct RegisterPage {
  @State username: string = '';
  @State phone: string = '';
  @State password: string = '';
  @State confirmPassword: string = '';
  @State showPassword: boolean = false;
  @State showConfirmPassword: boolean = false;
  @State errorMessage: string = '';
  @State isLoading: boolean = false;

  private authService: AuthServiceWithHttp = AuthServiceWithHttp.getInstance();

  /**
   * 页面即将显示时调用
   */
  aboutToAppear(): void {
    console.info('RegisterPage.aboutToAppear: 注册页初始化');
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
        console.info('RegisterPage.initContext: 获取上下文成功');
      } else {
        console.warn('RegisterPage.initContext: 获取上下文失败');
      }
    } catch (err) {
      console.error('RegisterPage.initContext: 初始化上下文失败:', JSON.stringify(err));
    }
  }

  /**
   * 处理注册
   */
  private async handleRegister(): Promise<void> {
    // 清空错误信息
    this.errorMessage = '';

    // 输入验证
    if (!this.username || this.username.trim().length === 0) {
      this.errorMessage = '请输入用户名';
      return;
    }

    if (!this.phone || this.phone.trim().length === 0) {
      this.errorMessage = '请输入手机号';
      return;
    }

    if (!this.password || this.password.length === 0) {
      this.errorMessage = '请输入密码';
      return;
    }

    if (this.password !== this.confirmPassword) {
      this.errorMessage = '两次输入的密码不一致';
      return;
    }

    this.isLoading = true;

    try {
      const result = await this.authService.register(this.username, this.phone, this.password);

      if (result.success) {
        console.info('RegisterPage: 注册成功，自动登录并跳转到主页面');
        // 注册成功，自动登录
        const loginResult = await this.authService.login(this.username, this.password, false);
        if (loginResult.success) {
          try {
            router.replaceUrl({
              url: 'pages/HomePage'
            });
          } catch (err) {
            console.error('RegisterPage: 跳转主页面失败:', JSON.stringify(err));
          }
        } else {
          // 登录失败，跳转到登录页
          this.errorMessage = '注册成功，请登录';
          setTimeout(() => {
            try {
              router.replaceUrl({
                url: 'pages/LoginPage'
              });
            } catch (err) {
              console.error('RegisterPage: 跳转登录页失败:', JSON.stringify(err));
            }
          }, 1500);
        }
      } else {
        // 注册失败，显示错误信息
        this.errorMessage = result.error || '注册失败，请重试';
      }
    } catch (err) {
      console.error('RegisterPage.handleRegister: 注册异常:', JSON.stringify(err));
      this.errorMessage = '注册失败，请稍后重试';
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
   * 切换确认密码显示/隐藏
   */
  private toggleConfirmPasswordVisibility(): void {
    this.showConfirmPassword = !this.showConfirmPassword;
  }

  /**
   * 跳转到登录页
   */
  private navigateToLogin(): void {
    try {
      router.back();
    } catch (err) {
      console.error('RegisterPage: 返回登录页失败:', JSON.stringify(err));
    }
  }

  build() {
    Column() {
      // 头部区域
      Column() {
        Text('用户注册')
          .fontSize(28)
          .fontWeight(FontWeight.Bold)
          .fontColor('#182431')
      }
      .width('100%')
      .padding({ top: 60, bottom: 32 })
      .alignItems(HorizontalAlign.Center)

      // 表单区域
      Scroll() {
        Column() {
          // 用户名输入框
          Column() {
            Text('用户名')
              .fontSize(14)
              .fontColor('#666666')
              .alignSelf(ItemAlign.Start)
              .margin({ bottom: 8 })

            TextInput({ placeholder: '请输入用户名（3-20位字母、数字、下划线）' })
              .type(InputType.Normal)
              .backgroundColor('#F5F5F5')
              .borderRadius(8)
              .height(48)
              .fontSize(16)
              .fontColor('#182431')
              .onChange((value: string) => {
                this.username = value;
                this.errorMessage = ''; // 输入时清空错误信息
              })
          }
          .width('100%')
          .margin({ bottom: 20 })

          // 手机号输入框
          Column() {
            Text('手机号')
              .fontSize(14)
              .fontColor('#666666')
              .alignSelf(ItemAlign.Start)
              .margin({ bottom: 8 })

            TextInput({ placeholder: '请输入手机号' })
              .type(InputType.PhoneNumber)
              .backgroundColor('#F5F5F5')
              .borderRadius(8)
              .height(48)
              .fontSize(16)
              .fontColor('#182431')
              .maxLength(11)
              .onChange((value: string) => {
                this.phone = value;
                this.errorMessage = ''; // 输入时清空错误信息
              })
          }
          .width('100%')
          .margin({ bottom: 20 })

          // 密码输入框
          Column() {
            Text('密码')
              .fontSize(14)
              .fontColor('#666666')
              .alignSelf(ItemAlign.Start)
              .margin({ bottom: 8 })

            Row() {
              TextInput({ placeholder: '请输入密码（6-20位，包含字母和数字）' })
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
          .margin({ bottom: 20 })

          // 确认密码输入框
          Column() {
            Text('确认密码')
              .fontSize(14)
              .fontColor('#666666')
              .alignSelf(ItemAlign.Start)
              .margin({ bottom: 8 })

            Row() {
              TextInput({ placeholder: '请确认密码' })
                .type(this.showConfirmPassword ? InputType.Normal : InputType.Password)
                .backgroundColor('#F5F5F5')
                .borderRadius(8)
                .height(48)
                .fontSize(16)
                .fontColor('#182431')
                .layoutWeight(1)
                .onChange((value: string) => {
                  this.confirmPassword = value;
                  this.errorMessage = ''; // 输入时清空错误信息
                })

              Image(this.showConfirmPassword ? $r('app.media.foreground') : $r('app.media.foreground'))
                .width(24)
                .height(24)
                .margin({ left: 12 })
                .onClick(() => {
                  this.toggleConfirmPasswordVisibility();
                })
            }
            .width('100%')
          }
          .width('100%')
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

          // 注册按钮
          Button('注册')
            .type(ButtonType.Normal)
            .backgroundColor('#007DFF')
            .fontColor('#FFFFFF')
            .fontSize(16)
            .width('100%')
            .height(48)
            .borderRadius(8)
            .enabled(!this.isLoading && 
              this.username.trim().length > 0 && 
              this.phone.trim().length > 0 && 
              this.password.length > 0 && 
              this.confirmPassword.length > 0)
            .onClick(() => {
              this.handleRegister();
            })
        }
        .width('100%')
        .padding({ left: 24, right: 24 })
      }
      .layoutWeight(1)
      .scrollBar(BarState.Auto)

      // 底部区域
      Row() {
        Text('已有账号？')
          .fontSize(14)
          .fontColor('#999999')

        Text('立即登录')
          .fontSize(14)
          .fontColor('#007DFF')
          .margin({ left: 4 })
          .onClick(() => {
            this.navigateToLogin();
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

