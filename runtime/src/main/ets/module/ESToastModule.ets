import {
  HippyEngineContext,
  HippyAny,
  HippyModulePromise,
  HippyNativeModule,
  LogUtils
} from 'hippy';

import { BaseModule } from './BaseModule';

@HippyNativeModule({ name: "ESToastModule" })
export class ESToastModule extends BaseModule {
  public static readonly NAME: string = 'ESToastModule'
  private readonly TAG: string = 'ESToastModule'

  constructor(ctx: HippyEngineContext) {
    super(ctx)
  }

  initialize(): void {
  }

  public call(method: string, params: Array<HippyAny>, promise: HippyModulePromise): HippyAny {
    switch (method) {
      case 'showToast':
      case 'showShortToast':
      case 'showLongToast':
        LogUtils.d(this.TAG,
          `showToast message:${params[0] as string} duration:${params[1] as number}`);
        if (this.getContext() != null && this.getContext().getUIContext() != null) {
          this.getContext().getUIContext()!.getPromptAction().showToast({
            message: params[0] as string ?? '',
            duration: params[1] as number,
          })
        }
        break;
      default:
        super.call(method, params, promise);
    }
    return null;
  }
}
