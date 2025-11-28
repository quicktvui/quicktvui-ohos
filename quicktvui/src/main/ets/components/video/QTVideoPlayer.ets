import {
  HippyRenderBaseView,
  HippyObservedArray,
  HippyAny,
  HIPPY_COMPONENT_KEY_PREFIX,
  HippyRenderCallback,
  LogUtils
} from 'hippy'
import media from '@ohos.multimedia.media';
import { QTPlayerOp } from '../player/QTPlayerOp';
import { QTPlayerEvent } from '../player/QTPlayerEvent';
import { QTPlayerState } from '../player/QTPlayerState';
import { QTPlayerEventProp } from '../player/QTPlayerEventProp';
import { QTAVPlayerState, QTPlayerAspectRatio, QTPlayerRenderView } from '../player/QTPlayerEnums';
import { QTVideoPlayerView } from './QTVideoPlayerView';
import { getAspectRatioSize, getAvPlayerSpeed, PlayerViewSize } from './QTPlayerUtils';
import { BusinessError } from '@kit.BasicServicesKit';

@Component
export struct QTVideoPlayer {
  private readonly TAG = "QTVideoPlayer"
  @ObjectLink renderView: QTVideoPlayerView
  @ObjectLink children: HippyObservedArray<HippyRenderBaseView>
  //
  private xComponentController: XComponentController = new XComponentController();
  private surfaceId: string = '';
  private videoPlayer: media.AVPlayer | null = null;
  private currentAspectRatio: QTPlayerAspectRatio = QTPlayerAspectRatio.AR_ASPECT_FIT_PARENT;
  private currentState: QTAVPlayerState = QTAVPlayerState.RELEASED;
  private loop: boolean = false;
  private render: QTPlayerRenderView = QTPlayerRenderView.NONE;
  private availableBitrates: Array<number> = [];
  private currentVolume: number = 1.0;
  private url: string = '';
  //
  @State surfaceW: number = 1;
  @State surfaceH: number = 1;
  @State viewWidth: number = 0;
  @State viewHeight: number = 0;
  @State videoWidth: number = 0;
  @State videoHeight: number = 0;

  @State isInitialized: boolean = false

  public call(method: string, params: Array<HippyAny>,
    callback: HippyRenderCallback | null): boolean {
    // LogUtils.i(this.TAG, `call method ${method} params: ${params}`);
    switch (method) {
      case QTPlayerOp.INIT: {
        // this.isInitialized = true
        return true;
      }
      case QTPlayerOp.PLAY: {
        //1.
        const url: string = params[0] as string;
        //2.
        this.currentAspectRatio = params[1] as number;
        //3.音量
        const leftVolume: string = params[2] as string
        const rightVolume: string = params[3] as string;
        //4.options
        const playerOptions: [] = params[4] as [];
        //5.播放器类型
        const playerType: number = params[5] as number;
        //6.
        const playerMediaCodec: boolean = params[6] as boolean;
        //
        const extraMap: Map<string, HippyAny> = params[7] as Map<string, HippyAny>;
        this.loop = extraMap.get('loop') as boolean;
        this.render = extraMap.get('render') as number;

        this.url = url;
        this.isInitialized = true

        break;
      }
      case QTPlayerOp.START: {
        this.start()
        break;
      }
      case QTPlayerOp.SEEK_TO: {
        const position: number = params[0] as number;
        this.seekTo(position)
        break;
      }
      case QTPlayerOp.RESUME: {
        // 目前没有调用
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
        if (callback) {
          callback(this.getCurrentPosition());
        }
        break;
      }
      case QTPlayerOp.GET_DURATION: {
        if (callback) {
          callback(this.getDuration());
        }
        break;
      }
    //------------------------------------------------------------------------
      case QTPlayerOp.SET_PLAYER_SIZE: { // 设置宽高
        const viewWidth = params[0] as number;
        const viewHeight = params[1] as number;
        this.setPlayerSize(viewWidth, viewHeight);
        break;
      }
    //------------------------------------------------------------------------
      case QTPlayerOp.SET_SPEED: {
        const speed = params[0] as string;
        this.setSpeed(speed);
        break;
      }
      case QTPlayerOp.SET_DEFINITION: {
        break;
      }
      case QTPlayerOp.SET_DECODE: {
        break;
      }
      case QTPlayerOp.SET_ASPECT_RATIO: {
        const ratio = params[0] as number;
        this.setAspectRatio(ratio);
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
        const volume = params[0] as number;
        this.setVolume(volume);
        break;
      }
      case QTPlayerOp.SET_RIGHT_VOLUME: {
        const volume = params[0] as number;
        this.setVolume(volume);
        break;
      }
      case QTPlayerOp.SET_VOLUME: {
        const volume = params[0] as number;
        this.setVolume(volume);
        break;
      }
      // 自适应码率
      case QTPlayerOp.GET_M3U8_DEFINITION_INFO: {
        if (this.availableBitrates instanceof Array
          && this.availableBitrates.length > 0) {
          const infos: Array<Map<string, HippyAny>> = [];
          for (let i = 0; i < this.availableBitrates.length; i++) {
            const map: Map<string, HippyAny> = new Map();
            map.set('id', i);
            const innerMap: Map<string, HippyAny> = new Map();
            innerMap.set('trackType', 1);
            innerMap.set('videoWidth', i);
            innerMap.set('videoHeight', this.availableBitrates[i]);
            map.set('streams', [innerMap])
            infos.push(map);
          }
          if (callback) {
            callback(infos);
          }
        }
        break;
      }
      case QTPlayerOp.SET_M3U8_DEFINITION: {
        const index = params[0] as number;
        if (index >= 0 && this.availableBitrates instanceof Array
          && this.availableBitrates.length > index) {
          LogUtils.d(this.TAG, "setBitrate " + this.availableBitrates[index]);
          this.videoPlayer?.setBitrate(this.availableBitrates[index]);
        }
        break;
      }
      // 轨道信息
      case QTPlayerOp.GET_TRACK_INFO:
        this.getTrackInfo();
        break;
      case QTPlayerOp.SELECT_TRACK:
        break;
      case QTPlayerOp.DE_SELECT_TRACK:
        break;
    }
    return false
  }

  aboutToAppear() {
    this.renderView.videoPlayer = this
    // this.isInitialized = true
    const map = new Map<string, HippyAny>()
    map.set(QTPlayerEventProp.PLAYER_STATE, QTPlayerState.INITIALIZE_SUCCESS)
    this.renderView.sendEvent(QTPlayerEvent.ON_PLAYER_STATUS_CHANGED, map)
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
      const map = new Map<string, HippyAny>()
      map.set(QTPlayerEventProp.PLAYER_STATE, QTPlayerState.PREPARED)
      this.renderView.sendEvent(QTPlayerEvent.ON_PLAYER_STATUS_CHANGED, map)
      // 设置循环
      avPlayer.loop = this.loop;
      this.start()

    });
    this.videoPlayer.url = url
  }

  // 注册avplayer回调函数
  async setAVPlayerCallback(callback: (avPlayer: media.AVPlayer) => void): Promise<void> {
    if (this.videoPlayer == null) {
      return;
    }
    /**
     * 首帧播放回调
     */
    this.videoPlayer.on('startRenderFrame', () => {
      LogUtils.d(this.TAG, "=========startRenderFrame=====>>>>首帧播放")
    });

    this.videoPlayer.on('videoSizeChange', (width: number, height: number) => {
      LogUtils.d(this.TAG, "=========videoSizeChange=====>>>>" + width + ' ' + height)
      this.videoWidth = width;
      this.videoHeight = height;
      this.setAspectRatio(this.currentAspectRatio);
    });
    /**
     * 快进
     */
    this.videoPlayer.on('seekDone', (seekDoneTime) => {
      LogUtils.d(this.TAG, "=========seekDone=====>>>>" + seekDoneTime)
      const map = new Map<string, HippyAny>()
      map.set(QTPlayerEventProp.PLAYER_STATE, QTPlayerState.SEEK_COMPLETED)
      this.renderView.sendEvent(QTPlayerEvent.ON_PLAYER_STATUS_CHANGED, map)
    });
    /**
     * 倍速
     */
    this.videoPlayer.on('speedDone', (speed) => {
      LogUtils.d(this.TAG, "=========speedDone=====>>>>" + speed)
      const map = new Map<string, HippyAny>()
      map.set(QTPlayerEventProp.PLAYER_STATE, QTPlayerState.SET_PLAY_RATE_SUCCESS)
      this.renderView.sendEvent(QTPlayerEvent.ON_PLAYER_STATUS_CHANGED, map)
    });
    /**
     * 错误
     */
    this.videoPlayer.on('error', (err) => {
      LogUtils.e(this.TAG, "=========error=====>>>>" + err)
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
      let params: HippyAny
      let eventName: string
      switch (type) {
        case media.BufferingInfoType.BUFFERING_START:
          LogUtils.i(this.TAG, "=========bufferingStart=====>>>>" + value)
          eventName = QTPlayerEvent.ON_PLAYER_STATUS_CHANGED
          params = new Map<string, HippyAny>()
          params.set(QTPlayerEventProp.PLAYER_STATE, QTPlayerState.BUFFER_START)
          break;
        case media.BufferingInfoType.BUFFERING_END:
          LogUtils.i(this.TAG, "=========bufferingEnd=====>>>>" + value)
          eventName = QTPlayerEvent.ON_PLAYER_STATUS_CHANGED;
          params = new Map<string, HippyAny>()
          params.set(QTPlayerEventProp.PLAYER_STATE, QTPlayerState.BUFFER_END)
          break;
        case media.BufferingInfoType.BUFFERING_PERCENT:
          LogUtils.i(this.TAG, "=========bufferingPercent=====>>>>" + value)
          eventName = QTPlayerEvent.ON_BUFFERING_PERCENT;
          params = value
          break;
        case media.BufferingInfoType.CACHED_DURATION:
          LogUtils.d(this.TAG, "=========cachedDuration=====>>>>" + value)
          eventName = QTPlayerEvent.ON_CACHED_POSITIONS;
          params = new Array(1)
          params[0] = ('0:' + value)
          break;
      }

      this.renderView.sendEvent(eventName, params)
    })

    /**
     * 播放进度
     */
    this.videoPlayer.on('timeUpdate', (time: number) => {
      // LogUtils.d(this.TAG, "=========timeUpdate=====>>>>" + time)
      // this.currentTime = time;
    });

    this.videoPlayer.on('durationUpdate', (time: number) => {
      LogUtils.d(this.TAG, "=========durationUpdate=====>>>>" + time)
    });

    this.videoPlayer.on('volumeChange', (volume: number) => {
      LogUtils.d(this.TAG, "=========volumeChange=====>>>>" + volume)
    });

    this.videoPlayer.on('trackInfoUpdate', (infos :Array<media.MediaDescription>) => {
      LogUtils.d(this.TAG, "=========trackInfoUpdate=====>>>>" + JSON.stringify(infos))
    });

    this.videoPlayer.on('trackChange', (index: number, isSelected: boolean) => {
      LogUtils.d(this.TAG, "=========trackChange=====>>>>" + index + " | " + isSelected)
    });

    /**
     * 播放状态
     */
    this.videoPlayer.on('stateChange', async (state, reason) => {
      LogUtils.d(this.TAG, "=========stateChange=====>>>>" + state + " " + reason)
      if (this.videoPlayer == null) {
        return;
      }
      switch (state) {
        case 'idle': {
          this.currentState = QTAVPlayerState.IDLE;
          const map = new Map<string, HippyAny>()
          map.set(QTPlayerEventProp.PLAYER_STATE, QTPlayerState.IDLE)
          this.renderView.sendEvent(QTPlayerEvent.ON_PLAYER_STATUS_CHANGED, map)
          break;
        }
        case 'initialized': {
          this.currentState = QTAVPlayerState.INITIALIZED;
          if (this.surfaceId) {
            this.videoPlayer.surfaceId = this.surfaceId;
            this.videoPlayer.prepare();
          }
          break;
        }
        case 'prepared': {
          this.currentState = QTAVPlayerState.PREPARED;
          if (callback) {
            callback(this.videoPlayer);
          }
          break;
        }
        case 'playing': {
          this.currentState = QTAVPlayerState.PLAYING;
          const map = new Map<string, HippyAny>()
          map.set(QTPlayerEventProp.PLAYER_STATE, QTPlayerState.PLAYING)
          this.renderView.sendEvent(QTPlayerEvent.ON_PLAYER_STATUS_CHANGED, map)
          break;
        }

        case 'completed': {
          this.currentState = QTAVPlayerState.COMPLETED;
          const map = new Map<string, HippyAny>()
          map.set(QTPlayerEventProp.PLAYER_STATE, QTPlayerState.PLAYBACK_COMPLETED)
          this.renderView.sendEvent(QTPlayerEvent.ON_PLAYER_STATUS_CHANGED, map)
          break;
        }
        case 'released': {
          this.currentState = QTAVPlayerState.RELEASED;
          const map = new Map<string, HippyAny>()
          map.set(QTPlayerEventProp.PLAYER_STATE, QTPlayerState.IDLE)
          this.renderView.sendEvent(QTPlayerEvent.ON_PLAYER_STATUS_CHANGED, map)
          break
        }
        case 'stopped': {
          this.currentState = QTAVPlayerState.STOPPED;
          const map = new Map<string, HippyAny>()
          map.set(QTPlayerEventProp.PLAYER_STATE, QTPlayerState.STOP)
          this.renderView.sendEvent(QTPlayerEvent.ON_PLAYER_STATUS_CHANGED, map)
          break
        }
        case 'error': {
          this.currentState = QTAVPlayerState.ERROR;
          const map = new Map<string, HippyAny>()
          map.set(QTPlayerEventProp.PLAYER_STATE, QTPlayerState.ERROR)
          this.renderView.sendEvent(QTPlayerEvent.ON_PLAYER_STATUS_CHANGED, map)
          break
        }
        case 'paused': {
          this.currentState = QTAVPlayerState.PAUSED;
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

    this.videoPlayer.on('bitrateDone', (bitrate: number) => {
      LogUtils.d(this.TAG, "=========bitrateDone=====>>>>" + bitrate)
    });

    this.videoPlayer.on('availableBitrates', (bitrates: Array<number>) => {
      LogUtils.d(this.TAG, "=========availableBitrates=====>>>>" + bitrates.toString())
      this.availableBitrates = bitrates;
    })
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

      const map = new Map<string, HippyAny>()
      map.set(QTPlayerEventProp.PLAYER_STATE, QTPlayerState.SEEK_START)
      this.renderView.sendEvent(QTPlayerEvent.ON_PLAYER_STATUS_CHANGED, map)
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
  setSpeed(speed: string): void {
    if (this.videoPlayer) {
      this.videoPlayer.setSpeed(getAvPlayerSpeed(speed));
    }
  }

  setAspectRatio(ratio: number): void {
    this.currentAspectRatio = ratio;
    const surfaceSize: PlayerViewSize =
      getAspectRatioSize(ratio,
        {width: this.videoWidth, height: this.videoHeight},
        {width: this.viewWidth, height: this.viewHeight});
    this.surfaceW = surfaceSize.width;
    this.surfaceH = surfaceSize.height;
  }

  setPlayerSize(width: number, height: number) {
    this.viewWidth = width;
    this.viewHeight = height;
    if (this.currentState >= QTAVPlayerState.PREPARED &&
      this.currentState < QTAVPlayerState.STOPPED) {
      const surfaceSize: PlayerViewSize =
        getAspectRatioSize(this.currentAspectRatio,
          {width: this.videoWidth, height: this.videoHeight},
          {width: this.viewWidth, height: this.viewHeight});
      this.surfaceW = surfaceSize.width;
      this.surfaceH = surfaceSize.height;
    }
  }

  getPlaybackInfo() {
    if (!this.videoPlayer) return;
    this.videoPlayer.getPlaybackInfo().then((res: media.PlaybackInfo)=>{
      console.log("testGet", "getPlaybackInfo: ", JSON.stringify(res));
    })
  }

  getTrackInfo() {
    if (!this.videoPlayer) return;
    this.videoPlayer.getTrackDescription()
      .then((arr: Array<media.MediaDescription>)=>{
        console.log("testGet", "getTrackDescription: ", JSON.stringify(arr));
        if (this.availableBitrates && this.availableBitrates.length > 0) {

        }
      })
      .catch((err: BusinessError)=>{
        console.error("testGet", "getTrackDescription", JSON.stringify(err))
      })
  }

  getSelectedTracks() {
    if (!this.videoPlayer) return;
    this.videoPlayer.getSelectedTracks()
      .then((arr: Array<number>)=>{
        console.log("testGet", "getSelectedTracks: ", JSON.stringify(arr));
      })
      .catch((err: BusinessError)=>{
        console.error("testGet", "getSelectedTracks", JSON.stringify(err))
      })
  }

  setVolume(volume: number): void {
    LogUtils.d(this.TAG, 'setVolume ' + volume + ', current ' + this.currentVolume);
    if (volume == this.currentVolume)
      return;

    if (this.videoPlayer) {
      this.currentVolume = volume;
      this.videoPlayer.setVolume(volume);
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
    .backgroundColor(Color.Pink)
    .height(`${this.viewHeight}px`)
    .width(`${this.viewWidth}px`)
    .clip(true)
  }

  @Builder
  CoverXComponent() {
    XComponent({
      id: 'xComponent',
      type: this.render == QTPlayerRenderView.TEXTURE ? XComponentType.TEXTURE : XComponentType.SURFACE,
      controller: this.xComponentController
    }).id('VideoView')// .visibility(this.XComponentFlag ? Visibility.Visible : Visibility.Hidden)
      .onLoad(() => {
        LogUtils.e(this.TAG, "=====1====CoverXComponent==call===onLoad====>>>>")
        this.surfaceId = this.xComponentController.getXComponentSurfaceId();
        //
        if (this.surfaceId) {
          // const map = new Map<string, HippyAny>()
          // map.set(QTPlayerEventProp.PLAYER_STATE, QTPlayerState.INITIALIZE_SUCCESS)
          // this.renderView.sendEvent(QTPlayerEvent.ON_PLAYER_STATUS_CHANGED, map)
          this.play(this.url)
        } else {
          const map = new Map<string, HippyAny>()
          map.set(QTPlayerEventProp.PLAYER_STATE, QTPlayerState.INITIALIZE_ERROR)
          this.renderView.sendEvent(QTPlayerEvent.ON_PLAYER_STATUS_CHANGED, map)
        }
      })
      .height(`${this.surfaceH}px`)
      .width(`${this.surfaceW}px`)
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
