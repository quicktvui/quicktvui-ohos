import {
  HippyRenderBaseView,
  HippyObservedArray,
  NativeRenderContext,
  HippyAny,
  HIPPY_COMPONENT_KEY_PREFIX,
  HippyRenderCallback,
  HippyViewEvent,
} from 'hippy'
import { webview } from '@kit.ArkWeb';
import { QTBaseComponentView } from '../QTBaseComponentView';
import { BusinessError } from '@kit.BasicServicesKit';

// 定义一个接口来描述缓存的指令结构
interface PendingCall {
  method: string;
  params: Array<HippyAny>;
  callback: HippyRenderCallback | null;
}

@Observed
export class QTWebView extends QTBaseComponentView {
  public web: QTWeb | null = null
  public url: string | null = null;
  // 1. 新增：用于缓存未执行指令的队列
  private pendingCalls: Array<PendingCall> = [];

  public bindComponent(web: QTWeb) {
    this.web = web;
    if (this.pendingCalls.length > 0) {
      this.pendingCalls.forEach(req => {
        this.call(req.method, req.params, req.callback);
      });
      this.pendingCalls = [];
    }
  }

  public unbindComponent() {
    this.web = null;
  }

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
    if (this.web) {
      if (this.web.call(method, params, callback)) {
        return;
      }
      super.call(method, params, callback)
    } else {
      this.pendingCalls.push({
        method: method,
        params: params,
        callback: callback
      });
    }
  }
}

class Js2Vue {
  private view: QTWebView | null = null

  constructor(renderView: QTWebView) {
    this.view = renderView
  }

  js2Vue(value: string): void {
    if (this.view != null) {
      let event = new HippyViewEvent("onJs2Vue")
      let params = new Map<string, string>()
      params.set('js2VueValue', value)
      event.send(this.view.ctx, this.view.tag, params)
    }
  }
}

@Component
export struct QTWeb {
  @ObjectLink renderView: QTWebView
  @ObjectLink children: HippyObservedArray<HippyRenderBaseView>
  private webviewController: WebviewController = new webview.WebviewController()
  private js2Vue: Js2Vue = new Js2Vue(this.renderView);
  @State private url: string | null = null;
  private isControllerAttached: boolean = false
  private localHtmlUrl = "resource://rawfile/local.html"

  aboutToAppear() {
    this.renderView.bindComponent(this);
  }

  aboutToDisappear() {
    this.renderView.unbindComponent()
  }

  public call(method: string, params: Array<HippyAny>,
    callback: HippyRenderCallback | null): boolean {
    switch (method) {
      case 'loadUrl': {
        this.url = params[0] as string;
        if (this.isControllerAttached) {
          try {
            this.webviewController.loadUrl(this.url);
          } catch (error) {
            console.error(`ErrorCode: ${(error as BusinessError).code},  Message: ${(error as BusinessError).message}`);
          }
        }
        return true
      }
      case 'evaluateJavascript': {
        const script: string = params[0] as string;
        this.webviewController.runJavaScript(script)
          .then((ret) => {
            if (callback != null) {
              callback(ret)
            }
          })
          .catch((e: BusinessError) => {
            if (callback != null) {
              callback(null)
            }
          });
        return true
      }
      default:
        return false
    }
  }

  build() {
    Web({
      src: $rawfile("local.html"),
      controller: this.webviewController,
      renderMode: RenderMode.ASYNC_RENDER
    })
      .javaScriptAccess(true)
      .fileAccess(true)
      .onControllerAttached(() => {
        this.isControllerAttached = true
        try {
          this.webviewController.registerJavaScriptProxy(this.js2Vue, "Js2Vue", ["js2Vue"], [], '')
        } catch (error) {
          console.error(`ErrorCode: ${(error as BusinessError).code},Message: ${(error as BusinessError).message}`);
        }
        if (this.url != null) {
          try {
            setTimeout(() => {
              this.webviewController.loadUrl(this.url);
            }, 0)
          } catch (error) {
            console.error(`ErrorCode: ${(error as BusinessError).code},  Message: ${(error as BusinessError).message}`);
          }
        }
      })
      .onPageBegin(e => {
        if (this.localHtmlUrl == e.url) {
          return
        }
        let event = new HippyViewEvent("onPageStarted")
        let params = new Map<string, string>()
        params.set('url', e.url)
        event.send(this.renderView.ctx, this.renderView.tag, params)
      })
      .onPageEnd(e => {
        if (this.localHtmlUrl == e.url) {
          return
        }
        let event = new HippyViewEvent("onPageFinished")
        let params = new Map<string, string>()
        params.set('url', e.url)
        event.send(this.renderView.ctx, this.renderView.tag, params)
      })
      .onResourceLoad(e => {
        if (this.localHtmlUrl == e.url) {
          return
        }
        let event = new HippyViewEvent("onLoadResource")
        let params = new Map<string, string>()
        params.set('url', e.url)
        event.send(this.renderView.ctx, this.renderView.tag, params)
      })
      .applyRenderViewBaseAttr(this.renderView)
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
