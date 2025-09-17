import {
  HippyEngineContext,
  HippyAny,
  HippyMap,
  HippyModulePromise,
  HippyNativeModule
} from 'hippy';

import { BaseModule } from './BaseModule';

/**
 * 插件模块
 * 空实现，默认返回安装失败
 */
@HippyNativeModule({ name: "ESPluginModule" })
export class ESPluginModule extends BaseModule {
  public static readonly NAME: string = 'ESPluginModule'

  constructor(ctx: HippyEngineContext) {
    super(ctx)
  }

  initialize(): void {
  }

  public call(method: string, params: Array<HippyAny>, promise: HippyModulePromise): HippyAny {
    switch (method) {
      case 'install': {
        const ret: HippyMap = new Map()
        ret.set('pkg', params[0] as string)
        ret.set('success', false)
        ret.set('status', -1)
        ret.set('msg', 'Plugins are not supported on the Harmony platform.!')
        this.dispatchEvent('onESPluginStateChanged', ret)
        break;
      }
      default:
        super.call(method, params, promise);
    }
    return null;
  }
}
