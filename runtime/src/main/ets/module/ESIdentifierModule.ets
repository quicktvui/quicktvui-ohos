import {
  HippyEngineContext,
  HippyAny,
  HippyMap,
  HippyModulePromise,
  HippyNativeModule,
  PixelUtil
} from 'hippy';

import { BaseModule } from './BaseModule';
import { display } from '@kit.ArkUI';
import { abilityAccessCtrl } from '@kit.AbilityKit';
import { identifier } from '@kit.AdsKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { deviceInfo } from '@kit.BasicServicesKit';

/**
 *
 */
@HippyNativeModule({ name: "ESIdentifierModule" })
export class ESIdentifierModule extends BaseModule {
  public static readonly NAME: string = 'ESIdentifierModule'

  constructor(ctx: HippyEngineContext) {
    super(ctx)
  }

  initialize(): void {

  }

  public call(method: string, params: Array<HippyAny>, promise: HippyModulePromise): HippyAny {
    switch (method) {
      case 'getOAID': {
        let atManager = abilityAccessCtrl.createAtManager();
        atManager.requestPermissionsFromUser(this.ctx.getAbilityContext(),
          ['ohos.permission.APP_TRACKING_CONSENT']).then((data) => {
          identifier.getOAID().then((data) => {
            promise.resolve(data)
          }).catch((err: BusinessError) => {
            promise.reject(JSON.stringify(err))
          });
        }).catch((err: BusinessError) => {
          promise.reject(JSON.stringify(err))
        });
        break;
      }
      case 'getAAID': {
        promise.resolve('')
        break;
      }
      case 'getODID': {
        try {
          promise.resolve(deviceInfo.ODID)
        } catch (e) {
          promise.reject(JSON.stringify(e))
        }
        break;
      }
      case 'getUDID': {
        try {
          promise.resolve(deviceInfo.udid)
        } catch (e) {
          promise.reject(JSON.stringify(e))
        }
        break;
      }
      default:
        super.call(method, params, promise);
    }
    return null;
  }
}
