import {
  HippyRenderBaseView,
  HippyObservedArray,
  NativeRenderContext,
  HippyAny,
  HIPPY_COMPONENT_KEY_PREFIX,
} from 'hippy'
import { QTBaseComponentView } from '../QTBaseComponentView';


@Observed
export class QTPlayMarkView extends QTBaseComponentView {
  public color: string = '#ffffff';

  constructor(ctx: NativeRenderContext) {
    super(ctx)
  }

  setProp(propKey: string, propValue: HippyAny): boolean {
    if (propKey === 'color') {
      this.color = propValue as string;
      return true;
    }
    return super.setProp(propKey, propValue)
  }
}

@Component
export struct QTPlayMark {
  @ObjectLink renderView: QTPlayMarkView
  @ObjectLink children: HippyObservedArray<HippyRenderBaseView>
  // ---------- 可配置属性（外部可以绑定/设置） ----------
  @Prop showType: number = 0; // 0: bottomWaveView, 1: centerWaveView
  @Prop gap: number = -1; // -1: 自动计算
  @Prop roundCorner: number = 3;
  @Prop isSupportGradient: number = 0; // 0: 不支持, 1: 支持
  @Prop startColor: string = '#FF8534';
  @Prop endColor: string = '#FFCA37';
  @Prop barColor: string = '#FFFFFF'; // 当不使用渐变时的纯色
  @Prop visible: boolean = true; // 可控制显示/隐藏

  // ---------- 内部状态 ----------
  @State private canvasWidth: number = 50;
  @State private canvasHeight: number = 50;
  private readonly BARS: number = 4;
  private bars: BarState[] = [];
  private rafId: number | null = null;
  private lastTimestamp: number = 0;
  private attached: boolean = false;
  // 默认参数（借鉴 Java 源）
  private readonly barStartRate = [0.8, 0.9, 1.0, 0.5];
  private readonly barEndRate = [0.2, 0.4, 0.2, 0.1];
  private readonly durations = [200, 190, 180, 180]; // ms 单次变动（我们会乘 2 用作往返）
  private readonly delays = [0, 0, 0, 20]; // ms

  private settings: RenderingContextSettings = new RenderingContextSettings(true);
  private context: CanvasRenderingContext2D = new CanvasRenderingContext2D(this.settings);

  build() {
    Canvas(this.context)
      .applyRenderViewBaseAttr(this.renderView)
      .onReady(() => {
        // 保存画布尺寸（用于动画计算）
        this._ensureBarsInitialized();
        this._drawAllBars(this.context);
      })
  }

  // 生命周期函数 —— 当组件即将展示时启动动画，当离开时停止（符合 ArkTS 生命周期建议）。详见官方 lifecycle 文档。
  aboutToAppear() {
    this.attached = true;
    this.startLoop();
  }

  aboutToDisappear() {
    this.attached = false;
    this.stopLoop();
  }

  // 外部属性变化时可触发重建 bars（例如 gap, showType, color 等）
  // @Watch('gap')
  // @Watch('showType')
  // @Watch('roundCorner')
  // @Watch('isSupportGradient')
  // @Watch('startColor')
  // @Watch('endColor')
  // onPropChange() {
  //   // 下一帧重新计算 bars 布局
  //   this._resetBars();
  // }

  // ---------- 动画循环（requestAnimationFrame） ----------
  private startLoop() {
    if (this.rafId != null) {
      return;
    }
    this.lastTimestamp = 0;
    const step = (timestamp: number) => {
      if (!this.attached || !this.visible) {
        this.rafId = null;
        return;
      }
      if (!this.lastTimestamp) {
        this.lastTimestamp = timestamp;
      }
      const delta = timestamp - this.lastTimestamp;
      this.lastTimestamp = timestamp;

      // 更新每个 bar 的进度
      for (let i = 0; i < this.bars.length; i++) {
        const b = this.bars[i];
        // 使用时间推进，用 duration（往返周期 = duration * 2）和 delay 来计算当前值
        b.elapsed += delta;
        // 考虑 delay：当 elapsed < delay 则不开始
        const localTime = Math.max(0, b.elapsed - b.delay);
        const cycle = b.duration * 2; // 来回一个周期
        const t = localTime % cycle;
        // 反转效果（ValueAnimator.REVERSE）：
        let progress = t / b.duration;
        if (progress > 1) { // second half (reverse)
          progress = 2 - progress;
        }
        // 线性插值（可按需加入 easing）
        const value = b.startY + (b.endY - b.startY) * progress;
        b.currentValue = value;
        // 更新 rect
        if (b.type === 0) {
          b.top = this.canvasHeight - value;
          b.bottom = this.canvasHeight;
        } else {
          b.top = this.canvasHeight / 2 - value / 2;
          b.bottom = this.canvasHeight / 2 + value / 2;
        }
      }

      // 请求 Canvas 重绘（ArkTS Canvas 会在下次 render 时使用 onDraw）
      // 在 Stage 模型里，修改 @State 驱动渲染更稳妥；这里我们直接触发一个微小 state 变化以促发重绘：
      // 但为避免频繁 state 写入，我们直接用内置 Canvas 刷新机制：调用 framework 重绘（不同版本可能名称不同）。
      // 最简兼容方式：通过 changing a dummy state counter（如果你的框架支持的话）。这里为通用示例：调用 engine.requestUpdate() 的替代是 setState toggling。
      // 因为不同 ArkTS 版本对强制重绘接口不同，这里我们使用一个微小 hack：改变一个内部 @State（若你的项目中不喜欢，可以改为官方 API）
      // 例如：this._frameTick = (this._frameTick + 1) % 100000;
      // 我们假定 Canvas 的 onDraw 会在下一帧被调用。
      // （注意：实际集成时如需改为官方触发重绘 API，请替换为对应接口）
      this._requestCanvasRedraw();

      // this.rafId = requestAnimationFrame(this.step);
    };

    // this.rafId = globalThis.requestAnimationFrame(step);
  }

  private stopLoop() {
    if (this.rafId != null) {
      // globalThis.cancelAnimationFrame?.(this.rafId);
      this.rafId = null;
    }
  }

  // ---------- 内部绘制与 bar init ----------
  private _ensureBarsInitialized() {
    // 如果已有 bars 并且 canvas 尺寸未变化则跳过重建
    if (this.bars.length === this.BARS && !this._needRecreate) {
      return;
    }
    this._createBars();
    this._needRecreate = false;
  }

  private _needRecreate: boolean = true;

  private _resetBars() {
    this._needRecreate = true;
  }

  private _createBars() {
    // 清理旧数据并初始化 bars 布局
    this.bars = [];
    // 计算 gap 与 barWidth
    const gap = this.gap > 0 ? this.gap : Math.floor(this.canvasWidth * 0.1);
    const barWidth = Math.floor((this.canvasWidth - (this.BARS - 1) * gap) / this.BARS);
    let startX = 0;
    for (let i = 0; i < this.BARS; i++) {
      const startY = Math.max(1, Math.floor(this.canvasHeight * this.barStartRate[i]));
      const endY = Math.max(1, Math.floor(this.canvasHeight * this.barEndRate[i]));
      const duration = Math.max(20, this.durations[i]);
      const delay = this.delays[i];
      const bar: BarState = {
        x: startX,
        width: barWidth,
        startY,
        endY,
        duration,
        delay,
        elapsed: 0,
        currentValue: startY,
        top: this.canvasHeight - startY,
        bottom: this.canvasHeight,
        round: this.roundCorner,
        type: this.showType
      };
      this.bars.push(bar);
      startX += barWidth + gap;
    }
  }

  // 绘制所有 bars（在 Canvas onDraw 中被调用）
  private _drawAllBars(ctx: CanvasRenderingContext2D) {
    // 清空画布（默认透明背景）
    ctx.clearRect(0, 0, this.canvasWidth, this.canvasHeight);

    for (let i = 0; i < this.bars.length; i++) {
      const b = this.bars[i];
      if (!b) {
        continue;
      }

      // 填充样式：渐变 or 单色
      if (this.isSupportGradient === 1) {
        // 横向渐变从 rect.top 到 rect.bottom（或可按需横向）
        // createLinearGradient(x0, y0, x1, y1)
        const g = ctx.createLinearGradient(b.x, b.top, b.x + b.width, b.bottom);
        g.addColorStop(0, this.startColor);
        g.addColorStop(1, this.endColor);
        ctx.fillStyle = g;
      } else {
        ctx.fillStyle = this.barColor || this.startColor;
      }

      // 绘制圆角矩形（手动 path）
      const left = b.x;
      const top = b.top;
      const right = b.x + b.width;
      const bottom = b.bottom;
      const r = Math.min(b.round, Math.min(b.width / 2, (bottom - top) / 2));

      ctx.beginPath();
      // top-left
      ctx.moveTo(left + r, top);
      ctx.lineTo(right - r, top);
      ctx.quadraticCurveTo(right, top, right, top + r);
      ctx.lineTo(right, bottom - r);
      ctx.quadraticCurveTo(right, bottom, right - r, bottom);
      ctx.lineTo(left + r, bottom);
      ctx.quadraticCurveTo(left, bottom, left, bottom - r);
      ctx.lineTo(left, top + r);
      ctx.quadraticCurveTo(left, top, left + r, top);
      ctx.closePath();
      ctx.fill();
    }
  }

  // 触发 Canvas 重绘的小工具（不同 ArkTS 版本可能有更直接的方法）
  private _frameTick: number = 0;

  private _requestCanvasRedraw() {
    // 切换一个 @State 变量以触发框架重新绘制 Canvas（多数 ArkTS 框架将观测 state 变动）
    // 如果你有更合适的重绘 API（例如 Canvas.forceRender()），可以替换这里。
    this._frameTick = (this._frameTick + 1) % 100000;
  }
}

// Bar 的内部状态描述（Type）
interface BarState {
  x: number;
  width: number;
  startY: number;
  endY: number;
  duration: number; // ms 单次（往返周期 = duration*2）
  delay: number; // ms 起始延迟
  elapsed: number; // 累积时间，用于计算 progress
  currentValue: number;
  top: number;
  bottom: number;
  round: number;
  type: number; // showType
}


// base props for all components
@Extend(Canvas)
function applyRenderViewBaseAttr($$: HippyRenderBaseView) {
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
