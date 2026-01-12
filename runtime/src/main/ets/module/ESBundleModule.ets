import {
  HippyEngineContext, HippyAny, HippyModulePromise, HippyNativeModule, LogUtils
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
    console.log("-------ESBundleModule------constructor---start----->>>>>")
    super(ctx)
  }

  initialize(): void {
    try {
      installer.getBundleInstaller((err: BusinessError, data: installer.BundleInstaller) => {
        if (err) {
          console.error('getBundleInstaller failed:' + err.message);
          console.log("-------ESBundleModule------constructor---failed----->>>>>" + JSON.stringify(err))
        } else {
          console.info('getBundleInstaller successfully');
          console.log("-------ESBundleModule------constructor---successfully----->>>>>")
        }
      });

    } catch (error) {
      console.log("-------ESBundleModule------constructor---error----->>>>>")
      let message = (error as BusinessError).message;
      console.error('getBundleInstaller failed:' + message);
    }
  }

  public call(method: string, params: Array<HippyAny>, promise: HippyModulePromise): HippyAny {
    switch (method) {
      case 'install': {
        const hapFilePath = params[0] as string
        console.log('========ESBundleModule=======install===1=====>>>>' + hapFilePath)
        let hapFilePaths = [hapFilePath];
        let installParam: installer.InstallParam = {
          userId: 100,
          isKeepData: false,
          installFlag: 1,
        };
        console.log('========ESBundleModule=======install====2====>>>>' + hapFilePath)
        try {
          installer.getBundleInstaller().then((data: installer.BundleInstaller) => {
            data.install(hapFilePaths, installParam, (err: BusinessError) => {
              if (err) {
                console.log('========ESBundleModule=======install===3====>>>>' + JSON.stringify(err))
                console.error('install failed:' + err.message);
              } else {
                console.log('========ESBundleModule=======install===3==successfully==>>>>')
                console.info('install successfully.');
                promise.resolve(true)
              }
            });
          }).catch((error: BusinessError) => {
            console.log('========ESBundleModule=======install===5==error==>>>>' + JSON.stringify(error))
            console.error('getBundleInstaller failed. Cause: ' + error.message);
          });
        } catch (error) {
          let message = (error as BusinessError).message;
          console.error('getBundleInstaller failed. Cause: ' + message);
          console.log('========ESBundleModule=======install===6==error==>>>>' + JSON.stringify(error))
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
                promise.reject(JSON.stringify(err))
              } else {
                promise.resolve(true)
              }
            });
          }).catch((error: BusinessError) => {
            promise.reject(JSON.stringify(error))
          });
        } catch (error) {
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
              promise.reject(JSON.stringify(err))
            } else {
              promise.resolve(JSON.stringify(data))
            }
          });
        } catch (err) {
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
              promise.reject(JSON.stringify(err))
            } else {
              promise.resolve(JSON.stringify(data))
            }
          });
        } catch (err) {
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
