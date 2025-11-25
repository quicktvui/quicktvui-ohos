import {
  NativeRenderContext,
  HippyAny,
  HippyRenderCallback,
  HippyViewEvent,
  LogUtils
} from 'hippy'

import { QTBaseComponentView } from '../QTBaseComponentView';
import { QTVideoPlayer } from './QTVideoPlayer';


@Observed
export class QTVideoPlayerView extends QTBaseComponentView {
  private readonly TAG = "QTVideoPlayerView"
  public color: string = '#ffffff';
  public videoPlayer: QTVideoPlayer | null = null

  constructor(ctx: NativeRenderContext) {
    super(ctx)
  }

  /**
   * 发送事件
   */
  sendEvent(eventName: string, params: HippyAny) {
    let event = new HippyViewEvent(eventName)
    event.send(this.ctx, this.tag, params)
  }

  /**
   * 设置属性
   */
  setProp(propKey: string, propValue: HippyAny): boolean {
    if (propKey === 'color') {
      this.color = propValue as string;
      return true;
    }
    return super.setProp(propKey, propValue)
  }

  /**
   * 调用方法
   */
  call(method: string, params: Array<HippyAny>, callback: HippyRenderCallback | null): void {
    LogUtils.i(this.TAG, `call method ${method} params: ${params} videoPlayer: ${this.videoPlayer}`);
    if (this.videoPlayer && this.videoPlayer.call(method, params, callback)) {
      return;
    }
    if (method == "getEsInfo") {
      if (callback) {
        const info = new Map<string, HippyAny>()
        info.set("isSupportAsyncInit", false)
        callback(info)
      }
    }
    super.call(method, params, callback)
  }
}


