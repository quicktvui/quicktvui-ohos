import {
  HippyEngineContext,
  HippyAny,
  HippyModulePromise,
  HippyNativeModule,
  NativeRenderImpl
} from 'hippy';

import { BaseModule } from './BaseModule';
import { LogUtils } from 'hippy/src/main/ets/support/utils/LogUtils'
import QTAppManager from '../quick/QTAppManager';

/**
 * TODO
 */
@HippyNativeModule({ name: "ESModule" })
export class ESModule extends BaseModule {
  public static readonly NAME: string = 'ESModule'
  private readonly TAG: string = 'ESModule'

  constructor(ctx: HippyEngineContext) {
    super(ctx)
  }

  initialize(): void {
  }

  public call(method: string, params: Array<HippyAny>, promise: HippyModulePromise): HippyAny {
    switch (method) {
      //TODO
      case 'getESDeviceInfo': {
        try {
          const info = new Map<string, HippyAny>()
          info.set('cid', QTAppManager.getInstance().getAppId())
          info.set('device_ip', 'x')
          info.set('device_name', 'x')
          promise.resolve(info)
          LogUtils.e(this.TAG, 'call method: getESDeviceInfo success,' + JSON.stringify(info));
        } catch (e) {
          LogUtils.e(this.TAG, 'call method: getESDeviceInfo error,' + JSON.stringify(e));
        }

        break;
      }
    //TODO
      case 'getESSDKInfo': {
        const info = new Map<string, HippyAny>()
        info.set('cid', QTAppManager.getInstance().getAppId())
        info.set('IPAddress', '')
        info.set('deviceName', '')
        info.set('versionCode', '')
        info.set('versionName', '')
        info.set('packageName', '')
        info.set('eskit_ver_code', 3.0)
        info.set('eskit_ver_name', '')
        info.set('miniProgramPath',
          QTAppManager.getInstance().getESAppFilePath(this.ctx.getAbilityContext()))
        info.set('runtimePath',
          QTAppManager.getInstance().getESAppRuntimePath(this.ctx.getAbilityContext()))
        info.set('schemes', '')
        info.set('sdkChannel', '')
        promise.resolve(info)
        break;
      }
      case 'getESSDKVersionCode': {
        promise.resolve(QTAppManager.getInstance().getVersionCode())
        break;
      }
      case 'getESSDKVersionName': {
        promise.resolve(QTAppManager.getInstance().getVersionName())
        break;
      }
      case 'getESPackageName': {
        promise.resolve(QTAppManager.getInstance().getPackageName())
        break;
      }
    //-------------------------------------------------------------------

    /**
     * 获取EsApp路径, 用于文件存储管理
     * @return
     * /data/data/APK包名/app_rpk/apps/小程序包名/files
     * 示例:/data/data/com.extscreen.runtime/app_rpk/apps/es.com.baduanjin.tv/files
     */
      case 'getESAppFilePath': {
        promise.resolve(QTAppManager.getInstance().getESAppFilePath(this.ctx.getAbilityContext()))
        break;
      }
    /**
     * 获取EsApp运行时路径, 通常用于获取代码包里的assets
     * @return
     * /data/data/APK包名/app_rpk/apps/小程序包名/版本号/android
     * 示例:/data/data/com.extscreen.runtime/app_rpk/apps/es.com.baduanjin.tv/2.2.2203/android
     */
      case 'getESAppRuntimePath': {
        promise.resolve(QTAppManager.getInstance()
          .getESAppRuntimePath(this.ctx.getAbilityContext()))
        break;
      }
    //-------------------------------------------------------------------
      case 'getSupportSchemes': {
        LogUtils.d(this.TAG, '=======getSupportSchemes=========>>>>>');
        promise.resolve('')
        break;
      }
      case 'launchESPageByArgs': {
        LogUtils.d(this.TAG, '=======launchESPageByArgs=========>>>>>');
        promise.resolve([])
        break;
      }
      case 'launchESPage': {
        LogUtils.d(this.TAG, '=======launchESPage=========>>>>>');
        promise.resolve('')
        break;
      }
      case 'launchNativeApp': {
        LogUtils.d(this.TAG, '=======launchNativeApp=========>>>>>');
        promise.resolve([])
        break;
      }
      case 'launchNativeAppWithPackage': {
        LogUtils.d(this.TAG, '=======launchNativeAppWithPackage=========>>>>>');
        break;
      }
      case 'finish': {
        LogUtils.d(this.TAG, '=======finish=========>>>>>');
        break;
      }
      case 'finishAll': {
        LogUtils.d(this.TAG, '=======finishAll=========>>>>>');
        break;
      }
      case 'isModuleRegistered': {
        try {
          const moduleName = params[0] as string
          const module = this.ctx.getModuleManager().getNativeModule(moduleName, false)
          promise.resolve(module != null)
        } catch (e) {
          promise.reject(e)
        }
        break;
      }
      case 'isComponentRegistered': {
        try {
          const componentName = params[0] as string
          if (this.ctx.getNativeRender() instanceof NativeRenderImpl) {
            const render = this.ctx.getNativeRender() as NativeRenderImpl
            const isRegistered = render.getCustomRenderViewCreatorMap()?.has(componentName)
            promise.resolve(isRegistered)
          } else {
            promise.resolve(false)
          }
        } catch (e) {
          promise.reject(e)
        }
        break;
      }
      default:
        super.call(method, params, promise);
    }
    return null;
  }
}
