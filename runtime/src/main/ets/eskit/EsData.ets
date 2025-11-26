export class EsData {
  /* 应用名称 */
  appName?: string
  /* icon */
  icon?: string
  /* 包名 */
  packageName?: string
  /* 版本 */
  versionName?: string
  /* 启动参数 */
  args?: Map<string, object>
  /* 自定义加载地址 */
  uri?: string

  static tryParse(parameters?: Record<string, Object>): EsData | null {
    if (parameters?.uri) {
      return EsData.parseWithUri(parameters.uri as string)
    }

    if (parameters?.pkg) {
      return EsData.parseWithParams(parameters);
    }

    return null
  }

  private static parseWithUri(uri: string): EsData | null {
    return null
  }

  private static parseWithParams(params: Record<string, Object>): EsData {
    let data = new EsData()
    data.packageName = params.pkg as string
    data.uri = params.uri as string
    return data;
  }
}