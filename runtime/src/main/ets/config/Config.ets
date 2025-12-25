export interface Config {
  // app
  appId?: string
  // appName?: string
  // appIcon?: string
  appEntry?: string
  appDebug?: boolean
  //
  bundleSource: BundleSourceType  | undefined//枚举：LOCAL | REMOTE
  bundleUri?: string
  //
  params?: object
}

export type BundleSourceType = 'LOCAL' | 'REMOTE';