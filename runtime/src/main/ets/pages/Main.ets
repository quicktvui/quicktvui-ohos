import { LogUtils, } from 'hippy'
import { App } from '../App';

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
    App.instance.nav?.pushPathByName(runtimeConfig?.appEntry, null, false);
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
