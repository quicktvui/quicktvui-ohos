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
import { QTPageView } from './QTPageView';

const TAG = "QTPageRouter";

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
  // 依然需要 ObjectLink 保证响应式，但不需要 Watch 做延迟了
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
   * 计算可见区域的起始索引
   * 目的：只渲染栈顶可见的页面，底下的页面即使在 children 数组里，也不构建 UI
   */
  private getVisibleStartIndex(): number {
    if (!this.children || this.children.length === 0) {
      return 0;
    }

    const count = this.children.length;
    // [性能保险] 最大允许叠加渲染层数。
    // 如果没有动画，其实只需要渲染栈顶 1 层即可。
    // 如果有透明 Dialog，可能需要渲染 2-3 层。
    const MAX_STACK_DEPTH = 3;
    let currentDepth = 0;
    let visibleStartIndex = 0;

    // 倒序遍历，找到最底下的那个“基座”
    for (let i = count - 1; i >= 0; i--) {
      const item = this.children[i];
      let isDialog = false;

      if (item instanceof QTPageView) {
        isDialog = item.isDialogMode;
      }

      currentDepth++;
      // 如果是非透明页面（基座），或者深度超标，就以此为起点
      if (!isDialog || currentDepth >= MAX_STACK_DEPTH) {
        visibleStartIndex = i;
        break;
      }
    }
    return visibleStartIndex;
  }

  build(): void {
    Stack() {
      // [核心优化点]
      // 1. 直接遍历 this.children，绝对不要用 slice() 生成新数组
      //    这保证了 ArkUI 认为数据源引用没变，只处理 Push 进来的那一个新 Item
      // 2. 只有新 Push 的页面会触发 buildHippyRenderView，
      //    底下的旧页面因为 Key 没变且数据没变，ArkUI 会直接复用，零开销。
      ForEach(this.children, (item: HippyRenderBaseView, index: number) => {
        // [逻辑过滤]
        // 在循环内部判断是否渲染。不满足条件的页面，ArkUI 不会生成对应的 Component 实例
        if (item && index >= this.getVisibleStartIndex()) {
          buildHippyRenderView(item, null)
        }
      }, (item: HippyRenderBaseView) => {
        // [Key 生成]
        // 必须使用唯一 ID。
        // 只要 Key 不变，ArkUI 就不会销毁重建这个节点。
        return item ? (HIPPY_COMPONENT_KEY_PREFIX + item.tag) : ''
      })

      ContentSlot(this.renderView.childSlot)
    }
    .applyRenderViewBaseAttr(this.renderView)
  }
}

// 样式设置保持不变
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