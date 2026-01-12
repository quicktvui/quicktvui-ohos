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
  public progress: number = 0;
  public showText: boolean = true;

  // 这里的颜色属性其实主要用于控制“要擦除的区域”和“留下的背景”
  // 背景色：黑色 70%
  public backgroundColor: string = 'rgba(0, 0, 0, 0.7)';
  // 镂空圆环的宽度
  public ringWidth: number = 3;
  // 圆角矩形的圆角半径 (对应 border-radius: 20px)
  public borderRadius: number = 20;

  public needsDraw: () => void = () => {
  };

  constructor(ctx: NativeRenderContext) {
    super(ctx)
  }

  setProp(propKey: string, propValue: HippyAny): boolean {
    let shouldRedraw = false;
    switch (propKey) {
      case 'progress':
        let pVal = Number(propValue);
        if (isNaN(pVal)) pVal = 0;
        this.progress = Math.min(Math.max(pVal, 0), 100);
        shouldRedraw = true;
        break;
      case 'showText':
        this.showText = Boolean(propValue);
        shouldRedraw = true;
        break;
      // ... 其他属性 setter
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

  // 辅助方法：绘制圆角矩形路径
  private drawRoundedRect(ctx: CanvasRenderingContext2D, x: number, y: number, width: number, height: number, radius: number) {
    ctx.beginPath();
    ctx.moveTo(x + radius, y);
    ctx.arcTo(x + width, y, x + width, y + height, radius);
    ctx.arcTo(x + width, y + height, x, y + height, radius);
    ctx.arcTo(x, y + height, x, y, radius);
    ctx.arcTo(x, y, x + width, y, radius);
    ctx.closePath();
  }

  draw() {
    const w = typeof this.renderView.cssWidth === 'number' ? this.renderView.cssWidth : parseFloat(this.renderView.cssWidth) || 176;
    const h = typeof this.renderView.cssHeight === 'number' ? this.renderView.cssHeight : parseFloat(this.renderView.cssHeight) || 100;

    const centerX = w / 2;
    const centerY = h / 2;
    // 计算半径：取高度的一半，减去一点padding防止贴边
    const maxRadius = Math.min(w, h) / 2 - 10;

    // 1. 重置画布
    this.context.clearRect(0, 0, w, h);

    // ==========================================
    // 第一步：绘制全屏的半透明黑色圆角矩形背景
    // ==========================================
    this.context.globalCompositeOperation = 'source-over'; // 默认模式：覆盖
    this.context.fillStyle = this.renderView.backgroundColor; // rgba(0,0,0,0.7)
    this.drawRoundedRect(this.context, 0, 0, w, h, this.renderView.borderRadius);
    this.context.fill();

    // ==========================================
    // 第二步：开启“擦除”模式 (destination-out)
    // 接下来画的所有东西都会让背景变透明
    // ==========================================
    this.context.globalCompositeOperation = 'destination-out';

    // A. 擦除“外圈圆环”
    if (this.renderView.ringWidth > 0) {
      this.context.beginPath();
      this.context.arc(centerX, centerY, maxRadius, 0, 2 * Math.PI);
      this.context.lineWidth = this.renderView.ringWidth;
      this.context.strokeStyle = 'red'; // 颜色无所谓，重要的是形状，它会变成透明
      this.context.stroke();
    }

    // B. 擦除“走过的进度扇形”
    if (this.renderView.progress > 0) {
      const startAngle = -Math.PI / 2;
      const progressRatio = this.renderView.progress / 100;
      const endAngle = startAngle + (Math.PI * 2 * progressRatio);

      // 扇形半径要比外圈稍微小一点点，或者一样大，看设计需求
      // 这里设为 maxRadius - ringWidth/2 保证扇形在圆环内部
      const fanRadius = maxRadius - (this.renderView.ringWidth / 2);

      this.context.beginPath();
      this.context.moveTo(centerX, centerY);
      this.context.arc(centerX, centerY, fanRadius, startAngle, endAngle);
      this.context.closePath();
      this.context.fillStyle = 'red'; // 颜色无所谓，这块区域会变成透明
      this.context.fill();
    }

    // ==========================================
    // 第三步：恢复正常绘制模式，绘制文字
    // ==========================================
    this.context.globalCompositeOperation = 'source-over';

    if (this.renderView.showText) {
      const fontSize = maxRadius * 0.5;
      this.context.font = `bold ${fontSize}px sans-serif`;
      this.context.textAlign = 'center';
      this.context.textBaseline = 'middle';

      // 文字颜色：白色
      this.context.fillStyle = '#FFFFFF';
      this.context.fillText(`${Math.round(this.renderView.progress)}%`, centerX, centerY);
    }
  }

  build() {
    Stack() {
      Canvas(this.context)
        .onReady(() => {
          this.renderView.needsDraw = () => {
            this.draw();
          };
          this.draw();
        })
    }
    .applyRenderViewBaseAttr(this.renderView)
  }
}

// @Extend 保持不变...
@Extend(Stack)
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