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

// 接口：描述缓存的 JS 脚本 (专门给 evaluateJavascript 用)
interface PendingJs {
  script: string;
  callback: HippyRenderCallback | null;
}

//---------------------------------------------------------

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
  private isControllerAttached: boolean = false
  // 2. 第二层缓存：等待 Controller 就绪 (专门存 evaluateJavascript)
  private pendingJsCalls: Array<PendingJs> = [];
  @State private url: string | null = null;
  private localHtmlUrl = "resource://rawfile/local.html"

  aboutToAppear() {
    this.renderView.bindComponent(this);
  }

  aboutToDisappear() {
    this.renderView.unbindComponent()
  }

  // 执行具体的 JS 脚本逻辑，提取出来复用
  private runScript(script: string, callback: HippyRenderCallback | null) {
    try {
      this.webviewController.runJavaScript(script)
        .then((ret) => {
          if (callback != null) {
            callback(ret)
          }
        })
        .catch((e: BusinessError) => {
          console.error(`runJavaScript error: ${e.code}, ${e.message}`)
          if (callback != null) {
            callback(null)
          }
        });
    } catch (error) {
      console.error(`runJavaScript exception: ${(error as BusinessError).message}`);
      if (callback != null) {
        callback(null)
      }
    }
  }

  public call(method: string, params: Array<HippyAny>,
    callback: HippyRenderCallback | null): boolean {
    switch (method) {
      case 'loadUrl': {
        this.url = params[0] as string;
        // 只有当 Controller 就绪时才立即加载，否则只更新 this.url 状态，等 onControllerAttached 自动加载
        if (this.isControllerAttached && this.url) {
          try {
            this.webviewController.loadUrl(this.url);
          } catch (error) {
            console.error(`loadUrl Error: ${(error as BusinessError).message}`);
          }
        }
        return true
      }
      case 'evaluateJavascript': {
        const script: string = params[0] as string;
        if (this.isControllerAttached) {
          // 如果 Controller 已就绪，直接执行
          this.runScript(script, callback);
        } else {
          // 如果 Controller 还没好，放入第二层缓存队列
          console.log('QTWeb Controller not ready, queuing JS script...');
          this.pendingJsCalls.push({ script: script, callback: callback });
        }
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
        console.log('QTWeb onControllerAttached: Controller is ready.');

        // 1. 注册 JS 桥接
        try {
          this.webviewController.registerJavaScriptProxy(this.js2Vue, "Js2Vue", ["js2Vue"], [], '')
        } catch (error) {
          console.error(`registerProxy Error: ${(error as BusinessError).message}`);
        }

        // 2. 检查是否有 URL 需要加载 (处理 loadUrl 的时序)
        if (this.url != null) {
          try {
            // 这里可以直接 loadUrl，不需要 setTimeout，因为已经在 Attached 回调里了
            setTimeout(() => {
              this.webviewController.loadUrl(this.url);
            }, 0)
          } catch (error) {
            console.error(`Initial loadUrl Error: ${(error as BusinessError).message}`);
          }
        }

        // 3. 检查是否有积压的 JS 脚本需要执行 (处理 evaluateJavascript 的时序)
        if (this.pendingJsCalls.length > 0) {
          console.log(`QTWeb flushing ${this.pendingJsCalls.length} pending JS scripts...`);
          this.pendingJsCalls.forEach(js => {
            this.runScript(js.script, js.callback);
          });
          this.pendingJsCalls = [];
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
