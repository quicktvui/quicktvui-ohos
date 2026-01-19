import { LogUtils } from 'hippy'
import { App } from '../App';
import { EsData } from '../eskit/EsData';
import { abilityAccessCtrl, common } from '@kit.AbilityKit'; // [新增] 权限控制
import { identifier } from '@kit.AdsKit'; // [新增] OAID

/**
 * 入口
 */
@Entry
@Component
struct Main {
  private readonly TAG: string = 'MainPage'

  async aboutToAppear() {
    LogUtils.d(this.TAG, 'Lifecycle: aboutToAppear');
    // 获取配置
    const runtimeConfig = App.instance.runtimeConfig;
    // 判断是否开启了 OAID 获取
    if (runtimeConfig?.appEnableOAID) {
      await this.initOAIDFlow();
    } else {
      // 没开启，直接跳转
      this.launchPage();
    }
  }

  /**
   * 初始化 OAID 流程
   */
  private async initOAIDFlow() {
    try {
      const atManager = abilityAccessCtrl.createAtManager();
      const context = getContext(this) as common.UIAbilityContext;

      // 1. 请求权限 'ohos.permission.APP_TRACKING_CONSENT'
      // 注意：这需要在 module.json5 中配置 requestPermissions
      const data = await atManager.requestPermissionsFromUser(context, ['ohos.permission.APP_TRACKING_CONSENT']);

      if (data.authResults && data.authResults.length > 0 && data.authResults[0] === 0) {
        // 2. 授权成功，获取 OAID
        const oaid = await identifier.getOAID();
        LogUtils.i(this.TAG, `Get OAID success: ${oaid}`);

        // 3. 存入全局缓存 (AppStorage)，后续页面可以通过 AppStorage.get('GLOBAL_OAID') 获取
        if (App.instance.runtimeConfig) {
          App.instance.runtimeConfig.oaid = oaid
        }
      } else {
        LogUtils.w(this.TAG, 'User denied OAID permission.');
        if (App.instance.runtimeConfig) {
          App.instance.runtimeConfig.oaid = ''
        }
      }
    } catch (e) {
      LogUtils.e(this.TAG, `OAID Init Error: ${JSON.stringify(e)}`);
    } finally {
      // 4. 无论成功还是失败，都必须进入应用
      this.launchPage();
    }
  }

  /**
   * 执行跳转逻辑
   */
  private launchPage() {
    LogUtils.d(this.TAG, 'Ready to jump to next page');
    const runtimeConfig = App.instance.runtimeConfig
    const params = EsData.buildESData(
      runtimeConfig?.appId,
      runtimeConfig?.appVersion,
      runtimeConfig?.appName,
      runtimeConfig?.appIcon,
      runtimeConfig?.appDebug,
      runtimeConfig?.appBundleUri,
      runtimeConfig?.appParams,
      runtimeConfig?.appEnableOAID,
      runtimeConfig?.oaid,
    )
    App.instance.nav?.pushPathByName(runtimeConfig?.appEntry, params, false);
  }

  onPageShow(): void {
    LogUtils.d(this.TAG, 'Lifecycle: onPageShow');
    // 注意：原来的 pushPathByName 移到了 launchPage 中
    // 避免 onPageShow 每次切回来都触发跳转
  }

  onPageHide(): void {
    LogUtils.d(this.TAG, 'Lifecycle: onPageHide');
  }

  aboutToDisappear(): void {
    LogUtils.d(this.TAG, 'Lifecycle: aboutToDisappear');
  }

  onBackPress(): boolean | void {
    LogUtils.d(this.TAG, 'Lifecycle: onBackPress');
    return false;
  }

  build() {
    Navigation(App.instance.nav) {
      Stack() {
      }
      .alignContent(Alignment.Center)
      .width('100%')
      .height('100%')
      .backgroundColor(Color.Transparent)
      .expandSafeArea()
    }
    .hideToolBar(true)
    .hideBackButton(true)
    .mode(NavigationMode.Stack)
  }
}
