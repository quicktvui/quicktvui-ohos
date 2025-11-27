import { AppContext } from '../../AppContext';
import { LoadStatus } from '../../LoadStatus';
import { App } from '../../../App';

@Component
export struct LoadingSplashView {
  build() {
  }
}

@Component
export struct IconSplashView {
  @Consume('appContext')
  private appContext: AppContext
  @State appName: string = ''
  @State appIcon: string = ''

  aboutToAppear(): void {
    let appInfo = App.instance.context?.applicationInfo
    this.appName = appInfo?.label || ''
    this.appIcon = appInfo?.icon || ''
  }

  build() {
    Stack({ alignContent: Alignment.Center }) {
      Column() {
        Row() {
          Image($r('app.media.app_icon')).width(90).height(90)
          Text($r('app.string.EntryAbility_label')).fontSize(60).margin({ left: 15 })
        }

        if (this.appContext.loadResult.status == LoadStatus.FAIL) {
          Text(this.appContext.loadResult.exception.code + ' ' + this.appContext.loadResult.exception.message)
            .margin({ top: 50 })
        } else {
          LoadingProgress()
            .color(Color.Blue)
            .width(90)
            .height(90)
            .margin({ top: 10 })
        }
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#FFFFFF')
    .expandSafeArea()

    // .onAppear(() => {
    // this.fetchAppInfo()
    // })
  }

  // private fetchAppInfo() {
  //   const call = http.createHttp()
  //   call.request('https://api.extscreen.com/v1/client/appinfo',
  //     {
  //       method: http.RequestMethod.POST,
  //       header: {
  //         'Content-Type': 'application/json',
  //         "isEncode": "false",
  //       },
  //       extraData: {
  //         'package_name': this.appContext.data.packageName,
  //         'channel': 'TCL'
  //       },
  //     },
  //     (error: BusinessError, response: http.HttpResponse) => {
  //       if (!error) {
  //         let result: ResponseData<Data> = JSON.parse(response.result as string)
  //         if (result && result.code == 200) {
  //           this.appName = result.data.name
  //           this.appIcon = result.data.icon
  //         }
  //       }
  //       call.destroy()
  //     })
  // }
}