/**
 *
 */
import { HippyEngineContext } from 'hippy';

export default class QTAppManager {
  private static instance: QTAppManager;

  private constructor() {
  }

  static getInstance(): QTAppManager {
    if (!QTAppManager.instance) {
      QTAppManager.instance = new QTAppManager();
    }
    return QTAppManager.instance;
  }

  public getAppId(): string {
    return "AppId"
  }

  public getPackageName(): string {
    return "test"
  }

  public getVersionCode(): number {
    return 100
  }

  public getVersionName(): string {
    return "test"
  }

  public getBundleName(): string {
    return "com.extscreen.runtime"
  }

  //----------------------------------------------------------------------------------------
  // filesDir:        /data/storage/el2/base/haps/runtime/files
  // tempDir:         /data/storage/el2/base/haps/runtime/temp
  // bundleCodeDir:   /data/storage/el1/bundle
  // preferencesDir:  /data/storage/el2/base/haps/runtime/preferences

  /**
   * 获取EsApp路径, 用于文件存储管理
   * @return
   * /data/data/APK包名/app_rpk/apps/小程序包名/files
   * 示例:/data/data/com.extscreen.runtime/app_rpk/apps/es.com.baduanjin.tv/files
   */
  public getESAppFilePath(ctx: Context): string {
    return ctx.filesDir + "/app_rpk/apps/"
      + QTAppManager.getInstance().getPackageName() + "/files"
  }

  /**
   * 获取EsApp运行时路径, 通常用于获取代码包里的assets
   * @return
   * /data/data/APK包名/app_rpk/apps/小程序包名/版本号/android
   * 示例:/data/data/com.extscreen.runtime/app_rpk/apps/es.com.baduanjin.tv/2.2.2203/android
   */
  public getESAppRuntimePath(ctx: Context): string {
    return ctx.filesDir + "/app_rpk/apps/"
      + QTAppManager.getInstance().getPackageName() + "/files/"
      + QTAppManager.getInstance().getVersionCode() + "/ohos"
  }
}
