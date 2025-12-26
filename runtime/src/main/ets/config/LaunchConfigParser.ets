import type { LaunchConfig } from './LaunchConfig'

export class LaunchConfigParser {
  static parse(params?: Record<string, Object>): LaunchConfig | undefined {
    if (!params) {
      return undefined
    }
    const cfg: LaunchConfig = {}
    //pkg
    if (typeof params.pkg === 'string') {
      cfg.appId = params.pkg
    }
    //entry
    if (typeof params.entry === 'string') {
      cfg.appEntry = params.entry
    }
    //name
    if (typeof params.name === 'string') {
      cfg.appName = params.name
    }
    //icon
    if (typeof params.icon === 'string') {
      cfg.appIcon = params.icon
    }
    //verion
    if (typeof params.verion === 'string') {
      cfg.appVersion = params.verion
    }
    //debug
    if (typeof params.debug === 'boolean') {
      cfg.appDebug = params.debug
    }
    //uri
    if (typeof params.uri === 'string') {
      cfg.bundleUri = params.uri
    }
    //params
    if (typeof params.params === 'string') {
      try {
        cfg.params = JSON.parse(params.params)
      } catch {
        cfg.params = params.parameters
      }
    }
    return cfg
  }
}