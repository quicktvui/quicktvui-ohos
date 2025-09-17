import {
  HippyEngineContext,
  HippyAny,
  HippyValue,
  HippyModulePromise,
  HippyNativeModule,
  LogUtils
} from 'hippy';

import { BaseModule } from './BaseModule';
import { abilityAccessCtrl, bundleManager, common, Permissions } from '@kit.AbilityKit';
import { BusinessError } from '@kit.BasicServicesKit';

/**
 *
 */
export interface ESRequestPermissionsResult {
  readonly granted: boolean
  readonly grantedList?: Array<string>
  readonly deniedList?: Array<string>
  readonly deniedForeverList?: Array<string>
}

@HippyNativeModule({ name: "ESPermissionModule" })
export class ESPermissionModule extends BaseModule {
  public static readonly NAME: string = 'ESPermissionModule'
  public readonly TAG: string = 'ESPermissionModule'

  constructor(ctx: HippyEngineContext) {
    super(ctx)
  }

  initialize(): void {
  }

  public call(method: string, params: Array<HippyAny>, promise: HippyModulePromise): HippyAny {
    switch (method) {
      //请求权限
      case 'requestPermissions': {
        const permissionParams = params[0]
        let permissions: Array<string> = [];
        if (Array.isArray(permissionParams)) {
          permissions = permissionParams as Array<string>;
        } else if (typeof permissionParams === 'string') {
          permissions = [permissionParams];
        } else {
          LogUtils.e(this.TAG, 'requestPermissions: ' + permissionParams);
        }
        this.requestPermissions(permissions as Array<Permissions>).then((ret) => {
          promise.resolve(ret)
        }, (error: BusinessError) => {
          promise.reject(JSON.stringify(error))
        })
        break;
      }
    //权限是否通过
      case 'isPermissionsGranted': {
        const permissionParams = params[0]
        let permissions: Array<string> = [];
        if (Array.isArray(permissionParams)) {
          permissions = permissionParams as Array<string>;
        } else if (typeof permissionParams === 'string') {
          permissions = [permissionParams];
        } else {
          LogUtils.e(this.TAG, 'isPermissionsGranted: ' + permissionParams);
        }
        this.isPermissionsGranted(permissions as Array<Permissions>).then((ret) => {
          promise.resolve(ret)
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

  /**
   * 请求权限
   * @param permissions
   */
  async requestPermissions(permissions: Array<Permissions>): Promise<HippyValue> {
    const atManager: abilityAccessCtrl.AtManager = abilityAccessCtrl.createAtManager()
    try {
      const data =
        await atManager.requestPermissionsFromUser(this.ctx.getAbilityContext(), permissions)
      const grantStatus: Array<number> = data.authResults
      const grantedList: string[] = []
      const deniedList: string[] = []
      for (let i = 0; i < grantStatus.length; i++) {
        if (grantStatus[i] === 0) {
          grantedList.push(permissions[i])
        } else {
          deniedList.push(permissions[i])
        }
      }
      const granted = deniedList.length === 0
      const result: ESRequestPermissionsResult = {
        granted,
        grantedList: grantedList.length > 0 ? grantedList : undefined,
        deniedList: deniedList.length > 0 ? deniedList : undefined,
        deniedForeverList: [] // 暂不支持判断“永久拒绝”
      }
      return JSON.stringify(result) as HippyValue
    } catch (err) {
      const result: ESRequestPermissionsResult = {
        granted: false,
        deniedList: permissions,
        deniedForeverList: []
      }
      const error = err as BusinessError
      LogUtils.e(this.TAG,
        `Failed to request permissions. Code=${error.code}, message=${error.message}`)
      return JSON.stringify(result) as HippyValue
    }
  }

  async isPermissionsGranted(permissions: Array<Permissions>): Promise<HippyValue> {
    const atManager: abilityAccessCtrl.AtManager = abilityAccessCtrl.createAtManager()
    let tokenId = 0
    // 获取 tokenId
    try {
      const bundleInfo = await bundleManager.getBundleInfoForSelf(
        bundleManager.BundleFlag.GET_BUNDLE_INFO_WITH_APPLICATION
      )
      tokenId = bundleInfo.appInfo.accessTokenId
    } catch (error) {
      const err = error as BusinessError
      LogUtils.e(this.TAG,
        `Failed to get bundle info. Code=${err.code}, message=${err.message}`)
      // tokenId 获取失败，直接返回所有权限 denied
      return JSON.stringify({
        granted: false,
        deniedList: permissions,
        deniedForeverList: []
      }) as HippyValue;
    }
    const grantedList: string[] = []
    const deniedList: string[] = []

    for (const permission of permissions) {
      try {
        const status = await atManager.checkAccessToken(tokenId, permission)
        if (status === abilityAccessCtrl.GrantStatus.PERMISSION_GRANTED) {
          grantedList.push(permission)
        } else {
          deniedList.push(permission)
        }
      } catch (error) {
        const err = error as BusinessError
        LogUtils.e(this.TAG,
          `Failed to check permission: ${permission}, Code=${err.code}, message=${err.message}`)
        deniedList.push(permission)
      }
    }

    const granted = deniedList.length === 0
    const result: ESRequestPermissionsResult = {
      granted,
      grantedList: grantedList.length > 0 ? grantedList : undefined,
      deniedList: deniedList.length > 0 ? deniedList : undefined,
      deniedForeverList: [] // 无法判断永久拒绝
    }
    return JSON.stringify(result) as HippyValue;
  }
}


