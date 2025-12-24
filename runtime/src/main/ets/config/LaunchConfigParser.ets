import { BundleSourceType } from './Config'
import type { LaunchConfig } from './LaunchConfig'

export class LaunchConfigParser {
  static parse(params?: Record<string, Object>): LaunchConfig | undefined {
    if (!params) {
      return undefined
    }

    const cfg: LaunchConfig = {
      bundleSource: 'REMOTE'
    }

    //---------------------------------------------------
    if (typeof params.appId === 'string') {
      cfg.appId = params.appId
    }
    if (typeof params.appEntry === 'string') {
      cfg.appEntry = params.appEntry
    }
    if (typeof params.appDebug === 'boolean') {
      cfg.appDebug = params.appDebug
    }
    //---------------------------------------------------

    if (typeof params.apiHost === 'string') {
      cfg.apiHost = params.apiHost
    }

    if (typeof params.apiVersion === 'string') {
      cfg.apiVersion = params.apiVersion
    }
    //---------------------------------------------------
    if (params.bundleSource && (params.bundleSource === 'LOCAL' || params.bundleSource === 'REMOTE')) {
      cfg.bundleSource = params.bundleSource as BundleSourceType;
    }
    if (typeof params.bundleUri === 'string') {
      cfg.bundleUri = params.bundleUri
    }
    //---------------------------------------------------

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