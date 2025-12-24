import type { LaunchConfig } from './LaunchConfig'

export class LaunchConfigParser {
  static parse(params?: Record<string, Object>): LaunchConfig | undefined {
    if (!params) {
      return undefined
    }

    const cfg: LaunchConfig = {
      packageName: '',
      parameters: ''
    }

    if (typeof params.entryPage === 'string') {
      cfg.entryPage = params.entryPage
    }

    if (typeof params.enableLog === 'boolean') {
      cfg.enableLog = params.enableLog
    }

    if (typeof params.packageName === 'string') {
      cfg.packageName = params.packageName
    }

    if (typeof params.parameters === 'string') {
      try {
        cfg.parameters = JSON.parse(params.parameters)
      } catch {
        cfg.parameters = params.parameters
      }
    }

    return cfg
  }
}