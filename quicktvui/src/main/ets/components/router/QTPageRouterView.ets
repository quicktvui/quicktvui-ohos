import {
  HippyRenderBaseView,
  HippyObservedArray,
  NativeRenderContext,
  HippyAny,
  HippyRenderCallback,
  HIPPY_COMPONENT_KEY_PREFIX,
  buildHippyRenderView,
  LogUtils
} from 'hippy'
import { QTBaseComponentView } from '../QTBaseComponentView';
import { PageManager } from './PageManager';
import { QTPageView } from './QTPageView'; // 导入 QTPageView

const TAG = "QTPageRouter";

@Observed
export class QTPageRouterView extends QTBaseComponentView {
  public event: QTPageRouter | null = null

  constructor(ctx: NativeRenderContext) {
    super(ctx)
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
    const uiContext = this.getUIContext();
    if (uiContext) {
      PageManager.setUIContext(uiContext);
    }
  }

  aboutToDisappear() {
    this.renderView.event = null
  }

  /**
   * 计算可见的起始索引。
   * 逻辑：从栈顶向下找，找到第一个“非透明背景”（isDialogMode=false）的页面。
   * 该页面及其之上的所有页面都应该可见。该页面之下的页面隐藏。
   */
  private getVisibleStartIndex(): number {
    if (!this.children || this.children.length === 0) {
      return 0;
    }

    const count = this.children.length;
    let visibleStartIndex = 0;

    // 倒序遍历（从栈顶往下找）
    for (let i = count - 1; i >= 0; i--) {
      const item = this.children[i];
      let isDialog = false;

      // 关键：判断 child 是否为 QTPageView，并读取 isDialogMode
      if (item instanceof QTPageView) {
        isDialog = item.isDialogMode;
      }

      // 如果遇到了一个非 Dialog 页面（全屏页面），那么它就是最底层的可见页
      // 它下面的页面都不需要显示了
      if (!isDialog) {
        visibleStartIndex = i;
        break;
      }
    }
    return visibleStartIndex;
  }

  build(): void {
    Stack() {
      // 1. 遍历所有 children，不要 slice，保持引用
      ForEach(this.children, (item: HippyRenderBaseView, index: number) => {
        // 2. 【核心修复】：只要 item 存在，就必须执行 buildHippyRenderView
        // 绝对不能用 if (index >= visible) 来包裹 buildHippyRenderView，
        // 否则 ArkUI 会销毁底下的组件，导致 Detail 页重建、滚动丢失。
        if (item) {
          Stack() {
            buildHippyRenderView(item, null)
          }
          .applyItemAttr(item, index, this.getVisibleStartIndex())
        }
      }, (item: HippyRenderBaseView) => {
        // 3. Key 生成：确保唯一且稳定，防止重新渲染
        // item.uid 是你在 QTPageView 构造函数里生成的 `page-${num}`，非常适合做 Key
        if (item instanceof QTPageView && item.uid) {
          return item.uid
        }
        return item ? (HIPPY_COMPONENT_KEY_PREFIX + item.tag) : ''
      })

      ContentSlot(this.renderView.childSlot)
    }
    .applyRenderViewBaseAttr(this.renderView)
  }
}

// 抽取子项属性设置，控制 Visibility
@Extend(Stack)
function applyItemAttr(item: HippyRenderBaseView, index: number, visibleStartIndex: number) {
  // 核心逻辑：如果 index 小于起始可见索引，设为不可见，而不是销毁
  .visibility(index >= visibleStartIndex ? Visibility.Visible : Visibility.None)
  // 确保层级正确
  .zIndex(index)
  // 这里的 Key 和 ForEach 的 key 最好保持一致
  .key(item instanceof QTPageView && item.uid ? item.uid : (HIPPY_COMPONENT_KEY_PREFIX + item.tag))
}

// 根容器属性
@Extend(Stack)
function applyRenderViewBaseAttr($$: HippyRenderBaseView) {
  .key(HIPPY_COMPONENT_KEY_PREFIX + $$.tag)
  .backgroundColor($$.cssBackgroundColor)
  .position({ x: $$.cssPositionX, y: $$.cssPositionY })
  .size({ width: $$.cssWidth, height: $$.cssHeight })
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
}