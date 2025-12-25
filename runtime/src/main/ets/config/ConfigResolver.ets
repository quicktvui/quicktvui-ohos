import { BuildConfig } from './BuildConfig'
import { BundleSourceType } from './Config'
import { DefaultConfig } from './DefaultConfig'
import type { LaunchConfig } from './LaunchConfig'
import type { RuntimeConfig } from './RuntimeConfig'

export class ConfigResolver {
  static resolve(launch?: LaunchConfig): RuntimeConfig {
    return {
      appId: pickString(
        launch?.appId,
        BuildConfig.appId,
        DefaultConfig.appId
      ),

      appEntry: pickString(
        launch?.appEntry,
        BuildConfig.appEntry,
        DefaultConfig.appEntry
      ),
      bundleSource: pickString(
        launch?.bundleSource,
        BuildConfig.bundleSource,
        DefaultConfig.bundleSource
      ) as BundleSourceType,

      bundleUri: pickString(
        launch?.bundleUri,
        BuildConfig.bundleUri,
        DefaultConfig.bundleUri
      ),

      params: launch?.params ?? BuildConfig.params ?? DefaultConfig.params,
      appDebug: launch?.appDebug ?? BuildConfig.appDebug ?? DefaultConfig.appDebug,
    }
  }
}


function pickString(...values: Array<string | undefined | null>): string {
  for (const v of values) {
    if (typeof v === 'string' && v.trim() !== '') {
      return v
    }
  }
  return ''
}