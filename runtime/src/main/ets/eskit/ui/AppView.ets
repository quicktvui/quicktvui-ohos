import { App } from '../../App'
import { AppContext } from '../AppContext'
import { AppManager } from '../AppManager'
import { EsData } from '../EsData'
import { LoadStatus } from '../LoadStatus'
import { HippyView } from './hippy/HippyView'
import { SplashView } from './splash/SplashView'

@Builder
export function PageDebugBuilder() {
  AppView()
}

@Component
export struct AppView {
  @Provide('appContext')
  private appContext: AppContext = new AppContext(App.instance.context!)
  @Prop data: EsData

  aboutToAppear(): void {
    this.appContext.data = this.data;
    AppManager.instance.addAppContext(this.appContext)
  }

  build() {
    NavDestination() {
      Stack() {
        HippyView()
        if (this.appContext.loadResult.status != LoadStatus.SUCCESS) {
          SplashView()
        }
      }
      .expandSafeArea()
    }.onReady((context) => {
      let data = context.pathInfo.param as EsData
      if (data) {
        this.appContext.data = data
      }
    })
  }

  aboutToDisappear(): void {
    AppManager.instance.removeAppContext(this.appContext)
  }
}