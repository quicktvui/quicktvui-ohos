import {
  HippyEngineContext,
  HippyAny,
  HippyModulePromise,
  HippyNativeModule,
  LogUtils
} from 'hippy';

import { BaseModule } from './BaseModule';
import media from '@ohos.multimedia.media';
import audio from '@ohos.multimedia.audio';
import { BusinessError } from '@kit.BasicServicesKit';
import { fileIo as fs } from '@kit.CoreFileKit';

import { QTPlayerEvent, QTPlayerEventProp, QTPlayerState } from 'quicktvui';

/**
 * SoundPool
 */
@HippyNativeModule({ name: "ESSoundPoolPlayerModule" })
export class ESSoundPoolPlayerModule extends BaseModule {
  public static readonly NAME: string = 'ESSoundPoolPlayerModule'
  private readonly TAG: string = 'ESSoundPoolPlayerModule'
  private soundPool: media.SoundPool | null = null;

  constructor(ctx: HippyEngineContext) {
    super(ctx)
  }

  initialize(): void {
  }

  destroy(): void {
  }

  public call(method: string, params: Array<HippyAny>, promise: HippyModulePromise): HippyAny {
    switch (method) {
      case 'init': {
        const usage = params[0] as number
        const contentType = params[1] as number
        const maxStreams = params[2] as number
        const streamType = params[3] as number
        const enableCache = params[4] as boolean

        let audioRendererInfo: audio.AudioRendererInfo = {
          usage: usage as audio.StreamUsage, // 音频流使用类型：音乐。根据业务场景配置，参考StreamUsage。
          rendererFlags: 1 // 音频渲染器标志。
        };
        media.createSoundPool(maxStreams, audioRendererInfo).then((soundPool: media.SoundPool) => {
          if (soundPool != null) {
            this.soundPool = soundPool;

            soundPool.on('loadComplete', (soundId: number) => {
              //
              const event = new Map<string, HippyAny>()
              event.set("sampleId", soundId)
              event.set("status", 0)
              this.dispatchEvent('onESSoundPoolLoadComplete', event)
            })
            soundPool.on('playFinished', () => {
              const event = new Map<string, HippyAny>()
              event.set(QTPlayerEventProp.PLAYER_STATE, QTPlayerState.PLAYBACK_COMPLETED)
              this.dispatchEvent(QTPlayerEvent.ON_PLAYER_STATUS_CHANGED, event)
            })
            soundPool.on('error', (error: BusinessError) => {
              // errorEvent
              const errorEvent = new Map<string, HippyAny>()
              errorEvent.set(QTPlayerEventProp.ERROR_CODE, error.code)
              errorEvent.set(QTPlayerEventProp.ERROR_MESSAGE, error.message)
              this.dispatchEvent(QTPlayerEvent.ON_PLAYER_ERROR, errorEvent)

              // statusEvent
              this.notifyError(error)
            })
            //
            if (promise) {
              promise.resolve(true)
            }
            LogUtils.i(this.TAG, 'create SoundPool success');
          } else {
            LogUtils.e(this.TAG, 'create SoundPool fail');
          }
        }).catch((error: BusinessError) => {
          LogUtils.e(this.TAG, `SoundPool catchCallback, error message:${error.message}`);
          if (promise) {
            promise.reject(JSON.stringify(error))
          }
        });
        break;
      }
      case 'load': {
        let url = params[0] as string
        this.load(url).then((soundId: number) => {
          LogUtils.i(this.TAG, 'SoundPool load soundId:' + soundId);
          if (promise) {
            promise.resolve(soundId)
          }
        }).catch((error: BusinessError) => {
          LogUtils.e(this.TAG, `SoundPool load error message:${JSON.stringify(error)}`);
          if (promise) {
            promise.reject(JSON.stringify(error))
          }
          const event = new Map<string, HippyAny>()
          event.set("url", url)
          this.dispatchEvent('onESSoundPoolLoadError', event)
        });
        break;
      }
      case 'unload': {
        const soundId = params[0] as number
        this.soundPool?.unload(soundId).then(() => {
          LogUtils.i(this.TAG, 'SoundPool unload success soundId:' + soundId);
        }).catch((error: BusinessError) => {
          LogUtils.e(this.TAG, `SoundPool unload error message:${error.message}`);
          this.notifyError(error)
        });
        break;
      }
      case 'play': {
        const soundId = params[0] as number
        const leftVolume = params[1] as number
        const rightVolume = params[2] as number
        const priority = params[3] as number
        const loop = params[4] as number
        const rate = params[5] as number

        let playParameters: media.PlayParameters = {
          loop: loop, // 循环0次。
          rate: rate, // 2倍速。
          leftVolume: leftVolume, // range = 0.0-1.0
          rightVolume: rightVolume, // range = 0.0-1.0
          priority: priority, // 最低优先级。
        };
        this.soundPool?.play(soundId, playParameters, (error: BusinessError, streamId: number) => {
          if (error) {
            if (promise) {
              promise.reject(JSON.stringify(error))
            }
            LogUtils.e(this.TAG,
              `play sound Error: errCode is ${error.code}, errMessage is ${error.message}`);
          } else {
            if (promise) {
              promise.resolve(streamId)
            }
            LogUtils.i(this.TAG, 'play success sound id:' + streamId);
          }
        })
        break;
      }
      case 'pause': {
        LogUtils.e(this.TAG,
          "UnsupportedOperationException: 'pause' is not supported on HarmonyOS.");
        break;
      }
      case 'autoPause': {
        LogUtils.e(this.TAG,
          "UnsupportedOperationException: 'autoPause' is not supported on HarmonyOS.");
        break;
      }
      case 'resume': {
        LogUtils.e(this.TAG,
          "UnsupportedOperationException: 'resume' is not supported on HarmonyOS.");
        break;
      }
      case 'autoResume': {
        LogUtils.e(this.TAG,
          "UnsupportedOperationException: 'autoResume' is not supported on HarmonyOS.");
        break;
      }
      case 'stop': {
        const streamId = params[0] as number
        this.soundPool?.stop(streamId).then(() => {
          LogUtils.i(this.TAG, 'SoundPool stop success streamId:' + streamId);
        }).catch((error: BusinessError) => {
          LogUtils.e(this.TAG,
            `SoundPool stop error streamId: ${streamId} message:${error.message}`);
          this.notifyError(error)
        });
        break;
      }
      case 'setVolume': {
        const streamId = params[0] as number
        const leftVolume = params[1] as number
        const rightVolume = params[2] as number
        this.soundPool?.setVolume(streamId, leftVolume, rightVolume).then(() => {
          LogUtils.i(this.TAG, 'SoundPool setVolume success streamId:' + streamId);
        }).catch((error: BusinessError) => {
          LogUtils.e(this.TAG,
            `SoundPool setVolume error streamId: ${streamId} message:${error.message}`);
          this.notifyError(error)
        });
        break;
      }
      case 'setRate': {
        const streamId = params[0] as number
        const rate = params[1] as number
        this.soundPool?.setRate(streamId, rate).then(() => {
          LogUtils.i(this.TAG, 'SoundPool setRate success streamId:' + streamId);
        }).catch((error: BusinessError) => {
          LogUtils.e(this.TAG,
            `SoundPool setRate error streamId: ${streamId} message:${error.message}`);
          this.notifyError(error)
        });
        break;
      }
      case 'setPriority': {
        const streamId = params[0] as number
        const priority = params[1] as number
        this.soundPool?.setPriority(streamId, priority).then(() => {
          LogUtils.i(this.TAG, 'SoundPool setPriority success streamId:' + streamId);
        }).catch((error: BusinessError) => {
          LogUtils.e(this.TAG,
            `SoundPool setPriority error streamId: ${streamId} message:${error.message}`);
          this.notifyError(error)
        });
        break;
      }
      case 'setLoop': {
        const streamId = params[0] as number
        const loop = params[1] as number
        this.soundPool?.setLoop(streamId, loop).then(() => {
          LogUtils.i(this.TAG, 'SoundPool setLoop success streamId:' + streamId);
        }).catch((error: BusinessError) => {
          LogUtils.e(this.TAG,
            `SoundPool setLoop error streamId: ${streamId} message:${error.message}`);
          this.notifyError(error)
        });
        break;
      }
      case 'release': {
        this.soundPool?.release().then(() => {
          LogUtils.i(this.TAG, 'SoundPool release success');
        }).catch((error: BusinessError) => {
          LogUtils.e(this.TAG,
            `SoundPool release error message:${error.message}`);
          this.notifyError(error)
        });
        break;
      }
      default:
        super.call(method, params, promise);
    }
    return null;
  }

  private async load(url: string) {
    LogUtils.i(this.TAG, 'SoundPool load file url: ' + url);
    const file: fs.File = await fs.openSync(url, fs.OpenMode.READ_ONLY)
    LogUtils.i(this.TAG, 'SoundPool load url file: ' + file.fd);
    url = 'fd://' + (file.fd).toString()
    const soundId: number = await this.soundPool?.load(url) ?? -1
    return soundId
  }

  private notifyError(error: BusinessError) {
    // statusEvent
    const statusEvent = new Map<string, HippyAny>()
    statusEvent.set(QTPlayerEventProp.PLAYER_STATE, QTPlayerState.ERROR)
    statusEvent.set(QTPlayerEventProp.ERROR_CODE, error.code)
    statusEvent.set(QTPlayerEventProp.ERROR_MESSAGE, error.message)
    this.dispatchEvent(QTPlayerEvent.ON_PLAYER_STATUS_CHANGED, statusEvent)
  }
}
