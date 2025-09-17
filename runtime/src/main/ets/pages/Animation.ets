import {
  HippyLibrary,
} from 'hippy'
import { LogUtils } from 'hippy/src/main/ets/support/utils/LogUtils'

const TAG: string = 'RuntimeAnimationPage'

@Builder
export function PageDebugBuilder(name: string, param: Object) {
  Animation()
}

@Component
struct Animation {
  pageInfos: NavPathStack = new NavPathStack();
  // 第一步: 声明相关状态变量
  @State rotateValue: number = 0; // 组件一旋转角度
  @State translateX: number = 0; // 组件二偏移量
  @State opacityValue: number = 1; // 组件二透明度
  @State scaleX: number = 1; //

  // 第二步：将状态变量设置到相关可动画属性接口

  async aboutToAppear() {
    LogUtils.e(TAG, 'Lifecycle: aboutToAppear');
  }

  onPageShow(): void {
    LogUtils.e(TAG, 'Lifecycle: onPageShow');
  }

  onPageHide(): void {
    LogUtils.e(TAG, 'Lifecycle: onPageHide');
  }

  aboutToDisappear(): void {
    LogUtils.e(TAG, 'Lifecycle: aboutToDisappear');
  }

  build() {
    NavDestination() {
      Stack() {
        Row() {
          Column() {
            Button()
              .fontColor(Color.Black)
              .fontSize(40)
              .fontWeight(FontWeight.Bold)
              .type(ButtonType.Normal)
              .width(300)
              .height(300)
              .opacity(this.opacityValue)
              .translate({ x: this.translateX })
              .rotate({ angle: this.rotateValue })
              .scale({ x: this.scaleX })
              .onClick(() => {
                // 第三步：调用keyframeAnimateTo接口
                this.getUIContext()?.keyframeAnimateTo({
                  iterations: 1
                }, [
                  {
                    // 第一段关键帧动画时长为800ms，组件一顺时针旋转90度，组件二的透明度变从1变为0.6，组件二的translate从0位移到50
                    duration: 0,
                    curve:Curve.Linear,
                    event: () => {
                      // this.rotateValue = 90;
                      this.scaleX = 0;
                      // this.translateX = 50;
                    }
                  },
                  {
                    // 第二段关键帧动画时长为500ms，组件一逆时针旋转90度恢复至0度，组件二的透明度变从0.6变为1，组件二的translate从50位移到0
                    duration: 1000,
                    curve:Curve.Linear,
                    event: () => {
                      // this.rotateValue = 0;
                      // this.opacityValue = 1;
                      // this.translateX = 0;

                      this.scaleX = 1.5;
                    }
                  }
                ]);
              })
          }.margin({ right: 70 })
        }
        .alignItems(VerticalAlign.Center)
        .justifyContent(FlexAlign.Center)
        .width('100%')
        .height('100%')
        .expandSafeArea()
      }
      .alignContent(Alignment.TopStart)
      .width('100%')
      .height('100%')
      .backgroundColor('#3A4251')
      .expandSafeArea()
    }
    .hideTitleBar(true)
    .hideBackButton(true)
    .hideToolBar(true)
    .onReady((context: NavDestinationContext) => {
      this.pageInfos = context.pathStack;
    })
    .onWillAppear(() => {
      LogUtils.e(TAG, 'Lifecycle: onWillAppear');
    })
    .onAttach(() => {
      LogUtils.e(TAG, 'Lifecycle: onAttach');
    })
    .onAppear(() => {
      LogUtils.e(TAG, 'Lifecycle: onAppear');
    })
    .onWillShow(() => {
      LogUtils.e(TAG, 'Lifecycle: onWillShow');
    })
    .onShown(() => {
      LogUtils.e(TAG, 'Lifecycle: onShown');
      // 第三步：调用keyframeAnimateTo接口
      this.getUIContext()?.keyframeAnimateTo({
        iterations: 1
      }, [
        {
          // 第一段关键帧动画时长为800ms，组件一顺时针旋转90度，组件二的透明度变从1变为0.6，组件二的translate从0位移到50
          duration: 0,
          curve:Curve.Linear,
          event: () => {
            // this.rotateValue = 90;
            this.scaleX = 0;
            // this.translateX = 50;
          }
        },
        {
          // 第二段关键帧动画时长为500ms，组件一逆时针旋转90度恢复至0度，组件二的透明度变从0.6变为1，组件二的translate从50位移到0
          duration: 1000,
          curve:Curve.Linear,
          event: () => {
            // this.rotateValue = 0;
            // this.opacityValue = 1;
            // this.translateX = 0;

            this.scaleX = 1.5;
          }
        }
      ]);
    })
    .onWillHide(() => {
      LogUtils.e(TAG, 'Lifecycle: onWillHide');
    })
    .onHidden(() => {
      LogUtils.e(TAG, 'Lifecycle: onHidden');
    })
    .onWillDisappear(() => {
      LogUtils.e(TAG, 'Lifecycle: onWillDisappear');
    })
    .onDetach(() => {
      LogUtils.e(TAG, 'Lifecycle: onDetach');
    })
    .onDisAppear(() => {
      LogUtils.e(TAG, 'Lifecycle: onDisAppear');
    })
    .onBackPressed(() => {
      return false
    })
  }
}
