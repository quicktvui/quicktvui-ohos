import { App } from '../App'
import { EsData } from '../eskit/EsData'
import { AppView } from '../eskit/ui/AppView'
import { AppLoaderFactory } from '../eskit/ui/hippy/AppLoader'
import { Debug } from '../pages/Debug'

@Entry
@Component
struct RootView {
  private esData?: EsData | null

  aboutToAppear(): void {
    // 从启动参数里解析EsData
    // this.esData = EsData.tryParse(App.instance.launchParams)

    // 内部启动测试参数
    this.esData = new EsData()
    this.esData.appName = '土豆逗科普'
    this.esData.packageName = 'es.hello.world'
    this.esData.icon = 'https://extcdn.hsrc.tv/data_center/files/2024/05/29/3e07ff6b-cfc6-40d2-a885-843b1655348a.png'
    this.esData.uri = `${AppLoaderFactory.FROM_ASSETS}/vue`
  }

  build() {
    Navigation(App.instance.nav) {
      Stack() {
        if (this.esData) {
          AppView({ data: this.esData })
        } else {
          Debug()
        }
      }
      .alignContent(Alignment.Center)
      .width('100%')
      .height('100%')
      .backgroundColor('#3A4251')
      .expandSafeArea()
    }
    .hideToolBar(true)
    .hideBackButton(true)
    .mode(NavigationMode.Stack)
  }
}