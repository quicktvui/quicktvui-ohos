import {
  HippyRenderBaseView,
  HippyObservedArray,
  NativeRenderContext,
  HippyAny,
  HippyRenderCallback,
  HIPPY_COMPONENT_KEY_PREFIX,
  buildHippyRenderView
} from 'hippy'
import { QTBaseComponentView } from '../QTBaseComponentView';
import { QTPageView } from './QTPageView';

@Observed
export class QTPageRouterView extends QTBaseComponentView {
  public event: QTPageRouter | null = null

  constructor(ctx: NativeRenderContext) {
    super(ctx)
  }

  setProp(propKey: string, propValue: HippyAny): boolean {
    return super.setProp(propKey, propValue)
  }

  call(method: string, params: Array<HippyAny>, callback: HippyRenderCallback | null): void {
    if (this.event && this.event.call(method, params, callback)) {
      return;
    }
    super.call(method, params, callback)
  }
}

@Component
export struct QTPageRouter {
  @ObjectLink renderView: QTPageRouterView
  @ObjectLink children: HippyObservedArray<HippyRenderBaseView>

  public call(method: string, params: Array<HippyAny>,
    callback: HippyRenderCallback | null): boolean {
    return false
  }

  aboutToAppear(): void {
    this.renderView.event = this
  }

  aboutToDisappear() {
    this.renderView.event = null
  }

  /**
   * 核心逻辑：获取当前应该显示的 Children 列表
   * 从后往前找，找到第一个非 Dialog 的页面，将其以及它上面的所有页面返回
   */
  private getVisibleChildren(): Array<HippyRenderBaseView> {
    if (!this.children || this.children.length === 0) {
      return [];
    }

    let visibleStartIndex = 0;
    const count = this.children.length;

    // 倒序寻找基座（第一个非 Dialog 的页面）
    for (let i = count - 1; i >= 0; i--) {
      const item = this.children[i];
      // 安全获取 isDialogMode 属性
      let isDialog = false;
      if (item instanceof QTPageView) {
        isDialog = item.isDialogMode;
      } else {
        // 处理非 TS 类型安全的情况，或者 item 不是 QTPageView 的情况
        isDialog = (item as QTPageView).isDialogMode === true;
      }

      if (!isDialog) {
        visibleStartIndex = i;
        break; // 找到了底座，停止
      }
    }

    // 利用 slice 返回一个新的子数组（浅拷贝，item引用不变，不会影响 key 的生成）
    // 注意：如果 HippyObservedArray 不支持 slice，可能需要用 Array.from(this.children).slice(...)
    return this.children.slice(visibleStartIndex);
  }

  build(): void {
    Stack() {
      ForEach(this.getVisibleChildren(), (item: HippyRenderBaseView) => {
        buildHippyRenderView(item, null)
      }, (item: HippyRenderBaseView) => item ? item.tag + '' : '')
      ContentSlot(this.renderView.childSlot)
    }
    .applyRenderViewBaseAttr(this.renderView)
  }
}

// base props for all components
@Extend(Stack)
function applyRenderViewBaseAttr($$: HippyRenderBaseView) {
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
}

