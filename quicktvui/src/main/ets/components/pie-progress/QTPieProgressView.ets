import {
  HippyRenderBaseView,
  HippyObservedArray,
  NativeRenderContext,
  HippyAny,
  HIPPY_COMPONENT_KEY_PREFIX,
} from 'hippy'
import { QTPixelUtil } from '../../utils/QTPixelUtil';
import { QTBaseComponentView } from '../QTBaseComponentView';

/**
 * 逻辑层：QTPieProgressView
 */
@Observed
export class QTPieProgressView extends QTBaseComponentView {
  public progress: number = 0;
  public showText: boolean = true;

  // 遮罩颜色：默认黑色 70% (rgba(0, 0, 0, 0.7))
  // 建议默认值写死，防止外部没传参时变黑
  public maskColor: string = 'rgba(0, 0, 0, 0.7)';

  public ringWidth: number = 5;
  public borderRadius: number = 10; // 默认圆角 20

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

      // 【核心修复】：拦截 backgroundColor
      case 'backgroundColor':
        // 1. 保存颜色给 Canvas 用 (这就是你要的 70% 黑)
        // 如果传入的是纯黑 hex，这里需要前端配合传 rgba，或者在这里做转换
        this.maskColor = propValue as string;

        // 2. 【强制透明】告诉父类/渲染层，容器本身必须是全透明的！
        // 使用 '#00000000' (8位Hex) 表示全透明，比 'transparent' 兼容性更好
        super.setProp('backgroundColor', '#00000000');

        // 如果父类有公开的 cssBackgroundColor 字段，建议也强制赋值一下
        // this.cssBackgroundColor = '#00000000';

        shouldRedraw = true;
        return true; // 拦截结束，不让父类处理原始颜色

      case 'maskColor':
        this.maskColor = propValue as string;
        shouldRedraw = true;
        break;

      case 'ringWidth':
      case 'borderWidth':
        let rwVal = Number(propValue);
        if (!isNaN(rwVal) && rwVal >= 0) {
          this.ringWidth = QTPixelUtil.dev2Vp(rwVal);
          shouldRedraw = true;
        }
        break;

      case 'borderRadius':
        let brVal = Number(propValue);
        if (!isNaN(brVal) && brVal >= 0) {
          this.borderRadius = QTPixelUtil.dev2Vp(brVal);
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

  private drawRoundedRect(ctx: CanvasRenderingContext2D, x: number, y: number, width: number, height: number, radius: number) {
    const maxRadius = Math.min(width, height) / 2;
    const r = Math.min(radius, maxRadius);

    ctx.beginPath();
    ctx.moveTo(x + r, y);
    ctx.arcTo(x + width, y, x + width, y + height, r);
    ctx.arcTo(x + width, y + height, x, y + height, r);
    ctx.arcTo(x, y + height, x, y, r);
    ctx.arcTo(x, y, x + width, y, r);
    ctx.closePath();
  }

  draw() {
    const w = typeof this.renderView.cssWidth === 'number' ? this.renderView.cssWidth : parseFloat(this.renderView.cssWidth) || 100;
    const h = typeof this.renderView.cssHeight === 'number' ? this.renderView.cssHeight : parseFloat(this.renderView.cssHeight) || 100;

    const centerX = w / 2;
    const centerY = h / 2;
    // 留一点边距防止边缘切割
    const maxRadius = Math.min(w, h) / 2 - 2;

    // 1. 彻底清空画布
    this.context.clearRect(0, 0, w, h);

    // ==========================================
    // 第一步：绘制遮罩背景 (70% 黑)
    // ==========================================
    this.context.globalCompositeOperation = 'source-over';
    this.context.fillStyle = this.renderView.maskColor;

    // 如果担心颜色太深，可以在这里强制锁死透明度 (可选)
    this.context.globalAlpha = 0.7;

    this.drawRoundedRect(this.context, 0, 0, w, h, this.renderView.borderRadius);
    this.context.fill();

    // 恢复 Alpha (如果上面设置了的话)
    // this.context.globalAlpha = 1.0;

    // ==========================================
    // 第二步：擦除镂空 (destination-out)
    // ==========================================
    this.context.globalCompositeOperation = 'destination-out';

    // A. 擦除“外圈圆环”
    if (this.renderView.ringWidth > 0) {
      this.context.beginPath();
      const ringRadius = maxRadius - (this.renderView.ringWidth / 2);
      this.context.arc(centerX, centerY, ringRadius, 0, 2 * Math.PI);
      this.context.lineWidth = this.renderView.ringWidth;
      this.context.strokeStyle = 'rgba(0,0,0,1)'; // 颜色不重要，越不透明擦得越干净
      this.context.stroke();
    }

    // B. 擦除“进度扇形”
    if (this.renderView.progress > 0) {
      const startAngle = -Math.PI / 2;
      const progressRatio = this.renderView.progress / 100;
      const endAngle = startAngle + (Math.PI * 2 * progressRatio);

      // 扇形半径：让它贴合圆环内侧
      const fanRadius = maxRadius - this.renderView.ringWidth;

      if (fanRadius > 0) {
        this.context.beginPath();
        this.context.moveTo(centerX, centerY);
        this.context.arc(centerX, centerY, fanRadius, startAngle, endAngle);
        this.context.closePath();
        this.context.fillStyle = 'rgba(0,0,0,1)'; // 颜色不重要，用来擦除
        this.context.fill();
      }
    }

    // ==========================================
    // 第三步：绘制文字 (source-over)
    // ==========================================
    this.context.globalCompositeOperation = 'source-over';

    if (this.renderView.showText) {
      const fontSize = (maxRadius - this.renderView.ringWidth) * 0.5;
      if (fontSize > 0) {
        this.context.font = `bold ${fontSize}px sans-serif`;
        this.context.textAlign = 'center';
        this.context.textBaseline = 'middle';

        this.context.lineWidth = 2;
        this.context.strokeStyle = 'rgba(0,0,0,0.5)';
        this.context.strokeText(`${Math.round(this.renderView.progress)}%`, centerX, centerY);

        this.context.fillStyle = '#FFFFFF';
        this.context.fillText(`${Math.round(this.renderView.progress)}%`, centerX, centerY);
      }
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

// Extend 保持不变...
@Extend(Stack)
function applyRenderViewBaseAttr($$: QTBaseComponentView) {
  .key(HIPPY_COMPONENT_KEY_PREFIX + $$.tag)
  .backgroundColor($$.cssBackgroundColor) // 这里现在会拿到 '#00000000' (透明)
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