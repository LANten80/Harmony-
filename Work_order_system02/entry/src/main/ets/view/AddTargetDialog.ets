/**
 * 添加工单弹窗组件
 * 提供工单名称输入和确认操作
 */

@CustomDialog
export struct AddTargetDialog {
  controller: CustomDialogController;
  @State subtaskName: string = '';

  // 回调函数
  onClickOk: (taskName: string) => void = () => {};

  /**
   * 处理确定按钮点击
   */
  handleConfirm(): void {
    if (this.subtaskName.trim().length === 0) {
      return;
    }
    const taskName = this.subtaskName.trim();
    this.subtaskName = '';
    // 关闭弹窗
    this.controller.close();
    // 调用回调
    this.onClickOk(taskName);
  }

  /**
   * 处理取消按钮点击
   */
  handleCancel(): void {
    this.subtaskName = '';
    this.controller.close();
  }

  build() {
    Column() {
      // 弹窗标题
      Text('添加问题单')
        .fontSize(18)
        .fontWeight(FontWeight.Bold)
        .fontColor('#182431')
        .margin({ top: 24, bottom: 16 })

      // 输入区域
      Column() {
        Text('请输入问题单描述')
          .fontSize(14)
          .fontColor('#666666')
          .alignSelf(ItemAlign.Start)
          .margin({ bottom: 8 })

        TextInput({ placeholder: '例如：修复登录页面验证码显示问题' })
          .type(InputType.Normal)
          .backgroundColor('#F5F5F5')
          .borderRadius(8)
          .height(100)
          .fontSize(14)
          .fontColor('#182431')
          .onChange((value: string) => {
            this.subtaskName = value;
          })

        Text('例如：修复登录页面验证码显示问题')
          .fontSize(12)
          .fontColor('#999999')
          .alignSelf(ItemAlign.Start)
          .margin({ top: 8 })
      }
      .width('100%')
      .padding({ left: 24, right: 24 })
      .margin({ bottom: 24 })

      // 操作按钮区域
      Row() {
        Button('取消')
          .type(ButtonType.Normal)
          .backgroundColor('#F5F5F5')
          .fontColor('#666666')
          .fontSize(16)
          .layoutWeight(1)
          .height(48)
          .borderRadius(8)
          .onClick(() => {
            this.handleCancel();
          })

        Button('确定')
          .type(ButtonType.Normal)
          .backgroundColor('#007DFF')
          .fontColor('#FFFFFF')
          .fontSize(16)
          .layoutWeight(1)
          .height(48)
          .borderRadius(8)
          .margin({ left: 12 })
          .onClick(() => {
            this.handleConfirm();
          })
      }
      .width('100%')
      .padding({ left: 24, right: 24, bottom: 24 })
    }
    .width('100%')
    .backgroundColor('#FFFFFF')
    .borderRadius({ topLeft: 20, topRight: 20 })
  }
}

