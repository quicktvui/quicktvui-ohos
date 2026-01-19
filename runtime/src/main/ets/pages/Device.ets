import {
  bundleManager,
  common
} from '@kit.AbilityKit';
import { connection } from '@kit.NetworkKit';
import { BusinessError, deviceInfo } from '@kit.BasicServicesKit';
import { display } from '@kit.ArkUI';
import { statfs } from '@kit.CoreFileKit';
import { LogUtils } from 'hippy'; // 保持你的 LogUtils 引用
import { App } from '../App';

// ---------------------------------------------------------
// 1. 将 InfoRow 提取为独立的组件，确保 UI 刷新机制生效
// ---------------------------------------------------------
@Component
struct InfoRow {
  @Prop title: string = ''
  @Prop value: string = ''

  build() {
    Row() {
      Text(this.title)
        .fontSize(18)
        .fontColor('#AAAAAA')
        .width('35%')
        .fontWeight(FontWeight.Medium)
      Text(this.value)
        .fontSize(18)
        .fontColor(Color.White)
        .layoutWeight(1)
        .textAlign(TextAlign.End)
        .fontWeight(FontWeight.Regular)
        .textOverflow({ overflow: TextOverflow.Ellipsis }) // 防止文字过长换行难看
        .maxLines(1)
    }
    .width('100%')
    .padding({ top: 12, bottom: 12 })
    .border({ width: { bottom: 1 }, color: '#4A5261' })
  }
}

// ---------------------------------------------------------
// 2. 主页面逻辑
// ---------------------------------------------------------
@Builder
export function PageDeviceBuilder(name: string, param: Object) {
  DevicePage()
}

@Component
export struct DevicePage {
  private TAG: string = 'DevicePage'
  private navPathStack: NavPathStack = new NavPathStack();

  // 给所有 @State 加上默认值 "..."，这样一进页面你能看到它们占位，确认 UI 有在渲染
  @State deviceName: string = '...'
  @State deviceModel: string = '...'
  @State osFullName: string = '...'
  @State sdkApiVersion: string = '...'
  @State deviceType: string = '...'

  @State screenResolution: string = '...'
  @State screenDensity: string = '...'

  @State ipAddress: string = '正在获取...'
  @State netType: string = '...'

  @State storageTotal: string = '正在计算...'
  @State storageFree: string = '...'

  @State appName: string = '正在查询...'
  @State appVersion: string = '...'

  async aboutToAppear() {
    LogUtils.i(this.TAG, 'Lifecycle: aboutToAppear');
    this.initBasicDeviceInfo()
    this.initScreenInfo()
    this.initAppInfo()
    this.initStorageInfo()
    this.initNetworkInfo()
  }

  // --- 硬件信息 ---
  private initBasicDeviceInfo() {
    try {
      this.deviceName = deviceInfo.marketName || 'Unknown';
      this.deviceModel = deviceInfo.productModel || 'Unknown';
      this.osFullName = deviceInfo.osFullName || 'HarmonyOS';
      this.sdkApiVersion = deviceInfo.sdkApiVersion.toString();
      this.deviceType = deviceInfo.deviceType || 'default';
    } catch (e) {
      LogUtils.e(this.TAG, 'initBasic error: ' + JSON.stringify(e));
    }
  }

  // --- 屏幕信息 ---
  private initScreenInfo() {
    try {
      let displayClass = display.getDefaultDisplaySync();
      this.screenResolution = `${displayClass.width} x ${displayClass.height}`;
      this.screenDensity = `${displayClass.densityDPI}`;
    } catch (e) {
      LogUtils.e(this.TAG, 'initScreen error: ' + JSON.stringify(e));
    }
  }

  // --- 应用信息 (重点修复) ---
  private initAppInfo() {
    let bundleFlags = bundleManager.BundleFlag.GET_BUNDLE_INFO_WITH_APPLICATION;
    bundleManager.getBundleInfoForSelf(bundleFlags).then((data) => {
      LogUtils.i(this.TAG, `[AppInfo] Fetched: ${data.name}`);
      // 这里的赋值会自动触发 InfoRow 组件的 @Prop 更新
      this.appName = data.name;
      this.appVersion = data.versionCode + ""; // 保存一下做后续逻辑
      this.appVersion = `${data.versionName} (${data.versionCode})`;
    }).catch((err: BusinessError) => {
      LogUtils.e(this.TAG, `[AppInfo] Error: ${JSON.stringify(err)}`);
      this.appName = "查询失败";
    });
  }

  // --- 存储信息 ---
  private async initStorageInfo() {
    try {
      let context = getContext(this) as common.UIAbilityContext;
      // 使用 cacheDir 更加稳定
      let path = context.cacheDir;
      let freeSize = await statfs.getFreeSize(path);
      let totalSize = await statfs.getTotalSize(path);

      this.storageFree = this.formatBytes(freeSize);
      this.storageTotal = this.formatBytes(totalSize);
    } catch (e) {
      LogUtils.e(this.TAG, `[Storage] Error: ${JSON.stringify(e)}`);
      this.storageFree = "未知";
    }
  }

  // --- 网络信息 ---
  private async initNetworkInfo() {
    try {
      const netHandle = connection.getDefaultNetSync();
      if (!netHandle || netHandle.netId === 0) {
        this.ipAddress = "无网络";
        this.netType = "None";
        return;
      }

      const properties = await connection.getConnectionProperties(netHandle);
      const addressArray = properties.linkAddresses;
      if (addressArray && addressArray.length > 0) {
        this.ipAddress = addressArray[0].address?.address ?? '获取异常';
      }

      this.netType = "已连接"; // 简化显示，确保有值
    } catch (e) {
      LogUtils.e(this.TAG, `[Network] Error: ${JSON.stringify(e)}`);
    }
  }

  private formatBytes(bytes: number) {
    if (bytes === 0) return '0 B';
    const k = 1024;
    const sizes = ['B', 'KB', 'MB', 'GB', 'TB'];
    const i = Math.floor(Math.log(bytes) / Math.log(k));
    return parseFloat((bytes / Math.pow(k, i)).toFixed(2)) + ' ' + sizes[i];
  }

  build() {
    NavDestination() {
      Column() {
        // 标题
        Row() {
          Text("设备详情")
            .fontSize(30)
            .fontWeight(FontWeight.Bold)
            .fontColor(Color.White)
        }
        .width('100%')
        .padding({ top: 40, bottom: 20, left: 20 })

        Scroll() {
          Column() {
            // 注意：这里使用独立的 Component 组件，传入参数

            Text("硬件信息").fontSize(14).fontColor('#007DFF').width('100%').margin({ top: 10, bottom: 5 })
            InfoRow({ title: "设备名称", value: this.deviceName })
            InfoRow({ title: "设备型号", value: this.deviceModel })
            InfoRow({ title: "系统版本", value: this.osFullName })
            InfoRow({ title: "分辨率", value: this.screenResolution })

            Text("系统与软件").fontSize(14).fontColor('#007DFF').width('100%').margin({ top: 20, bottom: 5 })
            InfoRow({ title: "应用名称", value: this.appName })
            InfoRow({ title: "应用版本", value: this.appVersion })

            Text("存储与网络").fontSize(14).fontColor('#007DFF').width('100%').margin({ top: 20, bottom: 5 })
            InfoRow({ title: "IP 地址", value: this.ipAddress })
            InfoRow({ title: "网络状态", value: this.netType })
            InfoRow({ title: "剩余空间", value: this.storageFree })
            InfoRow({ title: "总空间", value: this.storageTotal })
          }
          .padding({ left: 20, right: 20, bottom: 50 })
        }
        .layoutWeight(1)

        // 退出按钮
        Button("返回")
          .width('80%')
          .height(50)
          .backgroundColor('#FF4040')
          .margin({ bottom: 20 })
          .onClick(() => {
            // 简单的退出逻辑
            if (this.navPathStack.size() > 0) this.navPathStack.pop();
            else (getContext(this) as common.UIAbilityContext).terminateSelf();
          })
      }
      .width('100%')
      .height('100%')
      .backgroundColor('#3A4251')
      .expandSafeArea()
    }
    .hideTitleBar(true)
    .onReady((context) => {
      this.navPathStack = context.pathStack;
    })
  }
}