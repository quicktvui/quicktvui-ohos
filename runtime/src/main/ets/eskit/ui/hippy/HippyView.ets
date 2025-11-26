import {
  createHippyEngine,
  EngineInitParams,
  EngineInitStatus,
  HippyEngine,
  ModuleLoadParams,
  HippyRoot,
  HippyRootViewWrapper,
  ModuleLoadStatus,
  HippyJsException
} from 'hippy'
import { RuntimeAPIProvider } from '../../../api/RuntimeAPIProvider'
import { buildCustomRenderView, QTAPIProvider } from 'quicktvui'
import { BusinessError } from '@kit.BasicServicesKit'
import { AppContext } from '../../AppContext'
import { LoadStatus } from '../../LoadStatus'
import { AppLoader, AppLoaderFactory } from './AppLoader'
import { AssetsAppLoader } from './AssetsAppLoader'
import libHippy from 'libhippy.so';
import { App } from '../../../App'

@Component
export struct HippyView {
  @Consume('appContext')
  private appContext: AppContext
  private appLoader?: AppLoader
  private hippyEngine: HippyEngine | null = null
  private hippyViewWrapper = new HippyRootViewWrapper()
  @State isHippyViewCreated: boolean = false

  aboutToAppear(): void {
    this.startLoadEsApp()
  }

  private async startLoadEsApp() {
    try {
      const data = this.appContext.data
      this.appLoader = AppLoaderFactory.create(data)
      await this.appLoader.startLoad()
      this.hippyEngine = await this.createEngine()
      this.loadModule()
    } catch (error) {
      console.log('发生异常', error)
      this.appContext.loadResult = {
        status: LoadStatus.FAIL,
        exception: this.parseException(error)
      }
    }
  }

  private parseException(error: Error): BusinessError<string> {
    return (error as BusinessError)?.data !== undefined ? error as BusinessError<string> : {
      code: -1,
      data: '未知异常:' + error.message
    } as BusinessError<string>
  }

  build() {
    if (!this.isHippyViewCreated) {
      Stack({ alignContent: Alignment.Center }) {
        Column() {

          Row() {
            Image(this.appContext.data.icon).width(90).height(90)
            Text(this.appContext.data.appName).fontSize(60).margin({ left: 10 })
          }

          LoadingProgress()
            .color(Color.Blue)
            .width(90)
            .height(90)
        }
      }
      .width('100%')
      .height('100%')
    } else {
      HippyRoot({
        rootViewWrapper: this.hippyViewWrapper
      }).expandSafeArea()
    }
  }

  //region 引擎

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
    const params = new EngineInitParams(libHippy!, App.instance.context!, this.getUIContext())
    params.debugMode = false
    params.enableLog = true
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
    const view = this.hippyEngine?.loadModuleWithListener(params, {
      onLoadCompleted(statusCode: ModuleLoadStatus, msg: string) {
        console.log("loadModule", statusCode, msg)
      },
      onJsException(exception: HippyJsException): boolean {
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
      viewThis.isHippyViewCreated = true
    }
  }

  private generateLoadModuleParams(): ModuleLoadParams {
    const params = new ModuleLoadParams('', '', '', '', null, null, null)
    params.componentName = 'EsApp'
    params.codeCacheTag = 'EsApp'
    // params.jsParams
    params.wrappedCustomRenderViewBuilder = wrapBuilder(buildCustomRenderView)
    if (this.appLoader instanceof AssetsAppLoader) {
      params.jsAssetsPath = this.appLoader.getIndexJsFile()
    }
    return params
  }

  //endregion
}