import { AppContext } from "./AppContext"

export class AppManager {
  // region 单例

  private static _instance: AppManager

  static get instance(): AppManager {
    if (!this._instance) {
      this._instance = new AppManager()
    }
    return this._instance
  }

  private constructor() {
  }

  // endregion

  private apps: Set<AppContext> = new Set()

  addAppContext(value: AppContext) {
    this.apps.add(value)
  }

  removeAppContext(value: AppContext) {
    this.apps.delete(value)
  }

  findAppContextWithPackageName(value: string): AppContext | null {
    for (let ctx of this.apps) {
      if (ctx.data.packageName == value) {
        return ctx
      }
    }
    return null
  }
}