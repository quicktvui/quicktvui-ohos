import common from '@ohos.app.ability.common';
import { RuntimeConfig } from './config/RuntimeConfig';
import { window } from '@kit.ArkUI';

export class App {
  private static _instance: App

  static get instance(): App {
    if (!this._instance) {
      this._instance = new App()
    }
    return this._instance
  }

  private constructor() {
  }

  windowStage?: window.WindowStage
  context?: common.UIAbilityContext
  nav?: NavPathStack
  runtimeConfig?: RuntimeConfig
}