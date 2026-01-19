import {
  bundleManager, common
} from '@kit.AbilityKit';
import { connection } from '@kit.NetworkKit';
import { BusinessError, deviceInfo } from '@kit.BasicServicesKit';
import { display } from '@kit.ArkUI';
import { statfs } from '@kit.CoreFileKit';
import { LogUtils } from 'hippy'; // 假设 LogUtils 依然可用，如果不可用请换成 console
import { App } from '../App';

@Builder
export function PageDeviceBuilder(name: string, param: Object) {
  DevicePage()
}

@Component
export struct DevicePage {
  private TAG: string = 'DevicePage'
  private navPathStack: NavPathStack = new NavPathStack();
  // --- 设备信息状态 ---
  @State deviceName: string = '' // 设备名称
  @State deviceModel: string = '' // 设备型号
  @State osFullName: string = '' // 系统版本
  @State sdkApiVersion: string = '' // SDK 版本
  @State deviceType: string = '' // 设备类型
  @State screenResolution: string = '' // 屏幕分辨率
  @State screenDensity: string = '' // 屏幕密度
  @State ipAddress: string = '正在获取...' // IP地址
  @State netType: string = '未知' // 网络类型
  @State storageTotal: string = '' // 总存储
  @State storageFree: string = '' // 剩余存储
  @State appName: string = '' // 应用名称
  @State appVersion: string = '' // 应用版本

  async aboutToAppear() {
    LogUtils.i(this.TAG, 'Lifecycle: aboutToAppear');
    // 并行获取各类信息
    this.initBasicDeviceInfo()
    this.initScreenInfo()
    this.initAppInfo()
    this.initStorageInfo()
    this.initNetworkInfo()
  }

  /**
   * 1. 获取基础设备信息 (同步)
   */
  private initBasicDeviceInfo() {
    try {
      this.deviceName = deviceInfo.marketName; // 市场名称
      this.deviceModel = deviceInfo.productModel; // 产品型号
      this.osFullName = deviceInfo.osFullName; // 系统全称
      this.sdkApiVersion = deviceInfo.sdkApiVersion.toString(); // API 版本
      this.deviceType = deviceInfo.deviceType; // 设备类型 (tablet, tv, phone etc.)
    } catch (e) {
      LogUtils.e(this.TAG, 'initBasicDeviceInfo error: ' + JSON.stringify(e));
    }
  }

  /**
   * 2. 获取屏幕信息
   */
  private initScreenInfo() {
    try {
      let displayClass = display.getDefaultDisplaySync();
      this.screenResolution = `${displayClass.width} x ${displayClass.height}`;
      this.screenDensity = `${displayClass.densityDPI} (Scale: ${displayClass.densityPixels})`;
    } catch (e) {
      LogUtils.e(this.TAG, 'initScreenInfo error: ' + JSON.stringify(e));
    }
  }

  /**
   * 3. 获取应用版本信息
   */
  private initAppInfo() {
    let bundleFlags = bundleManager.BundleFlag.GET_BUNDLE_INFO_WITH_APPLICATION;
    bundleManager.getBundleInfoForSelf(bundleFlags).then((data) => {
      this.appName = data.name;
      this.appVersion = `${data.versionName} (Code: ${data.versionCode})`;
    }).catch((err: BusinessError) => {
      LogUtils.e(this.TAG, 'initAppInfo error: ' + JSON.stringify(err));
    });
  }

  /**
   * 4. 获取存储空间信息 (需要权限: ohos.permission.READ_MEDIA 可能不需要，视具体路径而定，这里查沙箱或根路径)
   */
  private async initStorageInfo() {
    try {
      let path = getContext(this).filesDir; // 获取应用文件目录所在分区的存储信息
      let freeSize = await statfs.getFreeSize(path);
      let totalSize = await statfs.getTotalSize(path);

      this.storageFree = this.formatBytes(freeSize);
      this.storageTotal = this.formatBytes(totalSize);
    } catch (e) {
      LogUtils.e(this.TAG, 'initStorageInfo error: ' + JSON.stringify(e));
      this.storageFree = '未知';
    }
  }

  /**
   * 5. 获取网络 IP 信息
   */
  private async initNetworkInfo() {
    try {
      const netHandle = await connection.getDefaultNet();
      const properties = await connection.getConnectionProperties(netHandle);
      const capabilities = await connection.getNetCapabilities(netHandle);

      // 获取 IP
      const addressArray = properties.linkAddresses;
      if (addressArray && addressArray.length > 0) {
        this.ipAddress = addressArray[0].address?.address ?? '获取失败';
      }

      // 获取网络类型
      if (capabilities.bearerTypes.includes(connection.NetBearType.BEARER_WIFI)) {
        this.netType = 'Wi-Fi';
      } else if (capabilities.bearerTypes.includes(connection.NetBearType.BEARER_ETHERNET)) {
        this.netType = 'Ethernet (有线)';
      } else if (capabilities.bearerTypes.includes(connection.NetBearType.BEARER_CELLULAR)) {
        this.netType = 'Cellular (蜂窝)';
      }
    } catch (e) {
      LogUtils.e(this.TAG, 'initNetworkInfo error: ' + JSON.stringify(e));
      this.ipAddress = '无网络连接';
    }
  }

  // 工具：格式化字节
  private formatBytes(bytes: number, decimals = 2) {
    if (bytes === 0) {
      return '0 Bytes';
    }
    const k = 1024;
    const dm = decimals < 0 ? 0 : decimals;
    const sizes = ['Bytes', 'KB', 'MB', 'GB', 'TB', 'PB', 'EB', 'ZB', 'YB'];
    const i = Math.floor(Math.log(bytes) / Math.log(k));
    return parseFloat((bytes / Math.pow(k, i)).toFixed(dm)) + ' ' + sizes[i];
  }

  // --- UI 构建 ---

  @Builder
  InfoRow(title: string, value: string) {
    Row() {
      Text(title)
        .fontSize(18)
        .fontColor('#AAAAAA') // 浅灰色标签
        .width('35%')
        .fontWeight(FontWeight.Medium)
      Text(value)
        .fontSize(18)
        .fontColor(Color.White) // 白色内容
        .layoutWeight(1)
        .textAlign(TextAlign.End)
        .fontWeight(FontWeight.Regular)
    }
    .width('100%')
    .padding({ top: 12, bottom: 12 })
    .border({ width: { bottom: 1 }, color: '#4A5261' }) // 分割线
  }

  build() {
    NavDestination() {
      Column() {
        // 标题栏
        Row() {
          Text("设备详情")
            .fontSize(30)
            .fontWeight(FontWeight.Bold)
            .fontColor(Color.White)
        }
        .width('100%')
        .padding({ top: 40, bottom: 20, left: 20 })
        .justifyContent(FlexAlign.Start)

        // 信息列表区域
        Scroll() {
          Column() {
            // 分组 1: 硬件信息
            Text("硬件信息").fontSize(14).fontColor('#007DFF').width('100%').margin({ top: 10, bottom: 5 })
            this.InfoRow("设备名称", this.deviceName)
            this.InfoRow("设备型号", this.deviceModel)
            this.InfoRow("设备类型", this.deviceType)
            this.InfoRow("分辨率", this.screenResolution)
            this.InfoRow("屏幕密度 (DPI)", this.screenDensity)

            // 分组 2: 系统与应用
            Text("系统与软件").fontSize(14).fontColor('#007DFF').width('100%').margin({ top: 20, bottom: 5 })
            this.InfoRow("系统版本", this.osFullName)
            this.InfoRow("SDK API", this.sdkApiVersion)
            this.InfoRow("应用名称", this.appName)
            this.InfoRow("应用版本", this.appVersion)

            // 分组 3: 存储与网络
            Text("存储与网络").fontSize(14).fontColor('#007DFF').width('100%').margin({ top: 20, bottom: 5 })
            this.InfoRow("IP 地址", this.ipAddress)
            this.InfoRow("网络类型", this.netType)
            this.InfoRow("剩余空间", this.storageFree)
            this.InfoRow("总空间", this.storageTotal)
          }
          .padding({ left: 20, right: 20, bottom: 50 })
        }
        .layoutWeight(1)
        .scrollBar(BarState.Auto)
        .edgeEffect(EdgeEffect.Spring)

        // 底部按钮 (可选：退出)
        Button("退出页面")
          .width('80%')
          .height(50)
          .backgroundColor('#FF4040') // 红色退出
          .margin({ bottom: 20 })
          .onClick(() => {
            if (this.navPathStack.size() > 0) {
              this.navPathStack.pop();
            } else {
              // 如果是根页面，选择关闭应用
              (App.instance.context as common.UIAbilityContext).terminateSelf();
            }
          })

      }
      .width('100%')
      .height('100%')
      .backgroundColor('#3A4251') // 保持原有的深色背景
      .expandSafeArea()
    }
    .hideTitleBar(true)
    .hideBackButton(true) // 使用自定义退出按钮，或者你可以改成 false 显示系统返回
    .onReady((context: NavDestinationContext) => {
      this.navPathStack = context.pathStack;
      LogUtils.i(this.TAG, "DevicePage Ready");
    })
  }
}