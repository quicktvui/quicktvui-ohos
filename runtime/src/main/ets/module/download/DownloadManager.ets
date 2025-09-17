import { Download } from "./Download";
import { DownloadProgressListener, DownloadStatusListener } from "./DownloadListener";
import request from '@ohos.request';
import QTAppManager from "../../quick/QTAppManager";
import { DownloadTask } from "./DownloadTask";
import { LogUtils } from 'hippy';
import { DownloadMessage } from "./DownloadMessage";
import { DownloadStatus } from "./DownloadStatus";
import { DownloadProgress } from "./DownloadProgress";
import { DownloadState } from "./DownloadState";
import { DownloadConfig } from "./DownloadConfig";

/**
 * 下载管理器
 */
export class DownloadManager {
  private readonly TAG = 'DownloadManager';
  private readonly TASK_MAX: number = 10;
  private static instance: DownloadManager;
  private waitList: Download[] = [];
  private taskMap: Map<string, DownloadTask> = new Map(); // fileUrl → DownloadTask
  private statusListeners: Set<DownloadStatusListener> = new Set();
  private progressListeners: Set<DownloadProgressListener> = new Set();
  private context: Context | null = null;
  private cachePath: string | null = null;
  private progressThrottleInterval: number = 1000; // 节流间隔（单位 ms）
  private lastProgressNotifyTime: Map<string, number> = new Map(); // fileUrl → timestamp

  private overwrite: boolean = true
  private config: DownloadConfig | null = null;

  private constructor() {
  }

  static getInstance(): DownloadManager {
    if (!DownloadManager.instance) {
      DownloadManager.instance = new DownloadManager();
    }
    return DownloadManager.instance;
  }

  public init(context: Context, config: DownloadConfig) {
    this.config = config;
    this.overwrite = config.overwrite ?? true
    this.context = context;
    this.cachePath = config.downloadCacheDir;
    this.progressThrottleInterval = config.progressThrottleInterval;
  }

  public async download(download: Download) {
    if (!download || !download.fileUrl) {
      return;
    }
    LogUtils.d(this.TAG, `Download download: ${JSON.stringify(download)}`);
    this.waitList.push(download);
    await this.flushBackgroundTask();
  }

  private async flushBackgroundTask() {
    if (!this.context) {
      return;
    }
    const runningTasks = await request.agent.search({ state: request.agent.State.RUNNING });
    const availableSlots = this.TASK_MAX - runningTasks.length;

    if (availableSlots <= 0 || this.waitList.length === 0) {
      return;
    }
    const toStart = this.waitList.splice(0, availableSlots);
    await this.createDownloadTasks(toStart);
  }

  private async createDownloadTasks(downloads: Download[]) {
    for (const download of downloads) {
      const url = download.fileUrl;
      if (this.taskMap.has(url)) {
        LogUtils.i(this.TAG, `Task for ${url} already exists`);
        continue;
      }
      //
      const path = QTAppManager.getInstance().getESAppFilePath(this.context!) + this.cachePath +
        "/" + download.fileName;
      download.downloadPath = path;

      const task = new DownloadTask(this.context!, this.config!);
      LogUtils.d(this.TAG, `createDownloadTasks: ${url}`);
      this.taskMap.set(url, task);

      task.setDownloadStatusListener((status: DownloadStatus<DownloadMessage>) => {
        try {
          this.statusListeners.forEach(l => l(status));
        } catch (e) {
          LogUtils.e(this.TAG, `Status listener error: ${e}`);
        }

        if (
          status.state === DownloadState.SUCCESS ||
            status.state === DownloadState.ERROR
        ) {
          this.taskMap.delete(url);
          this.flushBackgroundTask();
        }
      });
      task.setDownloadProgressListener((progressStatus: DownloadStatus<DownloadProgress>) => {
        try {
          const fileUrl: string = progressStatus.download?.fileUrl ?? "";
          const progress: number = progressStatus.data?.progress ?? -1
          const now = Date.now();
          const lastTime: number = this.lastProgressNotifyTime.get(fileUrl!) ?? 0;

          // 如果时间间隔超过 throttle 或任务已完成（100%），则触发回调
          if ((now - lastTime >= this.progressThrottleInterval) || progress === 100) {
            this.lastProgressNotifyTime.set(fileUrl!, now);
            this.progressListeners.forEach(listener => listener(progressStatus));
          }
        } catch (e) {
          LogUtils.e(this.TAG, `Progress listener error: ${e}`);
        }
      });
      await task.download(download);
    }
  }

  public start(download: Download) {
    LogUtils.d(this.TAG,
      `Download start: ${JSON.stringify(download)} ${this.taskMap.get(download.fileUrl)}`);
    this.taskMap.get(download.fileUrl)?.start();
  }

  public stop(download: Download) {
    LogUtils.d(this.TAG, `Download stop: ${JSON.stringify(download)}`);
    this.taskMap.get(download.fileUrl)?.stop();
  }

  public pause(download: Download) {
    LogUtils.d(this.TAG, `Download pause: ${JSON.stringify(download)}`);
    this.taskMap.get(download.fileUrl)?.pause();
  }

  public pauseAll() {
    LogUtils.d(this.TAG, `Download pauseAll`);
    this.taskMap.forEach((task): Promise<void> => task.pause());
  }

  public resume(download: Download) {
    LogUtils.d(this.TAG, `Download resume: ${JSON.stringify(download)}`);
    this.taskMap.get(download.fileUrl)?.resume();
  }

  public resumeAll() {
    LogUtils.d(this.TAG, `Download resumeAll`);
    this.taskMap.forEach((task): Promise<void> => task.resume());
  }

  public cancel(download: Download) {
    LogUtils.d(this.TAG, `Download cancel: ${JSON.stringify(download)}`);
    this.taskMap.get(download.fileUrl)?.cancel();
    this.taskMap.delete(download.fileUrl);
  }

  public async release() {
    LogUtils.d(this.TAG, `Download release`);
    await Promise.all(Array.from(this.taskMap.values()).map((task): Promise<void> => {
      task.stop();
      task.cancel();
      return task.release();
    }));
    this.taskMap.clear();
    this.waitList = [];
    this.statusListeners.clear();
    this.progressListeners.clear();
  }

  public registerDownloadStatusListener(listener: DownloadStatusListener) {
    this.statusListeners.add(listener);
  }

  public unregisterDownloadStatusListener(listener: DownloadStatusListener) {
    this.statusListeners.delete(listener);
  }

  public registerDownloadProgressListener(listener: DownloadProgressListener) {
    this.progressListeners.add(listener);
  }

  public unregisterDownloadProgressListener(listener: DownloadProgressListener) {
    this.progressListeners.delete(listener);
  }
}
