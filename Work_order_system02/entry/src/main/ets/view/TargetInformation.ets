/**
 * 整体进度展示组件
 * 显示目标信息和整体进度统计
 */

import { formatDateTime } from '../common/utils/DateUtil';

@Component
export struct TargetInformation {
  @Prop totalTasksNumber: number = 0;
  @Prop completedTasksNumber: number = 0;
  @Prop overallProgress: number = 0;

  build() {
    Column() {
      // 目标信息区域
      Row() {
        Image($r('app.media.foreground'))
          .width(48)
          .height(48)
          .margin({ right: 12 })

        Column() {
          Text('运营平台问题单管理')
            .fontSize(18)
            .fontWeight(FontWeight.Bold)
            .fontColor('#182431')
            .margin({ bottom: 4 })

          Text('追踪和管理各类任务、问题和需求')
            .fontSize(14)
            .fontColor('#666666')
        }
        .alignItems(HorizontalAlign.Start)
        .layoutWeight(1)
      }
      .width('100%')
      .padding(16)
      .backgroundColor('#FFFFFF')
      .borderRadius(12)
      .margin({ bottom: 12 })

      // 整体进度区域
      Column() {
        Row() {
          Text('整体进度')
            .fontSize(16)
            .fontColor('#182431')

          Blank()

          Text(`${this.completedTasksNumber}/${this.totalTasksNumber}`)
            .fontSize(16)
            .fontWeight(FontWeight.Bold)
            .fontColor('#182431')
        }
        .width('100%')
        .margin({ bottom: 16 })

        // 环形进度条
        Stack({ alignContent: Alignment.Center }) {
          Progress({
            value: this.overallProgress,
            total: 100,
            type: ProgressType.Ring
          })
            .width(120)
            .height(120)
            .color('#007DFF')

          Column() {
            Text(`${this.overallProgress}%`)
              .fontSize(24)
              .fontWeight(FontWeight.Bold)
              .fontColor('#182431')
          }
        }
        .width('100%')
        .height(120)
        .margin({ bottom: 16 })

        // 统计信息区域
        Row() {
          // 总计
          Column() {
            Text('总计')
              .fontSize(12)
              .fontColor('#666666')
              .margin({ bottom: 4 })
            Text(`${this.totalTasksNumber}`)
              .fontSize(20)
              .fontWeight(FontWeight.Bold)
              .fontColor('#182431')
          }
          .layoutWeight(1)

          // 进行中
          Column() {
            Text('进行中')
              .fontSize(12)
              .fontColor('#666666')
              .margin({ bottom: 4 })
            Text(`${this.totalTasksNumber - this.completedTasksNumber}`)
              .fontSize(20)
              .fontWeight(FontWeight.Bold)
              .fontColor('#FF9500')
          }
          .layoutWeight(1)

          // 已完成
          Column() {
            Text('已完成')
              .fontSize(12)
              .fontColor('#666666')
              .margin({ bottom: 4 })
            Text(`${this.completedTasksNumber}`)
              .fontSize(20)
              .fontWeight(FontWeight.Bold)
              .fontColor('#00C853')
          }
          .layoutWeight(1)
        }
        .width('100%')
        .padding({ top: 16 })
      }
      .width('100%')
      .padding(16)
      .backgroundColor('#FFFFFF')
      .borderRadius(12)
      .margin({ bottom: 12 })
    }
    .width('100%')
    .padding({ left: 16, right: 16, top: 12 })
  }
}





