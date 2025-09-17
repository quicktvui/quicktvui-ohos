import {
  HippyEngineContext,
  HippyAny,
  HippyMap,
  HippyModulePromise,
  HippyNativeModule,
  PixelUtil
} from 'hippy';

import { BaseModule } from './BaseModule';
import deviceInfo from '@ohos.deviceInfo';
import { display } from '@kit.ArkUI';

/**
 *
 */
@HippyNativeModule({ name: "ESDeviceModule" })
export class ESDeviceModule extends BaseModule {
  public static readonly NAME: string = 'ESDeviceModule'
  width: number = -1
  height: number = -1
  densityDPI: number = -1
  scaledDensity: number = -1
  densityPixels: number = -1

  constructor(ctx: HippyEngineContext) {
    super(ctx)
  }

  initialize(): void {
    const displayClass: display.Display = display.getDefaultDisplaySync();
    this.width = displayClass.width
    this.height = displayClass.height
    this.densityDPI = displayClass.densityDPI
    this.scaledDensity = displayClass.scaledDensity
    this.densityPixels = displayClass.densityPixels
  }

  public call(method: string, params: Array<HippyAny>, promise: HippyModulePromise): HippyAny {
    switch (method) {
      case 'getDevice': {
        const info: HippyMap = new Map()
        //TODO
        info.set("ethMac", '')
        info.set("wifiMac", '')
        //TODO
        info.set("deviceId", '')
        info.set("deviceType", '')
        //TODO
        info.set("totalMemory", -1)
        info.set("availableMemory", -1)
        //
        info.set("screenWidth", this.width)
        info.set("screenHeight", this.height)
        //
        info.set("resolution", this.width + "*" + this.height)
        info.set("density", this.densityPixels)
        info.set("densityDpi", this.densityDPI / PixelUtil.getDensityScale())
        info.set("scaledDensity", this.scaledDensity)
        //
        info.set("buildModel", deviceInfo.productModel)
        info.set("buildBrand", deviceInfo.brand)
        info.set("buildBoard", deviceInfo.softwareModel)
        info.set("buildDevice", deviceInfo.deviceType)
        info.set("buildProduct", deviceInfo.productSeries)
        info.set("buildHardware", deviceInfo.hardwareModel)
        info.set("buildManufacturer", deviceInfo.manufacture)
        info.set("buildVersionRelease", deviceInfo.displayVersion)
        info.set("buildVersionSDKInt", deviceInfo.sdkApiVersion)

        promise.resolve(info)
        break;
      }
    //TODO 待实现
      case 'getEthMac': {
        promise.resolve('')
        break;
      }
    //TODO 待实现
      case 'getWifiMac': {
        promise.resolve('')
        break;
      }
    //TODO 待实现
      case 'getTotalMemory': {
        promise.resolve(-1)
        break;
      }
    //TODO 待实现
      case 'getAvailableMemory': {
        promise.resolve(-1)
        break;
      }
      case 'getScreenWidth': {
        promise.resolve(this.width)
        break;
      }
      case 'getScreenHeight': {
        promise.resolve(this.height)
        break;
      }
      case 'getResolution': {
        promise.resolve(this.width + "*" + this.height)
        break;
      }
      case 'getDensity': {
        promise.resolve(this.densityPixels)
        break;
      }
      case 'getDensityDpi': {
        promise.resolve(this.densityDPI / PixelUtil.getDensityScale())
        break;
      }
      case 'getScaledDensity': {
        promise.resolve(this.scaledDensity)
        break;
      }
      case 'getBuildVersionRelease': {
        promise.resolve(deviceInfo.displayVersion)
        break;
      }
      case 'getBuildModel': {
        promise.resolve(deviceInfo.productModel)
        break;
      }
      case 'getBuildBrand': {
        promise.resolve(deviceInfo.brand)
        break;
      }
      case 'getBuildDevice': {
        promise.resolve(deviceInfo.deviceType)
        break;
      }
      case 'getBuildBoard': {
        promise.resolve(deviceInfo.softwareModel)
        break;
      }
      case 'getBuildProduct': {
        promise.resolve(deviceInfo.productSeries)
        break;
      }
      case 'getBuildHardware': {
        promise.resolve(deviceInfo.hardwareModel)
        break;
      }
      case 'getBuildManufacturer': {
        promise.resolve(deviceInfo.manufacture)
        break;
      }
      default:
        super.call(method, params, promise);
    }
    return null;
  }
}
