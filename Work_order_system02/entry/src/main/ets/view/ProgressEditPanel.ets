/**
 * 进度编辑面板组件
 * 提供进度设置和操作按钮
 */

@Component
export struct ProgressEditPanel {
  @Prop currentProgress: number = 0;
  @State sliderProgress: number = 0;
  private lastProgress: number = 0;

  // 回调函数
  onCancel: () => void = () => {};
  onClickOK: (progress: number) => void = () => {};

  /**
   * 初始化时同步进度值
   */
  aboutToAppear(): void {
    this.sliderProgress = this.currentProgress;
    this.lastProgress = this.currentProgress;
  }

  /**
   * 减少进度
   */
  decreaseProgress(): void {
    if (this.sliderProgress > 0) {
      this.sliderProgress = Math.max(0, this.sliderProgress - 5);
    }
  }

  /**
   * 增加进度
   */
  increaseProgress(): void {
    if (this.sliderProgress < 100) {
      this.sliderProgress = Math.min(100, this.sliderProgress + 5);
    }
  }

  /**
   * 完成操作
   */
  handleComplete(): void {
    this.onClickOK(100);
  }

  /**
   * 确认操作
   */
  handleConfirm(): void {
    const progress = Math.round(this.sliderProgress);
    console.info('ProgressEditPanel.handleConfirm: 确认进度值:', progress);
    this.onClickOK(progress);
  }

  build() {
    Column() {
      // 操作按钮行
      Row() {
        Button('取消')
          .type(ButtonType.Normal)
          .backgroundColor('#F5F5F5')
          .fontColor('#666666')
          .fontSize(14)
          .width(80)
          .height(36)
          .borderRadius(8)
          .onClick(() => {
            this.onCancel();
          })

        Button('确认')
          .type(ButtonType.Normal)
          .backgroundColor('#007DFF')
          .fontColor('#FFFFFF')
          .fontSize(14)
          .width(80)
          .height(36)
          .borderRadius(8)
          .onClick(() => {
            this.handleConfirm();
          })
          .margin({ right: 8 })

        Button('完成')
          .type(ButtonType.Normal)
          .backgroundColor('#00C853')
          .fontColor('#FFFFFF')
          .fontSize(14)
          .width(80)
          .height(36)
          .borderRadius(8)
          .onClick(() => {
            this.handleComplete();
          })
      }
      .width('100%')
      .padding({ left: 16, right: 16, top: 12, bottom: 12 })

      // 进度控制区域
      Column() {
        Row() {
          Button('-')
            .type(ButtonType.Normal)
            .backgroundColor('#F5F5F5')
            .fontColor('#182431')
            .fontSize(18)
            .width(40)
            .height(40)
            .borderRadius(20)
            .onClick(() => {
              this.decreaseProgress();
            })

          Slider({
            value: this.sliderProgress,
            min: 0,
            max: 100,
            step: 1
          })
            .blockColor('#007DFF')
            .trackColor('#E5E5E5')
            .selectedColor('#007DFF')
            .layoutWeight(1)
            .margin({ left: 12, right: 12 })
            .onChange((value: number) => {
              const roundedValue = Math.round(value);
              this.sliderProgress = roundedValue;
              console.info('ProgressEditPanel: 进度条值变化:', roundedValue);
            })

          Button('+')
            .type(ButtonType.Normal)
            .backgroundColor('#F5F5F5')
            .fontColor('#182431')
            .fontSize(18)
            .width(40)
            .height(40)
            .borderRadius(20)
            .onClick(() => {
              this.increaseProgress();
            })
        }
        .width('100%')
        .padding({ left: 16, right: 16 })

        Text(`当前进度：${this.sliderProgress}%`)
          .fontSize(14)
          .fontColor('#666666')
          .margin({ top: 12, bottom: 12 })
      }
      .width('100%')
      .padding({ bottom: 16 })
    }
    .width('100%')
    .backgroundColor('#F9F9F9')
    .borderRadius({ bottomLeft: 12, bottomRight: 12 })
    .margin({ top: 8 })
    .onAppear(() => {
      // 检查外部进度是否变化
      if (this.lastProgress !== this.currentProgress) {
        this.sliderProgress = this.currentProgress;
        this.lastProgress = this.currentProgress;
      }
    })
  }
}

