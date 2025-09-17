import { LogUtils, } from 'hippy'

/**
 * 入口
 */
@Entry
@Component
struct Main {
  private readonly TAG: string = 'RuntimeMainPage'
  @State progressValue: number = 0;
  private intervalId: number = -1
  //
  private navPathStack: NavPathStack | null | undefined = null

  async aboutToAppear() {
    this.navPathStack = AppStorage.get("RuntimeNavPathStack")
    LogUtils.d(this.TAG, 'Lifecycle: aboutToAppear');
  }

  onPageShow(): void {
    LogUtils.d(this.TAG, 'Lifecycle: onPageShow');
    this.intervalId = setInterval(() => {
      this.progressValue = this.progressValue + 20
      if (this.progressValue >= 100) {
        clearInterval(this.intervalId)
        //
        this.navPathStack?.pushPathByName('Debug', null, false);
      }
    }, 500)
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
    Navigation(this.navPathStack) {
      Stack() {
        Progress({ value: 0, total: 100, type: ProgressType.Capsule })
          .width(600)
          .height(10)
          .color('#0A59F7')
          .value(this.progressValue)
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
