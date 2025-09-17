import {
  HippyEngineContext,
  HippyAny,
  HippyModulePromise,
  HippyNativeModule,
  LogUtils
} from 'hippy';

import { BaseModule } from './BaseModule';
import { BusinessError, usbManager } from '@kit.BasicServicesKit';

@HippyNativeModule({ name: "ESUsbDeviceModule" })
export class ESUsbDeviceModule extends BaseModule {
  public static readonly NAME: string = 'ESUsbDeviceModule'
  public readonly TAG: string = 'ESUsbDeviceModule'

  constructor(ctx: HippyEngineContext) {
    super(ctx)
  }

  initialize(): void {
  }

  public call(method: string, params: Array<HippyAny>, promise: HippyModulePromise): HippyAny {
    switch (method) {
      case 'getDevices': {
        try {
          let deviceList: Array<usbManager.USBDevice> = usbManager.getDevices();
          const list: Array<HippyAny> = []
          if (deviceList && deviceList.length > 0) {
            deviceList.map((value) => {
              list.push(this.usbDeviceToMap(value))
            })
          }
          promise?.resolve(list)
        } catch (e) {
          promise?.reject(e)
          LogUtils.e(this.TAG, 'getDevices error: ' + JSON.stringify(e));
        }
        break;
      }
      case 'getDevice': {
        try {
          const vendorId = params[0] as number
          const productId = params[1] as number
          let deviceList: Array<usbManager.USBDevice> = usbManager.getDevices();
          if (deviceList && deviceList.length > 0) {
            for (let i = 0; i < deviceList.length; i++) {
              const device: usbManager.USBDevice = deviceList[i];
              if (device.vendorId == vendorId && device.productId == productId) {
                promise?.resolve(this.usbDeviceToMap(device))
                return
              }
            }
          }
          promise?.resolve({})
        } catch (e) {
          promise?.reject(e)
          LogUtils.e(this.TAG, 'getDevice error: ' + JSON.stringify(e));
        }
        break;
      }
      case 'getDevicesByArray': {
        try {
          // deviceIdList: [[vendorId, productId], ...]
          const deviceIdList: Array<Array<number>> = params[0] as Array<Array<number>>;
          let deviceList: Array<usbManager.USBDevice> = usbManager.getDevices();
          let matchedDevices: Array<HippyAny> = [];

          if (deviceList && deviceList.length > 0) {
            for (let i = 0; i < deviceList.length; i++) {
              const device: usbManager.USBDevice = deviceList[i];
              for (let j = 0; j < deviceIdList.length; j++) {
                const vendorId = deviceIdList[j][0];
                const productId = deviceIdList[j][1];
                if (device.vendorId === vendorId && device.productId === productId) {
                  matchedDevices.push(this.usbDeviceToMap(device));
                  break; // 已匹配，不必继续比对该设备
                }
              }
            }
          }
          // 返回匹配的设备数组（若没有则为空数组）
          promise?.resolve(matchedDevices);
        } catch (e) {
          promise?.reject(e)
          LogUtils.e(this.TAG, 'getDeviceList error: ' + JSON.stringify(e));
        }
        break;
      }
      case 'requestRight': {
        try {
          const vendorId = params[0] as number;
          const productId = params[1] as number;
          const deviceList: usbManager.USBDevice[] = usbManager.getDevices() ?? [];
          const device = deviceList.find(
            d => d.vendorId === vendorId && d.productId === productId
          );
          if (!device) {
            promise?.resolve(false);
            break;
          }
          usbManager.requestRight(device.name)
            .then(ret => promise?.resolve(ret))
            .catch((error: BusinessError) => {
              promise?.reject(JSON.stringify(error));
            });
        } catch (e) {
          promise?.reject(e);
          LogUtils.e(this.TAG, 'requestRight error: ' + JSON.stringify(e));
        }
        break;
      }
      case 'hasRight': {
        try {
          const vendorId = params[0] as number;
          const productId = params[1] as number;
          const deviceList: Array<usbManager.USBDevice> = usbManager.getDevices() ?? [];
          const device = deviceList.find(
            (d) => d.vendorId === vendorId && d.productId === productId
          );
          if (device) {
            promise?.resolve(usbManager.hasRight(device.name));
          } else {
            promise?.resolve(false);
          }
        } catch (e) {
          promise?.reject(e);
          LogUtils.e(this.TAG, 'hasRight error: ' + JSON.stringify(e));
        }
        break;
      }
      default:
        super.call(method, params, promise);
    }
    return null;
  }

  private usbDeviceToMap(device: usbManager.USBDevice): Map<string, HippyAny> {
    const map = new Map<string, HippyAny>()
    map.set('deviceName', device.name)
    map.set('vendorId', device.vendorId)
    map.set('productId', device.productId)
    map.set('deviceId', device.busNum)
    map.set('deviceProtocol', device.protocol)
    map.set('productName', device.productName)
    map.set('serialNumber', device.serial)
    map.set('manufacturerName', device.manufacturerName)
    return map
  }
}
