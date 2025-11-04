import { App } from '../App'
import { EsData } from '../eskit/EsData'
import { AppView } from '../eskit/ui/AppView'
import { Debug } from '../pages/Debug'

@Entry
@Component
struct RootView {
  private esData?: EsData | null

  aboutToAppear(): void {
    App.instance.nav = new NavPathStack()
    this.esData = EsData.tryParse(App.instance.launchParams)
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