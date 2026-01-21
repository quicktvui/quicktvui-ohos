import {
  bundleManager,
  common,
  abilityAccessCtrl
} from '@kit.AbilityKit';
import { connection } from '@kit.NetworkKit';
import { BusinessError, deviceInfo, pasteboard } from '@kit.BasicServicesKit'; // [新增] pasteboard
import { display, promptAction } from '@kit.ArkUI'; // [新增] promptAction
import { statfs } from '@kit.CoreFileKit';
import { identifier } from '@kit.AdsKit';
import { LogUtils } from 'hippy';
import { App } from '../App';

// ---------------------------------------------------------
// 1. InfoRow 组件 (修改：添加点击复制功能)
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

      // 修改：给 Value 文本添加点击事件
      Text(this.value)
        .fontSize(18)
        .fontColor(Color.White)
        .layoutWeight(1)
        .textAlign(TextAlign.End)
        .fontWeight(FontWeight.Regular)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
        .maxLines(1)
        .onClick(() => {
          this.copyToClipboard(this.value)
        })
    }
    .width('100%')
    .padding({ top: 12, bottom: 12 })
    .border({ width: { bottom: 1 }, color: '#4A5261' })
  }

  // [新增] 复制逻辑
  private copyToClipboard(text: string) {
    if (!text || text.includes('...')) {
      return;
    }
    try {
      // 1. 创建剪贴板数据
      let pasteData = pasteboard.createData(pasteboard.MIMETYPE_TEXT_PLAIN, text);
      // 2. 获取系统剪贴板对象
      let systemPasteboard = pasteboard.getSystemPasteboard();
      // 3. 写入数据
      systemPasteboard.setData(pasteData).then(() => {
        // 4. 成功提示
        promptAction.showToast({
          message: `已复制: ${text}`,
          duration: 1500,
          bottom: 100 // 提示框位置稍微靠上一点
        });
      }).catch((err: BusinessError) => {
        LogUtils.e('InfoRow', 'Copy failed: ' + JSON.stringify(err));
      });
    } catch (e) {
      LogUtils.e('InfoRow', 'Copy error: ' + JSON.stringify(e));
    }
  }
}

// ---------------------------------------------------------
// 2. 主页面逻辑 (保持不变，仅展示完整结构)
// ---------------------------------------------------------
@Builder
export function PageDeviceBuilder(name: string, param: Object) {
  DevicePage()
}

@Component
export struct DevicePage {
  private TAG: string = 'DevicePage'
  private navPathStack: NavPathStack = new NavPathStack();

  @State deviceName: string = '...'
  @State deviceModel: string = '...'
  @State osFullName: string = '...'
  @State sdkApiVersion: string = '...'
  @State deviceType: string = '...'

  @State oaid: string = '点击获取'

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
    this.initOAID()
  }

  // --- OAID 获取 ---
  private async initOAID() {
    try {
      const atManager = abilityAccessCtrl.createAtManager();
      const context = getContext(this) as common.UIAbilityContext;

      atManager.requestPermissionsFromUser(context, ['ohos.permission.APP_TRACKING_CONSENT'])
        .then((data) => {
          if (data.authResults && data.authResults.length > 0 && data.authResults[0] === 0) {
            this.getOAIDRaw();
          } else {
            this.oaid = '用户未授权 (点击空白处重试)';
          }
        })
        .catch((err: BusinessError) => {
          this.oaid = '权限请求出错';
        })
    } catch (e) {
      this.oaid = '不支持或出错';
    }
  }

  private getOAIDRaw() {
    try {
      identifier.getOAID().then((data) => {
        this.oaid = data;
      }).catch((err: BusinessError) => {
        this.oaid = `获取失败: ${err.code}`;
      });
    } catch (err) {
      this.oaid = "API调用异常";
    }
  }

  // --- 基础信息 ---
  private initBasicDeviceInfo() {
    try {
      this.deviceName = deviceInfo.marketName || 'Unknown';
      this.deviceModel = deviceInfo.productModel || 'Unknown';
      this.osFullName = deviceInfo.osFullName || 'HarmonyOS';
      this.sdkApiVersion = deviceInfo.sdkApiVersion.toString();
      this.deviceType = deviceInfo.deviceType || 'default';
    } catch (e) { }
  }

  // --- 屏幕 ---
  private initScreenInfo() {
    try {
      let displayClass = display.getDefaultDisplaySync();
      this.screenResolution = `${displayClass.width} x ${displayClass.height}`;
      this.screenDensity = `${displayClass.densityDPI}`;
    } catch (e) { }
  }

  // --- 应用 ---
  private initAppInfo() {
    let bundleFlags = bundleManager.BundleFlag.GET_BUNDLE_INFO_WITH_APPLICATION;
    bundleManager.getBundleInfoForSelf(bundleFlags).then((data) => {
      this.appName = data.name;
      this.appVersion = `${data.versionName} (${data.versionCode})`;
    }).catch((err: BusinessError) => {
      this.appName = "查询失败";
    });
  }

  // --- 存储 ---
  private async initStorageInfo() {
    try {
      let context = getContext(this) as common.UIAbilityContext;
      let path = context.cacheDir;
      let freeSize = await statfs.getFreeSize(path);
      let totalSize = await statfs.getTotalSize(path);
      this.storageFree = this.formatBytes(freeSize);
      this.storageTotal = this.formatBytes(totalSize);
    } catch (e) { }
  }

  // --- 网络 ---
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
      this.netType = "已连接";
    } catch (e) { }
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
            Text("硬件信息").fontSize(14).fontColor('#007DFF').width('100%').margin({ top: 10, bottom: 5 })
            InfoRow({ title: "设备名称", value: this.deviceName })
            InfoRow({ title: "设备型号", value: this.deviceModel })

            // OAID 这里有一个特殊的逻辑：
            // 1. 点击具体的 OAID 字符串 -> 触发 InfoRow 内部的复制
            // 2. 点击该行的空白处 -> 触发外层的 onClick (重试获取)
            Row() {
              InfoRow({ title: "OAID", value: this.oaid })
            }.onClick(() => {
              // 如果 OAID 是异常状态，允许点击整行重试
              if(this.oaid.includes('点击') || this.oaid.includes('未授权')) {
                this.initOAID()
              }
            })

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

        Button("返回")
          .width('80%')
          .height(50)
          .backgroundColor('#FF4040')
          .margin({ bottom: 20 })
          .onClick(() => {
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