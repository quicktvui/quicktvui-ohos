import {
  HippyEngineContext,
  HippyAny,
  HippyModulePromise,
  HippyNativeModule,
  LogUtils,
  HippyMap
} from 'hippy';

import { BaseModule } from '../BaseModule';
import { Upload } from './Upload';
import { UploadConfig } from './UploadConfig';
import { UploadProgressListener, UploadStatusListener } from './UploadListener';
import { UploadManager } from './UploadManager';
import { UploadMessage } from './UploadMessage';
import { UploadProgress } from './UploadProgress';
import { UploadStatus } from './UploadStatus';

/**
 * 上传模块
 */
@HippyNativeModule({ name: "ESUploadModule" })
export class ESUploadModule extends BaseModule {
  public static readonly NAME: string = 'ESUploadModule'
  //
  public readonly TAG: string = 'ESUploadModule'
  private uploadStatusListener: UploadStatusListener | null = null
  private uploadProgressListener: UploadProgressListener | null = null

  constructor(ctx: HippyEngineContext) {
    super(ctx)
    this.uploadStatusListener = (status: UploadStatus<UploadMessage>) => {
      LogUtils.d(this.TAG, `[UploadStatusListener] Status Changed:
        filePath = ${status.upload?.filePath},
        state = ${status.state},
        message = ${status.data?.message ?? 'N/A'},
        code = ${status.data?.code ?? 'N/A'}
      `);
      const event = new Map<string, HippyAny>()
      event.set("upload", this.uploadToHippyAny(status.upload))
      event.set("filePath", status.upload?.uploadPath)
      event.set("state", status.state)
      this.dispatchEvent("onUploadStatusChanged", event)
    }
    this.uploadProgressListener = (progressStatus: UploadStatus<UploadProgress>) => {
      LogUtils.d(this.TAG, `[UploadProgressListener] Progress Update:
        filePath = ${progressStatus.upload?.filePath},
        state = ${progressStatus.state},
        uploaded = ${progressStatus.data?.uploadSize},
        total = ${progressStatus.data?.totalSize},
        progress = ${progressStatus.data?.progress}%
      `);
      const event = new Map<string, HippyAny>()
      event.set("uploadSize", progressStatus.data?.uploadSize)
      event.set("totalSize", progressStatus.data?.totalSize)
      event.set("upload", this.uploadToHippyAny(progressStatus.upload))
      event.set("state", progressStatus.state)
      event.set("filePath", progressStatus.upload?.uploadPath)
      this.dispatchEvent("onUploadStatusChanged", event)
    }
  }

  initialize(): void {
    UploadManager.getInstance()
      .registerUploadStatusListener(this.uploadStatusListener!)
    UploadManager.getInstance()
      .registerUploadProgressListener(this.uploadProgressListener!)
  }

  destroy(): void {
    UploadManager.getInstance()
      .unregisterUploadStatusListener(this.uploadStatusListener!)
    UploadManager.getInstance()
      .unregisterUploadProgressListener(this.uploadProgressListener!)
  }

  public call(method: string, params: Array<HippyAny>, promise: HippyModulePromise): HippyAny {
    switch (method) {
      case 'initUpload': {
        const config: UploadConfig = this.hippyAnyToUploadConfig(params[0] as HippyMap);
        LogUtils.d(this.TAG, `[initUpload] Config:${JSON.stringify(config)}}`);
        UploadManager.getInstance()
          .init(this.ctx.getAbilityContext(), config)
        break;
      }
      case 'upload': {
        const uploadParams = params[0] as HippyMap
        UploadManager.getInstance().upload(this.hippyAnyToUpload(uploadParams))
        break;
      }
      case 'start': {
        const uploadParams = params[0] as HippyMap
        UploadManager.getInstance().start(this.hippyAnyToUpload(uploadParams))
        break;
      }
      case 'stop': {
        const uploadParams = params[0] as HippyMap
        UploadManager.getInstance().stop(this.hippyAnyToUpload(uploadParams))
        break;
      }
      case 'cancel': {
        const uploadParams = params[0] as HippyMap
        UploadManager.getInstance().cancel(this.hippyAnyToUpload(uploadParams))
        break;
      }
      case 'pause': {
        const uploadParams = params[0] as HippyMap
        UploadManager.getInstance().pause(this.hippyAnyToUpload(uploadParams))
        break;
      }
      case 'pauseAll': {
        UploadManager.getInstance().pauseAll()
        break;
      }
      case 'resume': {
        const uploadParams = params[0] as HippyMap
        UploadManager.getInstance().resume(this.hippyAnyToUpload(uploadParams))
        break;
      }
      case 'resumeAll': {
        UploadManager.getInstance().resumeAll()
        break;
      }
      case 'release': {
        UploadManager.getInstance().release()
        break;
      }
      default:
        super.call(method, params, promise);
    }
    return null;
  }

  private hippyAnyToUpload(params: HippyMap): Upload {
    const upload: Upload = {
      id: params.get("id") as number,
      filePath: params.get("filePath") as string,
      fileName: params.get("fileName") as string,
      fileType: params.get("fileType") as string,
      uploadPath: params.get("url") as string,
    }
    return upload
  }

  private uploadToHippyAny(upload: Upload | null | undefined): HippyAny {
    if (!upload) {
      return {}
    }
    const map: HippyMap = new Map<string, HippyAny>()
    map.set("id", upload.id)
    map.set("filePath", upload.filePath)
    map.set("fileName", upload.fileName)
    map.set("fileType", upload.fileType)
    map.set("url", upload.uploadPath)
    return map
  }

  private hippyAnyToUploadConfig(params: HippyMap): UploadConfig {
    const config: UploadConfig = {
      uploadCacheDir: params.get('cacheDir') as string,
      progressThrottleInterval: params.get('progressThrottleInterval') as number,
      precise: params.get('precise') as boolean,
      overwrite: params.get('overwrite') as boolean,
      gauge: params.get('gauge') as boolean,
      headers: params.get('headers') as object,
    }
    return config
  }
}
