/**
 * 数据统计页面
 * 显示工单的整体进度和详细统计数据
 */

import { DataModel } from '../viewmodel/DataModel';
import { StatisticsModel } from '../viewmodel/StatisticsModel';
import { TargetInformation } from '../view/TargetInformation';
import { router } from '@kit.ArkUI';

@Entry
@Component
struct StatisticsPage {
  // 统计数据
  @State statistics: StatisticsModel = {
    total: 0,
    completed: 0,
    inProgress: 0,
    notStarted: 0,
    completionRate: 0,
    averageProgress: 0
  };

  // 数据模型实例
  private dataModel: DataModel = DataModel.getInstance();

  /**
   * 页面即将显示时调用
   */
  aboutToAppear(): void {
    this.loadStatistics();
    
    // 注册数据变更监听器
    this.dataModel.addChangeListener(() => {
      this.loadStatistics();
    });
  }

  /**
   * 加载统计数据
   */
  loadStatistics(): void {
    this.statistics = this.dataModel.getStatistics();
  }

  /**
   * 返回上一页
   */
  goBack(): void {
    router.back();
  }

  build() {
    Column() {
      // 标题栏
      Row() {
        Image($r('app.media.foreground'))
          .width(24)
          .height(24)
          .onClick(() => {
            this.goBack();
          })
          .margin({ right: 12 })

        Text('数据统计')
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
          .fontColor('#182431')

        Blank()
      }
      .width('100%')
      .height(56)
      .padding({ left: 16, right: 16 })
      .backgroundColor('#FFFFFF')

      Scroll() {
        Column() {
          // 整体进度展示区
          TargetInformation({
            totalTasksNumber: this.statistics.total,
            completedTasksNumber: this.statistics.completed,
            overallProgress: this.statistics.completionRate
          })

          // 详细统计信息卡片
          Column() {
            Text('详细统计')
              .fontSize(18)
              .fontWeight(FontWeight.Bold)
              .fontColor('#182431')
              .alignSelf(ItemAlign.Start)
              .margin({ bottom: 16 })

            // 平均进度
            Row() {
              Column() {
                Text('平均进度')
                  .fontSize(14)
                  .fontColor('#666666')
                  .margin({ bottom: 8 })
                Text(`${this.statistics.averageProgress}%`)
                  .fontSize(24)
                  .fontWeight(FontWeight.Bold)
                  .fontColor('#007DFF')
              }
              .layoutWeight(1)

              Column() {
                Text('待处理')
                  .fontSize(14)
                  .fontColor('#666666')
                  .margin({ bottom: 8 })
                Text(`${this.statistics.notStarted}`)
                  .fontSize(24)
                  .fontWeight(FontWeight.Bold)
                  .fontColor('#999999')
              }
              .layoutWeight(1)
            }
            .width('100%')
            .margin({ bottom: 24 })

            // 进度条展示
            Column() {
              Text('进度分布')
                .fontSize(16)
                .fontWeight(FontWeight.Medium)
                .fontColor('#182431')
                .alignSelf(ItemAlign.Start)
                .margin({ bottom: 16 })

              // 已完成进度条
              Column() {
                Row() {
                  Text('已完成')
                    .fontSize(14)
                    .fontColor('#182431')
                  Blank()
                  Text(`${this.statistics.completed} 项`)
                    .fontSize(14)
                    .fontColor('#666666')
                }
                .width('100%')
                .margin({ bottom: 8 })

                Progress({
                  value: this.statistics.completed,
                  total: this.statistics.total > 0 ? this.statistics.total : 1,
                  type: ProgressType.Linear
                })
                  .width('100%')
                  .height(8)
                  .color('#00C853')
              }
              .width('100%')
              .margin({ bottom: 16 })

              // 进行中进度条
              Column() {
                Row() {
                  Text('进行中')
                    .fontSize(14)
                    .fontColor('#182431')
                  Blank()
                  Text(`${this.statistics.inProgress} 项`)
                    .fontSize(14)
                    .fontColor('#666666')
                }
                .width('100%')
                .margin({ bottom: 8 })

                Progress({
                  value: this.statistics.inProgress,
                  total: this.statistics.total > 0 ? this.statistics.total : 1,
                  type: ProgressType.Linear
                })
                  .width('100%')
                  .height(8)
                  .color('#FF9500')
              }
              .width('100%')
              .margin({ bottom: 16 })

              // 待处理进度条
              Column() {
                Row() {
                  Text('待处理')
                    .fontSize(14)
                    .fontColor('#182431')
                  Blank()
                  Text(`${this.statistics.notStarted} 项`)
                    .fontSize(14)
                    .fontColor('#666666')
                }
                .width('100%')
                .margin({ bottom: 8 })

                Progress({
                  value: this.statistics.notStarted,
                  total: this.statistics.total > 0 ? this.statistics.total : 1,
                  type: ProgressType.Linear
                })
                  .width('100%')
                  .height(8)
                  .color('#999999')
              }
              .width('100%')
            }
            .width('100%')
          }
          .width('100%')
          .padding(16)
          .backgroundColor('#FFFFFF')
          .borderRadius(12)
          .margin({ left: 16, right: 16, bottom: 12 })
        }
        .width('100%')
      }
      .layoutWeight(1)
      .width('100%')
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F5F5F5')
  }
}

