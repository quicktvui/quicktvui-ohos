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
  public roundCorner: number = 3
  public startColor: string = '#FF8534'
  public endColor: string = '#FFCA37'
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
  // 动画状态
  private timer: number = 0
  private readonly BAR_COUNT = 4
  private readonly interval = 16 // 约 60fps
  private bars: BarState[] = []
  private settings: RenderingContextSettings = new RenderingContextSettings(true)
  private ctx: CanvasRenderingContext2D = new CanvasRenderingContext2D(this.settings)

  aboutToAppear() {
    this.initBars()
    this.timer = setInterval(() => {
      this.updateBars()
      this.draw()
    }, this.interval)
  }

  aboutToDisappear() {
    clearInterval(this.timer)
    this.timer = -1
  }

  private initBars() {
    const viewWidth = this.parseSize(this.renderView.cssWidth, 100)
    const gap = this.renderView.gap > 0 ? this.renderView.gap : viewWidth * 0.1
    const barWidth = (viewWidth - (this.BAR_COUNT - 1) * gap) / this.BAR_COUNT

    const barStartRates = [0.8, 0.9, 1.0, 0.5]
    const barEndRates = [0.2, 0.4, 0.2, 0.1]
    const duration = [200, 190, 180, 180]
    const delays = [0, 0, 0, 20]

    this.bars = []
    let startX = 0
    for (let i = 0; i < this.BAR_COUNT; i++) {
      this.bars.push(new BarState(
        startX,
        barWidth,
        barStartRates[i],
        barEndRates[i],
        duration[i],
        delays[i],
        this.renderView.showType
      ))
      startX += barWidth + gap
    }
  }

  private updateBars() {
    const now = Date.now()
    this.bars.forEach((bar): void => bar.update(now))
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
      this.drawRoundRect(ctx, bar.x, top, bar.width, bottom - top, radius)
    }
  }

  private drawRoundRect(ctx: CanvasRenderingContext2D, x: number, y: number, w: number, h: number, r: number) {
    ctx.beginPath()
    ctx.moveTo(x + r, y)
    ctx.lineTo(x + w - r, y)
    ctx.quadraticCurveTo(x + w, y, x + w, y + r)
    ctx.lineTo(x + w, y + h - r)
    ctx.quadraticCurveTo(x + w, y + h, x + w - r, y + h)
    ctx.lineTo(x + r, y + h)
    ctx.quadraticCurveTo(x, y + h, x, y + h - r)
    ctx.lineTo(x, y + r)
    ctx.quadraticCurveTo(x, y, x + r, y)
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

// 条形波动画状态
class BarState {
  private lastUpdate = Date.now()
  private progress = 0
  private direction = 1
  public x: number;
  public width: number;
  public startRate: number;
  public endRate: number;
  public duration: number;
  public delay: number;
  public type: number;

  constructor(
    x: number,
    width: number,
    startRate: number,
    endRate: number,
    duration: number,
    delay: number,
    type: number
  ) {
    this.x = x;
    this.width = width;
    this.startRate = startRate;
    this.endRate = endRate;
    this.duration = duration;
    this.delay = delay;
    this.type = type;
  }

  update(now: number) {
    const elapsed = now - this.lastUpdate - this.delay
    if (elapsed < 0) {
      return
    }
    const cycle = this.duration
    const t = (elapsed % cycle) / cycle
    this.progress = this.direction === 1 ? t : 1 - t

    if (elapsed % (2 * cycle) >= cycle) {
      this.direction = -this.direction
    }
  }

  getValue(): number {
    return this.startRate - (this.startRate - this.endRate) * this.progress
  }
}

// 通用 Canvas 属性扩展
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
  .visibility($$.cssVisibility)
  .zIndex($$.cssZIndex)
  .transform($$.cssMatrix)
  .rotate($$.cssRotate)
  .scale($$.cssScale)
  .translate($$.cssTranslate)
}