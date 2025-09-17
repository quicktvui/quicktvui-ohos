import { Download } from "./Download";
import { DownloadProgressListener, DownloadStatusListener } from "./DownloadListener";
import request from '@ohos.request';
import { DownloadStatus } from "./DownloadStatus";
import { DownloadProgress } from "./DownloadProgress";
import { DownloadState } from "./DownloadState";
import { DownloadMessage } from "./DownloadMessage";
import { DownloadConfig } from "./DownloadConfig";
import { LogUtils, } from 'hippy';

/**
 * 下载任务
 */
export class DownloadTask {
  //
  private readonly TAG = "DownloadTask"
  private context: Context;
  private downloadTask: request.agent.Task | null = null
  private downloadInfo: Download | null = null;
  private downloadStatusListener: DownloadStatusListener | null = null;
  private downloadProgressListener: DownloadProgressListener | null = null
  private config: DownloadConfig | null = null

  public constructor(context: Context, config: DownloadConfig) {
    this.context = context
    this.config = config
  }

  getDownload(): Download | null {
    return this.downloadInfo
  }

  async download(download: Download) {
    this.downloadInfo = download
    const url = download.fileUrl
    const path = download.downloadPath
    const config: request.agent.Config = {
      action: request.agent.Action.DOWNLOAD,
      url,
      method: 'GET',
      title: 'download',
      mode: request.agent.Mode.BACKGROUND,
      network: request.agent.Network.ANY,
      saveas: path,
      overwrite: this.config!.overwrite ?? true,
      gauge: this.config!.gauge ?? true,
      headers: this.config!.headers,
      token: this.config?.token
    };
    //
    this.downloadTask = await request.agent.create(this.context, config);

    //
    this.downloadTask.on('progress', (progress: request.agent.Progress) => {

      let processed = Number(progress.processed.toString()).valueOf();
      let size = progress.sizes[0];
      let process: number = Math.floor(processed / size * 100);

      LogUtils.d(this.TAG, `[DownloadProgressListener] Progress Update:
        fileUrl = ${this.downloadInfo?.fileUrl},
        downloaded = ${processed},
        total = ${size},
        progress = ${process}%
      `);

      if (this.downloadProgressListener) {
        const progress: DownloadProgress = {
          downloadSize: processed,
          totalSize: size,
          progress: process
        }
        const status: DownloadStatus<DownloadProgress> = {
          state: DownloadState.PROGRESS,
          download: this.downloadInfo,
          data: progress
        }
        this.downloadProgressListener(status)
      }
    })
    //
    this.downloadTask.on('completed', async (progress: request.agent.Progress) => {
      if (this.downloadStatusListener) {
        const status: DownloadStatus<DownloadMessage> = {
          state: DownloadState.SUCCESS,
          download: this.downloadInfo,
          data: null
        }
        this.downloadStatusListener(status)
      }
      await this.cancel()
    })
    //pause
    this.downloadTask.on('pause', async () => {
      if (this.downloadStatusListener) {
        const status: DownloadStatus<DownloadMessage> = {
          state: DownloadState.PAUSE,
          download: this.downloadInfo,
          data: null
        }
        this.downloadStatusListener(status)
      }
    })
    //resume
    this.downloadTask.on('resume', async () => {
      if (this.downloadStatusListener) {
        const status: DownloadStatus<DownloadMessage> = {
          state: DownloadState.RESUME,
          download: this.downloadInfo,
          data: null
        }
        this.downloadStatusListener(status)
      }
    })
    //
    this.downloadTask.on('failed', async (progress: request.agent.Progress) => {
      LogUtils.e(this.TAG, `[DownloadProgressListener] failed:
        fileUrl = ${this.downloadInfo?.fileUrl},
      `);

      if (this.downloadTask) {
        let taskInfo = await request.agent.show(this.downloadTask.tid);

        if (this.downloadStatusListener) {
          const message: DownloadMessage = {
            message: taskInfo.reason,
            code: -1
          }
          const status: DownloadStatus<DownloadMessage> = {
            state: DownloadState.ERROR,
            download: this.downloadInfo,
            data: message
          }
          this.downloadStatusListener(status)
        }
        await this.cancel()
      }
    })
    //init
    if (this.downloadStatusListener) {
      const status: DownloadStatus<DownloadMessage> = {
        state: DownloadState.INIT,
        download: this.downloadInfo,
        data: null
      }
      this.downloadStatusListener(status)
    }
  }

  async start() {

    if (this.downloadTask) {
      LogUtils.d(this.TAG, `Download start`);
      await this.downloadTask.start();
    } else {
      LogUtils.d(this.TAG, `Download start: DownloadTask is null`);
    }
  }

  async stop() {
    if (this.downloadTask) {
      LogUtils.d(this.TAG, `Download stop`);
      await this.downloadTask.stop();
    } else {
      LogUtils.d(this.TAG, `Download start: DownloadTask is null`);
    }
  }

  async pause() {
    if (this.downloadTask) {
      LogUtils.d(this.TAG, `Download pause`);
      await this.downloadTask.pause();
    } else {
      LogUtils.d(this.TAG, `Download start: DownloadTask is null`);
    }
  }

  async resume() {
    if (this.downloadTask) {
      LogUtils.d(this.TAG, `Download resume`);
      await this.downloadTask.resume();
    } else {
      LogUtils.d(this.TAG, `Download start: DownloadTask is null`);
    }
  }

  async cancel() {
    if (this.downloadTask) {
      LogUtils.d(this.TAG, `Download cancel`);
      this.downloadTask.off('progress');
      this.downloadTask.off('completed');
      this.downloadTask.off('failed');
      this.downloadTask.off('pause');
      this.downloadTask.off('resume');
      await request.agent.remove(this.downloadTask.tid);
    } else {
      LogUtils.d(this.TAG, `Download start: DownloadTask is null`);
    }
  }

  async release() {
    LogUtils.d(this.TAG, `Download release`);
    this.downloadStatusListener = null
  }

  setDownloadStatusListener(downloadStatusListener: DownloadStatusListener): void {
    this.downloadStatusListener = downloadStatusListener
  }

  setDownloadProgressListener(downloadProgressListener: DownloadProgressListener): void {
    this.downloadProgressListener = downloadProgressListener
  }
}
