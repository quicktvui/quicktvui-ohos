import {
  HippyEngineContext,
  HippyAny,
  LogUtils,
  HippyModulePromise,
  HippyNativeModule
} from 'hippy';

import { BaseModule } from './BaseModule';

import { BusinessError, commonEventManager } from '@kit.BasicServicesKit';

interface Broadcast {
  id?: number
  action: string
  extras: Record<string, string | number | boolean>
}

@HippyNativeModule({ name: "ESBroadcastModule" })
export class ESBroadcastModule extends BaseModule {
  public static readonly NAME: string = 'ESBroadcastModule'
  private getNextId: () => number = this.createCounter(100)
  private subscriberList = new Map<number, commonEventManager.CommonEventSubscriber>()

  constructor(ctx: HippyEngineContext) {
    super(ctx)
  }

  initialize(): void {
  }

  public call(method: string, params: Array<HippyAny>, promise: HippyModulePromise): HippyAny {
    switch (method) {
      //注册广播接收者
      case 'registerReceiver': {
        const map = params[0] as Map<string, string>
        const actionList = map.get("action")
        let actions: Array<string> = [];
        if (Array.isArray(actionList)) {
          actions = actionList as Array<string>;
        } else if (typeof actionList === 'string') {
          actions = [actionList];
        } else {
          LogUtils.e('ESBroadcastModule', 'registerReceiver: ' + actions);
        }
        const receiverId = this.registerReceiver(actions)
        promise.resolve(receiverId);
        break;
      }
    //取消注册广播接收者
      case 'unregisterReceiver': {
        const receiverId = this.unregisterReceiver(params[0] as number)
        promise.resolve(receiverId);
        break;
      }
    //发送广播
      case 'sendBroadcast': {
        this.sendBroadcast(params[0] as Array<Array<string>>)
        break;
      }
      default:
        super.call(method, params, promise);
    }
    return null;
  }

  /**
   * 发送广播
   * @param params
   */
  sendBroadcast(params: Array<Array<string>>) {
    const broadcast: Broadcast = this.parseBroadcastParams(params)
    // 公共事件相关信息
    let options: commonEventManager.CommonEventPublishData = {
      code: 1, // 公共事件的初始代码
      data: JSON.stringify(broadcast.extras), // 公共事件的初始数据
    };
    // 发布公共事件，其中的event字段需要替换为实际的事件名称。
    commonEventManager.publish(broadcast.action, options, (err: BusinessError) => {
      if (err) {
        LogUtils.e('ESBroadcastModule',
          `Failed to publish common event. Code is ${err.code}, message is ${err.message}`);
      } else {
        LogUtils.i('ESBroadcastModule', `Succeeded in publishing common event.`);
      }
    });
  }

  parseBroadcastParams(paramsArray: Array<Array<string>>): Broadcast {
    let action = ''
    const extras: Record<string, string | number | boolean> = {}

    for (const item of paramsArray) {
      if (item.length === 0) {
        continue
      }
      const prefix = item[0]
      if (prefix === '-a' && item.length >= 2) {
        action = item[1]
      } else if (prefix.startsWith('--') && item.length >= 3) {
        const typeFlag = prefix.substring(2) // es, ei, ez
        const key = item[1]
        const rawValue = item[2]
        let value: string | number | boolean = rawValue
        switch (typeFlag) {
          case 'ei':
            value = parseInt(rawValue, 10)
            break
          case 'ez':
            value = rawValue === 'true'
            break
          case 'es':
          default:
            value = rawValue
        }
        extras[key] = value
      }
    }
    return {
      action,
      extras
    }
  }

  /**
   * 注册广播接收者
   * @param actions
   */
  registerReceiver(actions: Array<string>): number {
    let subscriber: commonEventManager.CommonEventSubscriber | null = null;
    // 订阅者信息，其中的event字段需要替换为实际的事件名称。
    let subscribeInfo: commonEventManager.CommonEventSubscribeInfo = {
      events: actions, // 订阅灭屏公共事件
    };

    const id = this.getNextId()
    // 创建订阅者回调
    commonEventManager.createSubscriber(subscribeInfo,
      (err: BusinessError, data: commonEventManager.CommonEventSubscriber) => {
        if (err) {
          LogUtils.e('ESBroadcastModule',
            `Failed to create subscriber. Code is ${err.code}, message is ${err.message}`);
          return;
        }
        LogUtils.i('ESBroadcastModule', 'Succeeded in creating subscriber.');
        subscriber = data;
        // 订阅公共事件回调
        if (subscriber) {
          //cache
          this.subscriberList.set(id, subscriber)
          commonEventManager.subscribe(subscriber,
            (err: BusinessError, data: commonEventManager.CommonEventData) => {
              if (err) {
                LogUtils.e('ESBroadcastModule',
                  `Failed to subscribe common event. Code is ${err.code}, message is ${err.message}`);
                return;
              }
              //
              LogUtils.e('ESBroadcastModule',
                `Succeeded subscribe common event：${data.event}  data：${data.data}`);
              //
              const event = new Map<string, HippyAny>()
              event.set("id", id)
              event.set("action", data.event)
              if (data.data) {
                event.set("extras", JSON.parse(data.data))
              }
              this.dispatchEvent('onESBroadcastReceive', event)
            })
        } else {
          LogUtils.e('ESBroadcastModule', `Need create subscriber`);
        }
      })
    return id;
  }

  /**
   *  subscriber为订阅事件时创建的订阅者对象
   */
  unregisterReceiver(id: number): number {
    const subscriber = this.subscriberList.get(id)
    if (subscriber) {
      commonEventManager.unsubscribe(subscriber, (err: BusinessError) => {
        if (err) {
          LogUtils.e('ESBroadcastModule',
            `Failed to unsubscribe. code is ${err.code}, message is ${err.message}`);
        } else {
          LogUtils.i('ESBroadcastModule', `Succeeded in unsubscribing.`);
        }
      })
      this.subscriberList.delete(id)
    }
    return id
  }

  //-----------------------------------------------------------
  createCounter(start: number = 0): () => number {
    let count = start
    return () => ++count
  }
}
