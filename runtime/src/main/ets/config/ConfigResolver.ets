import { BuildConfig } from './BuildConfig'
import { DefaultConfig } from './DefaultConfig'
import type { LaunchConfig } from './LaunchConfig'
import type { RuntimeConfig } from './RuntimeConfig'

export class ConfigResolver {
  static resolve(launch?: LaunchConfig): RuntimeConfig {
    return {
      entryPage: launch?.entryPage ?? BuildConfig.entryPage ?? DefaultConfig.entryPage,
      enableLog: launch?.enableLog ?? BuildConfig.enableLog ?? DefaultConfig.enableLog,
      packageName: launch?.packageName ?? BuildConfig.packageName ?? DefaultConfig.packageName,
      parameters: launch?.parameters ?? BuildConfig.parameters ?? DefaultConfig.parameters,
    }
  }
}