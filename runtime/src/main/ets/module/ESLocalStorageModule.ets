import {
  HippyEngineContext,
  HippyNativeModule,
  HippyAny,
  HippyModulePromise,
} from 'hippy';

import { BaseModule } from './BaseModule';
import { BusinessError } from '@kit.BasicServicesKit';
import { preferences, ValueType } from '@kit.ArkData';

@HippyNativeModule({ name: "ESLocalStorageModule" })
export class ESLocalStorageModule extends BaseModule {
  public static readonly NAME: string = 'ESLocalStorageModule'
  dataPreferences: preferences.Preferences | null = null;

  constructor(ctx: HippyEngineContext) {
    super(ctx)
  }

  initialize(): void {

  }

  public call(method: string, params: Array<HippyAny>, promise: HippyModulePromise): HippyAny {
    switch (method) {
      case 'initPreferences': {
        const name = params[0] as string
        let options: preferences.Options = { name: name };
        preferences.getPreferences(this.ctx.getAbilityContext(), options,
          (err: BusinessError, preferences: preferences.Preferences) => {
            if (err) {
              promise.reject(JSON.stringify(err))
            } else {
              this.dataPreferences = preferences
              promise.resolve(true)
            }
          });
        break;
      }
      case 'deletePreferences': {
        const name = params[0] as string
        preferences.deletePreferences(this.ctx.getAbilityContext(), name, (err: BusinessError) => {
          if (err) {
            promise.reject(JSON.stringify(err))
          } else {
            promise.resolve(true)
          }
        })
        break;
      }
    //----------------------------------------------------------------------------------------------------
      case 'get': {
        const key = params[0] as string
        const value = params[1] as ValueType
        if (this.dataPreferences) {
          this.dataPreferences.get(key, value, (err: BusinessError, ret: preferences.ValueType) => {
            if (err) {
              promise.reject(JSON.stringify(err))
            } else {
              promise.resolve(ret as HippyAny)
            }
          })
        } else {
          promise.reject("Please call the initPreferences method before using this feature.")
        }
        break;
      }
      case 'getSync': {
        const key = params[0] as string
        const value = params[1] as ValueType
        if (this.dataPreferences) {
          const ret: preferences.ValueType = this.dataPreferences.getSync(key, value)
          promise.resolve(ret as HippyAny)
        } else {
          promise.reject("Please call the initPreferences method before using this feature.")
        }
        break;
      }
    //--------------------------------------------------------------
      case 'put': {
        const key = params[0] as string
        const value = params[1] as ValueType
        if (this.dataPreferences) {
          this.dataPreferences.put(key, value, (err: BusinessError) => {
            if (err) {
              promise.reject(JSON.stringify(err))
            } else {
              promise.resolve(true)
            }
          })
        } else {
          promise.reject("Please call the initPreferences method before using this feature.")
        }
        break;
      }
      case 'putSync': {
        const key = params[0] as string
        const value = params[1] as ValueType
        if (this.dataPreferences) {
          this.dataPreferences.putSync(key, value)
          promise.resolve(true)
        } else {
          promise.reject("Please call the initPreferences method before using this feature.")
        }
        break;
      }
    //--------------------------------------------------------------
      case 'has': {
        const key = params[0] as string
        if (this.dataPreferences) {
          this.dataPreferences.has(key, (err: BusinessError, ret: boolean) => {
            if (err) {
              promise.reject(JSON.stringify(err))
            } else {
              promise.resolve(ret)
            }
          })
        } else {
          promise.reject("Please call the initPreferences method before using this feature.")
        }
        break;
      }
      case 'hasSync': {
        const key = params[0] as string
        if (this.dataPreferences) {
          let has: boolean = this.dataPreferences.hasSync(key)
          promise.resolve(has)
        } else {
          promise.reject("Please call the initPreferences method before using this feature.")
        }
        break;
      }
    //--------------------------------------------------------------
      case 'delete': {
        const key = params[0] as string
        if (this.dataPreferences) {
          this.dataPreferences.delete(key, (err: BusinessError) => {
            if (err) {
              promise.reject(JSON.stringify(err))
            } else {
              promise.resolve(true)
            }
          })
        } else {
          promise.reject("Please call the initPreferences method before using this feature.")
        }
        break;
      }
      case 'deleteSync': {
        const key = params[0] as string
        if (this.dataPreferences) {
          this.dataPreferences.deleteSync(key)
          promise.resolve(true)
        } else {
          promise.reject("Please call the initPreferences method before using this feature.")
        }
        break;
      }
    //--------------------------------------------------------------
      case 'flush': {
        if (this.dataPreferences) {
          this.dataPreferences.flush((err: BusinessError) => {
            if (err) {
              promise.reject(JSON.stringify(err))
            } else {
              promise.resolve(true)
            }
          })
        } else {
          promise.reject("Please call the initPreferences method before using this feature.")
        }
        break;
      }
      case 'flushSync': {
        if (this.dataPreferences) {
          this.dataPreferences.flushSync()
          promise.resolve(true)
        } else {
          promise.reject("Please call the initPreferences method before using this feature.")
        }
        break;
      }
    //--------------------------------------------------------------
      case 'clear': {
        if (this.dataPreferences) {
          this.dataPreferences.clear((err: BusinessError) => {
            if (err) {
              promise.reject(JSON.stringify(err))
            } else {
              promise.resolve(true)
            }
          })
        } else {
          promise.reject("Please call the initPreferences method before using this feature.")
        }
        break;
      }
      case 'clearSync': {
        if (this.dataPreferences) {
          this.dataPreferences.clearSync()
          promise.resolve(true)
        } else {
          promise.reject("Please call the initPreferences method before using this feature.")
        }
        break;
      }
      //--------------------------------------------------------------
      default:
        super.call(method, params, promise);
    }
    return null;
  }
}
