import { HippyEngineContext, HippyAny, HippyModulePromise, HippyNativeModule } from 'hippy';

import { BaseModule } from './BaseModule';
import { hilog } from '@kit.PerformanceAnalysisKit';

@HippyNativeModule({ name: "ESLogModule" })
export class ESLogModule extends BaseModule {
  public static readonly NAME: string = 'ESLogModule'

  constructor(ctx: HippyEngineContext) {
    super(ctx)
  }

  public call(method: string, params: Array<HippyAny>, promise: HippyModulePromise): HippyAny {
    switch (method) {
      case 'v': {
        hilog.info(params[0] as number, params[1] as string, params[2] as string)
        break;
      }
      case 'd': {
        hilog.debug(params[0] as number, params[1] as string, params[2] as string)
        break;
      }
      case 'i': {
        hilog.info(params[0] as number, params[1] as string, params[2] as string)
        break;
      }
      case 'w': {
        hilog.warn(params[0] as number, params[1] as string, params[2] as string)
        break;
      }
      case 'e': {
        hilog.error(params[0] as number, params[1] as string, params[2] as string)
        break;
      }
      case 'f': {
        hilog.fatal(params[0] as number, params[1] as string, params[2] as string)
        break;
      }
      default:
        super.call(method, params, promise);
    }
    return null;
  }
}
