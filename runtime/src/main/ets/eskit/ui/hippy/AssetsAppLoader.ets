import { EsData } from "../../EsData";
import { AppLoader, AppLoaderFactory } from "./AppLoader";

export class AssetsAppLoader implements AppLoader {
  private data: EsData;
  private baseDir: string

  constructor(data: EsData) {
    this.data = data
    this.baseDir = data.uri!.replace(AppLoaderFactory.FROM_ASSETS, '')
  }

  async startLoad(): Promise<void> {

  }

  getAppName(): string {
    return this.data.appName!
  }

  getAppIcon(): string {
    return this.data.icon!
  }

  getVendorJsFile(): string {
    return `${this.baseDir}/vendor.js`
  }

  getIndexJsFile(): string {
    return `${this.baseDir}/index.js`
  }
}