import { EsData } from "../../EsData";
import { AppLoader, AppLoaderFactory } from "./AppLoader";
import fs from '@ohos.file.fs';

export class AssetsAppLoader implements AppLoader {
  private data: EsData;
  private baseDir: string

  constructor(data: EsData) {
    this.data = data
    let dir = data.appBundleUri!.replace(AppLoaderFactory.FROM_ASSETS, '')
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
    const filePath = `${this.baseDir}/vendor.js`;

    try {
      fs.accessSync(filePath);
      console.debug(`[FileCheck] ✅ vendor.js exists: ${filePath}`);
    } catch (e) {
      console.error(`[FileCheck] ❌ vendor.js NOT FOUND: ${filePath}`);
    }
    return filePath;
  }

  getIndexJsFile(): string {
    const filePath = `${this.baseDir}/index.js`;

    try {
      fs.accessSync(filePath);
      console.debug(`[FileCheck] ✅ index.js exists: ${filePath}`);
    } catch (e) {
      console.error(`[FileCheck] ❌ index.js NOT FOUND: ${filePath}`);
    }
    return filePath;
  }
}