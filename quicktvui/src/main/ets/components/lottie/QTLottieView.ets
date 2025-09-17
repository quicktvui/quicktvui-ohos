import {
  HippyRenderBaseView,
  HippyObservedArray,
  NativeRenderContext,
  HippyAny,
  HippyRenderCallback,
  HIPPY_COMPONENT_KEY_PREFIX,
  HippyViewEvent,
  buildHippyRenderView,
  LogUtils
} from 'hippy'
import { QTBaseComponentView } from '../QTBaseComponentView'
import lottie, { AnimationItem } from '@ohos/lottie';

@Observed
export class QTLottieView extends QTBaseComponentView {
  private readonly TAG = "QTLottieView";
  public color: string = '#ffffff';
  public lottie: QTLottie | null = null

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
    if (this.lottie && this.lottie.call(method, params, callback)) {
      return;
    }
    super.call(method, params, callback)
  }
}

@Component
export struct QTLottie {
  private readonly TAG = "QTLottie";
  @ObjectLink renderView: QTLottieView
  @ObjectLink children: HippyObservedArray<HippyRenderBaseView>
  // 构建上下文
  private renderingSettings: RenderingContextSettings = new RenderingContextSettings(true);
  private canvasRenderingContext: CanvasRenderingContext2D =
    new CanvasRenderingContext2D(this.renderingSettings);
  private animateItem: AnimationItem | null = null;
  private animateName: string = 'animation';

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
      return true
    }
    return false
  }

  aboutToAppear(): void {
    this.renderView.lottie = this
  }

  aboutToDisappear() {
    this.renderView.lottie = null
    lottie.destroy();
  }

  build(): void {
    Stack() {
      Canvas(this.canvasRenderingContext)
        .onReady(() => {
          LogUtils.e(this.TAG, "=========onReady=====1=====>>>>")
          // 加载动画
          if (this.animateItem != null) {
            LogUtils.e(this.TAG, "=========onReady====2=====>>>>")
            // 可在此生命回调周期中加载动画，可以保证动画尺寸正确
            this.animateItem?.resize();
          } else {
            // 抗锯齿的设置
            LogUtils.e(this.TAG, "=========onReady=====3=====>>>>")
            this.canvasRenderingContext.imageSmoothingEnabled = true;
            this.canvasRenderingContext.imageSmoothingQuality = 'medium';
            this.loadAnimation();
          }
        })
    }
    .applyRenderViewBaseAttr(this.renderView)
  }

  loadAnimation() {
    LogUtils.e(this.TAG, "=========loadAnimation=====4====>>>>")
    this.animateItem = lottie.loadAnimation({
      container: this.canvasRenderingContext,
      renderer: 'canvas', // canvas 渲染模式
      loop: true,
      autoplay: false,
      name: this.animateName,
      contentMode: 'Contain',
      uri: "https://assets7.lottiefiles.com/packages/lf20_sF7uci.json",
      // path: 'https://extcdn.hsrc.tv/channelzero_image/web_static/extend_screen/mood/lottie1.json',
    })
    // 因为动画是异步加载，所以对animateItem的操作需要放在动画加载完成回调里操作
    if (this.animateItem != null) {
      this.animateItem.addEventListener('DOMLoaded', (args: Object): void => {
        if (this.animateItem) {
          // this.animateItem.changeColor([225, 25, 100, 1]);
          LogUtils.e(this.TAG, "=========loadAnimation=====play===>>>>")
          this.animateItem.play();
        }
      });
    }
  }

  destroy() {
    if (this.animateItem) {
      this.animateItem.removeEventListener('DOMLoaded');
    }
    lottie.destroy(this.animateName);
    this.animateItem = null;
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

