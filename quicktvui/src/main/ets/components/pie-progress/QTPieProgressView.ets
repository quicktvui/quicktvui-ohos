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
 */
@Observed
export class QTPieProgressView extends QTBaseComponentView {
  public color: string = '#FF6600'; // 亮色
  public trackColor: string = '#E0E0E0'; // 暗色
  public progress: number = 0; // 进度

  // 新增属性
  public showText: boolean = true; // 是否显示中间文字，默认 true
  public borderWidth: number = 2; // 外圆边框宽度，默认 2

  public needsDraw: () => void = () => {
  };

  constructor(ctx: NativeRenderContext) {
    super(ctx)
  }

  setProp(propKey: string, propValue: HippyAny): boolean {
    let shouldRedraw = false;

    switch (propKey) {
      case 'color':
        this.color = propValue as string;
        shouldRedraw = true;
        break;
      case 'trackColor':
        this.trackColor = propValue as string;
        shouldRedraw = true;
        break;
      case 'progress':
        let pVal = Number(propValue);
        if (isNaN(pVal)) {
          pVal = 0;
        }
        this.progress = Math.min(Math.max(pVal, 0), 100);
        shouldRedraw = true;
        break;
      // 处理显示文字属性
      case 'showText':
        this.showText = Boolean(propValue);
        shouldRedraw = true;
        break;
      // 处理边框宽度属性
      case 'borderWidth':
        let bVal = Number(propValue);
        // 确保宽度不为负数
        if (!isNaN(bVal) && bVal >= 0) {
          this.borderWidth = bVal;
          shouldRedraw = true;
        }
        break;
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

    // 使用动态的边框宽度
    const borderWidth = this.renderView.borderWidth;
    // 半径减去边框宽度，确保边框完全在画布内
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
      this.context.moveTo(centerX, centerY);
      const startAngle = -Math.PI / 2;
      const endAngle = startAngle + (Math.PI * 2 * (this.renderView.progress / 100));
      this.context.arc(centerX, centerY, radius, startAngle, endAngle);
      this.context.closePath();
      this.context.fillStyle = this.renderView.color;
      this.context.fill();
    }

    // 3. 绘制外边框 (只有当宽度大于0时才绘制)
    if (borderWidth > 0) {
      this.context.beginPath();
      this.context.arc(centerX, centerY, radius, 0, 2 * Math.PI);
      this.context.strokeStyle = this.renderView.color;
      this.context.lineWidth = borderWidth;
      this.context.stroke();
    }

    // 4. 绘制百分比文字 (受 showText 控制)
    if (this.renderView.showText) {
      // 字体大小简单自适应：直径的 30%
      const fontSize = radius * 0.6;
      this.context.font = `bold ${fontSize}px sans-serif`;
      this.context.textAlign = 'center';
      this.context.textBaseline = 'middle';

      // 文字描边 + 填充
      this.context.lineWidth = 1;
      this.context.strokeStyle = '#000000';
      this.context.strokeText(`${Math.round(this.renderView.progress)}%`, centerX, centerY);

      this.context.fillStyle = '#FFFFFF';
      this.context.fillText(`${Math.round(this.renderView.progress)}%`, centerX, centerY);
    }
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

// Extend 保持不变
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