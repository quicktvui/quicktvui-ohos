import {
  HippyEngineContext,
  HippyAny,
  HippyModulePromise,
  HippyNativeModule,
  LogUtils,
  HippyRecord
} from 'hippy';

import { BaseModule } from './BaseModule';
import { emitter } from '@kit.BasicServicesKit';

/**
 *
 */
@HippyNativeModule({ name: "ESEmitterModule" })
export class ESEmitterModule extends BaseModule {
  public static readonly NAME: string = 'ESEmitterModule'
  public readonly TAG: string = 'ESEmitterModule'
  // 追踪已注册的事件 ID（用于防止重复注册、销毁时清理）
  private registeredEventIds: Set<number> = new Set()

  constructor(ctx: HippyEngineContext) {
    super(ctx)
  }

  initialize(): void {
  }

  destroy(): void {
    // 自动清理未手动 off 的事件
    this.registeredEventIds.forEach((eventId) => {
      LogUtils.i(this.TAG, `destroy → auto off eventId: ${eventId}`);
      emitter.off(eventId);
    });
    this.registeredEventIds.clear();
  }

  public call(method: string, params: Array<HippyAny>, promise: HippyModulePromise): HippyAny {
    switch (method) {
      case 'emit': {
        try {
          const eventId = params[0] as number
          const priority = params[1] as number
          const data = JSON.parse(params[2] as string) as HippyRecord
          let event: emitter.InnerEvent = {
            eventId: eventId,
            priority: priority as emitter.EventPriority
          };
          let eventData: emitter.EventData = {
            data: data
          };
          LogUtils.i(this.TAG,
            `emit → eventId: ${eventId}, priority: ${priority}, data: ${JSON.stringify(data)}`);
          emitter.emit(event, eventData);
          promise?.resolve(true)
        } catch (e) {
          promise?.reject(e)
        }
        break;
      }
      case 'off': {
        try {
          const eventId = params[0] as number
          LogUtils.i(this.TAG, `off → eventId: ${eventId}`);
          emitter.off(eventId);
          this.registeredEventIds.delete(eventId);
          promise?.resolve(true)
        } catch (e) {
          promise?.reject(e)
        }
        break;
      }
      case 'once': {
        try {
          const eventId = params[0] as number
          let event: emitter.InnerEvent = {
            eventId: eventId
          };
          let callback: Callback<emitter.EventData> = (eventData: emitter.EventData) => {
            LogUtils.i(this.TAG,
              `once callback → eventId: ${eventId}, data: ${JSON.stringify(eventData.data ??
                null)}`);
            this.dispatchEvent(eventId + '', eventData.data ? eventData.data as HippyRecord : null);
          }
          LogUtils.i(this.TAG, `once → eventId: ${eventId}`);
          emitter.once(event, callback);
          this.registeredEventIds.add(eventId);
          promise?.resolve(true)
        } catch (e) {
          promise?.reject(e)
        }
        break;
      }
      case 'on': {
        try {
          const eventId = params[0] as number
          if (this.registeredEventIds.has(eventId)) {
            LogUtils.w(this.TAG, `on ignored → eventId: ${eventId} already registered.`);
            break;
          }
          let event: emitter.InnerEvent = {
            eventId: eventId
          };
          let callback: Callback<emitter.EventData> = (eventData: emitter.EventData) => {
            LogUtils.i(this.TAG,
              `on callback → eventId: ${eventId}, data: ${JSON.stringify(eventData.data ?? null)}`);
            this.dispatchEvent(eventId + '', eventData.data ? eventData.data as HippyRecord : null);
          }
          LogUtils.i(this.TAG, `on → eventId: ${eventId}`);
          emitter.on(event, callback);
          this.registeredEventIds.add(eventId);
          promise?.resolve(true)
        } catch (e) {
          promise?.reject(e)
        }
        break;
      }
      default: {
        LogUtils.w(this.TAG, `Unknown method called: ${method}`);
        super.call(method, params, promise);
      }
    }
    return null;
  }
}
