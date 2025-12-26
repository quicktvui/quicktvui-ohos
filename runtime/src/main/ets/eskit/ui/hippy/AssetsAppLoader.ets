import { EsData } from "../../EsData";
import { AppLoader, AppLoaderFactory } from "./AppLoader";

export class AssetsAppLoader implements AppLoader {
  private data: EsData;
  private baseDir: string

  constructor(data: EsData) {
    this.data = data
    let dir = data.bundleUri!.replace(AppLoaderFactory.FROM_ASSETS, '')
    this.baseDir = dir.startsWith('/') ? dir.slice(1) : dir;
  }

  async startLoad(): Promise<void> {

  }

  getAppName(): string {
    return this.data.appName!
  }

  getAppIcon(): string {
    return this.data.appIcon!
  }

  getVendorJsFile(): string {
    return `${this.baseDir}/vendor.js`
  }

  getIndexJsFile(): string {
    return `${this.baseDir}/index.js`
  }
}