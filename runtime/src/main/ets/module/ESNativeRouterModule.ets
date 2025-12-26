import {
  HippyEngineContext, HippyAny, HippyModulePromise, HippyNativeModule, LogUtils, HippyMap
} from 'hippy';

import { BaseModule } from './BaseModule';
import { BusinessError } from '@kit.BasicServicesKit';
import { bundleManager, common, OpenLinkOptions } from '@kit.AbilityKit';
import { App } from '../App';
import { EsData } from '../eskit/EsData';
import Url from '@ohos.url'

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
          // 传入的 payload 格式：
          // esapp://es.hello.world/2.0?entry=Debug&uri=assets%3A%2F%2F%2Fvue%2F&params=%7B%22key%22%3A%22value%22%7D&debug=true&from=cmd
          const payload = params[0] as string;
          // 1. 使用标准库解析
          const urlObj = Url.URL.parseURL(payload);

          LogUtils.e(this.TAG,
            `openESApp parsing: scheme=${urlObj.protocol} host=${urlObj.hostname} path=${urlObj.pathname}`);

          // 2. 校验协议
          if (urlObj.protocol === 'esapp:') {
            // --- A. 提取基础信息 ---
            // Host 即为包名
            const pkgName = urlObj.hostname;
            // Path 即为版本 (去掉开头的 /)
            const version = urlObj.pathname.startsWith('/') ? urlObj.pathname.substring(1) : urlObj.pathname;

            // --- B. 提取 Query 参数 ---
            const queryParams = urlObj.params;

            const appName = queryParams.get('name');
            const appIcon = queryParams.get('icon');

            // 入口页面 (默认为 Application)
            const entryPage = queryParams.get('entry') || 'Application';

            // 调试标记
            const isDebug = queryParams.get('debug') === 'true';

            // URI (需要解码)
            const encodedUri = queryParams.get('uri');
            const realUri = encodedUri ? decodeURIComponent(encodedUri) : '';

            // JSON Params (需要解码 + 反序列化)
            const encodedArgs = queryParams.get('params');
            let argJson: Record<string, Object> = {};
            try {
              if (encodedArgs) {
                argJson = JSON.parse(decodeURIComponent(encodedArgs)) as Record<string, Object>;
              }
            } catch (e) {
              LogUtils.w(this.TAG, `JSON parse failed: ${e}`);
            }

            // --- C. 构造 EsData ---
            const appInfo: EsData = {
              appId: pkgName,
              appName: appName || '',
              appIcon: appIcon || '',
              appVersion: version,
              appBundleUri: realUri,
              appParams: argJson,
              appDebug: isDebug
            };
            // --- D. 路由跳转 ---
            LogUtils.e(this.TAG, `Navigating to ${entryPage} with info: ${JSON.stringify(appInfo)}`);

            App.instance.nav?.pushPathByName(entryPage, appInfo, false);
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
          const context = this.ctx.getAbilityContext() as common.UIAbilityContext;
          context.openLink(link, openLinkOptions).then(() => {
            LogUtils.i(this.TAG, `OpenLink: link: ${link}`)
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
      default:
        super.call(method, params, promise);
    }
    return null;
  }
}
