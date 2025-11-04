export class EsData {
  /* 包名 */
  packageName: string | undefined
  /* 版本 */
  versionName: string | undefined
  /* 启动参数 */
  args: Map<string, object> | undefined
  /* 自定义下载地址 */
  url: string | undefined

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
    data.url = params.url as string
    return data;
  }
}