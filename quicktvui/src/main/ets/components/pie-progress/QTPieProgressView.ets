import {
  HippyRenderBaseView,
  HippyObservedArray,
  NativeRenderContext,
  HippyAny,
  HIPPY_COMPONENT_KEY_PREFIX,
} from 'hippy'
import { QTBaseComponentView } from '../QTBaseComponentView';

/**
 * 逻辑层：QTPieProgressView
 * 管理进度数据和重绘通知
 */
@Observed
export class QTPieProgressView extends QTBaseComponentView {
  public color: string = '#FF6600'; // 亮色（扫描过的区域）
  public trackColor: string = '#E0E0E0'; // 暗色（未扫描的底色）
  public progress: number = 0; // 进度 0-100

  public needsDraw: () => void = () => {
  };

  constructor(ctx: NativeRenderContext) {
    super(ctx)
  }

  setProp(propKey: string, propValue: HippyAny): boolean {
    let shouldRedraw = false;

    if (propKey === 'color') {
      this.color = propValue as string;
      shouldRedraw = true;
    } else if (propKey === 'trackColor') { // 如果需要动态改底色
      this.trackColor = propValue as string;
      shouldRedraw = true;
    } else if (propKey === 'progress') {
      let val = Number(propValue);
      if (isNaN(val)) {
        val = 0;
      }
      this.progress = Math.min(Math.max(val, 0), 100);
      shouldRedraw = true;
    }

    if (shouldRedraw) {
      this.needsDraw();
      return true;
    }
    return super.setProp(propKey, propValue)
  }
}

/**
 * UI层：QTPieProgress
 * 负责 Canvas 绘制
 */
@Component
export struct QTPieProgress {
  @ObjectLink renderView: QTPieProgressView
  @ObjectLink children: HippyObservedArray<HippyRenderBaseView>
  private settings: RenderingContextSettings = new RenderingContextSettings(true);
  private context: CanvasRenderingContext2D = new CanvasRenderingContext2D(this.settings);

  aboutToDisappear() {
    this.renderView.needsDraw = () => {
    };
  }

  draw() {
    const w = typeof this.renderView.cssWidth === 'number' ? this.renderView.cssWidth :
      parseFloat(this.renderView.cssWidth) || 100;
    const h = typeof this.renderView.cssHeight === 'number' ? this.renderView.cssHeight :
      parseFloat(this.renderView.cssHeight) || 100;

    const centerX = w / 2;
    const centerY = h / 2;
    const borderWidth = 2; // 外边框宽度
    const radius = Math.min(centerX, centerY) - borderWidth;

    this.context.clearRect(0, 0, w, h);

    // 1. 绘制底色 (全圆)
    this.context.beginPath();
    this.context.arc(centerX, centerY, radius, 0, 2 * Math.PI);
    this.context.fillStyle = this.renderView.trackColor;
    this.context.fill();

    // 2. 绘制进度 (扇形扫描)
    if (this.renderView.progress > 0) {
      this.context.beginPath();
      this.context.moveTo(centerX, centerY); // 关键：移回圆心
      const startAngle = -Math.PI / 2;
      const endAngle = startAngle + (Math.PI * 2 * (this.renderView.progress / 100));
      this.context.arc(centerX, centerY, radius, startAngle, endAngle);
      this.context.closePath();
      this.context.fillStyle = this.renderView.color;
      this.context.fill();
    }

    // 3. 绘制外边框
    this.context.beginPath();
    this.context.arc(centerX, centerY, radius, 0, 2 * Math.PI);
    this.context.strokeStyle = this.renderView.color;
    this.context.lineWidth = borderWidth;
    this.context.stroke();

    // 4. 绘制百分比文字
    this.context.font = 'bold 30px sans-serif'; // 根据组件大小可能需要动态计算字体大小
    this.context.textAlign = 'center';
    this.context.textBaseline = 'middle';

    // 文字描边+填充，确保可视性
    this.context.lineWidth = 1;
    this.context.strokeStyle = '#000000';
    this.context.strokeText(`${Math.round(this.renderView.progress)}%`, centerX, centerY);

    this.context.fillStyle = '#FFFFFF';
    this.context.fillText(`${Math.round(this.renderView.progress)}%`, centerX, centerY);
  }

  build() {
    Canvas(this.context)
      .applyRenderViewBaseAttr(this.renderView)
      .onReady(() => {
        this.renderView.needsDraw = () => {
          this.draw();
        };
        this.draw();
      })
  }
}

// Extend 部分不变
@Extend(Canvas)
function applyRenderViewBaseAttr($$: QTBaseComponentView) {
  .key(HIPPY_COMPONENT_KEY_PREFIX + $$.tag)
  .backgroundColor($$.cssBackgroundColor)
  .position({ x: $$.cssPositionX, y: $$.cssPositionY })
  .size({
    width: typeof $$.cssWidth === 'number' ? $$.cssWidth : parseFloat($$.cssWidth) || 100,
    height: typeof $$.cssHeight === 'number' ? $$.cssHeight : parseFloat($$.cssHeight) || 100,
  })
  .opacity($$.cssOpacity)
  .clip($$.cssOverflow)
  .visibility(($$ as HippyRenderBaseView).cssVisibility)
  .zIndex($$.cssZIndex)
  .accessibilityText($$.cssAccessibilityLabel)
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