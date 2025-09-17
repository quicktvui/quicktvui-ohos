import {
  HippyEngineContext,
  HippyAny,
  HippyModulePromise,
  HippyNativeModule,
  LogUtils
} from 'hippy';

import { BaseModule } from './BaseModule';
import { preferences } from '@kit.ArkData';
import QTAppManager from '../quick/QTAppManager';

export enum ESShareDataType {
  BOOLEAN = 1,
  INT = 2,
  LONG = 3,
  FLOAT = 4,
  STRING = 5,
  STRING_ARRAY = 6,
  MAP = 7
}

export enum ESShareDataMode {
  PRIVATE = 0, // 仅模块自身访问
  READABLE = 1, // 可被其他模块读取
  READ_WRITE = 2 // 可读可写
}

export interface ESShareData {
  type: ESShareDataType;
  mode: ESShareDataMode;
  secretKey?: string;
  data: HippyAny;
}

/**
 *
 */
@HippyNativeModule({ name: "ESShareDataModule" })
export class ESShareDataModule extends BaseModule {
  public static readonly NAME: string = 'ESShareDataModule'
  public readonly TAG: string = 'ESShareDataModule'
  dataPreferences: preferences.Preferences | null = null;

  constructor(ctx: HippyEngineContext) {
    super(ctx)
  }

  initialize(): void {
  }

  /**
   *
   */
  public call(method: string, params: Array<HippyAny>, promise: HippyModulePromise): HippyAny {
    try {
      switch (method) {
        case 'get': {
          const packageName = params[0] as string
          const secretKey = params[1] as string
          const key = params[2] as string
          const defValue = params[3] as HippyAny
          const shareData =
            this.getShareData(this.getSelfPackageName(), packageName, secretKey, key, defValue)
          LogUtils.d(this.TAG, `call ${method} success: ${shareData}`);
          promise.resolve(shareData)
          break;
        }
        case 'put': {
          const packageName = params[0] as string
          const secretKey = params[1] as string
          const key = params[2] as string
          const value = params[3] as HippyAny
          const mode = params[4] as number
          const dataType = params[5] as number
          LogUtils.d(this.TAG,
            `call ${method} packageName: ${packageName} secretKey: ${secretKey} key: ${key} value: ${value}  mode: ${mode} dataType: ${dataType}`);
          const success =
            this.putShareData(this.getSelfPackageName(), packageName, secretKey, key, value,
              dataType, mode)
          LogUtils.d(this.TAG, `call ${method} success: ${success}`);
          promise.resolve(success)
          break;
        }
        default:
          super.call(method, params, promise);
      }
    } catch (error) {
      LogUtils.e(this.TAG, `call ${method} failed: ${error.message}`);
      promise.reject(`Call failed: ${error.message}`);
    }
    return null;
  }


  private putShareData(selfPackageName: string, sharedPackageName: string,
    secretKey: string, key: string, value: HippyAny, shareDataType: ESShareDataType,
    shareDataMode: ESShareDataMode
  ): boolean {
    try {
      this.initShareData(sharedPackageName);
      if (!this.dataPreferences) {
        return false;
      }
      const existing: preferences.ValueType = this.dataPreferences.getSync(key, null)
      //没有数据
      if (!existing) {
        if (this.isSelfData(selfPackageName, sharedPackageName)) {
          const shareData: ESShareData = {
            type: shareDataType,
            mode: shareDataMode,
            data: value,
            secretKey: secretKey
          }
          this.dataPreferences.putSync(key, JSON.stringify(shareData))
          this.dataPreferences.flushSync()
          return true
        } else {
          LogUtils.w(this.TAG, `Permission denied: cannot write to other's PRIVATE data.`);
          return false
        }
      }
      //已有数据
      const parsedData: ESShareData = JSON.parse(existing as string)
      //修改已有的自己的数据
      if (this.isSelfData(selfPackageName, sharedPackageName)) {
        parsedData.type = shareDataType
        parsedData.mode = shareDataMode //自己改权限
        parsedData.data = value //自己改数据
        parsedData.secretKey = secretKey //自己改秘钥
        this.dataPreferences.putSync(key, JSON.stringify(parsedData))
        this.dataPreferences.flushSync()
        return true
      }
      //修改已有其他人的数据
      if (parsedData.mode >= ESShareDataMode.READ_WRITE) {
        //秘钥匹配
        if (!parsedData.secretKey || parsedData.secretKey === secretKey) {
          parsedData.data = value
          this.dataPreferences.putSync(key, JSON.stringify(parsedData))
          this.dataPreferences.flushSync()
          return true
        }
        //秘钥不匹配
        else {
          LogUtils.w(this.TAG, `Permission denied: incorrect secret key.`);
          return false
        }
      } else {
        LogUtils.w(this.TAG, `Permission denied: not writable.`);
      }
    } catch (error) {
      LogUtils.e(this.TAG, `putShareData failed: ${error.message}`);
    }
    return false
  }

  private getShareData(selfPackageName: string, sharedPackageName: string,
    secretKey: string, key: string, defValue: HippyAny
  ): HippyAny {
    try {
      this.initShareData(sharedPackageName);
      if (!this.dataPreferences) {
        return defValue;
      }

      const existing: preferences.ValueType = this.dataPreferences.getSync(key, null)
      if (!existing) {
        return defValue;
      }

      const parsedData: ESShareData = JSON.parse(existing as string)
      if (this.isSelfData(selfPackageName, sharedPackageName)) {
        return parsedData.data
      }
      if (parsedData.mode >= ESShareDataMode.READABLE) {
        if (!parsedData.secretKey || parsedData.secretKey === secretKey) {
          return parsedData.data;
        } else {
          LogUtils.w(this.TAG, `Permission denied: incorrect secret key.`);
        }
      } else {
        LogUtils.w(this.TAG, `Permission denied: not readable.`);
        return defValue
      }
    } catch (error) {
      LogUtils.e(this.TAG, `getShareData failed: ${error.message}`);
    }
    return defValue
  }

  private initShareData(sharedPackageName: string) {
    try {
      const options: preferences.Options = { name: `${sharedPackageName}_share_data` };
      this.dataPreferences = preferences.getPreferencesSync(this.ctx.getAbilityContext(), options);
    } catch (error) {
      LogUtils.e(this.TAG, `initShareData failed: ${error.message}`);
    }
  }

  private isSelfData(selfPackageName: string, sharedPackageName: string): boolean {
    return selfPackageName === sharedPackageName && !!sharedPackageName;
  }

  private getSelfPackageName(): string {
    return QTAppManager.getInstance().getPackageName();
  }
}
