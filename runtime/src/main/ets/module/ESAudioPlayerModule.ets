import {
  HippyEngineContext,
  HippyAny,
  HippyModulePromise,
  HippyNativeModule,
  LogUtils,
  HippyException
} from 'hippy';

import { BaseModule } from './BaseModule';
import { media } from '@kit.MediaKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { QTPlayerEvent } from '../components/player/QTPlayerEvent';
import { QTPlayerEventProp } from '../components/player/QTPlayerEventProp';
import { QTPlayerState } from '../components/player/QTPlayerState';
import Url from '@ohos.url'
import { audio } from '@kit.AudioKit';
import { common } from '@kit.AbilityKit';
import { fileIo as fs } from '@kit.CoreFileKit';
import QTAppManager from '../quick/QTAppManager';

interface AVCommand {
  name: string;
  args: HippyAny[];
  execute: () => Promise<void>;
  immediate?: boolean;
}

/**
 * 音频播放
 */
@HippyNativeModule({ name: "ESAudioPlayerModule" })
export class ESAudioPlayerModule extends BaseModule {
  public static readonly NAME: string = 'ESAudioPlayerModule'
  private readonly TAG: string = 'ESAudioPlayerModule'
  private mediaPlayerMap = new Map<number, media.AVPlayer>()
  private commandQueueMap = new Map<number, AVCommand[]>();
  private preparedMap = new Map<number, boolean>();

  constructor(ctx: HippyEngineContext) {
    super(ctx)
  }

  initialize(): void {
  }

  destroy(): void {
    this.mediaPlayerMap.clear()
  }

  public call(method: string, params: Array<HippyAny>, promise: HippyModulePromise): HippyAny {
    switch (method) {
      case 'init': {
        const playerId = this.generateId();
        this.createMediaPlayer().then((mediaPlayer) => {
          if (mediaPlayer) {
            //cache
            this.mediaPlayerMap.set(playerId, mediaPlayer);
            this.commandQueueMap.set(playerId, []);
            this.preparedMap.set(playerId, false);

            this.initMediaPlayer(playerId, mediaPlayer)

            LogUtils.d(this.TAG, `Player ${playerId} initialized and stored.`);

            //先返回，然后在发送初始化成功事件
            promise?.resolve(playerId);
            //
            const map = new Map<string, HippyAny>()
            map.set(QTPlayerEventProp.PLAYER_ID, playerId)
            map.set(QTPlayerEventProp.PLAYER_STATE, QTPlayerState.INITIALIZE_SUCCESS)
            this.dispatchEvent(QTPlayerEvent.ON_AUDIO_PLAYER_STATUS_CHANGED, map)
          } else {
            LogUtils.d(this.TAG, `Failed to create player`);

            //先返回，然后在发送初始化失败事件
            promise?.reject?.(-1);

            const map = new Map<string, HippyAny>()
            map.set(QTPlayerEventProp.PLAYER_ID, playerId)
            map.set(QTPlayerEventProp.PLAYER_STATE, QTPlayerState.INITIALIZE_ERROR)
            this.dispatchEvent(QTPlayerEvent.ON_AUDIO_PLAYER_STATUS_CHANGED, map)
          }
        }).catch((err: BusinessError) => {
          LogUtils.d(this.TAG, 'init error.' + JSON.stringify(err));

          const map = new Map<string, HippyAny>()
          map.set(QTPlayerEventProp.PLAYER_ID, playerId)
          map.set(QTPlayerEventProp.PLAYER_STATE, QTPlayerState.INITIALIZE_ERROR)
          this.dispatchEvent(QTPlayerEvent.ON_AUDIO_PLAYER_STATUS_CHANGED, map)

          promise?.reject(-1)
        });
        break;
      }
      case 'play': {
        const playerId = params[0] as number
        const sourcePath = params[1] as string
        LogUtils.d(this.TAG, `call player ${playerId} play method`);
        const player = this.getMediaPlayer(playerId)
        if (player) {
          this.setPlayerSourceAuto(playerId, player, sourcePath)
          promise?.resolve?.(true);
        } else {
          promise?.reject?.(false);
        }
        break;
      }
      case 'resume':
      case 'start': {
        const playerId = params[0] as number
        const currentPlayer = this.getMediaPlayer(playerId)
        if (!currentPlayer) {
          promise?.reject?.(false);
          break;
        }
        this.enqueueOrExecute(playerId, {
          name: 'start',
          args: [],
          immediate: false,
          execute: this.wrapAsyncCommand(
            'start',
            async () => {
              const validStates = ['prepared', 'paused', 'completed'];
              if (validStates.includes(currentPlayer.state)) {
                await currentPlayer.play();
                return true;
              } else {
                throw new Error(`Invalid state: ${currentPlayer.state}`);
              }
            },
            promise,
            this.TAG
          )
        });
        break;
      }
      case 'pause': {
        const playerId = params[0] as number
        const currentPlayer = this.getMediaPlayer(playerId)
        if (!currentPlayer) {
          promise?.reject?.(false);
          break;
        }
        this.enqueueOrExecute(playerId, {
          name: 'pause',
          args: [],
          immediate: false,
          execute: this.wrapAsyncCommand(
            'pause',
            async () => {
              await currentPlayer.pause();
              return true
            },
            promise,
            this.TAG
          )
        });
        break;
      }
      case 'seekTo': {
        const playerId = params[0] as number
        const newPosition = params[1] as number
        const currentPlayer = this.getMediaPlayer(playerId)
        if (!currentPlayer) {
          promise?.reject?.(false);
          break;
        }
        this.enqueueOrExecute(playerId, {
          name: 'seekTo',
          args: [],
          immediate: false,
          execute: this.wrapAsyncCommand(
            'seekTo',
            async () => {
              LogUtils.i(this.TAG, 'seekTo: newPosition: ' + newPosition)
              currentPlayer.seek(newPosition, media.SeekMode.SEEK_PREV_SYNC)
              return true
            },
            promise,
            this.TAG
          )
        });
        break;
      }
      case 'stop': {
        const playerId = params[0] as number
        const player = this.getMediaPlayer(playerId)
        if (player) {
          player.stop().then(() => {
            LogUtils.i(this.TAG, 'media stopped')
            promise?.resolve?.(true);
          }).catch((err: HippyException) => {
            LogUtils.e(this.TAG, `ERROR: ${err}`)
            promise?.reject?.(JSON.stringify(err));
          });
        } else {
          promise?.reject?.(false);
        }
        break;
      }
      case 'setPlayRate': {
        const playerId = params[0] as number
        const speed = params[1] as number
        const player = this.getMediaPlayer(playerId)
        if (player) {
          try {
            player.setSpeed(speed)

            this.dispatchEvent(QTPlayerEvent.ON_AUDIO_PLAYER_RATE_CHANGED, speed)
            //
            promise?.resolve(true);
          } catch (err) {
            LogUtils.e(this.TAG, `ERROR: ${err}`)
            promise?.reject?.(JSON.stringify(err));
          }
        } else {
          promise?.reject?.(false);
        }
        break;
      }
      case 'release': {
        const playerId = params[0] as number
        const player = this.getMediaPlayer(playerId)
        if (player) {
          player.release().then(() => {
            LogUtils.i(this.TAG, 'media release')
            promise?.resolve?.(true);
          }).catch((err: HippyException) => {
            LogUtils.e(this.TAG, `ERROR: ${err}`)
            promise?.reject?.(JSON.stringify(err));
          });
        } else {
          promise?.reject?.(false);
        }
        break;
      }
      case 'isPlaying': {
        promise?.reject?.(false);
        break;
      }
      case 'isPaused': {
        promise?.reject?.(false);
        break;
      }
      case 'getDuration': {
        const playerId = params[0] as number
        const player = this.getMediaPlayer(playerId)
        if (player) {
          promise?.resolve?.(player.duration);
        } else {
          promise?.reject?.(false);
        }
        break;
      }
      case 'getCurrentPosition': {
        const playerId = params[0] as number
        const player = this.getMediaPlayer(playerId)
        if (player) {
          promise?.resolve?.(player.currentTime);
        } else {
          promise?.reject?.(false);
        }
        break;
      }
      case 'getBufferPercentage': {
        promise?.resolve?.(-1);
        break;
      }
      case 'getCurrentPlayRate': {
        promise?.resolve?.(-1);
        break;
      }
      case 'setVolume': {
        const playerId = params[0] as number
        const volume = params[1] as number
        const player = this.getMediaPlayer(playerId)
        if (player) {
          player.setVolume(volume)
          promise?.resolve?.(true);
        } else {
          promise?.reject?.(false);
        }
        break;
      }
      case 'getLeftVolume': {
        promise?.resolve?.(-1);
        break;
      }
      case 'getRightVolume': {
        promise?.resolve?.(-1);
        break;
      }
      default:
        super.call(method, params, promise);
    }
    return null;
  }

  private enqueueOrExecute(id: number, command: AVCommand) {
    const isPrepared = this.preparedMap.get(id);
    if (command.immediate || isPrepared) {
      command.execute().then((ret) => {
      }).catch((err: HippyException) => {
        LogUtils.e(this.TAG, `Command ${command.name} failed: ${err}`);
      });
    } else {
      const queue = this.commandQueueMap.get(id);
      queue?.push(command);
    }
  }

  private flushCommandQueue(id: number) {
    const queue = this.commandQueueMap.get(id);
    while (queue && queue.length > 0) {
      const cmd = queue.shift();
      try {
        cmd?.execute().then((ret) => {
        });
      } catch (e) {
        LogUtils.e(this.TAG, `Command ${cmd?.name} failed in flush: ${e}`);
      }
    }
  }

  private wrapAsyncCommand(
    name: string,
    logic: () => Promise<HippyAny>,
    promise?: HippyModulePromise,
    logTag = 'PlayerManager'
  ): () => Promise<void> {
    return async () => {
      try {
        const result = await logic();
        LogUtils.i(logTag, `[${name}] success`);
        promise?.resolve?.(result);
      } catch (err) {
        LogUtils.e(logTag, `[${name}] error: ${err}`);
        promise?.reject?.(JSON.stringify(err));
      }
    };
  }

  private createMediaPlayer(): Promise<media.AVPlayer | null> {
    return media.createAVPlayer().then((video) => {
      if (video != null) {
        LogUtils.i(this.TAG, 'createAVPlayer success');
        return video
      } else {
        LogUtils.e(this.TAG, 'createAVPlayer fail');
        return null
      }
    })
  }

  private getMediaPlayer(playerId: number): media.AVPlayer | undefined {
    if (this.mediaPlayerMap.has(playerId)) {
      LogUtils.d(this.TAG, `Player ${playerId} already initialized`);
      const player = this.mediaPlayerMap.get(playerId)
      return player
    }
    LogUtils.d(this.TAG, `No AVPlayer instance found for playerId=${playerId}.`);
    return undefined
  }

  private initMediaPlayer(mediaPlayerId: number, mediaPlayer: media.AVPlayer) {
    mediaPlayer.on('stateChange', async (state, reason) => {
      switch (state) {
        case 'idle': {
          LogUtils.d(this.TAG, 'state idle called')
          const map = new Map<string, HippyAny>()
          map.set(QTPlayerEventProp.PLAYER_ID, mediaPlayerId)
          map.set(QTPlayerEventProp.PLAYER_STATE, QTPlayerState.IDLE)
          this.dispatchEvent(QTPlayerEvent.ON_AUDIO_PLAYER_STATUS_CHANGED, map)
          break;
        }
        case 'initialized': {
          LogUtils.d(this.TAG, 'initialized prepared called')
          const map = new Map<string, HippyAny>()
          map.set(QTPlayerEventProp.PLAYER_ID, mediaPlayerId)
          map.set(QTPlayerEventProp.PLAYER_STATE, QTPlayerState.PREPARING)
          this.dispatchEvent(QTPlayerEvent.ON_AUDIO_PLAYER_STATUS_CHANGED, map)
          mediaPlayer.audioRendererInfo = {
            usage: audio.StreamUsage.STREAM_USAGE_MUSIC, // 音频流使用类型：音乐。根据业务场景配置，参考StreamUsage。
            rendererFlags: 0 // 音频渲染器标志。
          };
          mediaPlayer.prepare();
          break;
        }
        case 'prepared': {
          LogUtils.d(this.TAG, 'state prepared called')
          const map = new Map<string, HippyAny>()
          map.set(QTPlayerEventProp.PLAYER_ID, mediaPlayerId)
          map.set(QTPlayerEventProp.PLAYER_STATE, QTPlayerState.PREPARED)
          this.dispatchEvent(QTPlayerEvent.ON_AUDIO_PLAYER_STATUS_CHANGED, map)

          //
          this.preparedMap.set(mediaPlayerId, true);
          this.flushCommandQueue(mediaPlayerId);

          break;
        }
        case 'playing': {
          LogUtils.d(this.TAG, 'state playing called')
          const map = new Map<string, HippyAny>()
          map.set(QTPlayerEventProp.PLAYER_ID, mediaPlayerId)
          map.set(QTPlayerEventProp.PLAYER_STATE, QTPlayerState.PLAYING)
          this.dispatchEvent(QTPlayerEvent.ON_AUDIO_PLAYER_STATUS_CHANGED, map)
          break;
        }
        case 'paused': {
          LogUtils.d(this.TAG, 'state paused called')
          const map = new Map<string, HippyAny>()
          map.set(QTPlayerEventProp.PLAYER_ID, mediaPlayerId)
          map.set(QTPlayerEventProp.PLAYER_STATE, QTPlayerState.PAUSED)
          this.dispatchEvent(QTPlayerEvent.ON_AUDIO_PLAYER_STATUS_CHANGED, map)
          break;
        }
        case 'completed': {
          LogUtils.d(this.TAG, 'state completed called')
          const map = new Map<string, HippyAny>()
          map.set(QTPlayerEventProp.PLAYER_ID, mediaPlayerId)
          map.set(QTPlayerEventProp.PLAYER_STATE, QTPlayerState.PLAYBACK_COMPLETED)
          this.dispatchEvent(QTPlayerEvent.ON_AUDIO_PLAYER_STATUS_CHANGED, map)
          break;
        }
        case 'stopped': {
          LogUtils.d(this.TAG, 'state stopped called')
          const map = new Map<string, HippyAny>()
          map.set(QTPlayerEventProp.PLAYER_ID, mediaPlayerId)
          map.set(QTPlayerEventProp.PLAYER_STATE, QTPlayerState.STOP)
          this.dispatchEvent(QTPlayerEvent.ON_AUDIO_PLAYER_STATUS_CHANGED, map)
          break;
        }
        case 'released': {
          LogUtils.d(this.TAG, 'state released called')
          const map = new Map<string, HippyAny>()
          map.set(QTPlayerEventProp.PLAYER_ID, mediaPlayerId)
          map.set(QTPlayerEventProp.PLAYER_STATE, QTPlayerState.RELEASE)
          this.dispatchEvent(QTPlayerEvent.ON_AUDIO_PLAYER_STATUS_CHANGED, map)
          break;
        }
        case 'error': {
          LogUtils.e(this.TAG, 'state error called: ' + reason)
          const map = new Map<string, HippyAny>()
          map.set(QTPlayerEventProp.PLAYER_ID, mediaPlayerId)
          map.set(QTPlayerEventProp.PLAYER_STATE, QTPlayerState.ERROR)
          this.dispatchEvent(QTPlayerEvent.ON_AUDIO_PLAYER_STATUS_CHANGED, map)
          break;
        }
        default: {
          LogUtils.e(this.TAG, 'unkown state :' + state)
          break;
        }
      }
    })
    mediaPlayer.on('error', (err: BusinessError) => {
      LogUtils.e(this.TAG, `Invoke avPlayer failed, code is ${err.code}, message is ${err.message}`)

      const map = new Map<string, HippyAny>()
      map.set(QTPlayerEventProp.CODE, err.code)
      map.set(QTPlayerEventProp.MESSAGE, err.message)
      this.dispatchEvent(QTPlayerEvent.ON_AUDIO_PLAYER_ERROR, map)

      mediaPlayer.reset(); // 调用reset重置资源，触发idle状态。
    });
  }


  /**
   * 设置播放地址
   * @param playerId
   * @param avPlayer
   * @param sourcePath
   * @returns
   */
  async setPlayerSourceAuto(playerId: number, avPlayer: media.AVPlayer,
    sourcePath: string): Promise<void> {
    const context = getContext(this) as common.UIAbilityContext;

    try {
      // 1.网络播放
      if (sourcePath.startsWith('http://') || sourcePath.startsWith('https://')) {
        avPlayer.url = Url.URL.parseURL(sourcePath).toString();
        LogUtils.d(this.TAG, `Set AVPlayer source to network stream: ${sourcePath}`);
        return;
      }

      // 2.沙箱本地路径播放
      if (sourcePath.startsWith('/')) {
        const path = QTAppManager.getInstance().getESAppFilePath(context) + "/" + sourcePath;
        const file = await fs.open(path);
        const fdPath = 'fd://' + file.fd;
        avPlayer.url = fdPath;
        LogUtils.d(this.TAG, `Set AVPlayer source to sandbox file: ${path}`);
        return;
      }

      // 3.HAP 资源播放（如 '01.mp3'）
      const rawFd = await context.resourceManager.getRawFd(sourcePath);
      const avFileDescriptor: media.AVFileDescriptor = {
        fd: rawFd.fd,
        offset: rawFd.offset,
        length: rawFd.length
      };
      avPlayer.fdSrc = avFileDescriptor;
      LogUtils.d(this.TAG, `Set AVPlayer source to HAP resource: ${sourcePath}`);

    } catch (err) {
      LogUtils.e(this.TAG,
        `Failed to set player source: ${sourcePath}, error: ${JSON.stringify(err)}`);
      //
      const map = new Map<string, HippyAny>()
      map.set(QTPlayerEventProp.PLAYER_ID, playerId)
      map.set(QTPlayerEventProp.PLAYER_STATE, QTPlayerState.INITIALIZE_ERROR)
      this.dispatchEvent(QTPlayerEvent.ON_AUDIO_PLAYER_STATUS_CHANGED, map)
    }
  }
}
