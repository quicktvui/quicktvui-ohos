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
    if (typeof params.appVersion === 'string') {
      cfg.appVersion = params.appVersion
    }
    //debug
    if (typeof params.debug === 'boolean') {
      cfg.appDebug = params.debug
    }
    //appEnableOAID
    if (typeof params.appEnableOAID === 'boolean') {
      cfg.appEnableOAID = params.appEnableOAID
    }
    //uri
    if (typeof params.uri === 'string') {
      cfg.appBundleUri = params.uri
    }
    //params
    if (typeof params.params === 'string') {
      try {
        cfg.appParams = JSON.parse(params.params)
      } catch {
        cfg.appParams = params.parameters
      }
    }
    return cfg
  }
}