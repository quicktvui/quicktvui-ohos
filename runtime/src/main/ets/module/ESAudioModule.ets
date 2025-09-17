import {
  HippyEngineContext,
  HippyAny,
  HippyModulePromise,
  HippyNativeModule,
  LogUtils
} from 'hippy';

import { BaseModule } from './BaseModule';
import { audio } from '@kit.AudioKit';
import { BusinessError } from '@kit.BasicServicesKit';

@HippyNativeModule({ name: "ESAudioModule" })
export class ESAudioModule extends BaseModule {
  public static readonly NAME: string = 'ESAudioModule'
  public readonly TAG: string = 'ESAudioModule'
  //
  private audioManager: audio.AudioManager | null = null
  private audioStreamManager: audio.AudioStreamManager | null = null
  private audioVolumeManager: audio.AudioVolumeManager | null = null
  private callback: Callback<audio.VolumeEvent> | null = null

  constructor(ctx: HippyEngineContext) {
    super(ctx)
  }

  initialize(): void {
    this.audioManager = audio.getAudioManager()
    this.audioStreamManager = this.audioManager.getStreamManager();
    this.audioVolumeManager = this.audioManager.getVolumeManager();
  }

  public call(method: string, params: Array<HippyAny>, promise: HippyModulePromise): HippyAny {
    switch (method) {
      case 'onVolumeChange': {
        if (!this.audioVolumeManager) {
          promise?.reject(-1)
          return
        }
        try {
          this.callback = (volumeEvent: audio.VolumeEvent) => {
            try {
              const map = new Map<string, HippyAny>()
              map.set('volumeType', volumeEvent.volumeType)
              map.set('volume', volumeEvent.volume)
              map.set('updateUi', volumeEvent.updateUi)
              // map.set('volumeGroupId', volumeEvent.volumeGroupId)
              this.dispatchEvent('volumeChange', map)
            } catch (e) {
            }
          }
          this.audioVolumeManager.on('volumeChange', this.callback);
          promise?.resolve(true)
        } catch (e) {
          promise?.reject(false)
        }
        break;
      }
      case 'offVolumeChange': {
        if (!this.audioVolumeManager) {
          promise?.reject(-1)
          return
        }
        try {
          if (this.callback) {
            this.audioVolumeManager.off('volumeChange', this.callback);
            this.callback = null
          }
          promise?.resolve(true)
        } catch (e) {
          promise?.reject(false)
        }
        break;
      }
    //--------------------------------------------------------------------------------
      case 'getStreamVoiceCallMaxVolume': {
        this.getMaxVolume(audio.AudioVolumeType.VOICE_CALL, promise)
        break;
      }
      case 'getStreamVoiceCallMinVolume': {
        this.getMinVolume(audio.AudioVolumeType.VOICE_CALL, promise)
        break;
      }
      case 'getStreamVoiceCallVolume': {
        this.getVolume(audio.AudioVolumeType.VOICE_CALL, promise)
      }
    //--------------------------------------------------------------------------------
      case 'getStreamSystemMaxVolume': {
        this.getMaxVolume(audio.AudioVolumeType.MEDIA, promise)
        break;
      }
      case 'getStreamSystemMinVolume': {
        this.getMinVolume(audio.AudioVolumeType.MEDIA, promise)
        break;
      }
      case 'getStreamSystemVolume': {
        this.getVolume(audio.AudioVolumeType.MEDIA, promise)
        break;
      }
    //--------------------------------------------------------------------------------
      case 'getStreamRingMaxVolume': {
        this.getMaxVolume(audio.AudioVolumeType.RINGTONE, promise)
        break;
      }
      case 'getStreamRingMinVolume': {
        this.getMinVolume(audio.AudioVolumeType.RINGTONE, promise)
        break;
      }
      case 'getStreamRingVolume': {
        this.getVolume(audio.AudioVolumeType.RINGTONE, promise)
        break;
      }
    //--------------------------------------------------------------------------------
      case 'getStreamMusicMaxVolume': {
        this.getMaxVolume(audio.AudioVolumeType.MEDIA, promise)
        break;
      }
      case 'getStreamMusicMinVolume': {
        this.getMinVolume(audio.AudioVolumeType.MEDIA, promise)
        break;
      }
      case 'getStreamMusicVolume': {
        this.getVolume(audio.AudioVolumeType.MEDIA, promise)
        break;
      }
    //--------------------------------------------------------------------------------
      case 'getStreamAlarmMaxVolume': {
        this.getMaxVolume(audio.AudioVolumeType.ALARM, promise)
        break;
      }
      case 'getStreamAlarmMinVolume': {
        this.getMinVolume(audio.AudioVolumeType.ALARM, promise)
        break;
      }
      case 'getStreamAlarmVolume': {
        this.getVolume(audio.AudioVolumeType.ALARM, promise)
        break;
      }
    //--------------------------------------------------------------------------------
      case 'getStreamMaxVolume': {
        const streamType = params[0] as number
        this.getMaxVolume(streamType, promise)
        break;
      }
      case 'getStreamMinVolume': {
        const streamType = params[0] as number
        this.getMinVolume(streamType, promise)
        break;
      }
      case 'getStreamVolume': {
        const streamType = params[0] as number
        this.getVolume(streamType, promise)
        break;
      }
      case 'setStreamVolume': {
        const streamType = params[0] as number
        const volume = params[1] as number
        LogUtils.d(this.TAG, 'setStreamVolume: streamType: ' + streamType + " volume: " + volume);
        this.setVolume(streamType, volume, promise)
        break;
      }
    //--------------------------------------------------------------------------------

    //--------------------------------------------------------------------------------
      case 'mute': {
        if (!this.audioVolumeManager) {
          promise?.reject(-1)
          return
        }
        const streamType = params[0] as number
        const value = params[1] as boolean
        try {
          const audioVolumeGroupManager =
            this.audioVolumeManager.getVolumeGroupManagerSync(audio.DEFAULT_VOLUME_GROUP_ID)
          // audioVolumeGroupManager.mute(streamType, value)
          //   .then(() => {
          //     LogUtils.d(this.TAG, 'mute: streamType: ' + streamType + " value: " + value);
          //     promise?.resolve(true)
          //   }).catch((err: BusinessError) => {
          //   LogUtils.d(this.TAG, 'mute error! ' + JSON.stringify(err));
          //   if (promise) {
          //     promise.reject(JSON.stringify(err))
          //   }
          // });
        } catch (e) {
          promise?.reject(e)
        }
        break;
      }
      case 'isMute': {
        if (!this.audioVolumeManager) {
          promise?.reject(-1)
          return
        }
        const streamType = params[0] as number
        try {
          const audioVolumeGroupManager =
            this.audioVolumeManager.getVolumeGroupManagerSync(audio.DEFAULT_VOLUME_GROUP_ID)
          const isMute = audioVolumeGroupManager.isMuteSync(streamType)
          promise?.resolve(isMute)
        } catch (e) {
          promise?.reject(e)
        }
        break;
      }
      //
      default:
        super.call(method, params, promise);
    }
    return null;
  }

  //
  private setVolume(type: audio.AudioVolumeType, volume: number, promise: HippyModulePromise) {
    if (!this.audioVolumeManager) {
      promise?.reject(-1)
      return
    }
    try {
      const audioVolumeGroupManager =
        this.audioVolumeManager.getVolumeGroupManagerSync(audio.DEFAULT_VOLUME_GROUP_ID)
      // audioVolumeGroupManager.setVolume(type as audio.AudioVolumeType, volume, () => {
      //   LogUtils.d(this.TAG, 'setVolume success: ' + volume);
      //   promise?.resolve(volume)
      // })
    } catch (e) {
      promise?.reject(e)
    }
  }

  private getMaxVolume(type: audio.AudioVolumeType, promise: HippyModulePromise) {
    if (!this.audioVolumeManager) {
      promise?.reject(-1)
      return
    }
    try {
      const audioVolumeGroupManager =
        this.audioVolumeManager.getVolumeGroupManagerSync(audio.DEFAULT_VOLUME_GROUP_ID)
      const volume = audioVolumeGroupManager.getMaxVolumeSync(type)
      LogUtils.d(this.TAG, 'getMaxVolume: ' + volume);
      promise?.resolve(volume)
    } catch (e) {
      promise?.reject(e)
    }
  }

  private getMinVolume(type: audio.AudioVolumeType, promise: HippyModulePromise) {
    if (!this.audioVolumeManager) {
      promise?.reject(-1)
      return
    }
    try {
      const audioVolumeGroupManager =
        this.audioVolumeManager.getVolumeGroupManagerSync(audio.DEFAULT_VOLUME_GROUP_ID)
      const volume = audioVolumeGroupManager.getMinVolumeSync(type)
      LogUtils.d(this.TAG, 'getMinVolume: ' + volume);
      promise?.resolve(volume)
    } catch (e) {
      promise?.reject(e)
    }
  }

  private getVolume(type: audio.AudioVolumeType, promise: HippyModulePromise) {
    if (!this.audioVolumeManager) {
      promise?.reject(-1)
      return
    }
    try {
      const audioVolumeGroupManager =
        this.audioVolumeManager.getVolumeGroupManagerSync(audio.DEFAULT_VOLUME_GROUP_ID)
      const volume = audioVolumeGroupManager.getVolumeSync(type)
      LogUtils.d(this.TAG, 'getVolume: ' + volume);
      promise?.resolve(volume)
    } catch (e) {
      promise?.reject(e)
    }
  }
}
