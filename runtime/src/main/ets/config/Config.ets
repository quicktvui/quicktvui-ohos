export interface Config {
  // app
  appId?: string
  // appName?: string
  // appIcon?: string
  appEntry?: string
  appDebug?: boolean
  // api
  apiHost?: string
  apiVersion?: string
  //
  bundleSource: BundleSourceType //枚举：LOCAL | REMOTE
  bundleUri?: string
  //
  params?: object
}

export type BundleSourceType = 'LOCAL' | 'REMOTE';