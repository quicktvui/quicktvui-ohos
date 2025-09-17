import {
  HippyEngineContext,
  HippyAny,
  HippyModulePromise,
  HippyNativeModule,
  LogUtils,
  HippyMap
} from 'hippy';

import { BaseModule } from '../BaseModule';
import { Download } from './Download';
import { DownloadConfig } from './DownloadConfig';
import { DownloadProgressListener, DownloadStatusListener } from './DownloadListener';
import { DownloadManager } from './DownloadManager';
import { DownloadMessage } from './DownloadMessage';
import { DownloadProgress } from './DownloadProgress';
import { DownloadStatus } from './DownloadStatus';

/**
 * 下载模块
 */
@HippyNativeModule({ name: "ESDownloadModule" })
export class ESDownloadModule extends BaseModule {
  public static readonly NAME: string = 'ESDownloadModule'
  public readonly TAG: string = 'ESDownloadModule'
  private downloadStatusListener: DownloadStatusListener | null = null
  private downloadProgressListener: DownloadProgressListener | null = null

  constructor(ctx: HippyEngineContext) {
    super(ctx)
    this.downloadStatusListener = (status: DownloadStatus<DownloadMessage>) => {
      LogUtils.d(this.TAG, `[DownloadStatusListener] Status Changed:
        fileUrl = ${status.download?.fileUrl},
        state = ${status.state},
        message = ${status.data?.message ?? 'N/A'},
        code = ${status.data?.code ?? 'N/A'}
      `);
      const event = new Map<string, HippyAny>()
      event.set("download", this.downloadToHippyAny(status.download))
      event.set("filePath", status.download?.downloadPath)
      event.set("state", status.state)
      this.dispatchEvent("onDownloadStatusChanged", event)
    }
    this.downloadProgressListener = (progressStatus: DownloadStatus<DownloadProgress>) => {
      LogUtils.d(this.TAG, `[DownloadProgressListener] Progress Update:
        fileUrl = ${progressStatus.download?.fileUrl},
        state = ${progressStatus.state},
        downloaded = ${progressStatus.data?.downloadSize},
        total = ${progressStatus.data?.totalSize},
        progress = ${progressStatus.data?.progress}%
      `);
      const event = new Map<string, HippyAny>()
      event.set("downloadSize", progressStatus.data?.downloadSize)
      event.set("totalSize", progressStatus.data?.totalSize)
      event.set("download", this.downloadToHippyAny(progressStatus.download))
      event.set("state", progressStatus.state)
      event.set("filePath", progressStatus.download?.downloadPath)
      this.dispatchEvent("onDownloadStatusChanged", event)
    }
  }

  initialize(): void {
    DownloadManager.getInstance()
      .registerDownloadStatusListener(this.downloadStatusListener!)
    DownloadManager.getInstance()
      .registerDownloadProgressListener(this.downloadProgressListener!)
  }

  destroy(): void {
    DownloadManager.getInstance()
      .unregisterDownloadStatusListener(this.downloadStatusListener!)
    DownloadManager.getInstance()
      .unregisterDownloadProgressListener(this.downloadProgressListener!)
  }

  public call(method: string, params: Array<HippyAny>, promise: HippyModulePromise): HippyAny {
    switch (method) {
      case 'initDefaultDownload': {
        const config: DownloadConfig = {
          downloadCacheDir: "/download",
          progressThrottleInterval: 1000
        }
        DownloadManager.getInstance().init(this.ctx.getAbilityContext(), config)
        break;
      }
      case 'initDownload': {
        const config: DownloadConfig = this.hippyAnyToDownloadConfig(params[0] as HippyMap);
        LogUtils.e(this.TAG, `[initDownload] Config:${JSON.stringify(config)}}`);
        DownloadManager.getInstance()
          .init(this.ctx.getAbilityContext(), config)
        break;
      }
      case 'download': {
        const downloadParams = params[0] as HippyMap
        DownloadManager.getInstance().download(this.hippyAnyToDownload(downloadParams))
        break;
      }
      case 'start': {
        const downloadParams = params[0] as HippyMap
        DownloadManager.getInstance().start(this.hippyAnyToDownload(downloadParams))
        break;
      }
      case 'stop': {
        const downloadParams = params[0] as HippyMap
        DownloadManager.getInstance().stop(this.hippyAnyToDownload(downloadParams))
        break;
      }
      case 'cancel': {
        const downloadParams = params[0] as HippyMap
        DownloadManager.getInstance().cancel(this.hippyAnyToDownload(downloadParams))
        break;
      }
      case 'pause': {
        const downloadParams = params[0] as HippyMap
        DownloadManager.getInstance().pause(this.hippyAnyToDownload(downloadParams))
        break;
      }
      case 'pauseAll': {
        DownloadManager.getInstance().pauseAll()
        break;
      }
      case 'resume': {
        const downloadParams = params[0] as HippyMap
        DownloadManager.getInstance().resume(this.hippyAnyToDownload(downloadParams))
        break;
      }
      case 'resumeAll': {
        DownloadManager.getInstance().resumeAll()
        break;
      }
      case 'release': {
        DownloadManager.getInstance().release()
        break;
      }
      default:
        super.call(method, params, promise);
    }
    return null;
  }

  private hippyAnyToDownload(params: HippyMap): Download {
    const download: Download = {
      id: params.get("id") as number,
      fileUrl: params.get("fileUrl") as string,
      fileMD5: params.get("fileMD5") as string,
      fileName: params.get("fileName") as string,
      fileType: params.get("fileType") as string,
    }
    return download
  }

  private downloadToHippyAny(download: Download | null | undefined): HippyAny {
    if (!download) {
      return {}
    }
    const map: HippyMap = new Map<string, HippyAny>()
    map.set("id", download.id)
    map.set("fileUrl", download.fileUrl)
    map.set("fileMD5", download.fileMD5)
    map.set("fileName", download.fileName)
    map.set("fileType", download.fileType)
    map.set("filePath", download.downloadPath)
    return map
  }

  private hippyAnyToDownloadConfig(params: HippyMap): DownloadConfig {
    const config: DownloadConfig = {
      downloadCacheDir: params.get('cacheDir') as string,
      progressThrottleInterval: params.get('progressThrottleInterval') as number,
      precise: params.get('precise') as boolean,
      overwrite: params.get('overwrite') as boolean,
      gauge: params.get('gauge') as boolean,
      headers: params.get('headers') as object,
    }
    return config
  }
}
