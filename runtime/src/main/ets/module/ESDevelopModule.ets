import {
  HippyEngineContext,
  HippyAny,
  HippyMap,
  HippyModulePromise,
  HippyNativeModule
} from 'hippy';

import { BaseModule } from './BaseModule';
import { bundleManager } from '@kit.AbilityKit';
import { BusinessError } from '@kit.BasicServicesKit';

/**
 *
 */
@HippyNativeModule({ name: "ESDevelopModule" })
export class ESDevelopModule extends BaseModule {
  public static readonly NAME: string = 'ESDevelopModule'

  constructor(ctx: HippyEngineContext) {
    super(ctx)
  }

  initialize(): void {
  }

  public call(method: string, params: Array<HippyAny>, promise: HippyModulePromise): HippyAny {
    switch (method) {
      case 'getDevelop': {
        this.getAppInfo().then((ret) => {
          const info: HippyMap = new Map()
          info.set("versionCode", ret.versionCode)
          info.set("versionName", ret.versionName)
          info.set("packageName", ret.packageName)
          info.set("vendor", ret.vendor)
          promise.resolve(info)
        }, (error: BusinessError) => {
          promise.reject(JSON.stringify(error))
        })
        break;
      }
      case 'getPackageName': {
        this.getAppInfo().then((ret) => {
          promise.resolve(ret.packageName)
        }, (error: BusinessError) => {
          promise.reject(JSON.stringify(error))
        })
        break;
      }
      case 'getVersionName': {
        this.getAppInfo().then((ret) => {
          promise.resolve(ret.versionName)
        }, (error: BusinessError) => {
          promise.reject(JSON.stringify(error))
        })
        break;
      }
      case 'getVersionCode': {
        this.getAppInfo().then((ret) => {
          promise.resolve(ret.versionCode)
        }, (error: BusinessError) => {
          promise.reject(JSON.stringify(error))
        })
        break;
      }
      case 'getVendor': {
        this.getAppInfo().then((ret) => {
          promise.resolve(ret.vendor)
        }, (error: BusinessError) => {
          promise.reject(JSON.stringify(error))
        })
        break;
      }
      default:
        super.call(method, params, promise);
    }
    return null;
  }

  async getAppInfo(): Promise<ESDevelopInfo> {
    try {
      let bundleFlags = bundleManager.BundleFlag.GET_BUNDLE_INFO_WITH_APPLICATION |
      bundleManager.BundleFlag.GET_BUNDLE_INFO_WITH_SIGNATURE_INFO;
      const bundleInfo: bundleManager.BundleInfo =
        await bundleManager.getBundleInfoForSelf(bundleFlags)
      const info: ESDevelopInfo = {
        versionCode: bundleInfo.versionCode,
        versionName: bundleInfo.versionName,
        packageName: bundleInfo.name,
        vendor: bundleInfo.vendor
      }
      return Promise.resolve(info)
    } catch (e) {
      let message = (e as BusinessError).message;
      return Promise.reject(message)
    }
  }
}

export interface ESDevelopInfo {
  readonly versionCode: number
  readonly versionName: string
  readonly packageName: string
  readonly vendor: string
}
