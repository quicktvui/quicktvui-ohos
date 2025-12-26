import { AppContext } from '../../AppContext';
import { LoadStatus } from '../../LoadStatus';
import { App } from '../../../App';
import { EsData } from '../../EsData';

@Component
export struct LoadingSplashView {
  @Consume('appContext')
  private appContext: AppContext
  @Prop appInfo: EsData | null = null

  build() {
    Stack({ alignContent: Alignment.Center }) {
      Column() {
        Row() {
          // 优先显示 appInfo.appIcon (网络图片或base64)，为空则显示本地默认资源
          Image(this.appInfo?.appIcon ? this.appInfo.appIcon : $r('app.media.app_icon'))
            .width(90)
            .height(90)
            .objectFit(ImageFit.Contain) // 保持比例
            // 如果是网络图片，建议加上 alt 占位图
            .alt($r('app.media.app_icon'))

          // 优先显示 appInfo.appName，为空则显示本地默认字符串
          Text(this.appInfo?.appName ? this.appInfo.appName : $r('app.string.app_name'))
            .fontSize(60)
            .fontColor(Color.Black) // 显式设置颜色，防止在某些背景下看不清
            .margin({ left: 15 })
        }
        .justifyContent(FlexAlign.Center)
        .alignItems(VerticalAlign.Center)

        // 显示加载错误信息
        if (this.appContext.loadResult.status == LoadStatus.FAIL) {
          Text(this.appContext.loadResult.exception.code + ' ' + this.appContext.loadResult.exception.message)
            .margin({ top: 50 })
            .fontColor(Color.Red)
        }
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#FFFFFF')
    .expandSafeArea()
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
          Text($r('app.string.app_name')).fontSize(60).margin({ left: 15 })
        }

        if (this.appContext.loadResult.status == LoadStatus.FAIL) {
          Text(this.appContext.loadResult.exception.code + ' ' + this.appContext.loadResult.exception.message)
            .margin({ top: 50 })
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