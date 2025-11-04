import { AbilityConstant } from "@kit.AbilityKit"

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

  context?: Context
  launchParams?: Record<string, Object>
  nav?: NavPathStack
}