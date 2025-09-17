import { Upload } from "./Upload";
import { UploadProgressListener, UploadStatusListener } from "./UploadListener";
import request from '@ohos.request';
import { UploadStatus } from "./UploadStatus";
import { UploadProgress } from "./UploadProgress";
import { UploadState } from "./UploadState";
import { UploadMessage } from "./UploadMessage";
import { UploadConfig } from "./UploadConfig";
import { LogUtils, } from 'hippy';

/**
 * 下载任务
 */
export class UploadTask {
  //
  private readonly TAG = "UploadTask"
  private context: Context;
  private uploadTask: request.agent.Task | null = null
  private uploadInfo: Upload | null = null;
  //
  private uploadStatusListener: UploadStatusListener | null = null;
  private uploadProgressListener: UploadProgressListener | null = null
  private config: UploadConfig | null = null

  public constructor(context: Context, config: UploadConfig) {
    this.context = context
    this.config = config
  }

  getUpload(): Upload | null {
    return this.uploadInfo
  }

  async upload(upload: Upload) {
    LogUtils.d(this.TAG, `init upload task start!`);
    this.uploadInfo = upload
    const url = upload.uploadPath ?? ''
    //
    const config: request.agent.Config = {
      action: request.agent.Action.UPLOAD,
      headers: this.config!.headers,
      url: url,
      method: 'POST',
      title: 'upload',
      mode: request.agent.Mode.BACKGROUND,
      network: request.agent.Network.ANY,
      overwrite: this.config!.overwrite ?? true,
      gauge: this.config!.gauge ?? true,
      data: await this.getFileData(upload),
      token: this.config?.token
    };
    //
    this.uploadTask = await request.agent.create(this.context, config);
    //
    this.uploadTask.on('progress', (progress: request.agent.Progress) => {

      let processed = Number(progress.processed.toString()).valueOf();
      let size = progress.sizes[0];
      let process: number = Math.floor(processed / size * 100);

      LogUtils.d(this.TAG, `[DownloadProgressListener] Progress Update:
        fileUrl = ${this.uploadInfo?.filePath},
        uploaded = ${processed},
        total = ${size},
        progress = ${process}%
      `);

      if (this.uploadProgressListener) {
        const progress: UploadProgress = {
          uploadSize: processed,
          totalSize: size,
          progress: process
        }
        const status: UploadStatus<UploadProgress> = {
          state: UploadState.PROGRESS,
          upload: this.uploadInfo,
          data: progress
        }
        this.uploadProgressListener(status)
      }
    })
    //
    this.uploadTask.on('completed', async (progress: request.agent.Progress) => {
      if (this.uploadStatusListener) {
        const status: UploadStatus<UploadMessage> = {
          state: UploadState.SUCCESS,
          upload: this.uploadInfo,
          data: null
        }
        this.uploadStatusListener(status)
      }
      await this.cancel()
    })
    //pause
    this.uploadTask.on('pause', async () => {
      if (this.uploadStatusListener) {
        const status: UploadStatus<UploadMessage> = {
          state: UploadState.PAUSE,
          upload: this.uploadInfo,
          data: null
        }
        this.uploadStatusListener(status)
      }
    })
    //resume
    this.uploadTask.on('resume', async () => {
      if (this.uploadStatusListener) {
        const status: UploadStatus<UploadMessage> = {
          state: UploadState.RESUME,
          upload: this.uploadInfo,
          data: null
        }
        this.uploadStatusListener(status)
      }
    })
    //
    this.uploadTask.on('failed', async (progress: request.agent.Progress) => {
      LogUtils.e(this.TAG, `[UploadProgressListener] failed:
        fileUrl = ${this.uploadInfo?.filePath},
      `);

      if (this.uploadTask) {
        let taskInfo = await request.agent.show(this.uploadTask.tid);

        if (this.uploadStatusListener) {
          const message: UploadMessage = {
            message: taskInfo.reason,
            code: -1
          }
          const status: UploadStatus<UploadMessage> = {
            state: UploadState.ERROR,
            upload: this.uploadInfo,
            data: message
          }
          this.uploadStatusListener(status)
        }
        await this.cancel()
      }
    })
    //init
    if (this.uploadStatusListener) {
      const status: UploadStatus<UploadMessage> = {
        state: UploadState.INIT,
        upload: this.uploadInfo,
        data: null
      }
      this.uploadStatusListener(status)
    }
    LogUtils.d(this.TAG, `init upload task completed!`);
  }


  private async getFileData(upload: Upload): Promise<Array<request.agent.FormItem>> {
    let files: Array<request.agent.FormItem> = [];
    const path = upload.fileAbsolutePath ?? ''
    const fileName = this.getFileName(upload)
    const item: request.agent.FormItem = {
      name: fileName,
      value: {
        filename: fileName,
        mimeType: 'application/octet-stream',
        path: path,
      }
    }
    files.push(item)
    return files;
  }

  private getFileName(upload: Upload): string {
    const fileName = upload.fileName?.trim();
    const path = upload.fileAbsolutePath ?? '';
    if (fileName) {
      return fileName;
    }
    // 从 path 中截取最后的文件名部分（适配 Unix 和 Windows 路径）
    const segments = path.split(/[\\/]/); // 匹配 "/" 或 "\"
    return segments.length > 0 ? segments[segments.length - 1] : 'unknown';
  }

  async start() {
    if (this.uploadTask) {
      LogUtils.d(this.TAG, `Upload start`);
      await this.uploadTask.start();
    } else {
      LogUtils.d(this.TAG, `Upload start: UploadTask is null`);
    }
  }

  async stop() {
    if (this.uploadTask) {
      LogUtils.d(this.TAG, `Upload stop`);
      await this.uploadTask.stop();
    } else {
      LogUtils.d(this.TAG, `Upload start: UploadTask is null`);
    }
  }

  async pause() {
    if (this.uploadTask) {
      LogUtils.d(this.TAG, `Upload pause`);
      await this.uploadTask.pause();
    } else {
      LogUtils.d(this.TAG, `Upload start: UploadTask is null`);
    }
  }

  async resume() {
    if (this.uploadTask) {
      LogUtils.d(this.TAG, `Upload resume`);
      await this.uploadTask.resume();
    } else {
      LogUtils.d(this.TAG, `Upload start: UploadTask is null`);
    }
  }

  async cancel() {
    if (this.uploadTask) {
      LogUtils.d(this.TAG, `Upload cancel`);
      this.uploadTask.off('progress');
      this.uploadTask.off('completed');
      this.uploadTask.off('failed');
      this.uploadTask.off('pause');
      this.uploadTask.off('resume');
      await request.agent.remove(this.uploadTask.tid);
    } else {
      LogUtils.d(this.TAG, `Upload start: UploadTask is null`);
    }
  }

  async release() {
    LogUtils.d(this.TAG, `Upload release`);
    this.uploadStatusListener = null
  }

  setUploadStatusListener(uploadStatusListener: UploadStatusListener): void {
    this.uploadStatusListener = uploadStatusListener
  }

  setUploadProgressListener(uploadProgressListener: UploadProgressListener): void {
    this.uploadProgressListener = uploadProgressListener
  }
}
