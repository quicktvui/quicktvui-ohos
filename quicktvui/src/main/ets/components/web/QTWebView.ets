import {
  HippyRenderBaseView,
  HippyObservedArray,
  NativeRenderContext,
  HippyAny,
  HIPPY_COMPONENT_KEY_PREFIX,
  HippyRenderCallback,
} from 'hippy'
import { webview } from '@kit.ArkWeb';
import { QTBaseComponentView } from '../QTBaseComponentView';

@Observed
export class QTWebView extends QTBaseComponentView {
  public url: string | null = null;

  constructor(ctx: NativeRenderContext) {
    super(ctx)
  }

  setProp(propKey: string, propValue: HippyAny): boolean {
    switch (propKey) {
      case 'url': {
        this.url = propValue as string;
        return true;
      }
    }
    return super.setProp(propKey, propValue)
  }

  call(method: string, params: Array<HippyAny>, callback: HippyRenderCallback | null): void {
    if (method == "loadUrl") {
      this.url = params[0] as string;
    }
  }
}

@Component
export struct QTWeb {
  @ObjectLink renderView: QTWebView
  @ObjectLink children: HippyObservedArray<HippyRenderBaseView>
  private webviewController: WebviewController = new webview.WebviewController()

  aboutToAppear() {
  }

  aboutToDisappear() {

  }

  build() {
    Web({
      src: this.renderView.url,
      controller: this.webviewController,
      renderMode: RenderMode.ASYNC_RENDER
    }).applyRenderViewBaseAttr(this.renderView)
  }
}

// base props for all components
@Extend(Web)
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
