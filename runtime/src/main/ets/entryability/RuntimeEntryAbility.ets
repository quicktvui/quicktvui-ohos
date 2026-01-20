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
    // ... 保持原有逻辑不变 ...
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

    let entryPage = 'pages/Main';
    windowStage.loadContent(entryPage, (err) => {
      if (err.code) {
        LogUtils.i(this.TAG, `Failed to load content: ${JSON.stringify(err)}`)
        return;
      }

      // [PERF] 这是系统允许的最早时刻。
      // 在 loadContent 回调执行的瞬间，UIContext 刚刚准备好，立刻启动引擎。
      this.tryExecutePreWarm(windowStage, "LoadContent_Success");

      PerfLogger.mark('AppLaunch', 'loadContent_Success');
    });
  }

  /**
   * 同步预热
   */
  private tryExecutePreWarm(windowStage: window.WindowStage, source: string) {
    if (AppManager.instance.engineInitPromise || AppManager.instance.preloadedEngine) return;

    try {
      const win = windowStage.getMainWindowSync();
      if (!win) return;
      const uiContext = win.getUIContext();

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
    } catch (e) {
      LogUtils.e(this.TAG, `[PERF] Pre-warm failed (${source}): ${e.message}`);
    }
  }

  onForeground(): void {
    PerfLogger.mark('AppLaunch', 'Ability.onForeground');
  }
}