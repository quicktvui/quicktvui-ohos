import libHippy from 'libhippy.so'
import {
  createHippyEngine,
  EngineInitParams,
  EngineInitStatus,
  HippyEngine,
  HippyJsException,
  HippyRoot,
  HippyRootViewWrapper,
  HippyValue,
  ModuleLoadParams,
  ModuleLoadStatus,
  LogUtils,
} from 'hippy'
import { BusinessError } from '@ohos.base'
import { buildCustomRenderView, FocusManager, QTAPIProvider } from 'quicktvui'
import common from '@ohos.app.ability.common'
import { inputEventClient, KeyCode } from '@kit.InputKit'
import { EsData } from '../eskit/EsData'
import { ApiAppLoader } from '../eskit/ui/hippy/ApiAppLoader'
import { LoadStatus } from '../eskit/LoadStatus'
import { RuntimeAPIProvider } from '../api/RuntimeAPIProvider'
import { IconSplashView } from '../eskit/ui/splash/SplashView'
import { AssetsAppLoader } from '../eskit/ui/hippy/AssetsAppLoader'
import { AppContext } from '../eskit/AppContext'
import { AppManager } from '../eskit/AppManager'
import { App } from '../App'
import { AppLoader, AppLoaderFactory } from '../eskit/ui/hippy/AppLoader'

@Builder
export function PageDebugBuilder() {
  Application()
}

@Component
struct Application {
  private TAG: string = 'AppPage'
  @Provide('appContext')
  private appContext: AppContext = new AppContext(App.instance.context!)
  private appLoader?: AppLoader
  private hippyViewWrapper: HippyRootViewWrapper = new HippyRootViewWrapper()
  @State splashOpacity: number = 1.0
  @Provide('autoSize') autoSize?: number[] = []

  private parseEsData(): EsData {
    // 从启动参数里解析EsData
    // return EsData.tryParse(App.instance.launchParams)

    // TODO 打包动态生成
    //-----------------------2048方块-------------------------------
    let data = new EsData()
    // data.appName = '2048方块'
    // data.packageName = 'es.com.elsbfkharmony.tv'
    // data.appIcon = 'https://extcdn.hsrc.tv/data_center/files/2024/05/29/3e07ff6b-cfc6-40d2-a885-843b1655348a.png'
    data.uri = `${AppLoaderFactory.FROM_ASSETS}/vue`

    //-----------------------2048-------------------------------
    // let data = new EsData()
    // data.appName = '2048'
    // data.packageName = 'es.com.elsbharmony.tv'
    // data.appIcon = 'https://extcdn.hsrc.tv/data_center/files/2024/05/29/3e07ff6b-cfc6-40d2-a885-843b1655348a.png'
    return data
  }

  private async startLoadApp() {
    try {
      const data = this.appContext.data
      this.appLoader = AppLoaderFactory.create(data)
      await this.appLoader.startLoad()
      this.appContext.engine = await this.createEngine()
      this.loadModule()
    } catch (error) {
      console.log('发生异常', error)
      this.appContext.loadResult = {
        status: LoadStatus.FAIL,
        exception: this.parseException(error)
      }
    }
  }

  private createEngine(): Promise<HippyEngine> {
    return new Promise<HippyEngine>((resolve, reject) => {
      const engine = createHippyEngine(this.generateEngineInitParams())
      engine.initEngine({
        onInitialized: (statusCode: EngineInitStatus, msg: string) => {
          if (statusCode == EngineInitStatus.STATUS_OK) {
            resolve(engine)
          } else {
            reject({
              code: statusCode.valueOf(),
              data: msg
            } as BusinessError<string>)
          }
        }
      })
    })
  }

  private generateEngineInitParams(): EngineInitParams {
    //
    this.getUIContext().getFocusController().activate(true, false)
    //
    const params = new EngineInitParams(libHippy, App.instance.context!, this.getUIContext())
    params.debugMode = false
    params.enableLog = false
    params.enableArkCApi = false
    params.providers = [
      new RuntimeAPIProvider(),
      new QTAPIProvider()
    ]

    if (this.appLoader instanceof AssetsAppLoader) {
      const coreJSAssetsPath = this.appLoader.getVendorJsFile()
      params.coreJSAssetsPath = coreJSAssetsPath
    }
    //
    else if (this.appLoader instanceof ApiAppLoader) {
      const coreJSFilePath = this.appLoader.getVendorJsFile()
      params.coreJSFilePath = coreJSFilePath
    }
    return params
  }

  private loadModule() {
    const params = this.generateLoadModuleParams()
    const viewThis = this
    const view = this.appContext.engine?.loadModuleWithListener(params, {
      onLoadCompleted(statusCode: ModuleLoadStatus, msg: string) {
        console.log("loadModule", statusCode, msg)
        animateToImmediately({
          duration: 800,
          delay: 1000,
          curve: Curve.Smooth
        }, () => {
          viewThis.splashOpacity = 0.0
        })
      },
      onJsException(e: HippyJsException): boolean {
        console.log('onJsException', e)
        return true
      },
      onFirstViewAdded() {
        console.log("onFirstViewAdded")
      },
      onFirstContentfulPaint() {
        console.log("onFirstViewAdded")
      }
    })

    if (view) {
      this.hippyViewWrapper.setRootView(view)
    }
  }

  private generateLoadModuleParams(): ModuleLoadParams {
    const params = new ModuleLoadParams('', '', '', '', null, null, null)
    params.componentName = 'EsApp'
    params.jsParams = new Map<string, HippyValue>()
    params.wrappedCustomRenderViewBuilder = wrapBuilder(buildCustomRenderView)

    if (this.appLoader instanceof AssetsAppLoader) {
      const jsAssetsPath = this.appLoader.getIndexJsFile()
      params.jsAssetsPath = jsAssetsPath
    }
    //
    else if (this.appLoader instanceof ApiAppLoader) {
      const jsFilePath = this.appLoader.getIndexJsFile()
      params.jsFilePath = jsFilePath
    }
    return params
  }

  private parseException(error: Error): BusinessError<string> {
    return (error as BusinessError)?.data !== undefined ? error as BusinessError<string> : {
      code: -1,
      data: '未知异常:' + error.message
    } as BusinessError<string>
  }

  private postLifecycleEvent(eventName: string) {
    this.appContext.engine?.onLifecycleEvent(eventName)
  }

  build() {
    NavDestination() {
      Stack() {
        if (this.splashOpacity > 0) {
          IconSplashView().opacity(this.splashOpacity)
        } else {
          HippyRoot({
            hippyEngine: this.appContext.engine,
            rootViewWrapper: this.hippyViewWrapper,
            onRenderException: (exception) => {
              console.error('onRenderException', exception)
            }
          }).width('100%')
            .height('100%')
            .expandSafeArea()
        }
      }
      .alignContent(Alignment.Center)
      .width('100%')
      .height('100%')
      .backgroundColor('#000000')
      .expandSafeArea()
      .onKeyEvent((event) => {
        this.appContext.engine?.onKeyEvent(event)
      })
    }
    .hideTitleBar(true)
    .hideBackButton(true)
    .hideToolBar(true)
    .onReady((context: NavDestinationContext) => {
      LogUtils.e(this.TAG, 'Lifecycle: onReady');
    })
    .onWillAppear(() => {
      LogUtils.e(this.TAG, 'Lifecycle: onWillAppear');
      this.postLifecycleEvent('onWillAppear')

    })
    .onAttach(() => {
      LogUtils.e(this.TAG, 'Lifecycle: onAttach');
      this.postLifecycleEvent('onAttach')
    })
    .onAppear(() => {
      LogUtils.e(this.TAG, 'Lifecycle: onAppear');
      this.appContext.data = this.parseEsData()
      AppManager.instance.addAppContext(this.appContext)

      this.startLoadApp()
      this.postLifecycleEvent('onAppear')
    })
    .onWillShow(() => {
      LogUtils.e(this.TAG, 'Lifecycle: onWillShow');
      this.postLifecycleEvent('onWillShow')
    })
    .onShown(() => {
      this.appContext.engine?.onEngineResume()
      LogUtils.e(this.TAG, 'Lifecycle: onShown');
      this.postLifecycleEvent('onShown')
      let keyDown: inputEventClient.KeyEvent = {
        isPressed: true,
        keyCode: KeyCode.KEYCODE_TAB,
        keyDownDuration: 0,
        isIntercepted: false
      };
      let keyUp: inputEventClient.KeyEvent = {
        isPressed: false,
        keyCode: KeyCode.KEYCODE_TAB,
        keyDownDuration: 0,
        isIntercepted: false
      };
      setTimeout(() => {
        try {
          // 触发tab点击，使默认焦点组件多态样式生效
          inputEventClient.injectEvent({ KeyEvent: keyDown });
          inputEventClient.injectEvent({ KeyEvent: keyUp });
          console.log('123456  123');
        } catch (e) {
          console.log("123456 tab key event click false")
        }
      }, 5000)
    })
    .onWillHide(() => {
      LogUtils.e(this.TAG, 'Lifecycle: onWillHide');
      this.postLifecycleEvent('onWillHide')
    })
    .onHidden(() => {
      this.appContext.engine?.onEnginePause()
      LogUtils.e(this.TAG, 'Lifecycle: onHidden');
      this.postLifecycleEvent('onHidden')
    })
    .onWillDisappear(() => {
      LogUtils.e(this.TAG, 'Lifecycle: onWillDisappear');
      this.postLifecycleEvent('onWillDisappear')
    })
    .onDetach(() => {
      LogUtils.e(this.TAG, 'Lifecycle: onDetach');
      this.postLifecycleEvent('onDetach')
    })
    .onDisAppear(() => {
      LogUtils.e(this.TAG, 'Lifecycle: onDisAppear');
      this.postLifecycleEvent('onDisAppear')
      AppManager.instance.removeAppContext(this.appContext)
    })
    .onKeyPreIme((event) => {
      this.appContext.engine?.onKeyEvent(event)
      if (this.hippyViewWrapper.getRootView()) {
        return FocusManager.dispatchKeyEvent(this.hippyViewWrapper.getRootView()!!.renderView!!, event)
      }
      return false;
    })
    .onBackPressed(() => {
      let engine = this.appContext.engine
      if (engine) {
        engine?.onBackPressed({
          handleBackPress() {
            if (App.instance.nav && App.instance.nav.size() <= 1) {
              (App.instance.context as common.UIAbilityContext).terminateSelf()
                .then(() => {
                  LogUtils.d(this.TAG, 'terminateSelf success.');
                })
                .catch((err: BusinessError) => {
                  LogUtils.d(this.TAG, 'terminateSelf error.' + JSON.stringify(err));
                });
            }
          }
        })
        return true
      }
      return false
    })
  }
}



