import {
  HippyEngineContext,
  HippyAny,
  HippyModulePromise,
  HippyNativeModule,
  LogUtils
} from 'hippy';

import { BaseModule } from './BaseModule';
import { BusinessError } from '@kit.BasicServicesKit';
import { bundleManager, common, OpenLinkOptions } from '@kit.AbilityKit';

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
