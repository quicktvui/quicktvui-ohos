import {
  HippyEngineContext,
  HippyAny,
  HippyModulePromise,
  HippyNativeModule,
  LogUtils,
} from 'hippy';

import { BaseModule } from './BaseModule';
import { distributedKVStore } from '@kit.ArkData';
import { BusinessError } from '@kit.BasicServicesKit';
import QTAppManager from '../quick/QTAppManager';

export type KVValueType = Uint8Array | string | number | boolean;

/**
 * 分布式 KV 存储模块
 */
@HippyNativeModule({ name: "ESKVModule" })
export class ESKVModule extends BaseModule {
  public static readonly NAME: string = 'ESKVModule';
  public readonly TAG: string = 'ESKVModule';
  private kvManager: distributedKVStore.KVManager | undefined = undefined;
  private kvStore: distributedKVStore.SingleKVStore | undefined = undefined;

  constructor(ctx: HippyEngineContext) {
    super(ctx);
  }

  initialize(): void {
  }

  public call(method: string, params: Array<HippyAny>, promise: HippyModulePromise): HippyAny {
    switch (method) {
      //---------------------------------------------------------------------------------------------
      case 'initKV': {
        try {
          const kvManagerConfig: distributedKVStore.KVManagerConfig = {
            context: this.ctx.getAbilityContext(),
            bundleName: QTAppManager.getInstance().getBundleName(),
          };
          this.kvManager = distributedKVStore.createKVManager(kvManagerConfig);
          LogUtils.i(this.TAG, `[initKV] KVManager created successfully.`);
          promise.resolve(true);
        } catch (e) {
          LogUtils.e(this.TAG, `[initKV] Failed to create KVManager. ${JSON.stringify(e)}`);
          promise.reject(e);
        }
        break;
      }
      //---------------------------------------------------------------------------------------------
      case 'getKVStore': {
        if (!this.kvManager) {
          promise.reject("KVManager is undefined");
          return;
        }
        const storeId = params[0] as string;
        const createIfMissing = params[1] as boolean;
        const encrypt = params[2] as boolean;
        const backup = params[3] as boolean;
        const autoSync = params[4] as boolean;
        const collaboration = params[5] as boolean;

        LogUtils.d(this.TAG, `[getKVStore] params: ${JSON.stringify({
          storeId,
          createIfMissing,
          encrypt,
          backup,
          autoSync,
          collaboration
        }, null, 2)}`);

        try {
          const options: distributedKVStore.Options = {
            createIfMissing: createIfMissing ?? true,
            encrypt: encrypt ?? false,
            backup: backup ?? false,
            autoSync: autoSync ?? false,
            kvStoreType: collaboration ? distributedKVStore.KVStoreType.DEVICE_COLLABORATION :
            distributedKVStore.KVStoreType.SINGLE_VERSION,
            securityLevel: distributedKVStore.SecurityLevel.S3,
          };
          this.kvManager.getKVStore<distributedKVStore.SingleKVStore>(storeId, options,
            (err, store: distributedKVStore.SingleKVStore) => {
              if (err) {
                LogUtils.e(this.TAG,
                  `[getKVStore] Failed. Code:${err.code}, message:${err.message}`);
                const map = this.initErrorMap(err)
                promise.reject(map);
                return;
              }
              this.kvStore = store;
              LogUtils.i(this.TAG, `[getKVStore] KVStore obtained successfully.`);
              promise.resolve(true);
            });
        } catch (e) {
          const error = e as BusinessError;
          LogUtils.e(this.TAG,
            `[getKVStore] Unexpected error. Code:${error.code}, message:${error.message}`);
          promise.reject(e);
        }
        break;
      }
      //---------------------------------------------------------------------------------------------
      case 'closeKVStore': {
        if (!this.kvManager) {
          promise.reject('KVManager is undefined!');
          return;
        }
        const appId = params[0] as string;
        const storeId = params[1] as string;
        try {
          this.kvManager.closeKVStore(appId, storeId, (err: BusinessError) => {
            if (err) {
              LogUtils.e(this.TAG,
                `[closeKVStore] Failed. Code:${err.code}, message:${err.message}`);
              const map = this.initErrorMap(err)
              promise.reject(map);
              return;
            }
            LogUtils.i(this.TAG, `[closeKVStore] KVStore closed successfully.`);
            promise.resolve(true);
          });
        } catch (e) {
          const error = e as BusinessError;
          LogUtils.e(this.TAG,
            `[closeKVStore] Unexpected error. Code:${error.code}, message:${error.message}`);
          promise.reject(e);
        }
        break;
      }
      //---------------------------------------------------------------------------------------------
      case 'deleteKVStore': {
        if (!this.kvManager) {
          promise.reject('KVManager is undefined!');
          return;
        }
        const appId = params[0] as string;
        const storeId = params[1] as string;
        try {
          this.kvManager.deleteKVStore(appId, storeId, (err: BusinessError) => {
            if (err) {
              LogUtils.e(this.TAG,
                `[deleteKVStore] Failed. Code:${err.code}, message:${err.message}`);
              const map = this.initErrorMap(err)
              promise.reject(map);
              return;
            }
            LogUtils.i(this.TAG, `[deleteKVStore] KVStore deleted successfully.`);
            promise.resolve(true);
          });
        } catch (e) {
          const error = e as BusinessError;
          LogUtils.e(this.TAG,
            `[deleteKVStore] Unexpected error. Code:${error.code}, message:${error.message}`);
          promise.reject(e);
        }
        break;
      }
      //---------------------------------------------------------------------------------------------
      case 'put': {
        if (!this.kvStore) {
          promise.reject('KVStore is undefined!');
          return;
        }
        const key = params[0] as string;
        const value = params[1] as KVValueType;
        try {
          this.kvStore.put(key, value, (err) => {
            if (err) {
              LogUtils.e(this.TAG,
                `[put] Failed to put data. Code:${err.code}, message:${err.message}`);
              const map = this.initErrorMap(err)
              promise.reject(map);
              return;
            }
            LogUtils.i(this.TAG, `[put] Data inserted successfully. key=${key}`);
            promise.resolve(true);
          });
        } catch (e) {
          const error = e as BusinessError;
          LogUtils.e(this.TAG,
            `[put] Unexpected error. Code:${error.code}, message:${error.message}`);
          promise.reject(e);
        }
        break;
      }
      //---------------------------------------------------------------------------------------------
      case 'get': {
        if (!this.kvStore) {
          promise.reject('KVStore is undefined!');
          return;
        }
        const key = params[0] as string;
        try {
          this.kvStore.get(key, (err, data) => {
            if (err) {
              LogUtils.e(this.TAG, `[get] Failed. Code:${err.code}, message:${err.message}`);
              const map = this.initErrorMap(err)
              promise.reject(map);
              return;
            }
            LogUtils.i(this.TAG,
              `[get] Data retrieved successfully. key=${key}, value=${JSON.stringify(data)}`);
            promise.resolve(data);
          });
        } catch (e) {
          const error = e as BusinessError;
          LogUtils.e(this.TAG,
            `[get] Unexpected error. Code:${error.code}, message:${error.message}`);
          promise.reject(e);
        }
        break;
      }
      //---------------------------------------------------------------------------------------------
      case 'remove': {
        if (!this.kvStore) {
          promise.reject('KVStore is undefined!');
          return;
        }
        const key = params[0] as string;
        try {
          this.kvStore.delete(key, (err) => {
            if (err) {
              LogUtils.e(this.TAG,
                `[remove] Failed to delete data. Code:${err.code}, message:${err.message}`);
              const map = this.initErrorMap(err)
              promise.reject(map);
              return;
            }
            LogUtils.i(this.TAG, `[remove] Data deleted successfully. key=${key}`);
            promise.resolve(true);
          });
        } catch (e) {
          const error = e as BusinessError;
          LogUtils.e(this.TAG,
            `[remove] Unexpected error. Code:${error.code}, message:${error.message}`);
          promise.reject(e);
        }
        break;
      }
      //---------------------------------------------------------------------------------------------
      default:
        super.call(method, params, promise);
    }
    return null;
  }

  private initErrorMap(err: BusinessError): Map<string, HippyAny> {
    const map = new Map<string, HippyAny>()
    map.set('code', err.code)
    map.set('message', err.message)
    return map
  }
}
