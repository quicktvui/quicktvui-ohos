import { LogUtils, } from 'hippy'
import { App } from '../App';
import { EsData } from '../eskit/EsData';

/**
 * 入口
 */
@Entry
@Component
struct Main {
  private readonly TAG: string = 'MainPage'

  onPageShow(): void {
    LogUtils.d(this.TAG, 'Lifecycle: onPageShow');

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
    )
    App.instance.nav?.pushPathByName(runtimeConfig?.appEntry, params, false);
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
