/**
 * 主容器页面
 * 包含底部导航栏，管理工单页面和用户页面
 */

import { TaskPage } from '../view/TaskPage';
import { UserPage } from '../view/UserPage';

@Entry
@Component
struct HomePage {
  @State currentIndex: number = 0;

  build() {
    Column() {
      // 内容区域
      if (this.currentIndex === 0) {
        TaskPage()
      } else {
        UserPage()
      }

      // 底部导航栏
      Row() {
        // 工单管理标签
        Column() {
          Image($r('app.media.foreground'))
            .width(24)
            .height(24)
            .opacity(this.currentIndex === 0 ? 1 : 0.5)
            .fillColor(this.currentIndex === 0 ? '#007DFF' : '#999999')
          
          Text('工单')
            .fontSize(12)
            .fontColor(this.currentIndex === 0 ? '#007DFF' : '#999999')
            .fontWeight(this.currentIndex === 0 ? FontWeight.Medium : FontWeight.Normal)
            .margin({ top: 4 })
        }
        .layoutWeight(1)
        .height(56)
        .justifyContent(FlexAlign.Center)
        .backgroundColor(this.currentIndex === 0 ? '#F0F7FF' : '#FFFFFF')
        .onClick(() => {
          this.currentIndex = 0;
        })

        // 用户标签
        Column() {
          Image($r('app.media.foreground'))
            .width(24)
            .height(24)
            .opacity(this.currentIndex === 1 ? 1 : 0.5)
            .fillColor(this.currentIndex === 1 ? '#007DFF' : '#999999')
          
          Text('我的')
            .fontSize(12)
            .fontColor(this.currentIndex === 1 ? '#007DFF' : '#999999')
            .fontWeight(this.currentIndex === 1 ? FontWeight.Medium : FontWeight.Normal)
            .margin({ top: 4 })
        }
        .layoutWeight(1)
        .height(56)
        .justifyContent(FlexAlign.Center)
        .backgroundColor(this.currentIndex === 1 ? '#F0F7FF' : '#FFFFFF')
        .onClick(() => {
          this.currentIndex = 1;
        })
      }
      .width('100%')
      .height(56)
      .backgroundColor('#FFFFFF')
      .border({ width: { top: 1 }, color: '#F0F0F0' })
      .shadow({ radius: 8, color: '#1F000000', offsetX: 0, offsetY: -2 })
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F5F5F5')
  }
}

