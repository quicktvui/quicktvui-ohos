import {
  HippyRenderBaseView,
  HippyObservedArray,
  NativeRenderContext,
  HippyAny,
  HIPPY_COMPONENT_KEY_PREFIX,
  HippyRenderCallback,
} from 'hippy'
import { QTBaseComponentView } from '../QTBaseComponentView';

@Observed
export class QTSliderView extends QTBaseComponentView {
  public color: string = '#ffffff';
  public progress: number = 20;
  public maxProgress: number = 100;
  public type: number = 0;
  public strokeWidth: number = 5;
  public enableSmoothEffect: boolean = false;
  public enableScanEffect: boolean = false;

  constructor(ctx: NativeRenderContext) {
    super(ctx)
  }

  setProp(propKey: string, propValue: HippyAny): boolean {
    switch (propKey) {
      case 'color': {
        this.color = propValue as string;
        return true;
      }
      case 'progress': {
        this.progress = propValue as number;
        return true;
      }
      case 'maxProgress': {
        this.maxProgress = propValue as number;
        return true;
      }
    }
    return super.setProp(propKey, propValue)
  }

  call(method: string, params: Array<HippyAny>, callback: HippyRenderCallback | null): void {
    if (method == "setProgress") {
      this.progress = params[0] as number;
    } else if (method == "setMaxProgress") {
      this.maxProgress = params[0] as number;
    } else if (method == "setProgressColor") {
      this.color = params[0] as string;
    } else if (method == "setProgressDefaultColor") {
      this.cssBackgroundColor = params[0] as number;
    }
  }
}

@Component
export struct QTSlider {
  @ObjectLink renderView: QTSliderView
  @ObjectLink children: HippyObservedArray<HippyRenderBaseView>

  aboutToAppear() {
    if (this.renderView.eventAttachedToWindow) {
      this.renderView.eventAttachedToWindow()
    }
  }

  aboutToDisappear() {
    if (this.renderView.eventDetachedFromWindow) {
      this.renderView.eventDetachedFromWindow()
    }
  }

  build() {
    Slider({
      value: 10,
      step: 10,
      style: SliderStyle.OutSet
    }).applyRenderViewBaseAttr(this.renderView)
  }
}

// base props for all components
@Extend(Slider)
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
