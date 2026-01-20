import { AppContext } from "./AppContext"
import { HippyEngine, createHippyEngine, EngineInitParams, EngineInitStatus, LogUtils } from 'hippy'
import libHippy from 'libhippy.so'
import { RuntimeAPIProvider } from '../api/RuntimeAPIProvider'
import { QTAPIProvider } from 'quicktvui'

export class AppManager {
  // region 单例

  private static _instance: AppManager

  static get instance(): AppManager {
    if (!this._instance) {
      this._instance = new AppManager()
    }
    return this._instance
  }

  private constructor() {
  }

  // endregion

  private apps: Set<AppContext> = new Set()

  // --- [PERF] 引擎预热缓存 ---
  public preloadedEngine: HippyEngine | null = null
  public engineInitPromise: Promise<HippyEngine> | null = null

  /**
   * [PERF] 预热引擎：在 Ability 启动早期调用
   */
  public preWarmEngine(context: Context, uiContext: UIContext, coreJSPath: string, isAssets: boolean) {
    // 如果已经有引擎或正在初始化，直接返回
    if (this.engineInitPromise || this.preloadedEngine) {
      return
    }

    LogUtils.i('AppManager', '[PERF] 🔥 Start Pre-warming Engine...')

    this.engineInitPromise = new Promise((resolve, reject) => {
      const params = new EngineInitParams(libHippy, context, uiContext)
      params.debugMode = false
      params.enableLog = false
      params.enableArkCApi = false
      params.providers = [
        new RuntimeAPIProvider(),
        new QTAPIProvider()
      ]

      // 设置核心包路径
      if (isAssets) {
        params.coreJSAssetsPath = coreJSPath
      } else {
        params.coreJSFilePath = coreJSPath
      }

      const engine = createHippyEngine(params)
      engine.initEngine({
        onInitialized: (statusCode: EngineInitStatus, msg: string) => {
          if (statusCode == EngineInitStatus.STATUS_OK) {
            LogUtils.i('AppManager', '[PERF] ✅ Engine Pre-warm Success!')
            this.preloadedEngine = engine
            resolve(engine)
          } else {
            LogUtils.e('AppManager', '[PERF] ❌ Engine Pre-warm Failed: ' + msg)
            reject(msg)
          }
        }
      })
    })
  }
  // -------------------------

  addAppContext(value: AppContext) {
    this.apps.add(value)
  }

  removeAppContext(value: AppContext) {
    this.apps.delete(value)
  }

  findAppContextWithPackageName(value: string): AppContext | null {
    for (let ctx of this.apps) {
      if (ctx.data.appId == value) {
        return ctx
      }
    }
    return null
  }
}