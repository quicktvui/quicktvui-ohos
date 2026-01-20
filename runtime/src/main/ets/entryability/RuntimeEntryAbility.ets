import { AbilityConstant, UIAbility, Want } from '@kit.AbilityKit';
import { window } from '@kit.ArkUI';
import { JSON } from '@kit.ArkTS';
import { LogUtils } from 'hippy';
import { EsData } from '../eskit/EsData';
import { App } from '../App';
import { LaunchConfigParser } from '../config/LaunchConfigParser';
import { ConfigResolver } from '../config/ConfigResolver';
import Url from '@ohos.url';
import { PerfLogger } from '../utils/PerfLogger';
import { AppManager } from '../eskit/AppManager';
import { AppLoaderFactory } from '../eskit/ui/hippy/AppLoader';
import { AssetsAppLoader } from '../eskit/ui/hippy/AssetsAppLoader';

export default class RuntimeEntryAbility extends UIAbility {
  public readonly TAG: string = 'RuntimeEntryAbility'
  // 轮询定时器 ID
  private pollTimer: number = -1;

  onCreate(want: Want, launchParam: AbilityConstant.LaunchParam): void {
    PerfLogger.start('AppLaunch');
    LogUtils.i(this.TAG, `Ability onCreate`)
    App.instance.context = this.context
    App.instance.nav = new NavPathStack()
    this.launch(want, launchParam, false)
    PerfLogger.mark('AppLaunch', 'Ability.onCreate_Finished');
  }

  onNewWant(want: Want, launchParam: AbilityConstant.LaunchParam): void {
    this.launch(want, launchParam, true)
  }

  private launch(want: Want, launchParam: AbilityConstant.LaunchParam, onNewWant: boolean) {
    this.parseAndMergeUriParams(want);
    const launchConfig = LaunchConfigParser.parse(want.parameters as Record<string, Object>)
    const runtimeConfig = ConfigResolver.resolve(launchConfig)
    App.instance.runtimeConfig = runtimeConfig

    if (onNewWant) {
      const params = EsData.buildESData(
        runtimeConfig?.appId, runtimeConfig?.appVersion, runtimeConfig?.appName,
        runtimeConfig?.appIcon, runtimeConfig?.appDebug, runtimeConfig.appBundleUri,
        runtimeConfig?.appParams, runtimeConfig?.appEnableOAID, runtimeConfig.oaid,
      )
      App.instance.nav?.pushDestination(
        { name: runtimeConfig.appEntry, param: params },
        { launchMode: LaunchMode.STANDARD })
    }
  }

  private parseAndMergeUriParams(want: Want) {
    const uriString = want.uri;
    if (!uriString) return;
    try {
      const urlObj = Url.URL.parseURL(uriString);
      if (urlObj.protocol !== 'esapp:') return;
      if (!want.parameters) want.parameters = {};
      if (!want.parameters['pkg'] && urlObj.hostname) want.parameters['pkg'] = urlObj.hostname;
      const pathVer = urlObj.pathname.startsWith('/') ? urlObj.pathname.substring(1) : urlObj.pathname;
      if (!want.parameters['appVersion'] && pathVer) want.parameters['appVersion'] = pathVer;
      urlObj.params.forEach((value, key) => {
        if (want.parameters![key] === undefined) {
          if (key === 'params' || key === 'uri') {
            try { want.parameters![key] = decodeURIComponent(value); } catch (e) { want.parameters![key] = value; }
          } else {
            want.parameters![key] = value;
          }
        }
      });
    } catch (e) {
      LogUtils.e(this.TAG, `Failed to parse URI: ${uriString}. Error: ${e}`);
    }
  }

  onWindowStageCreate(windowStage: window.WindowStage): void {
    PerfLogger.mark('AppLaunch', 'onWindowStageCreate_Start');
    App.instance.windowStage = windowStage;

    // =================================================================
    // 1. 【暴力轮询】每 15ms 尝试一次，抢在 loadContent 完成前初始化
    // =================================================================
    this.startPollingPreWarm(windowStage);

    let entryPage = 'pages/Main';
    windowStage.loadContent(entryPage, (err) => {
      // 停止轮询，避免浪费资源
      this.stopPolling();

      if (err.code) {
        LogUtils.i(this.TAG, `Failed to load content: ${JSON.stringify(err)}`)
        return;
      }

      // =================================================================
      // 2. 【兜底策略】如果轮询一直没成功，这里最后补救
      // =================================================================
      this.tryExecutePreWarmSync(windowStage, "LoadContent_Success");

      PerfLogger.mark('AppLaunch', 'loadContent_Success');
    });
  }

  /**
   * 启动轮询预热
   */
  private startPollingPreWarm(windowStage: window.WindowStage) {
    let attempts = 0;
    const maxAttempts = 20; // 最多试 20 次 (约 300ms)

    this.pollTimer = setInterval(() => {
      attempts++;
      // 如果已经预热成功，直接停止
      if (AppManager.instance.engineInitPromise || AppManager.instance.preloadedEngine) {
        this.stopPolling();
        return;
      }

      if (attempts > maxAttempts) {
        this.stopPolling();
        return;
      }

      // 尝试同步获取
      const success = this.tryExecutePreWarmSync(windowStage, `Polling_Attempt_${attempts}`);
      if (success) {
        this.stopPolling(); // 成功了就停止
      }
    }, 15); // 每 15ms 试一次
  }

  private stopPolling() {
    if (this.pollTimer !== -1) {
      clearInterval(this.pollTimer);
      this.pollTimer = -1;
    }
  }

  /**
   * 尝试同步预热，返回是否成功
   */
  private tryExecutePreWarmSync(windowStage: window.WindowStage, source: string): boolean {
    if (AppManager.instance.engineInitPromise || AppManager.instance.preloadedEngine) return true;

    try {
      // 使用同步方法，因为它最快
      const win = windowStage.getMainWindowSync();
      if (!win) return false;

      // 关键点：如果 Window 还没准备好，这里会抛出 abnormal 异常
      // 我们捕获这个异常，然后等待下一次轮询
      const uiContext = win.getUIContext();

      this.doPreWarm(uiContext, source);
      return true; // 没报错就是成功了
    } catch (e) {
      // 只有在非轮询模式下才打印 error，防止轮询刷屏
      if (!source.startsWith("Polling")) {
        LogUtils.w(this.TAG, `[PERF] Pre-warm failed (${source}): ${e.message}`);
      }
      return false;
    }
  }

  private doPreWarm(uiContext: UIContext, source: string) {
    const runtimeConfig = App.instance.runtimeConfig;
    if (runtimeConfig) {
      const esData = EsData.buildESData(
        runtimeConfig.appId, runtimeConfig.appVersion, runtimeConfig.appName,
        runtimeConfig.appIcon, runtimeConfig.appDebug, runtimeConfig.appBundleUri,
        runtimeConfig.appParams, runtimeConfig.appEnableOAID, runtimeConfig.oaid
      );
      const appLoader = AppLoaderFactory.create(esData);

      if (appLoader instanceof AssetsAppLoader) {
        const corePath = appLoader.getVendorJsFile();
        LogUtils.w(this.TAG, `[PERF] Trigger Pre-warm from: ${source}`);
        AppManager.instance.preWarmEngine(this.context, uiContext, corePath, true);
      }
    }
  }

  onForeground(): void {
    PerfLogger.mark('AppLaunch', 'Ability.onForeground');
  }
}