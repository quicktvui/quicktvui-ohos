import { AbilityConstant, UIAbility, Want } from '@kit.AbilityKit';
import { window } from '@kit.ArkUI';
import { JSON } from '@kit.ArkTS'; // 引入 Url 用于解析
import {
  LogUtils
} from 'hippy';
import { EsData } from '../eskit/EsData';
import { App } from '../App';
import { LaunchConfigParser } from '../config/LaunchConfigParser';
import { ConfigResolver } from '../config/ConfigResolver';
import Url from '@ohos.url'
import { PerfLogger } from '../utils/PerfLogger';

export default class RuntimeEntryAbility extends UIAbility {
  public readonly TAG: string = 'RuntimeEntryAbility'

  onCreate(want: Want, launchParam: AbilityConstant.LaunchParam): void {
    PerfLogger.start('AppLaunch');

    LogUtils.i(this.TAG, `Ability onCreate`)
    // 打印原始的 uri，方便排查转义问题
    LogUtils.e(this.TAG, `onCreate: want: uri: ${want?.uri}  launchParam: ${JSON.stringify(launchParam)}`)

    App.instance.context = this.context
    App.instance.nav = new NavPathStack()

    this.launch(want, launchParam, false)

    PerfLogger.mark('AppLaunch', 'Ability.onCreate_Finished');
  }

  onNewWant(want: Want, launchParam: AbilityConstant.LaunchParam): void {
    LogUtils.i(this.TAG,
      `onNewWant: want: uri: ${want?.uri}  launchParam: ${JSON.stringify(launchParam)}`)
    this.launch(want, launchParam, true)
  }

  /**
   * 启动核心逻辑
   * @param want
   * @param launchParam
   * @param onNewWant
   */
  private launch(want: Want, launchParam: AbilityConstant.LaunchParam, onNewWant: boolean) {
    // 1. 【核心修改】先将 URI 中的参数解析并合并到 want.parameters 中
    this.parseAndMergeUriParams(want);

    LogUtils.d(this.TAG, `launch merged want params: ` + JSON.stringify(want.parameters)
      + ' onNewWant: ' + onNewWant
    )

    //--------------------------------------------------------------------
    // 2. 此时 want.parameters 已经包含了 -u 中的参数和 -s/-i 的参数
    const launchConfig = LaunchConfigParser.parse(
      want.parameters as Record<string, Object>
    )
    const runtimeConfig = ConfigResolver.resolve(launchConfig)
    LogUtils.e(this.TAG, `Ability runtimeConfig :` + JSON.stringify(runtimeConfig))

    App.instance.runtimeConfig = runtimeConfig
    //--------------------------------------------------------------------

    if (onNewWant) {
      const runtimeConfig = App.instance.runtimeConfig
      const params = EsData.buildESData(
        runtimeConfig?.appId,
        runtimeConfig?.appVersion,
        runtimeConfig?.appName,
        runtimeConfig?.appIcon,
        runtimeConfig?.appDebug,
        runtimeConfig?.appBundleUri,
        runtimeConfig?.appParams,
        runtimeConfig?.appEnableOAID,
        runtimeConfig?.oaid,
      )
      App.instance.nav?.pushDestination(
        { name: runtimeConfig.appEntry, param: params },
        { launchMode: LaunchMode.STANDARD })
    }
  }

  /**
   * 解析 DeepLink (esapp://...) 并将参数合并到 want.parameters
   * 策略：命令行显式参数 (-s/-i) 优先级高于 URI 参数
   */
  private parseAndMergeUriParams(want: Want) {
    const uriString = want.uri;
    if (!uriString) {
      return;
    }
    try {
      // 使用 ArkTS 自带的 URL 解析库
      const urlObj = Url.URL.parseURL(uriString);

      // 安全校验：只处理 esapp 协议
      if (urlObj.protocol !== 'esapp:') {
        LogUtils.w(this.TAG, `Skipping unknown protocol: ${urlObj.protocol}`);
        return;
      }
      // 确保 parameters 对象存在
      if (!want.parameters) {
        want.parameters = {};
      }
      // --- A. 解析基础结构 (Host & Path) ---
      // 1. Host -> 包名 (pkg)
      // 如果命令行没有传 pkg，则使用 URL 中的 host
      if (!want.parameters['pkg'] && urlObj.hostname) {
        want.parameters['pkg'] = urlObj.hostname;
      }

      // 2. Path -> 版本号 (version)
      // 移除开头的 '/'，例如 /2.0 -> 2.0
      const pathVer = urlObj.pathname.startsWith('/') ? urlObj.pathname.substring(1) : urlObj.pathname;
      if (!want.parameters['appVersion'] && pathVer) {
        want.parameters['appVersion'] = pathVer;
      }

      // --- B. 解析 Query 参数 ---

      // 遍历 URL 中的所有参数 (?key=value)
      urlObj.params.forEach((value, key) => {
        // 只有当 want.parameters 中不存在该 key 时才写入
        // 这意味着：命令行使用的 -s key value 优先级 > URL 中的 &key=value
        if (want.parameters![key] === undefined) {

          // 特殊字段解码处理
          if (key === 'params' || key === 'uri') {
            try {
              // 解码：assets%3A%2F%2F -> assets://
              // 解码：JSON %7B...%7D -> {...}
              const decodedValue = decodeURIComponent(value);
              want.parameters![key] = decodedValue;
            } catch (e) {
              LogUtils.e(this.TAG, `Decode failed for key ${key}: ${e}`);
              want.parameters![key] = value; // 降级处理：使用原始值
            }
          } else {
            // 普通字段直接赋值 (URL库通常会自动处理基础解码，但为了保险可以直接赋值)
            want.parameters![key] = value;
          }
        }
      });
    } catch (e) {
      LogUtils.e(this.TAG, `Failed to parse URI: ${uriString}. Error: ${e}`);
    }
  }

  onDestroy(): void {
    LogUtils.i(this.TAG, `Ability onDestroy`)
  }

  onWindowStageCreate(windowStage: window.WindowStage): void {
    PerfLogger.mark('AppLaunch', 'onWindowStageCreate_Start');

    LogUtils.i(this.TAG, `Ability onWindowStageCreate`)

    // 这里建议也把 windowStage 存入 App 单例，方便后续动态路由使用
    App.instance.windowStage = windowStage;

    // 根据解析出来的 runtimeConfig 决定是否直接跳 Debug 页
    // 假设 runtimeConfig.appEntry 是你在 LaunchConfigParser 里处理好的入口页面名称
    let entryPage = 'pages/Main';

    // 如果你有特殊的逻辑需要在这里直接加载不同页面，可以使用 runtimeConfig
    // 例如: if (App.instance.runtimeConfig.appEntry === 'Debug') entryPage = 'pages/DebugPage';

    windowStage.loadContent(entryPage, (err) => {
      if (err.code) {
        LogUtils.i(this.TAG, `Failed to load the content. Cause: ${JSON.stringify(err) ?? ''}`)
        return;
      }
      LogUtils.i(this.TAG, `Succeeded in loading the content.`)
      PerfLogger.mark('AppLaunch', 'loadContent_Success');
    });
  }

  onWindowStageDestroy(): void {
    LogUtils.i(this.TAG, `Ability onWindowStageDestroy`)
  }

  onForeground(): void {
    PerfLogger.mark('AppLaunch', 'Ability.onForeground');
    LogUtils.i(this.TAG, `Ability onForeground`)
  }

  onBackground(): void {
    LogUtils.i(this.TAG, `Ability onBackground`)
  }
}