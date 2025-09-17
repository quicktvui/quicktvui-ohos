import {
  HippyEngineContext,
  HippyAny,
  HippyRecord,
  HippyModulePromise,
  HippyNativeModule
} from 'hippy';

import { BaseModule } from './BaseModule';
import deviceInfo from '@ohos.deviceInfo';

// const systemVersion = deviceInfo.osFullName;     // eg: "HarmonyOS 4.0.0"
// const version = deviceInfo.osRelease;            // eg: "4.0"
// const model = deviceInfo.model;                  // eg: "P50"
// const brand = deviceInfo.brand;                  // eg: "HUAWEI"
// const manufacturer = deviceInfo.manufacturer;    // eg: "Huawei"
// const product = deviceInfo.product;              // eg: "P50"
// const deviceType = deviceInfo.deviceType;        // eg: "phone"
// const name = deviceInfo.deviceName;              // eg: "HUAWEI_P50"
/**
 *
 */
@HippyNativeModule({ name: "ESRuntimeDeviceModule" })
export class ESRuntimeDeviceModule extends BaseModule {
  public static readonly NAME: string = 'ESRuntimeDeviceModule'

  constructor(ctx: HippyEngineContext) {
    super(ctx)
  }

  initialize(): void {
  }

  public call(method: string, params: Array<HippyAny>, promise: HippyModulePromise): HippyAny {
    switch (method) {
      case 'getRuntimeDeviceId': {
        promise.resolve(deviceInfo.serial)
        break;
      }
      case 'getRuntimeDeviceType': {
        promise.resolve(deviceInfo.productModel)
        break;
      }
      case 'getRuntimeDeviceInfo': {
        const info: HippyRecord = {
          "deviceId": deviceInfo.serial,
          "deviceType": deviceInfo.productModel
        }
        promise.resolve(info)
        break;
      }
      default:
        super.call(method, params, promise);
    }
    return null;
  }
}
