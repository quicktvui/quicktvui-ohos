import http from '@ohos.net.http';
import { BusinessError } from '@kit.BasicServicesKit';
import { ResponseData } from '../../netwrok/OkHttpClient';
import { AppContext } from '../../AppContext';
import { LoadStatus } from '../../LoadStatus';

interface Data {
  icon: string
  name: string
}

export interface LoadCallback {}

@Component
export struct SplashView {
  @Consume('appContext')
  private appContext: AppContext
  @State iconUrl: string = ''
  @State appName: string = ''

  build() {
    Stack() {
      Column() {
        Row() {
          Image(this.iconUrl).width(45).height(45)
          Text(this.appName).margin({ left: 10 })
        }

        if (this.appContext.loadResult.status == LoadStatus.FAIL) {
          Text(this.appContext.loadResult.exception.code + ' ' + this.appContext.loadResult.exception.message)
            .margin({ top: 50 })
        } else {
          Progress({ value: 100, total: 100, type: ProgressType.Linear }).width(200).height(50)
        }
      }
    }
    .width('100%')
    .height('100%')
    .expandSafeArea()
    .onAppear(() => {
      this.fetchAppInfo()
    })
  }

  private fetchAppInfo() {
    const call = http.createHttp()
    call.request('https://api.extscreen.com/v1/client/appinfo',
      {
        method: http.RequestMethod.POST,
        header: {
          'Content-Type': 'application/json',
          "isEncode": "false",
        },
        extraData: {
          'package_name': this.appContext.data.packageName,
          'channel': 'TCL'
        },
      },
      (error: BusinessError, response: http.HttpResponse) => {
        if (!error) {
          let result: ResponseData<Data> = JSON.parse(response.result as string)
          if (result && result.code == 200) {
            this.iconUrl = result.data.icon
            this.appName = result.data.name
          }
        }
        call.destroy()
      })
  }
}