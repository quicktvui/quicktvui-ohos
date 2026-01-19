import { BuildConfig } from './BuildConfig'
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

      appName: pickString(
        launch?.appName,
        BuildConfig.appName,
        DefaultConfig.appName
      ),

      appIcon: pickString(
        launch?.appIcon,
        BuildConfig.appIcon,
        DefaultConfig.appIcon
      ),

      appEntry: pickString(
        launch?.appEntry,
        BuildConfig.appEntry,
        DefaultConfig.appEntry
      ),

      appVersion: pickString(
        launch?.appVersion,
        BuildConfig.appVersion,
        DefaultConfig.appVersion
      ),

      appBundleUri: pickString(
        launch?.appBundleUri,
        BuildConfig.appBundleUri,
        DefaultConfig.appBundleUri
      ),

      appParams: launch?.appParams ?? BuildConfig.appParams ?? DefaultConfig.appParams,
      appDebug: launch?.appDebug ?? BuildConfig.appDebug ?? DefaultConfig.appDebug,
      appEnableOAID: launch?.appEnableOAID ?? BuildConfig.appEnableOAID ?? DefaultConfig.appEnableOAID,
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