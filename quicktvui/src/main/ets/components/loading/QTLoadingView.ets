import {
  HippyRenderBaseView,
  HippyObservedArray,
  NativeRenderContext,
  HippyAny,
  HIPPY_COMPONENT_KEY_PREFIX,
} from 'hippy'
import { QTBaseComponentView } from '../QTBaseComponentView';

@Observed
export class QTLoadingView extends QTBaseComponentView {
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
export struct QTLoading {
  @ObjectLink renderView: QTLoadingView
  @ObjectLink children: HippyObservedArray<HippyRenderBaseView>
  @State private rotation: number = 0;
  @State private startAngle: number = 270 - 30;
  @State private sweepAngle: number = 30;
  @State private timer: number = 0;
  private isExpanding: boolean = true;
  private readonly minSweep = 30;
  private readonly maxSweep = 240;
  private readonly strokeMin = 2;
  private readonly strokeMax = 12;
  private readonly rotationSpeed = 5;
  private settings: RenderingContextSettings = new RenderingContextSettings(true);
  private context: CanvasRenderingContext2D = new CanvasRenderingContext2D(this.settings);

  aboutToAppear() {
    const interval = 16 // 固定 60 FPS
    this.timer = setInterval(() => {
      this.rotation = (this.rotation + this.rotationSpeed) % 360;
      if (this.isExpanding) {
        this.sweepAngle += 6;
        if (this.sweepAngle > this.maxSweep) {
          this.sweepAngle = this.maxSweep - 6; // 提前反向
          this.isExpanding = false;
        }
      } else {
        this.sweepAngle -= 6;
        this.startAngle += 6;
        if (this.sweepAngle < this.minSweep) {
          this.sweepAngle = this.minSweep + 6; // 提前反向
          this.startAngle = (this.startAngle + 30) % 360;
          this.isExpanding = true;
        }
      }

      this.draw();
    }, interval);
  }

  aboutToDisappear() {
    clearInterval(this.timer);
    this.timer = -1
  }

  private draw() {
    if (!this.context) {
      return;
    }
    const width = typeof this.renderView.cssWidth === 'number'
      ? this.renderView.cssWidth
      : parseFloat(this.renderView.cssWidth) || 100;

    const height = typeof this.renderView.cssHeight === 'number'
      ? this.renderView.cssHeight
      : parseFloat(this.renderView.cssHeight) || 100;

    const size = Math.min(width, height);
    const center = size / 2;
    const radius = center - this.calcStroke(size) / 2;
    const ctx = this.context;

    ctx.clearRect(0, 0, size, size);
    ctx.save();
    ctx.translate(center, center);
    ctx.rotate(this.rotation * Math.PI / 180);
    ctx.translate(-center, -center);

    ctx.beginPath();
    ctx.lineWidth = this.calcStroke(size);
    ctx.strokeStyle = this.renderView.color;
    ctx.lineCap = 'round';
    ctx.arc(center, center, radius,
      this.startAngle * Math.PI / 180,
      (this.startAngle + this.sweepAngle) * Math.PI / 180);
    ctx.stroke();

    ctx.restore();
  }

  private calcStroke(size: number): number {
    const stroke = size / 8;
    return Math.max(this.strokeMin, Math.min(this.strokeMax, stroke));
  }

  build() {
    Canvas(this.context)
      .applyRenderViewBaseAttr(this.renderView)
      .onReady(() => {
        this.draw();
      })
  }
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
