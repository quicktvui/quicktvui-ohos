import { BuildConfig } from './BuildConfig'
import { DefaultConfig } from './DefaultConfig'
import type { LaunchConfig } from './LaunchConfig'
import type { RuntimeConfig } from './RuntimeConfig'

export class ConfigResolver {
  static resolve(launch?: LaunchConfig): RuntimeConfig {
    return {
      //
      appId: launch?.appId ?? BuildConfig.appId ?? DefaultConfig.appId,
      appEntry: launch?.appEntry ?? BuildConfig.appEntry ?? DefaultConfig.appEntry,
      appDebug: launch?.appDebug ?? BuildConfig.appDebug ?? DefaultConfig.appDebug,
      //
      bundleSource: launch?.bundleSource ?? BuildConfig.bundleSource ?? DefaultConfig.bundleSource,
      bundleUri: launch?.bundleUri ?? BuildConfig.bundleUri ?? DefaultConfig.bundleUri,
      params: launch?.params ?? BuildConfig.params ?? DefaultConfig.params,
    }
  }
}
