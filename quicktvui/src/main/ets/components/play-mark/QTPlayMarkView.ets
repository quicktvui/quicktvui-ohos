import {
  HippyRenderBaseView,
  HippyObservedArray,
  NativeRenderContext,
  HippyAny,
  HIPPY_COMPONENT_KEY_PREFIX,
} from 'hippy'
import { QTBaseComponentView } from '../QTBaseComponentView'

@Observed
export class QTPlayMarkView extends QTBaseComponentView {
  public showType: number = 0 // 0 底部波动；1 中心波动
  public gap: number = -1
  public roundCorner: number = 6
  public startColor: string = '#FFFFFF'
  public endColor: string = '#FFFFFF'
  public isSupportGradient: number = 1

  constructor(ctx: NativeRenderContext) {
    super(ctx)
  }

  setProp(propKey: string, propValue: HippyAny): boolean {
    switch (propKey) {
      case 'showType':
        this.showType = propValue as number
        return true
      case 'gap':
        this.gap = propValue as number
        return true
      case 'roundCorner':
        this.roundCorner = propValue as number
        return true
      case 'startColor':
        this.startColor = propValue as string
        return true
      case 'endColor':
        this.endColor = propValue as string
        return true
      case 'isSupportGradient':
        this.isSupportGradient = propValue as number
        return true
    }
    return super.setProp(propKey, propValue)
  }
}

@Component
export struct QTPlayMark {
  @ObjectLink renderView: QTPlayMarkView
  @ObjectLink children: HippyObservedArray<HippyRenderBaseView>
  private timer: number = 0
  private readonly BAR_COUNT = 4
  private readonly FRAME_INTERVAL = 16
  private bars: BarState[] = []
  private settings: RenderingContextSettings = new RenderingContextSettings(true)
  private ctx: CanvasRenderingContext2D = new CanvasRenderingContext2D(this.settings)

  aboutToAppear() {
    this.initBars()
    const animate = () => {
      this.draw()
      this.timer = setTimeout(animate, this.FRAME_INTERVAL)
    }
    this.timer = setTimeout(animate, this.FRAME_INTERVAL)
  }

  aboutToDisappear() {
    clearTimeout(this.timer)
    this.timer = -1
  }

  private initBars() {
    const viewWidth = this.parseSize(this.renderView.cssWidth, 100)
    const gap = this.renderView.gap > 0 ? this.renderView.gap : viewWidth * 0.1
    const barWidth = (viewWidth - (this.BAR_COUNT - 1) * gap) / this.BAR_COUNT - 1
    const barHeightScale = 1.2 // 高度放大比例，可根据需要调整

    const barStartRates = [0.8, 0.8, 0.8, 0.8]
    const barEndRates = [0.2, 0.2, 0.2, 0.2]
    const duration = 720
    const phases = [0, 0.25, 0.5, 0.75]

    this.bars = []
    let startX = 0
    for (let i = 0; i < this.BAR_COUNT; i++) {
      this.bars.push(new BarState(
        startX,
        barWidth,
        barStartRates[i] * barHeightScale, // 高度放大
        barEndRates[i] * barHeightScale, // 高度放大
        duration,
        this.renderView.showType,
        phases[i]
      ))
      startX += barWidth + gap
    }
  }

  private draw() {
    const width = this.parseSize(this.renderView.cssWidth, 100)
    const height = this.parseSize(this.renderView.cssHeight, 60)
    const centerY = height / 2
    const ctx = this.ctx

    ctx.clearRect(0, 0, width, height)

    for (const bar of this.bars) {
      const value = bar.getValue()
      let top: number
      let bottom: number

      if (bar.type === 0) {
        bottom = height
        top = height - value * height
      } else {
        top = centerY - (value * height) / 2
        bottom = centerY + (value * height) / 2
      }

      if (this.renderView.isSupportGradient === 1) {
        const gradient = ctx.createLinearGradient(bar.x, top, bar.x + bar.width, bottom)
        gradient.addColorStop(0, this.renderView.startColor)
        gradient.addColorStop(1, this.renderView.endColor)
        ctx.fillStyle = gradient
      } else {
        ctx.fillStyle = this.renderView.startColor
      }

      const radius = this.renderView.roundCorner
      this.drawRoundWaveRect(ctx, bar.x, top, bar.width, bottom - top, radius)
    }
  }

  /** 上下圆角波浪矩形绘制 */
  private drawRoundWaveRect(ctx: CanvasRenderingContext2D, x: number, y: number, w: number, h: number, r: number) {
    ctx.beginPath()
    ctx.moveTo(x, y + r) // 起点左上角
    ctx.quadraticCurveTo(x, y, x + r, y) // top-left 圆角
    ctx.lineTo(x + w - r, y) // top-right 起点
    ctx.quadraticCurveTo(x + w, y, x + w, y + r) // top-right 圆角
    ctx.lineTo(x + w, y + h) // 直线到底部
    ctx.lineTo(x, y + h) // 底部直线回到左边
    ctx.closePath()
    ctx.fill()
  }

  private parseSize(v: string | number, def: number): number {
    if (typeof v === 'number') {
      return v
    }
    const n = parseFloat(v)
    return isNaN(n) ? def : n
  }

  build() {
    Canvas(this.ctx)
      .applyRenderViewBaseAttr(this.renderView)
      .onReady(() => this.draw())
  }
}

// 平滑条形动画状态（统一节奏、相位错落）
class BarState {
  public x: number
  public width: number
  public startRate: number
  public endRate: number
  public duration: number
  public type: number
  private startTime: number
  private phase: number

  constructor(
    x: number,
    width: number,
    startRate: number,
    endRate: number,
    duration: number,
    type: number,
    phase: number
  ) {
    this.x = x
    this.width = width
    this.startRate = startRate
    this.endRate = endRate
    this.duration = duration
    this.type = type
    this.phase = phase
    this.startTime = Date.now()
  }

  getValue(): number {
    const now = Date.now()
    const elapsed = ((now - this.startTime) / this.duration + this.phase) % 1
    const ease = 0.5 - 0.5 * Math.cos(elapsed * Math.PI * 2)
    return this.startRate + (this.endRate - this.startRate) * ease
  }
}

// 通用 Canvas 属性扩展
@Extend(Canvas)
function applyRenderViewBaseAttr($$: HippyRenderBaseView) {
  .key(HIPPY_COMPONENT_KEY_PREFIX + $$.tag)
  .backgroundColor($$.cssBackgroundColor)
  .position({ x: $$.cssPositionX, y: $$.cssPositionY })
  .size({
    width: typeof $$.cssWidth === 'number' ? $$.cssWidth : parseFloat($$.cssWidth) || 100,
    height: typeof $$.cssHeight === 'number' ? $$.cssHeight : parseFloat($$.cssHeight) || 100,
  })
  .opacity($$.cssOpacity)
  .visibility($$.cssVisibility)
  .zIndex($$.cssZIndex)
  .transform($$.cssMatrix)
  .rotate($$.cssRotate)
  .scale($$.cssScale)
  .translate($$.cssTranslate)
}