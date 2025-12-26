import { EsData } from '../../EsData';
import { ApiAppLoader } from './ApiAppLoader';
import { AssetsAppLoader } from './AssetsAppLoader';

export interface AppLoader {

  startLoad(): Promise<void>

  getAppName(): string

  getAppIcon(): string

  getVendorJsFile(): string

  getIndexJsFile(): string

}

export class AppLoaderFactory {
  public static FROM_ASSETS = "assets://"

  public static create(data: EsData): AppLoader {
    if (data.bundleUri?.length !== undefined) {
      if (data.bundleUri.startsWith(AppLoaderFactory.FROM_ASSETS)) {
        return new AssetsAppLoader(data)
      }
    }
    return new ApiAppLoader(data)
  }
}


