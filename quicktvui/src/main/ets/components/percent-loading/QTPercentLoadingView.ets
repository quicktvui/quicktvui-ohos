import {
  HippyRenderBaseView,
  HippyObservedArray,
  NativeRenderContext,
  HippyAny,
  HIPPY_COMPONENT_KEY_PREFIX,
} from 'hippy'
import { QTBaseComponentView } from '../QTBaseComponentView';

@Observed
export class QTPercentLoadingView extends QTBaseComponentView {
  public color: string = '#FF6600'; // 默认颜色，参考你图片的橙色
  public progress: number = 0; // 进度 0 - 100

  constructor(ctx: NativeRenderContext) {
    super(ctx)
  }

  // 定义一个回调函数，用于通知 UI 组件重绘
  public needsDraw: () => void = () => {
  };

  setProp(propKey: string, propValue: HippyAny): boolean {
    let shouldRedraw = false;

    if (propKey === 'color') {
      this.color = propValue as string;
      shouldRedraw = true;
    } else if (propKey === 'progress') {
      // 确保进度在 0-100 之间
      let val = Number(propValue);
      if (isNaN(val)) {
        val = 0;
      }
      this.progress = Math.min(Math.max(val, 0), 100);
      shouldRedraw = true;
    }

    if (shouldRedraw) {
      // 属性变化后，通知 Canvas 重绘
      this.needsDraw();
      return true;
    }
    return super.setProp(propKey, propValue)
  }
}

@Component
export struct QTPercentLoading {
  @ObjectLink renderView: QTPercentLoadingView
  @ObjectLink children: HippyObservedArray<HippyRenderBaseView>
  private settings: RenderingContextSettings = new RenderingContextSettings(true);
  private context: CanvasRenderingContext2D = new CanvasRenderingContext2D(this.settings);

  aboutToAppear() {

  }

  aboutToDisappear() {
    // 清理引用，防止内存泄漏
    this.renderView.needsDraw = () => {
    };
  }

  // 核心绘制逻辑
  draw() {
    // 获取宽高 (注意：QTBaseComponentView 中的 cssWidth 可能是字符串或数字)
    const w = typeof this.renderView.cssWidth === 'number' ? this.renderView.cssWidth :
      parseFloat(this.renderView.cssWidth) || 100;
    const h = typeof this.renderView.cssHeight === 'number' ? this.renderView.cssHeight :
      parseFloat(this.renderView.cssHeight) || 100;

    // 计算中心点和半径
    const centerX = w / 2;
    const centerY = h / 2;
    const lineWidth = 8; // 进度条宽度
    const radius = Math.min(centerX, centerY) - lineWidth; // 留出线宽的边距

    // 清空画布
    this.context.clearRect(0, 0, w, h);

    // 1. 绘制底色圆环 (灰色轨道)
    this.context.beginPath();
    this.context.lineWidth = lineWidth;
    this.context.strokeStyle = '#EEEEEE'; // 浅灰色底轨
    this.context.lineCap = 'round';
    this.context.arc(centerX, centerY, radius, 0, 2 * Math.PI);
    this.context.stroke();

    // 2. 绘制进度圆环 (有颜色的部分)
    if (this.renderView.progress > 0) {
      this.context.beginPath();
      this.context.lineWidth = lineWidth;
      this.context.strokeStyle = this.renderView.color;
      this.context.lineCap = 'round';

      // Canvas 的 0 度是在 3 点钟方向，我们需要从 12 点钟方向开始 (-90度)
      const startAngle = -Math.PI / 2;
      // 计算结束角度：起始角 + (2PI * 百分比)
      const endAngle = startAngle + (Math.PI * 2 * (this.renderView.progress / 100));

      this.context.arc(centerX, centerY, radius, startAngle, endAngle);
      this.context.stroke();
    }

    // 3. 绘制中间的文字 (例如 "85%")
    this.context.font = 'bold 30px sans-serif'; // 字体大小可根据实际需求调整
    this.context.fillStyle = this.renderView.color;
    this.context.textAlign = 'center';
    this.context.textBaseline = 'middle';
    this.context.fillText(`${Math.round(this.renderView.progress)}%`, centerX, centerY);
  }

  build() {
    Canvas(this.context)
      .applyRenderViewBaseAttr(this.renderView)
      .onReady(() => {
        // 1. 绑定重绘回调：当 View 层数据变化时，执行这里的 draw
        this.renderView.needsDraw = () => {
          this.draw();
        };
        // 2. 初始绘制
        this.draw();
      })
  }
}

// base props for all components
@Extend(Canvas)
function applyRenderViewBaseAttr($$: QTBaseComponentView) {
  .key(HIPPY_COMPONENT_KEY_PREFIX + $$.tag)
  .backgroundColor($$.cssBackgroundColor)
  .position({ x: $$.cssPositionX, y: $$.cssPositionY })
  .size({
    width:
    typeof $$.cssWidth === 'number'
      ? $$.cssWidth
      : parseFloat($$.cssWidth) || 100,
    height:
    typeof $$.cssHeight === 'number'
      ? $$.cssHeight
      : parseFloat($$.cssHeight) || 100,
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
