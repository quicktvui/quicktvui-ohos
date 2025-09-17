import {
  HippyRenderBaseView,
  HippyObservedArray,
  NativeRenderContext,
  HippyAny,
  HippyRenderCallback,
  HIPPY_COMPONENT_KEY_PREFIX,
  HippyViewEvent,
  buildHippyRenderView
} from 'hippy'
import { QTBaseComponentView } from '../QTBaseComponentView'

@Observed
export class QTEventView extends QTBaseComponentView {
  public color: string = '#ffffff';
  public event: QTEvent | null = null

  constructor(ctx: NativeRenderContext) {
    super(ctx)
  }

  setProp(propKey: string, propValue: HippyAny): boolean {
    if (propKey == "prop1") {
      // ...
      return true
    } else if (propKey == "prop2") {
      // ...
      return true
    }
    return super.setProp(propKey, propValue)
  }

  call(method: string, params: Array<HippyAny>, callback: HippyRenderCallback | null): void {
    if (this.event && this.event.call(method, params, callback)) {
      return;
    }
    super.call(method, params, callback)
  }
}

@Component
export struct QTEvent {
  @ObjectLink renderView: QTEventView
  @ObjectLink children: HippyObservedArray<HippyRenderBaseView>

  // 第一步: 声明相关状态变量
  @State rotateValue: number = 0; // 组件一旋转角度
  @State translateX: number = 0; // 组件二偏移量
  @State opacityValue: number = 1; // 组件二透明度
  @State scaleX: number = 1; //

  public call(method: string, params: Array<HippyAny>,
    callback: HippyRenderCallback | null): boolean {
    if (method == "sendEsMessage") {
      // 自定义事件举例
      let event = new HippyViewEvent("onEsEvent")
      let params = new Map<string, string>()
      params.set('code', "100")
      params.set('message', "Native 发送的事件消息")
      event.send(this.renderView.ctx, this.renderView.tag, params)
      // 如果需要返回值，返回值举例
      if (callback) {
        callback("result from native")
      }
      this.doAnimation()
      return true
    }
    return false
  }

  private doAnimation(){
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
  }

  aboutToAppear(): void {
    this.renderView.event = this
  }

  aboutToDisappear() {
    this.renderView.event = null
  }

  build(): void {
    Stack() {
      Text("This is a custom component A.")
      ForEach(this.children, (item: HippyRenderBaseView) => {
        buildHippyRenderView(item, null)
      }, (item: HippyRenderBaseView) => item.tag + '')
      // 该自定义组件有Hippy子组件或其它自定义子组件时，必须加Slot来衔接子组件
      ContentSlot(this.renderView.childSlot)
    }
    .opacity(this.opacityValue)
    .translate({ x: this.translateX })
    .rotate({ angle: this.rotateValue })
    .scale({ x: this.scaleX })
    .applyRenderViewBaseAttr(this.renderView)
  }
}

// base props for all components
@Extend(Stack)
function applyRenderViewBaseAttr($$: HippyRenderBaseView) {
  .key(HIPPY_COMPONENT_KEY_PREFIX + $$.tag)
  .backgroundColor($$.cssBackgroundColor)
  .position({ x: $$.cssPositionX, y: $$.cssPositionY })
  .size({ width: $$.cssWidth, height: $$.cssHeight })
  .opacity($$.cssOpacity)
  .clip($$.cssOverflow)
  .visibility(($$ as HippyRenderBaseView).cssVisibility) // must add as, otherwise the compiler has error
  .zIndex($$.cssZIndex)
  .accessibilityText($$.cssAccessibilityLabel)
  .focusable($$.cssFocusable)
  .border($$.cssBorder)
  .shadow($$.cssShadow)
  .linearGradient($$.cssLinearGradient)
  .backgroundImage($$.cssBackgroundImage)
  .backgroundImageSize($$.cssBackgroundImageSize)
  .backgroundImagePosition($$.cssBackgroundImagePosition)
  .transform($$.cssMatrix)
  .rotate($$.cssRotate)
  .scale($$.cssScale)
  .translate($$.cssTranslate)
  .hitTestBehavior($$.hitTestBehavior)
  .onClick($$.eventClick)
}

