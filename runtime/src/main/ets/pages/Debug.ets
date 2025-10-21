import {
  HippyEngine,
  HippyException,
  HippyRoot,
  HippyRootViewWrapper,
  HippyLibrary,
  EngineInitParams,
  createHippyEngine,
  ModuleListener,
  EngineListener,
  EngineInitStatus,
  ModuleLoadParams,
  ModuleLoadStatus,
  HippyJsException,
  HippyValue,
  BackPressHandler,
  LogUtils,
} from 'hippy'

import { RuntimeAPIProvider } from '../api/RuntimeAPIProvider'
import { QTAPIProvider } from 'quicktvui';
import {
  buildCustomRenderView,
} from 'quicktvui';

import { webSocket } from '@kit.NetworkKit';
import { util } from '@kit.ArkTS';
import { bundleManager, common } from '@kit.AbilityKit';
import { connection } from '@kit.NetworkKit';
import { preferences } from '@kit.ArkData';
import { BusinessError, commonEventManager, deviceInfo } from '@kit.BasicServicesKit';
import { QTNativeLayout } from 'libquicktvui.so';

@Builder
export function PageDebugBuilder(name: string, param: Object) {
  Debug()
}

@Component
struct Debug {
  private TAG: string = 'RuntimeDebugPage'
  private navPathStack: NavPathStack = new NavPathStack();
  @State name: string = ''
  @State currentEnv: string = 'dev'
  @State systemName: string = ''
  @State versionName: string = ''
  @State versionCode: string = ''
  @State deviceIp: string = '0.0.0.0' //TODO 不要修改 => 设备的IP地址
  //----------------------------------------------------------------------------------
  @State debugServerHost: string = '192.168.80.44' //TODO 调试服务地址
  @State debugServerAvailable: boolean = false
  private checkHostAvailableTimerId: number = -1
  private readonly ACTION_CHANGE_DEBUG_SERVER: string =
    "com.extscreen.runtime.ACTION_CHANGE_DEBUG_SERVER"
  private readonly ACTION_CODE_CHANGE: string =
    "com.extscreen.runtime.ACTION_CODE_CHANGED"
  private readonly PREFERENCES_KEY_DEBUG_SERVER_HOST: string = "DEBUG_SERVER_HOST"
  private readonly PREFERENCES_NAME_DEBUG: string = "debug"
  private subscriber: commonEventManager.CommonEventSubscriber | null = null;
  private subscribeInfo: commonEventManager.CommonEventSubscribeInfo = {
    events: [this.ACTION_CHANGE_DEBUG_SERVER, this.ACTION_CODE_CHANGE],
  };
  //----------------------------------------------------------------------------------
  envList: string[] = ['dev', 'test', 'prod']
  //----------------------------------------------------------------------

  @State message: string = 'Hello World';
  @StorageLink('libHippy') private libHippy: HippyLibrary | null = null
  @StorageLink('abilityContext') private abilityContext: Context | null = null
  //
  @State exception: string = ""
  hippyEngine: HippyEngine | null = null
  private rootViewWrapper: HippyRootViewWrapper = new HippyRootViewWrapper()
  @State isEngineInitialized: boolean = false
  @Provide('autoSize') autoSize?: number[] = []

  async aboutToAppear() {
    LogUtils.e(this.TAG, 'Lifecycle: aboutToAppear');
    this.initDebugServer()
    this.initNetworkInfo()
    this.initBundleInfo()
    this.initSystemInfo()
    console.error('quicktvui', 'aboutToAppear ')

    console.error('quicktvui', '=======222=====1======2====>>>>>')

    // let obj:MyObject = new MyObject(10);
    // console.error('quicktvui',"init:", obj.value);     // 10
    // obj.value = 20;
    // console.error('quicktvui',"after set:", obj.value); // 20
    // console.error('quicktvui',"plusOne:", obj.plusOne()); // 21


    // const value:number = quick.callNative(2, 3);
    const ln: QTNativeLayout = new QTNativeLayout()
    // console.error('quicktvui','============2==========>>>>>' + value + "")
    ln.SetWidth(10)
    ln.SetHeight(10)

    console.error('quicktvui', '============3==========>>>>>')
    ln.CalculateLayout(1920, 1080)
    console.info('quicktvui', `native width:${ln.GetWidth()}`)
  }

  aboutToDisappear(): void {
    this.unsubscribe()
    LogUtils.e(this.TAG, 'Lifecycle: aboutToDisappear');
  }

  private initEngine() {
    //
    this.destroyEngine()
    //
    let params = new EngineInitParams(this.libHippy!, this.abilityContext!, this.getUIContext())
    params.coreJSAssetsPath = "vue2/vendor.ohos.js"
    params.enableArkCApi = false
    params.debugServerHost = this.debugServerHost + ':38989'
    params.debugMode = true
    params.enableLog = true
    //自定义 module 和 component 入口
    params.providers = [
      new RuntimeAPIProvider(),
      new QTAPIProvider()
    ]
    //TODO
    params.enableArkCApi = false

    //
    this.hippyEngine = createHippyEngine(params)
    let engineListener = new DefaultEngineListener(this.hippyEngine, this.rootViewWrapper, () => {
      console.log("=======DefaultEngineListener========>>>>")
      this.isEngineInitialized = true
    })
    this.hippyEngine.initEngine(engineListener)
  }

  private initBundleInfo() {
    let bundleFlags = bundleManager.BundleFlag.GET_BUNDLE_INFO_WITH_APPLICATION |
    bundleManager.BundleFlag.GET_BUNDLE_INFO_WITH_METADATA;
    bundleManager.getBundleInfoForSelf(bundleFlags).then((data) => {
      this.versionName = data.versionName
      this.versionCode = data.versionCode + ""
      this.name = data.name
    }).catch((err: BusinessError) => {
    });
  }

  private initSystemInfo() {
    this.systemName = deviceInfo.osFullName
  }

  //--------------------------------DEBUG SERVER------------------------------------------
  private initDebugServer() {
    this.subscribe()
    const debugServerHost = this.getDebugServerHost()
    if (debugServerHost) {
      this.debugServerHost = debugServerHost
    }
  }

  private async subscribe() {
    this.subscriber = await commonEventManager.createSubscriber(this.subscribeInfo);
    commonEventManager.subscribe(this.subscriber,
      (error: BusinessError, data: commonEventManager.CommonEventData) => {
        if (error) {
          return;
        }
        LogUtils.i(this.TAG, `[DebugServer] data: ${JSON.stringify(data)}`);
        //
        if (data.event == this.ACTION_CHANGE_DEBUG_SERVER) {
          const debugServerHost = data.data
          if (debugServerHost) {
            this.debugServerHost = debugServerHost
            this.setDebugServerHost(this.debugServerHost)
            //
            this.checkDebugServerAvailable()
          }
        }
        //刷新
        else if (data.event == this.ACTION_CODE_CHANGE) {
          LogUtils.i(this.TAG, `[DebugServer] : ACTION_CODE_CHANGE`);
          this.getUIContext()!.getPromptAction().showToast({
            message: "代码变化 页面刷新",
            duration: 500,
          })
          this.isEngineInitialized = false
          // this.destroyEngine()
          // this.initEngine()
          let rootView = this.rootViewWrapper?.getRootView()
          if (rootView) {
            this.rootViewWrapper?.resetRootView()
          }
          try {
            this.hippyEngine?.getHippyEngineContext()?.getDevSupportManager()?.getDevImp().reload();
          } catch (e) {
            LogUtils.e(this.TAG, "reload error: " + e.getMessage());
          }
          // const loadParams = buildModuleLoadParams()
          // let moduleListener = new DefaultModuleListener()
          // let rootView = this.hippyEngine?.loadModuleWithListener(loadParams, moduleListener)
          // if (rootView) {
          //   this.rootViewWrapper.setRootView(rootView)
          // }
        }
      })
  }

  private async unsubscribe() {
    commonEventManager.unsubscribe(this.subscriber)
  }

  private getDebugServerHost(): string | null {
    try {
      let options: preferences.Options = { name: this.PREFERENCES_NAME_DEBUG };
      const pref = preferences.getPreferencesSync(getContext(), options)
      if (pref) {
        const debugServerHost = pref.getSync(this.PREFERENCES_KEY_DEBUG_SERVER_HOST, null) as string
        LogUtils.i(this.TAG,
          `[DebugServer] [getDebugServerHost]: ${debugServerHost}`);
        return debugServerHost
      }
    } catch (e) {
    }
    return null
  }

  private setDebugServerHost(debugServerHost: string) {
    try {
      let options: preferences.Options = { name: this.PREFERENCES_NAME_DEBUG };
      const pref = preferences.getPreferencesSync(getContext(), options)
      if (pref) {
        LogUtils.i(this.TAG, `[DebugServer] [setDebugServerHost]: ${debugServerHost}`);
        pref.putSync(this.PREFERENCES_KEY_DEBUG_SERVER_HOST, debugServerHost)
        pref.flushSync()
      }
    } catch (e) {
    }
  }

  private async initNetworkInfo() {
    try {
      const netHandle = await connection.getDefaultNet();
      const properties = await connection.getConnectionProperties(netHandle);
      const addressArray = properties.linkAddresses
      if (addressArray && addressArray.length > 0) {
        this.deviceIp = addressArray[0].address?.address ?? '0.0.0.0'
      }
    } catch (e) {
    }
  }

  private startCheckDebugServerAvailableTimer() {
    this.stopCheckDebugServerAvailableTimer()
    this.checkHostAvailableTimerId = setInterval(() => {
      this.checkDebugServerAvailable()
    }, 1000)
  }

  private stopCheckDebugServerAvailableTimer() {
    clearInterval(this.checkHostAvailableTimerId)
  }

  private checkDebugServerAvailable() {
    const uuid = util.generateRandomUUID(true)
    let defaultIpAddress =
      "ws://" + this.debugServerHost + ":38989/debugger-proxy?role=android_client&clientId=" + uuid;

    let ws = webSocket.createWebSocket();

    ws.on('open', (err: BusinessError, value: Object) => {
      LogUtils.i(this.TAG, `[WebSocket][open] status: ${JSON.stringify(value)}`);
      this.debugServerAvailable = true
      this.onDebugServerAvailable()
    });

    ws.on('message', (err: BusinessError, value: string | ArrayBuffer) => {
      LogUtils.i(this.TAG, `[WebSocket][message] message: ${value}`);
    });

    ws.on('close', (err: BusinessError, value: webSocket.CloseResult) => {
      LogUtils.i(this.TAG, `[WebSocket][close] code: ${value.code}, reason: ${value.reason}`);
    });

    ws.on('error', (err: BusinessError) => {
      if (this.debugServerAvailable) {
        this.showDebugServerAvailableToast(false)
      }
      this.debugServerAvailable = false
      this.startCheckDebugServerAvailableTimer()
      LogUtils.e(this.TAG, `[WebSocket][error] ${JSON.stringify(err)}`);
    });

    ws.connect(defaultIpAddress, (err: BusinessError, value: boolean) => {
      if (!err) {
        LogUtils.i(this.TAG, `[WebSocket][connect] Connected successfully`);
      } else {
        this.debugServerAvailable = false
        this.onDebugServerAvailable()
        LogUtils.e(this.TAG, `[WebSocket][connect] Failed. Err: ${JSON.stringify(err)}`);
      }
    });
  }

  private onDebugServerAvailable() {
    setTimeout(() => {
      if (this.debugServerAvailable) {
        this.showDebugServerAvailableToast(true)
        this.stopCheckDebugServerAvailableTimer()
      } else {
        this.showDebugServerAvailableToast(false)
      }
    }, 1000)
  }

  private showDebugServerAvailableToast(available: boolean) {
    this.getUIContext()!.getPromptAction().showToast({
      message: available ? "调试服务可用" : "调试服务不可用",
      duration: 1000,
    })
  }

  private destroyEngine() {
    let rootView = this.rootViewWrapper?.getRootView()
    if (rootView) {
      this.rootViewWrapper?.resetRootView()
      this.hippyEngine?.destroyModule(rootView.getRootId(), () => {
        this.hippyEngine?.destroyEngine()
      });
    }
    this.isEngineInitialized = false
  }

  build() {
    NavDestination() {
      Stack() {
        Column() {
          Text($r('app.string.set_debug_server_host_tip'))
            .fontSize(17)
            .fontColor(Color.Yellow)
            .margin({ bottom: 10 })
        }.margin({ left: 30, top: 30 })

        Row() {
          Column() {
            Text($r('app.string.debug_title'))
              .fontSize(40)
              .fontColor(Color.White)
              .fontWeight(FontWeight.Bold)
              .margin({ bottom: 80 })
            Column() {
              Text($r('app.string.system_name', this.systemName))
                .fontSize(20)
                .fontColor($r('app.color.debug_font_color'))
                .margin({ bottom: 15 })
              Text($r('app.string.debug_runtime_name', this.name))
                .fontSize(20)
                .fontColor($r('app.color.debug_font_color'))
                .margin({ bottom: 15 })
              Text($r('app.string.debug_runtime_version', this.versionName, this.versionCode))
                .fontSize(20)
                .fontColor($r('app.color.debug_font_color'))
                .margin({ bottom: 15 })
              Text(`IP地址: ${this.deviceIp}`)
                .fontSize(20)
                .fontColor($r('app.color.debug_font_color'))
                .margin({ bottom: 15 })
              Text($r('app.string.debug_server_ip_address', this.debugServerHost))
                .fontSize(20)
                .fontColor($r('app.color.debug_font_color'))
            }.margin({ bottom: 50 })
            .alignItems(HorizontalAlign.Start)

            Text($r('app.string.debug_app_tip'))
              .fontSize(20)
              .fontColor($r('app.color.debug_font_color'))
              .margin({ bottom: 50 })
          }
          .margin({ right: 150 })
          .alignItems(HorizontalAlign.Start)
          .justifyContent(FlexAlign.Start)

          Column() {
            Button(this.debugServerAvailable ? $r('app.string.debug_start') :
            $r('app.string.cross_mark'))
              .fontColor(Color.Black)
              .fontSize(this.debugServerAvailable ? 40 : 150)
              .fontWeight(FontWeight.Bold)
              .backgroundColor($r('app.color.debug_font_color'))
              .focusable(true)
              .defaultFocus(true)
              .type(ButtonType.Circle)
              .width(300)
              .height(300)
              .onClick(() => {
                if (!this.debugServerAvailable) {
                  this.showDebugServerAvailableToast(false)
                  return
                }
                this.initEngine()
              })
          }.margin({ right: 70 })
        }
        .alignItems(VerticalAlign.Center)
        .justifyContent(FlexAlign.Center)
        .width('100%')
        .height('100%')
        .expandSafeArea()

        Column() {
        }.width('100%')
        .height(40)

        if (this.isEngineInitialized) {
          HippyRoot({
            hippyEngine: this.hippyEngine,
            rootViewWrapper: this.rootViewWrapper,
            onRenderException: (exception: HippyException) => {
              this.exception = `${exception.message}\n${exception.stack}`
            },
          }).layoutWeight(1)
        }
        if (this.exception) {
          Text(this.exception)
        }
      }
      .alignContent(Alignment.TopStart)
      .width('100%')
      .height('100%')
      .backgroundColor('#3A4251')
      .expandSafeArea()
    }
    .hideTitleBar(true)
    .hideBackButton(true)
    .hideToolBar(true)
    .onReady((context: NavDestinationContext) => {
      this.navPathStack = context.pathStack;
    })
    .onWillAppear(() => {
      LogUtils.e(this.TAG, 'Lifecycle: onWillAppear');
      this.hippyEngine?.onLifecycleEvent("onWillAppear")
    })
    .onAttach(() => {
      LogUtils.e(this.TAG, 'Lifecycle: onAttach');
      this.hippyEngine?.onLifecycleEvent("onAttach")
    })
    .onAppear(() => {
      LogUtils.e(this.TAG, 'Lifecycle: onAppear');
      this.hippyEngine?.onLifecycleEvent("onAppear")
    })
    .onWillShow(() => {
      LogUtils.e(this.TAG, 'Lifecycle: onWillShow');
      this.hippyEngine?.onLifecycleEvent("onWillShow")
    })
    .onShown(() => {
      this.hippyEngine?.onEngineResume()
      LogUtils.e(this.TAG, 'Lifecycle: onShown');
      this.hippyEngine?.onLifecycleEvent("onShown")
      //
      this.checkDebugServerAvailable()
    })
    .onWillHide(() => {
      LogUtils.e(this.TAG, 'Lifecycle: onWillHide');
      this.hippyEngine?.onLifecycleEvent("onWillHide")
    })
    .onHidden(() => {
      this.hippyEngine?.onEnginePause()
      LogUtils.e(this.TAG, 'Lifecycle: onHidden');
      this.hippyEngine?.onLifecycleEvent("onHidden")
    })
    .onWillDisappear(() => {
      LogUtils.e(this.TAG, 'Lifecycle: onWillDisappear');
      this.hippyEngine?.onLifecycleEvent("onWillDisappear")
    })
    .onDetach(() => {
      LogUtils.e(this.TAG, 'Lifecycle: onDetach');
      this.hippyEngine?.onLifecycleEvent("onDetach")
    })
    .onDisAppear(() => {
      LogUtils.e(this.TAG, 'Lifecycle: onDisAppear');
      this.hippyEngine?.onLifecycleEvent("onDisAppear")
    })
    //返回键
    .onBackPressed(() => {
      if (this.isEngineInitialized) {
        this.hippyEngine?.onBackPressed(new RuntimeDefaultBackHandler())
        return true
      } else {
        if (this.navPathStack.size() <= 1) {
          //关闭应用
          (this.abilityContext as common.UIAbilityContext).terminateSelf()
            .then(() => {
              LogUtils.d(this.TAG, 'terminateSelf success.');
            })
            .catch((err: BusinessError) => {
              LogUtils.d(this.TAG, 'terminateSelf error.' + JSON.stringify(err));
            });
        }
        return false
      }
    })
  }
}

class RuntimeDefaultBackHandler implements BackPressHandler {
  handleBackPress(): void {
    console.log('Back button pressed');
  }
}


function buildModuleLoadParams(): ModuleLoadParams {
  let loadParams = new ModuleLoadParams(
    'vue2/index.ohos.js',
    '',
    '',
    '',
    null,
    null,
    null,
  )
  loadParams.componentName = "EsApp"
  loadParams.codeCacheTag = "EsApp"
  loadParams.jsParams = new Map<string, HippyValue>()
  loadParams.jsParams.set(
    "msgFromNative",
    "Hi js developer, I come from ohos native code!"
  )
  loadParams.wrappedCustomRenderViewBuilder = wrapBuilder(buildCustomRenderView)
  return loadParams
}

class DefaultEngineListener implements EngineListener {
  private hippyEngine: HippyEngine
  private rootViewWrapper: HippyRootViewWrapper
  private readonly TAG: string = "DefaultEngineListener";
  private callback?: Function = undefined

  constructor(hippyEngine: HippyEngine, rootViewWrapper: HippyRootViewWrapper, callback: Function) {
    this.hippyEngine = hippyEngine
    this.rootViewWrapper = rootViewWrapper
    this.callback = callback
  }

  onInitialized(statusCode: EngineInitStatus, msg: string): void {
    LogUtils.i(this.TAG, 'initEngine status: ' + statusCode + ' msg:' + msg);
    if (statusCode == EngineInitStatus.STATUS_OK) {
      // if (this.callback) {
      //   this.callback()
      // }
      const loadParams = buildModuleLoadParams()
      let moduleListener = new DefaultModuleListener(this.callback)
      let rootView = this.hippyEngine.loadModuleWithListener(loadParams, moduleListener)
      if (rootView) {
        this.rootViewWrapper.setRootView(rootView)
      }
    }
  }
}


class DefaultModuleListener implements ModuleListener {
  private readonly TAG: string = "DefaultModuleListener";
  private callback?: Function = undefined

  constructor(callback?: Function) {
    this.callback = callback
  }

  onLoadCompleted(statusCode: ModuleLoadStatus, msg: string): void {
    LogUtils.i(this.TAG, 'loadModule status: ' + statusCode + ' msg:' + msg);
    if (this.callback) {
      this.callback()
    }
  }

  onJsException(exception: HippyJsException): boolean {
    LogUtils.e(this.TAG, 'loadModule onJsException: ' + exception);
    return true;
  }

  onFirstViewAdded(): void {

  }

  onFirstContentfulPaint(): void {

  }
}

