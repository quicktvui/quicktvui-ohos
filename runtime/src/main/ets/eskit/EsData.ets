export class EsData {
  /* 应用名称 */
  appName?: string
  /* icon */
  appIcon?: string
  /* 包名 */
  appId?: string
  /* 版本 */
  appVersion?: string
  /* 启动参数 */
  appParams?: object
  /* 否开启调试 */
  appDebug?: boolean
  /* 自定义加载地址 */
  appBundleUri?: string

  public static buildESData(
    appId?: string,
    appVersion?: string,
    appName?: string,
    appIcon?: string,
    appDebug?: boolean,
    appBundleUri?: string,
    appParams?: object,
  ): EsData {
    const data: EsData = {
      appId,
      appVersion,
      appName,
      appIcon,
      appDebug,
      appBundleUri,
      appParams,
    }
    return data;
  }
}