import { App } from '../../App'
import { AppContext } from '../AppContext'
import { AppManager } from '../AppManager'
import { EsData } from '../EsData'
import { AppLoader, AppLoaderFactory } from './hippy/AppLoader'
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
  ModuleLoadStatus
} from 'hippy'
import { LoadStatus } from '../LoadStatus'
import { BusinessError } from '@ohos.base'
import { RuntimeAPIProvider } from '../../api/RuntimeAPIProvider'
import { buildCustomRenderView, QTAPIProvider } from 'quicktvui'
import { AssetsAppLoader } from './hippy/AssetsAppLoader'
import { IconSplashView } from './splash/SplashView'
import common from '@ohos.app.ability.common'
import { inputEventClient, KeyCode } from '@kit.InputKit'

@Builder
export function PageDebugBuilder() {
  AppView()
}

@Entry
@Component
struct AppView {
  @Provide('appContext')
  private appContext: AppContext = new AppContext(App.instance.context!)
  private appLoader?: AppLoader
  private hippyViewWrapper = new HippyRootViewWrapper()
  @State splashOpacity: number = 1.0
  @Provide('autoSize') autoSize?: number[] = []

  //region 生命周期

  aboutToAppear(): void {
    this.appContext.data = this.parseEsData()
    AppManager.instance.addAppContext(this.appContext)

    this.startLoadApp()
    this.postLifecycleEvent('onAppear')
  }

  onPageShow(): void {
    this.postLifecycleEvent('onShown')
    console.log('123456');
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
    setTimeout(()=>{
      try {
        // 触发tab点击，使默认焦点组件多态样式生效
        inputEventClient.injectEvent({ KeyEvent: keyDown });
        inputEventClient.injectEvent({ KeyEvent: keyUp });
        console.log('123456  123');
      } catch (e) {
        console.log("123456 tab key event click false")
      }
    },5000)

    // try {
    //   // 触发tab点击，使默认焦点组件多态样式生效
    //   inputEventClient.injectEvent({ KeyEvent: keyDown });
    //   inputEventClient.injectEvent({ KeyEvent: keyUp });
    //   console.log('123456  123');
    // } catch (e) {
    //   console.log("123456 tab key event click false")
    // }
  }

  onPageHide(): void {
    this.postLifecycleEvent('onHidden')
  }

  aboutToDisappear(): void {
    this.postLifecycleEvent('onDisAppear')
    AppManager.instance.removeAppContext(this.appContext)
  }

  onBackPress(): boolean | void {
    let engine = this.appContext.engine
    if (engine) {
      engine?.onBackPressed({
        handleBackPress() {
          console.log('Back button pressed');
          (App.instance.context as common.UIAbilityContext).terminateSelf().then(() => {
          }).catch(() => {
          })
        }
      })
      return true
    }
  }

  private postLifecycleEvent(eventName: string) {
    this.appContext.engine?.onLifecycleEvent(eventName)
  }

  //endregion

  //region 参数解析

  private parseEsData(): EsData {
    // 从启动参数里解析EsData
    // return EsData.tryParse(App.instance.launchParams)

    // TODO 打包动态生成
    let data = new EsData()
    data.appName = '土豆逗科普'
    data.packageName = 'es.hello.world'
    data.appIcon = 'https://extcdn.hsrc.tv/data_center/files/2024/05/29/3e07ff6b-cfc6-40d2-a885-843b1655348a.png'
    data.uri = `${AppLoaderFactory.FROM_ASSETS}/vue`

    return data
  }

  //endregion

  //region 应用加载

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
    const params = new EngineInitParams(libHippy, App.instance.context!, this.getUIContext())
    params.debugMode = false
    params.enableLog = false
    params.enableArkCApi = false
    params.providers = [
      new RuntimeAPIProvider(),
      new QTAPIProvider()
    ]
    if (this.appLoader instanceof AssetsAppLoader) {
      params.coreJSAssetsPath = this.appLoader.getVendorJsFile()
    }
    return params
  }

  private loadModule() {
    const params = this.generateLoadModuleParams()
    // this.hippyEngine?.loadModule(params)
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
    // params.codeCacheTag = 'EsApp'
    params.jsParams = new Map<string, HippyValue>()
    params.wrappedCustomRenderViewBuilder = wrapBuilder(buildCustomRenderView)
    if (this.appLoader instanceof AssetsAppLoader) {
      params.jsAssetsPath = this.appLoader.getIndexJsFile()
    }
    return params
  }

  private parseException(error: Error): BusinessError<string> {
    return (error as BusinessError)?.data !== undefined ? error as BusinessError<string> : {
      code: -1,
      data: '未知异常:' + error.message
    } as BusinessError<string>
  }

  //endregion

  //region 界面绘制

  build() {
    Navigation(App.instance.nav) {
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
    }
    .hideToolBar(true)
    .hideBackButton(true)
    .mode(NavigationMode.Stack)
    .onAttach(() => {
      this.postLifecycleEvent('onAttach')
    })
    .onDetach(() => {
      this.postLifecycleEvent('onDetach')
    })
  }

  //endregion
}