import {
  HippyEngineContext,
  HippyAny,
  HippyModulePromise,
  HippyNativeModule,
  LogUtils
} from 'hippy';

import { BaseModule } from './BaseModule';
import { common } from '@kit.AbilityKit';
import { BusinessError } from '@kit.BasicServicesKit';

/**
 *
 */
@HippyNativeModule({ name: "ESAbilityModule" })
export class ESAbilityModule extends BaseModule {
  public static readonly NAME: string = 'ESAbilityModule'
  public readonly TAG: string = 'ESAbilityModule'

  constructor(ctx: HippyEngineContext) {
    super(ctx)
  }

  initialize(): void {
  }

  /**
   *
   * @param method
   * @param params
   * @param promise
   * @returns
   */
  public call(method: string, params: Array<HippyAny>, promise: HippyModulePromise): HippyAny {
    switch (method) {
      case 'terminateSelf': {
        (this.ctx.getAbilityContext() as common.UIAbilityContext).terminateSelf()
          .then(() => {
            LogUtils.d(this.TAG, 'terminateSelf success.');
            if (promise) {
              promise.resolve(true)
            }
          })
          .catch((err: BusinessError) => {
            LogUtils.d(this.TAG, 'terminateSelf error.' + JSON.stringify(err));
            if (promise) {
              promise.reject(JSON.stringify(err))
            }
          });
        break;
      }
      default:
        super.call(method, params, promise);
    }
    return null;
  }
}
