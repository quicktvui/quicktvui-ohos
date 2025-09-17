import {
  HippyRenderBaseView,
  HippyObservedArray,
  NativeRenderContext,
  HippyAny,
  HIPPY_COMPONENT_KEY_PREFIX,
  HippyRenderCallback,
  HippyViewEvent,
  LogUtils
} from 'hippy'

import { QTBaseComponentView } from 'quicktvui';
import media from '@ohos.multimedia.media';
import { display } from '@kit.ArkUI';
import { QTPlayerOp } from '../player/QTPlayerOp';
import { QTPlayerEvent } from '../player/QTPlayerEvent';
import { QTPlayerState } from '../player/QTPlayerState';
import { QTPlayerEventProp } from '../player/QTPlayerEventProp';

const PROPORTION = 0.99; // 占屏幕比例
const SURFACE_W = 0.9; // 表面宽比例
const SURFACE_H = 1.78; // 表面高比例


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
        info.set("isSupportAsyncInit", true)
        callback(info)
      }
    }
    super.call(method, params, callback)
  }
}

@Component
export struct QTVideoPlayer {
  private readonly TAG = "QTVideoPlayer"
  @ObjectLink renderView: QTVideoPlayerView
  @ObjectLink children: HippyObservedArray<HippyRenderBaseView>
  //
  private xComponentController: XComponentController = new XComponentController();
  private surfaceId: string = '';
  private videoPlayer: media.AVPlayer | null = null;
  //
  @State percent: number = 0;
  @State windowWidth: number = 300;
  @State windowHeight: number = 200;
  @State surfaceW: number | null = null;
  @State surfaceH: number | null = null;
  @State isInitialized: boolean = false

  public call(method: string, params: Array<HippyAny>,
    callback: HippyRenderCallback | null): boolean {
    LogUtils.i(this.TAG, `call method ${method} params: ${params}`);
    switch (method) {
      case QTPlayerOp.INIT: {
        this.isInitialized = true
        return true;
      }
      case QTPlayerOp.PLAY: {
        //1.
        const url: string = params[0] as string;
        //2.
        const aspectRatio: number = params[1] as number;
        //3.音量
        const leftVolume: string = params[2] as string
        const rightVolume: string = params[3] as string;
        //4.options
        const playerOptions: [] = params[4] as [];
        //5.播放器类型
        const playerType: number = params[5] as number;
        //6.
        const playerMediaCodec: boolean = params[6] as boolean;

        this.play(url)
        break;
      }
      case QTPlayerOp.START: {
        this.start()
        break;
      }
      case QTPlayerOp.SEEK_TO: {
        break;
      }
      case QTPlayerOp.RESUME: {
        break;
      }
      case QTPlayerOp.PAUSE: {
        this.pause()
        break;
      }
      case QTPlayerOp.STOP: {
        this.stop()
        break;
      }
      case QTPlayerOp.RELEASE: {
        this.release()
        break;
      }
      case QTPlayerOp.RESET: {
        this.reset()
        break;
      }
    //------------------------------------------------------------------------
      case QTPlayerOp.GET_CURRENT_POSITION: {
        break;
      }
      case QTPlayerOp.GET_DURATION: {
        break;
      }
    //------------------------------------------------------------------------
      case QTPlayerOp.SET_PLAYER_SIZE: {
        break;
      }
    //------------------------------------------------------------------------
      case QTPlayerOp.SET_SPEED: {
        break;
      }
      case QTPlayerOp.SET_DEFINITION: {
        break;
      }
      case QTPlayerOp.SET_DECODE: {
        break;
      }
      case QTPlayerOp.SET_ASPECT_RATIO: {
        break;
      }
    //------------------------------------------------------------------------
      case QTPlayerOp.GET_LEFT_VOLUME: {
        break;
      }
      case QTPlayerOp.GET_RIGHT_VOLUME: {
        break;
      }
      case QTPlayerOp.SET_LEFT_VOLUME: {
        break;
      }
      case QTPlayerOp.SET_RIGHT_VOLUME: {
        break;
      }
      case QTPlayerOp.SET_VOLUME: {
        break;
      }
    }
    return false
  }

  aboutToAppear() {
    this.renderView.videoPlayer = this
    this.windowWidth = display.getDefaultDisplaySync().width;
    this.windowHeight = display.getDefaultDisplaySync().height;
    this.surfaceW = this.windowWidth * SURFACE_W;
    this.surfaceH = this.surfaceW / SURFACE_H;
  }

  aboutToDisappear() {

  }

  /**
   * 播放
   */
  async play(url: string) {
    if (this.videoPlayer) {
      this.videoPlayer.release();
    }
    this.videoPlayer = await media.createAVPlayer();
    await this.setAVPlayerCallback((avPlayer: media.AVPlayer) => {
      this.percent = avPlayer.width / avPlayer.height;
      this.setVideoWH();
    });
    this.videoPlayer.url = url
  }

  // 注册avplayer回调函数
  async setAVPlayerCallback(callback: (avPlayer: media.AVPlayer) => void,
    type?: number): Promise<void> {
    if (this.videoPlayer == null) {
      return;
    }
    /**
     * 快进
     */
    this.videoPlayer.on('seekDone', (seekDoneTime) => {
      const map = new Map<string, HippyAny>()
      map.set(QTPlayerEventProp.PLAYER_STATE, QTPlayerState.SEEK_COMPLETED)
      this.renderView.sendEvent(QTPlayerEvent.ON_PLAYER_STATUS_CHANGED, map)
    });
    /**
     * 倍速
     */
    this.videoPlayer.on('speedDone', (speed) => {
      const map = new Map<string, HippyAny>()
      map.set(QTPlayerEventProp.PLAYER_STATE, QTPlayerState.SET_PLAY_RATE_SUCCESS)
      this.renderView.sendEvent(QTPlayerEvent.ON_PLAYER_STATUS_CHANGED, map)
    });
    /**
     * 错误
     */
    this.videoPlayer.on('error', (err) => {
      const map = new Map<string, HippyAny>()
      map.set(QTPlayerEventProp.MESSAGE, JSON.stringify(err))
      map.set(QTPlayerEventProp.CODE, -1)
      this.renderView.sendEvent(QTPlayerEvent.ON_PLAYER_ERROR, map)
      if (this.videoPlayer == null) {
        return;
      }
      this.videoPlayer.reset();
    });

    /**
     * 缓冲进度
     */
    this.videoPlayer.on('bufferingUpdate', (type: media.BufferingInfoType, value: number) => {
      const map = new Map<string, HippyAny>()
      map.set(QTPlayerEventProp.BUFFER_PERCENT, value)

      if (type == media.BufferingInfoType.BUFFERING_START) {
        map.set(QTPlayerEventProp.PLAYER_STATE, QTPlayerState.BUFFER_START)
      } else if (type == media.BufferingInfoType.BUFFERING_END) {
        map.set(QTPlayerEventProp.PLAYER_STATE, QTPlayerState.BUFFER_END)
      } else if (type == media.BufferingInfoType.BUFFERING_PERCENT) {
        map.set(QTPlayerEventProp.PLAYER_STATE, QTPlayerState.BUFFERING_PERCENT)
      }
      this.renderView.sendEvent(QTPlayerEvent.ON_PLAYER_STATUS_CHANGED, map)
    })

    /**
     * 播放进度
     */
    this.videoPlayer.on('timeUpdate', (time: number) => {
      // this.currentTime = time;
    });

    /**
     * 播放状态
     */
    this.videoPlayer.on('stateChange', async (state, reason) => {
      LogUtils.e(this.TAG, "=========stateChange=====>>>>" + state)
      if (this.videoPlayer == null) {
        return;
      }
      switch (state) {
        case 'idle': {
          const map = new Map<string, HippyAny>()
          map.set(QTPlayerEventProp.PLAYER_STATE, QTPlayerState.IDLE)
          this.renderView.sendEvent(QTPlayerEvent.ON_PLAYER_STATUS_CHANGED, map)
          break;
        }
        case 'initialized': {
          if (this.surfaceId) {
            this.videoPlayer.surfaceId = this.surfaceId;
            this.videoPlayer.prepare();
          }
          break;
        }
        case 'prepared': {
          const map = new Map<string, HippyAny>()
          map.set(QTPlayerEventProp.PLAYER_STATE, QTPlayerState.ERROR)
          map.set(QTPlayerEventProp.CODE, -1)
          map.set(QTPlayerEventProp.MESSAGE, "AvPlayer has not init on state change")
          this.renderView.sendEvent(QTPlayerEvent.ON_PLAYER_STATUS_CHANGED, map)
          callback(this.videoPlayer);

          this.start()
          break;
        }
        case 'playing': {
          const map = new Map<string, HippyAny>()
          map.set(QTPlayerEventProp.PLAYER_STATE, QTPlayerState.PLAYING)
          this.renderView.sendEvent(QTPlayerEvent.ON_PLAYER_STATUS_CHANGED, map)
          break;
        }

        case 'completed': {
          const map = new Map<string, HippyAny>()
          map.set(QTPlayerEventProp.PLAYER_STATE, QTPlayerState.PLAYBACK_COMPLETED)
          this.renderView.sendEvent(QTPlayerEvent.ON_PLAYER_STATUS_CHANGED, map)
          break;
        }
        case 'released': {
          const map = new Map<string, HippyAny>()
          map.set(QTPlayerEventProp.PLAYER_STATE, QTPlayerState.IDLE)
          this.renderView.sendEvent(QTPlayerEvent.ON_PLAYER_STATUS_CHANGED, map)
          break
        }
        case 'stopped': {
          const map = new Map<string, HippyAny>()
          map.set(QTPlayerEventProp.PLAYER_STATE, QTPlayerState.STOP)
          this.renderView.sendEvent(QTPlayerEvent.ON_PLAYER_STATUS_CHANGED, map)
          break
        }
        case 'error': {
          const map = new Map<string, HippyAny>()
          map.set(QTPlayerEventProp.PLAYER_STATE, QTPlayerState.ERROR)
          this.renderView.sendEvent(QTPlayerEvent.ON_PLAYER_STATUS_CHANGED, map)
          break
        }
        case 'paused': {
          const map = new Map<string, HippyAny>()
          map.set(QTPlayerEventProp.PLAYER_STATE, QTPlayerState.PAUSED)
          this.renderView.sendEvent(QTPlayerEvent.ON_PLAYER_STATUS_CHANGED, map)
          break
        }
        default: {
          break;
        }
      }
    });
  }

  setVideoWH(): void {
    if (this.percent >= 1) { // 横向视频
      this.surfaceW = Math.round(this.windowWidth * PROPORTION);
      this.surfaceH = Math.round(this.surfaceW / this.percent);
    } else { // 纵向视频
      this.surfaceH = Math.round(this.windowHeight * PROPORTION);
      this.surfaceW = Math.round(this.surfaceH * this.percent);
    }
  }

  /**
   * 播放
   */
  start() {
    if (this.videoPlayer) {
      this.videoPlayer.play()
    }
  }

  /**
   * 快进
   * @param progress
   */
  seekTo(progress: number) {
    if (this.videoPlayer) {
      this.videoPlayer.seek(progress)
    }
  }

  /**
   * 暂停
   */
  pause() {
    if (this.videoPlayer) {
      this.videoPlayer.pause()
    }
  }

  /**
   * 停止
   */
  stop() {
    if (this.videoPlayer) {
      this.videoPlayer.stop()
    }
  }

  /**
   * 资源回收
   */
  release() {
    if (this.videoPlayer) {
      this.videoPlayer.release()
    }
  }

  /**
   * 重置
   */
  reset() {
    if (this.videoPlayer) {
      this.videoPlayer.reset()
    }
  }

  /**
   * 倍速
   * @param speed
   */
  setSpeed(speed: number): void {
    if (this.videoPlayer) {
      this.videoPlayer.setSpeed(speed);
    }
  }

  /**
   * 获取总时长
   * @returns
   */
  getDuration(): number {
    if (this.videoPlayer) {
      return this.videoPlayer.duration
    }
    return -1
  }

  /**
   * 获取当前的进度
   * @returns
   */
  getCurrentPosition(): number {
    if (this.videoPlayer) {
      return this.videoPlayer.currentTime
    }
    return -1
  }

  //------------------------------------------------------------------------------
  build() {
    Stack() {
      if (this.isInitialized) {
        this.CoverXComponent()
      }
    }
    .id('VideoView')
    .applyRenderViewBaseAttr(this.renderView)
    .backgroundColor(Color.Red)
  }

  @Builder
  CoverXComponent() {
    XComponent({
      id: 'xComponent',
      type: XComponentType.SURFACE,
      controller: this.xComponentController
    }).id('VideoView')// .visibility(this.XComponentFlag ? Visibility.Visible : Visibility.Hidden)
      .onLoad(() => {
        LogUtils.e(this.TAG, "=====1====CoverXComponent==call===onLoad====>>>>")
        this.surfaceId = this.xComponentController.getXComponentSurfaceId();
        //
        if (this.surfaceId) {
          const map = new Map<string, HippyAny>()
          map.set(QTPlayerEventProp.PLAYER_STATE, QTPlayerState.INITIALIZE_SUCCESS)
          this.renderView.sendEvent(QTPlayerEvent.ON_PLAYER_STATUS_CHANGED, map)
        } else {
          const map = new Map<string, HippyAny>()
          map.set(QTPlayerEventProp.PLAYER_STATE, QTPlayerState.INITIALIZE_ERROR)
          this.renderView.sendEvent(QTPlayerEvent.ON_PLAYER_STATUS_CHANGED, map)
        }
      })
  }
}

//------------------------------------------------------------------------------
@Extend(Stack)
function applyRenderViewBaseAttr($$: HippyRenderBaseView) {
  .key(HIPPY_COMPONENT_KEY_PREFIX + $$.tag)
  .backgroundColor($$.cssBackgroundColor)
  .position({ x: $$.cssPositionX, y: $$.cssPositionY })
  .size({ width: $$.cssWidth, height: $$.cssHeight, })
  .opacity($$.cssOpacity)
  .clip($$.cssOverflow)
  .visibility(($$ as HippyRenderBaseView).cssVisibility)
  .zIndex($$.cssZIndex)
  .accessibilityText($$.cssAccessibilityLabel)
  .focusable($$.cssFocusable)
  .border($$.cssBorder)
  .shadow($$.cssShadow)
  .linearGradient($$.cssLinearGradient)
  .backgroundImage($$.cssBackgroundImage)
  .backgroundImageSize($$.cssBackgroundImageSize)
  .backgroundImagePosition($$.cssBackgroundImagePosition)
  .transform($$.cssMatrix)
  .rotate($$.cssRotate)
  .scale($$.cssScale)
  .translate($$.cssTranslate)
  .hitTestBehavior($$.hitTestBehavior)
  .onClick($$.eventClick)
}
