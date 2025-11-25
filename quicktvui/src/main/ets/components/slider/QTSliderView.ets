import {
  HippyRenderBaseView,
  HippyObservedArray,
  NativeRenderContext,
  HippyAny,
  HIPPY_COMPONENT_KEY_PREFIX,
  HippyRenderCallback,
} from 'hippy'
import { QTBaseComponentView } from '../QTBaseComponentView';
import { ColorMetrics } from '@kit.ArkUI';
import { QTMap } from '../../QTTypes';
import { HRValueUtils } from '../../HRValueUtils';

@Observed
export class QTSliderView extends QTBaseComponentView {
  public color: string = '#ffffff'; // 进度条颜色
  public progress: number = 20;
  public maxProgress: number = 100;
  public minProgress: number = 0;
  public step: number = 0;
  public progressDefaultColor: string = ''; // 进度条背景颜色
  public setIndicatorBackgroundColor: string= '#ffffff' // 指示器背景颜色
  public progressHeight: number = 10; // 进度条的高度
  public progressRadius: number = 0;  // 进度条的圆角
  public slideRange: SlideRange = {}; // 有效滑动区间
  public thumbWidth: number = 40; // 滑块的宽
  public thumbHeight: number = 40; // 滑块的高
  public thumbType: SliderBlockType = SliderBlockType.DEFAULT; // 滑块形状参数类型
  public blockUrl: string = ""; // 滑块图片值
  public thumbUrl: string = ""; // 滑块形状激活图片
  public thumbInactivatedUrl: string = ""; // 滑块形状未激活图片
  public blockDrawable: EllipseOptions = {}; // 滑块自定义形状值
  public thumbDrawable: EllipseOptions = {}; //滑块形状激活样式
  public thumbInactivatedDrawable: EllipseOptions = {}; //滑块形状未激活样式
  public thumbBorderColor: string = ""; // 滑块描边颜色
  public thumbInactivatedBorderColor: string = ""; // 滑块未激活描边颜色
  public blockBorderColor: string = ""; // 滑块描边颜色值
  public thumbBorderWidth: number = 0; // 滑块描边粗细
  public thumbInactivatedBorderWidth: number = 0; // 滑块未激活描边粗细
  public blockBorderWidth: number = 0; // 滑块描边粗细值
  public enableFocusBorder: boolean = true; // 启用焦点边框
  public focusable: boolean = true; // 是否获焦
  public showTips: boolean = false; // 气泡是否显示
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
      case 'enableFocusBorder': {
        this.enableFocusBorder = propValue as boolean;
        return true;
      }
      case 'focusable': {
        this.focusable = propValue as boolean;
        return true;
      }
    }
    return super.setProp(propKey, propValue)
  }

  call(method: string, params: Array<HippyAny>, callback: HippyRenderCallback | null): void {
    switch (method) {
      case 'setProgress': {
        this.progress = params[0] as number;
        break;
      }
      case 'setMaxProgress': {
        this.maxProgress = params[0] as number;
        break;
      }
      case 'setProgressColor': {
        this.color = params[0] as string;
        break;
      }
      case 'setProgressDefaultColor': {
        this.progressDefaultColor = params[0] as string;
        break;
      }
      case 'setSeekBarMode': {
        // 单向 范围
        break;
      }
      case 'setProgressHeight': {
        this.progressHeight = params[0] as number;
        break;
      }
      case 'setGravity': {
        // 设置内部对齐方式
        break;
      }
      case 'setProgressRadius': {
        this.progressRadius = params[0] as number;
        break;
      }
      case 'setRange': {
        let from = params[0] as number;
        let to = params[1] as number;
        this.step = params[2] as number;
        this.maxProgress = params[1] as number;
        this.slideRange = {from, to};
        break;
      }
      case 'setThumbWidth': {
        this.thumbWidth = params[0] as number;
        break;
      }
      case 'setThumbHeight': {
        this.thumbHeight = params[0] as number;
        break;
      }
      case 'setThumbUrl': {
        this.thumbUrl = params[0] as string;
        break;
      }
      case 'setThumbInactivatedUrl': {
        this.thumbType = SliderBlockType.IMAGE;
        this.thumbInactivatedUrl = params[0] as string;
        this.blockUrl = params[0] as string;
        break;
      }
      case 'setThumbDrawable': {
        let initParam : QTMap = params[0] as QTMap;
        let colors: HippyAny = initParam.get('colors') as string;
        let cornerRadius: number = HRValueUtils.getNumberValue('cornerRadius',initParam,100);
        let orientation: number = HRValueUtils.getNumberValue('orientation',initParam,1);
        this.thumbDrawable = {width:cornerRadius ,height:cornerRadius};
        this.thumbBorderColor = colors;
        this.thumbBorderWidth = orientation;
        break;
      }
      case 'setThumbInactivatedDrawable': {
        this.thumbType = SliderBlockType.SHAPE;
        let initParam : QTMap = params[0] as QTMap;
        let colors = initParam.get('colors') as string;
        let cornerRadius = HRValueUtils.getNumberValue('cornerRadius',initParam,100);
        let orientation = HRValueUtils.getNumberValue('orientation',initParam,1);
        this.thumbInactivatedDrawable = {width:cornerRadius ,height:cornerRadius};
        this.thumbInactivatedBorderColor = colors;
        this.thumbInactivatedBorderWidth = orientation;
        // 未激活给页面的初始值
        this.blockDrawable = this.thumbInactivatedDrawable;
        this.blockBorderColor = this.thumbInactivatedBorderColor;
        this.blockBorderWidth = this.thumbInactivatedBorderWidth;
        break;
      }
      case 'setIndicatorShowMode':
      case 'setIndicatorWidth':
      case 'setIndicatorHeight':
      case 'setIndicatorBackgroundColor':
      case 'setIndicatorRadius':
      case 'setIndicatorArrowSize':
      case 'setIndicatorTextColor':
      case 'setIndicatorTextSize':
      case 'setIndicatorMargin':
        this.showTips = true;
        break;
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
      value: this.renderView.progress,
      step: this.renderView.step,
      min: this.renderView.minProgress,
      max: this.renderView.maxProgress,
      style: SliderStyle.OutSet,
    })
      .applyRenderViewBaseAttr(this.renderView)
      .trackThickness(this.renderView.progressHeight) // 滑轨的粗细
      .trackBorderRadius(this.renderView.progressRadius) // 底板圆角半径
      .blockColor(this.renderView.setIndicatorBackgroundColor) // 滑块的背景颜色
      .trackColor(this.renderView.progressDefaultColor) // 滑轨的背景颜色
      .selectedColor(this.renderView.color) // 滑轨的已滑动部分颜色
      .slideRange(this.renderView.slideRange) // 有效滑动区间
      .blockSize({ width: this.renderView.thumbWidth, height: this.renderView.thumbHeight }) // 滑块的宽高
      .blockStyle({ type: this.renderView.thumbType, image: this.renderView.blockUrl, shape: new Ellipse(this.renderView.thumbDrawable) }) // 滑块的样式
      .blockBorderColor(this.renderView.blockBorderColor) // 滑块的边框颜色
      .blockBorderWidth(this.renderView.blockBorderWidth) // 滑块的边框宽度
      // .focusable(this.renderView.focusable) // 是否获焦
      // .focusBox({ strokeColor: this.renderView.enableFocusBorder?ColorMetrics.rgba(0, 0, 255, 1):ColorMetrics.rgba(0, 0, 0, 0) }) // 获焦之后的样式
      .showTips(this.renderView.showTips) // 是否显示气泡
      .onFocus(() => {
        // 失去焦点是激活的初始值
        this.renderView.blockUrl = this.renderView.thumbUrl;
        this.renderView.blockDrawable = this.renderView.thumbDrawable;
        this.renderView.blockBorderColor = this.renderView.thumbBorderColor;
        this.renderView.blockBorderWidth = this.renderView.thumbBorderWidth;
      })
      .onBlur(() => {
        // 失去焦点是未激活的初始值
        this.renderView.blockUrl = this.renderView.thumbInactivatedUrl;
        this.renderView.blockDrawable = this.renderView.thumbInactivatedDrawable;
        this.renderView.blockBorderColor = this.renderView.thumbInactivatedBorderColor;
        this.renderView.blockBorderWidth = this.renderView.thumbInactivatedBorderWidth;
      })
  }
}

// base props for all components
@Extend(Slider)
function applyRenderViewBaseAttr($$: QTBaseComponentView) {
  .key(HIPPY_COMPONENT_KEY_PREFIX + $$.tag)
  .backgroundColor($$.cssBackgroundColor)
  .position({ x: $$.cssPositionX, y: $$.cssPositionY })
  .size({ width: $$.cssWidth, height: $$.cssHeight })
  .opacity($$.cssOpacity)
  .clip($$.cssOverflow)
  .visibility(($$ as HippyRenderBaseView).cssVisibility) // must add as, otherwise the compiler has error
  .zIndex($$.cssZIndex)
  .accessibilityText($$.cssAccessibilityLabel)
  // .focusable($$.cssFocusable)
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
  .key($$.name)
  .id($$.sid)
  .visibility($$.visibility)
}
