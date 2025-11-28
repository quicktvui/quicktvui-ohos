import common from '@ohos.app.ability.common';

export class App {
  // region 单例

  private static _instance: App

  static get instance(): App {
    if (!this._instance) {
      this._instance = new App()
    }
    return this._instance
  }

  private constructor() {
  }

  // endregion

  context?: common.UIAbilityContext
  launchParams?: Record<string, Object>
  nav?: NavPathStack
}