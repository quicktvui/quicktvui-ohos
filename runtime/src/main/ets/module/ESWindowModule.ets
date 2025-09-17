import {
  HippyEngineContext,
  HippyAny,
  HippyModulePromise,
  HippyNativeModule,
  LogUtils
} from 'hippy';

import { BaseModule } from './BaseModule';
import { window } from '@kit.ArkUI';
import { BusinessError } from '@kit.BasicServicesKit';

@HippyNativeModule({ name: "ESWindowModule" })
export class ESWindowModule extends BaseModule {
  public static readonly NAME: string = 'ESWindowModule'
  public readonly TAG: string = 'ESWindowModule'

  constructor(ctx: HippyEngineContext) {
    super(ctx)
  }

  initialize(): void {
  }

  public call(method: string, params: Array<HippyAny>, promise: HippyModulePromise): HippyAny {
    switch (method) {
      case 'setWindowKeepScreenOn': {
        this.setWindowKeepScreenOn(params[0] as boolean).then((ret => {
          promise.resolve(params[0] as boolean)
        }), (error: BusinessError) => {
          promise.reject(JSON.stringify(error))
        })
        break;
      }
      case 'setWindowBrightness': {
        let brightness = params[0] as number;
        if (brightness > 1) {
          brightness = 1
        }
        this.setWindowBrightness(brightness).then((ret => {
          LogUtils.i(this.TAG, 'setWindowBrightness: ' + brightness);
          promise.resolve(params[0] as boolean)
        }), (error: BusinessError) => {
          LogUtils.e(this.TAG, 'setWindowBrightness error: ' + JSON.stringify(error));
          promise.reject(JSON.stringify(error))
        })
        break;
      }
      case 'getWindowBrightness': {
        promise.resolve(1)
        break;
      }
      default:
        super.call(method, params, promise);
    }
    return null;
  }

  async setWindowKeepScreenOn(value: boolean) {
    const win = await window.getLastWindow(this.ctx.getAbilityContext());
    await win.setWindowKeepScreenOn(value);
  }

  async setWindowBrightness(value: number) {
    const win = await window.getLastWindow(this.ctx.getAbilityContext());
    await win.setWindowBrightness(value);
  }
}
