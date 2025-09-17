import {
  HippyEngineContext,
  HippyAny,
  HippyModulePromise,
  HippyNativeModule,
  LogUtils
} from 'hippy';

import { BaseModule } from './BaseModule';
import { relationalStore } from '@kit.ArkData';
import QTAppManager from '../quick/QTAppManager';
import { BusinessError } from '@kit.BasicServicesKit';

@HippyNativeModule({ name: "ESDatabaseModule" })
export class ESDatabaseModule extends BaseModule {
  public static readonly NAME: string = 'ESDatabaseModule'
  public readonly TAG: string = 'ESDatabaseModule'
  //
  private databaseMap = new Map<string, relationalStore.RdbStore>()

  constructor(ctx: HippyEngineContext) {
    super(ctx)
  }

  initialize(): void {
  }

  public call(method: string, params: Array<HippyAny>, promise: HippyModulePromise): HippyAny {
    switch (method) {
      //-------------------------------------------------------------------------------------------
      case 'getRdbStore': {
        try {
          const packageName = QTAppManager.getInstance().getPackageName()
          this.getOrCreateDatabase(packageName).then((store) => {
            LogUtils.d(this.TAG, 'getOrCreateDatabase: ' + store);
            promise.resolve(store.version);
          }).catch((err: BusinessError) => {
            LogUtils.d(this.TAG, 'getOrCreateDatabase error: ' + JSON.stringify(err));
            promise.reject(JSON.stringify(err));
          });
        } catch (e) {
          promise?.reject(JSON.stringify(e))
        }
        break;
      }
      //-------------------------------------------------------------------------------------------
      case 'deleteRdbStore': {
        try {
          const packageName = QTAppManager.getInstance().getPackageName()
          const databaseName = packageName + '.db'
          relationalStore.deleteRdbStore(this.ctx.getAbilityContext(), databaseName,
            (err: BusinessError) => {
              if (err) {
                promise?.reject(JSON.stringify(err))
                return;
              }
              promise.resolve(true)
            });
        } catch (e) {
          promise?.reject(JSON.stringify(e))
        }
        break;
      }
      //-------------------------------------------------------------------------------------------
      case 'execute': {
        try {
          const packageName = QTAppManager.getInstance().getPackageName()
          const sql = params[0] as string
          const version = params[1] as number

          this.getOrCreateDatabase(packageName).then((database) => {
            if (database) {
              database?.executeSql(sql).then(() => {
                if (version != undefined && version != null) {
                  database.version = version
                }
                LogUtils.d(this.TAG, 'execute sql: ' + sql + " version: " + version);
              })
              promise.resolve(true)
            } else {
              promise.resolve(false)
            }
          }).catch((err: BusinessError) => {
            promise.reject(JSON.stringify(err));
          });
        } catch (e) {
          promise?.reject(JSON.stringify(e))
        }
        break;
      }
      //-------------------------------------------------------------------------------------------
      case 'query': {
        try {
          const packageName = QTAppManager.getInstance().getPackageName()
          const sql = params[0] as string;

          this.getOrCreateDatabase(packageName).then((database) => {
            database.querySql(sql).then((resultSet: relationalStore.ResultSet) => {
              const results: HippyAny[] = [];

              while (resultSet.goToNextRow()) {
                const columnCount = resultSet.columnCount;
                const row: Record<string, HippyAny> = {};

                for (let index = 0; index < columnCount; index++) {
                  try {
                    const columnName = resultSet.getColumnName(index);
                    let value: relationalStore.ValueType = resultSet.getValue(index);
                    if (value instanceof Uint8Array) {
                      const v = Array.from(value) as number[];
                      row[columnName] = v;
                      break
                    }
                    if (
                      typeof value === 'number' ||
                        typeof value === 'string' ||
                        typeof value === 'boolean' ||
                      Array.isArray(value) ||
                        (value && typeof value === 'object')
                    ) {
                      row[columnName] = value as HippyAny;
                    } else {
                      row[columnName] = null;
                    }
                  } catch (e) {
                  }
                }
                results.push(row as HippyAny);
              }
              resultSet.close()
              LogUtils.d(this.TAG, 'query sql: ' + sql + " ResultSet: " + JSON.stringify(results));
              promise.resolve(results as HippyAny);
            }).catch((err: BusinessError) => {
              promise.reject(JSON.stringify(err));
            });
          }).catch((err: BusinessError) => {
            promise.reject(JSON.stringify(err));
          });
        } catch (e) {
          promise.reject(JSON.stringify(e));
        }
        break;
      }
      //-------------------------------------------------------------------------------------------
      default:
        super.call(method, params, promise);
    }
    return null;
  }

  private async getOrCreateDatabase(packageName: string): Promise<relationalStore.RdbStore> {
    if (this.databaseMap.has(packageName)) {
      const existingStore = this.databaseMap.get(packageName);
      if (existingStore) {
        return existingStore;
      }
    }

    const databaseName = packageName + '.db';
    const config: relationalStore.StoreConfig = {
      name: databaseName,
      securityLevel: relationalStore.SecurityLevel.S3,
    };

    return new Promise<relationalStore.RdbStore>((resolve, reject) => {
      relationalStore.getRdbStore(this.ctx.getAbilityContext(), config, (err, store) => {
        if (err) {
          reject(err);
          return;
        }
        this.databaseMap.set(packageName, store);
        resolve(store);
      });
    });
  }
}
