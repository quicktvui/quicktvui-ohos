import {
  HippyEngineContext,
  HippyAny,
  HippyModulePromise,
  HippyNativeModule,
  LogUtils,
  HippyRecord,
  HippyArray
} from 'hippy';
import { BaseModule } from './BaseModule';
import { installer } from '@kit.AbilityKit';
import { bundleManager } from '@kit.AbilityKit';
import { BusinessError } from '@kit.BasicServicesKit';

@HippyNativeModule({ name: "ESBundleModule" })
export class ESBundleModule extends BaseModule {
  public static readonly NAME: string = 'ESBundleModule'
  public readonly TAG: string = 'ESBundleModule'

  constructor(ctx: HippyEngineContext) {
    super(ctx)
  }

  initialize(): void {
    try {
      installer.getBundleInstaller((err: BusinessError, data: installer.BundleInstaller) => {
        if (err) {
          LogUtils.e(this.TAG, 'getBundleInstaller failed: ' + JSON.stringify(err));
        } else {
          LogUtils.d(this.TAG, 'getBundleInstaller success');
        }
      });
    } catch (error) {
      LogUtils.e(this.TAG, 'initialize exception: ' + JSON.stringify(error));
    }
  }

  public call(method: string, params: Array<HippyAny>, promise: HippyModulePromise): HippyAny {
    switch (method) {
      case 'install': {
        const hapFilePath = params[0] as string
        let hapFilePaths = [hapFilePath];
        let installParam: installer.InstallParam = {
          userId: 100,
          isKeepData: false,
          installFlag: 1,
        };
        try {
          installer.getBundleInstaller().then((data: installer.BundleInstaller) => {
            data.install(hapFilePaths, installParam, (err: BusinessError) => {
              if (err) {
                LogUtils.e(this.TAG, 'install failed: ' + JSON.stringify(err));
                promise.reject(JSON.stringify(err))
              } else {
                LogUtils.d(this.TAG, 'install success path: ' + hapFilePath);
                promise.resolve(true)
              }
            });
          }).catch((error: BusinessError) => {
            LogUtils.e(this.TAG, 'getBundleInstaller promise rejected: ' + JSON.stringify(error));
            promise.reject(JSON.stringify(error))
          });
        } catch (error) {
          LogUtils.e(this.TAG, 'install exception: ' + JSON.stringify(error));
          promise.reject(JSON.stringify(error))
        }
        break;
      }

      case 'uninstall': {
        const bundleName = params[0] as string
        let installParam: installer.InstallParam = {
          userId: 100,
          isKeepData: false,
          installFlag: 1
        };

        try {
          installer.getBundleInstaller().then((data: installer.BundleInstaller) => {
            data.uninstall(bundleName, installParam, (err: BusinessError) => {
              if (err) {
                LogUtils.e(this.TAG, 'uninstall failed: ' + JSON.stringify(err));
                promise.reject(JSON.stringify(err))
              } else {
                LogUtils.d(this.TAG, 'uninstall success');
                promise.resolve(true)
              }
            });
          }).catch((error: BusinessError) => {
            LogUtils.e(this.TAG, 'getBundleInstaller failed: ' + JSON.stringify(error));
            promise.reject(JSON.stringify(error))
          });
        } catch (error) {
          LogUtils.e(this.TAG, 'uninstall exception ' + JSON.stringify(error));
          promise.reject(JSON.stringify(error))
        }
        break;
      }

      case 'getBundleInfo': {
        const bundleName = params[0] as string
        let bundleFlags =
          bundleManager.BundleFlag.GET_BUNDLE_INFO_WITH_HAP_MODULE |
          bundleManager.BundleFlag.GET_BUNDLE_INFO_WITH_ABILITY;
        let userId = 100;

        try {
          bundleManager.getBundleInfo(bundleName, bundleFlags, userId, (err, data) => {
            if (err) {
              LogUtils.e(this.TAG, 'getBundleInfo failed: ' + JSON.stringify(err));
              promise.reject(JSON.stringify(err))
            } else {
              LogUtils.d(this.TAG, 'getBundleInfo success');
              // promise.resolve(JSON.stringify(data))
              promise.resolve(BundleInfoConverter.convertToHippyAny(data))
            }
          });
        } catch (err) {
          LogUtils.e(this.TAG, 'getBundleInfo exception ' + JSON.stringify(err));
          promise.reject(JSON.stringify(err))
        }
        break;
      }

      case 'getAllBundleInfo': {
        let bundleFlags =
          bundleManager.BundleFlag.GET_BUNDLE_INFO_WITH_HAP_MODULE |
          bundleManager.BundleFlag.GET_BUNDLE_INFO_WITH_ABILITY;
        let userId = 100;

        try {
          bundleManager.getAllBundleInfo(bundleFlags, userId, (err, data) => {
            if (err) {
              LogUtils.e(this.TAG, 'getAllBundleInfo failed: ' + JSON.stringify(err));
              promise.reject(JSON.stringify(err))
            } else {
              LogUtils.d(this.TAG, 'getAllBundleInfo success');
              const ret: HippyArray = []
              if (data && data.length > 0) {
                for (let i = 0; i < data.length; i++) {
                  const info = BundleInfoConverter.convertToHippyAny(data[i])
                  ret.push(info)
                }
              }
              promise.resolve(ret)
            }
          });
        } catch (err) {
          LogUtils.e(this.TAG, 'getAllBundleInfo exception ' + JSON.stringify(err));
          promise.reject(JSON.stringify(err))
        }
        break;
      }

      default:
        super.call(method, params, promise);
    }
    return null;
  }
}

export class BundleInfoConverter {
  /**
   * 主转换函数
   */
  static convertToHippyAny(info: bundleManager.BundleInfo): HippyRecord {
    const record: HippyRecord = {};

    record['name'] = info.name;
    record['vendor'] = info.vendor;
    record['versionCode'] = info.versionCode;
    record['versionName'] = info.versionName;
    record['minCompatibleVersionCode'] = info.minCompatibleVersionCode;
    record['targetVersion'] = info.targetVersion;
    record['installTime'] = info.installTime;
    record['updateTime'] = info.updateTime;
    record['appIndex'] = info.appIndex;
    if (info.firstInstallTime !== undefined) {
      record['firstInstallTime'] = info.firstInstallTime;
    }
    return record;
  }
}