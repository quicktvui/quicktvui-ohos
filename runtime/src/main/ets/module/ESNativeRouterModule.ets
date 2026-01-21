import {
  HippyEngineContext, HippyAny, HippyModulePromise, HippyNativeModule, LogUtils, HippyMap
} from 'hippy';

import { BaseModule } from './BaseModule';
import { BusinessError } from '@kit.BasicServicesKit';
import { bundleManager, common, OpenLinkOptions } from '@kit.AbilityKit';
import { App } from '../App';
import { EsData } from '../eskit/EsData';
import Url from '@ohos.url'
import { Want } from '@kit.AbilityKit'; // 记得导入 Want

/**
 *
 */
@HippyNativeModule({ name: "ESNativeRouterModule" })
export class ESNativeRouterModule extends BaseModule {
  public static readonly NAME: string = 'ESNativeRouterModule'
  public readonly TAG: string = 'ESNativeRouterModule'

  constructor(ctx: HippyEngineContext) {
    super(ctx)
  }

  initialize(): void {
  }

  public call(method: string, params: Array<HippyAny>, promise: HippyModulePromise): HippyAny {
    switch (method) {
      //
      case 'back': {
        const navPathStack = AppStorage.get<NavPathStack>("RuntimeNavPathStack")
        if (navPathStack) {
          //TODO 有没有其他业务需要不关闭??
          if (navPathStack.size() <= 1) {
            (this.ctx.getAbilityContext() as common.UIAbilityContext).terminateSelf()
              .then(() => {
                LogUtils.d(this.TAG, 'terminateSelf success.');
              })
              .catch((err: BusinessError) => {
                LogUtils.d(this.TAG, 'terminateSelf error.' + JSON.stringify(err));
              });
          } else {
            navPathStack.pop(false)
          }
          LogUtils.d(this.TAG, 'back success');
        } else {
          LogUtils.d(this.TAG, 'back error! NavPathStack is null!');
        }
        //
        break;
      }
      //
      case 'canOpenLink': {
        try {
          const link = params[0] as string;
          const canOpen = bundleManager.canOpenLink(link);
          LogUtils.i(this.TAG, `CanOpenLink: link: ${link} canOpen: ${canOpen}`)
          promise?.resolve(canOpen)
        } catch (error) {
          LogUtils.e(this.TAG,
            `Failed to canOpenLink. code=${error.code}, message=${error.message}`)
          promise?.reject(error)
        }
        break;
      }
      case 'openESApp': {
        try {
          const payload = params[0] as string;
          console.log(this.TAG + " openESApp params: " + payload);

          // 1. 解析 URL
          const urlObj = Url.URL.parseURL(payload);

          LogUtils.e(this.TAG,
            `openESApp parsing: scheme=${urlObj.protocol} host=${urlObj.hostname} path=${urlObj.pathname}`);

          // 2. 校验协议
          if (urlObj.protocol === 'esapp:') {
            const queryParams = urlObj.params;

            let pkgName = '';
            let version = '';

            // --- A. 格式分流逻辑 ---
            // 检查是否为新格式: esapp://action/start
            if (urlObj.hostname === 'action' && urlObj.pathname.startsWith('/start')) {
              // [新格式逻辑]
              // 优先取 es_pkg，如果没有则取 pkg
              pkgName = queryParams.get('es_pkg') || queryParams.get('pkg') || '';
              // 新格式中如果没有版本号，可以给默认值 '1.0' 或保留为空
              version = queryParams.get('version') || '1.0';
            } else {
              // [旧格式逻辑] esapp://es.hello.world/2.0
              // Host 即为包名
              pkgName = urlObj.hostname;
              // Path 即为版本 (去掉开头的 /)
              version = urlObj.pathname.startsWith('/') ? urlObj.pathname.substring(1) : urlObj.pathname;
            }

            // --- B. 提取通用 Query 参数 ---
            // 无论哪种格式，这些参数的提取逻辑是一样的
            const appName = queryParams.get('name');
            const appIcon = queryParams.get('icon');

            // 入口页面 (默认为 Application)
            const entryPage = queryParams.get('entry') || 'Application';

            // 调试标记
            const isDebug = queryParams.get('debug') === 'true';

            // URI 处理
            const rawUri = queryParams.get('uri');
            const realUri = rawUri ? decodeURIComponent(rawUri) : '';

            // --- C. 参数 JSON 处理 (args/params) ---
            // 兼容两种参数名: args (新格式/部分旧格式) 和 params (部分旧格式)
            const encodedArgs = queryParams.get('args') || queryParams.get('params');
            let argJson: Record<string, Object> = {};
            try {
              if (encodedArgs) {
                // 尝试解码并解析
                argJson = JSON.parse(decodeURIComponent(encodedArgs)) as Record<string, Object>;
              }
            } catch (e) {
              LogUtils.w(this.TAG, `JSON parse encoded failed, trying raw: ${e}`);
              // 容错处理：有时传入的 JSON 没有 URL Encode，尝试直接解析
              try {
                if (encodedArgs) {
                  argJson = JSON.parse(encodedArgs) as Record<string, Object>;
                }
              } catch (e2) {
                LogUtils.e(this.TAG, `JSON parse completely failed`);
              }
            }

            // --- D. 构造 EsData ---
            const appInfo: EsData = {
              appId: pkgName, // 统一后的包名
              appName: appName || '',
              appIcon: appIcon || '',
              appVersion: version, // 统一后的版本
              appBundleUri: realUri,
              appParams: argJson,
              appDebug: isDebug
            };

            // --- E. 路由跳转 ---
            LogUtils.e(this.TAG, `Navigating to ${entryPage} with info: ${JSON.stringify(appInfo)}`);

            if (pkgName) {
              App.instance.nav?.pushPathByName(entryPage, appInfo, false);
            } else {
              LogUtils.e(this.TAG, `Package name is empty, cannot open ESApp.`);
            }

          } else {
            LogUtils.w(this.TAG, `Unknown scheme: ${urlObj.protocol}`);
          }
          promise?.resolve(true);
        } catch (error) {
          LogUtils.e(this.TAG, `Failed to open app. error:${JSON.stringify(error)}`);
          promise?.reject(error);
        }
        break;
      }
      //
      case 'openLink': {
        try {
          const link = params[0] as string;
          const appLinkingOnly = params[1] as boolean ?? false;
          const openLinkOptions: OpenLinkOptions = {
            appLinkingOnly: appLinkingOnly
          };

          LogUtils.e(this.TAG, `OpenLink: link: ${link}`)

          const context = this.ctx.getAbilityContext() as common.UIAbilityContext;
          context.openLink(link, openLinkOptions).then(() => {
            LogUtils.e(this.TAG, `OpenLink: link: ${link}`)
            promise?.resolve(true)
          }).catch((err: BusinessError) => {
            LogUtils.e(this.TAG,
              `Failed to OpenLink. code=${err.code}, message=${err.message}`)
            promise?.reject(JSON.stringify(err))
          })
        } catch (error) {
          LogUtils.e(this.TAG,
            `Failed to OpenLink. code=${error.code}, message=${error.message}`)
          promise?.reject(error)
        }
        break;
      }
      case 'startAbility': {
        try {
          // 1. 定义变量
          let uri = '';
          let bundleName = '';
          let abilityName = ''; // 如果将来有 -n 参数指定 abilityName，可以预留
          let flags = 0x10000000; // 默认 FLAG_ABILITY_NEW_MISSION

          LogUtils.i(this.TAG, `startAbility raw params: ${JSON.stringify(params)}`);

          // 2. 解析 CLI 风格参数: [['-d', 'xxx'], ['-p', 'xxx']]
          if (Array.isArray(params)) {
            for (const item of params) {
              // 确保每一项是数组且至少有两个元素 [key, value]
              if (Array.isArray(item) && item.length >= 2) {
                const key = item[0] as string;
                const value = item[1] as string;

                switch (key) {
                  case '-d': // Data / URI
                    uri = value;
                    break;
                  case '-p': // Package / BundleName
                    bundleName = value;
                    break;
                  case '-f': // Flags (可选支持)
                    flags = parseInt(value) || flags;
                    break;
                  // 如果需要支持 abilityName，可以加 case '-n': abilityName = value;
                }
              }
            }
          }

          // 3. 校验必要参数
          if (!bundleName) {
            const msg = 'Missing bundleName (-p) for startAbility';
            LogUtils.e(this.TAG, msg);
            promise?.reject(msg);
            break;
          }

          // 4. 构造 Want 对象
          const want: Want = {
            bundleName: bundleName,
            uri: uri,
            flags: flags
          };

          // 如果将来支持指定 Ability，可以加上
          // if (abilityName) { want.abilityName = abilityName; }

          LogUtils.i(this.TAG, `Executing startAbility with Want: ${JSON.stringify(want)}`);

          // 5. 调用系统能力
          const context = this.ctx.getAbilityContext() as common.UIAbilityContext;

          context.startAbility(want).then(() => {
            LogUtils.i(this.TAG, `startAbility success.`);
            promise?.resolve(true);
          }).catch((err: BusinessError) => {
            LogUtils.e(this.TAG, `startAbility failed. code=${err.code}, msg=${err.message}`);
            promise?.reject(JSON.stringify(err));
          });
        } catch (error) {
          LogUtils.e(this.TAG, `startAbility exception: ${JSON.stringify(error)}`);
          promise?.reject(error);
        }
        break;
      }
      default:
        super.call(method, params, promise);
    }
    return null;
  }
}
