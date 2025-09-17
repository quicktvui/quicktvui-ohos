import { Upload } from "./Upload";
import { UploadProgressListener, UploadStatusListener } from "./UploadListener";
import request from '@ohos.request';
import QTAppManager from "../../quick/QTAppManager";
import { UploadTask } from "./UploadTask";
import { LogUtils } from 'hippy';
import { UploadMessage } from "./UploadMessage";
import { UploadStatus } from "./UploadStatus";
import { UploadProgress } from "./UploadProgress";
import { UploadState } from "./UploadState";
import { UploadConfig } from "./UploadConfig";

/**
 * 下载管理器
 */
export class UploadManager {
  private readonly TAG = 'UploadManager';
  private readonly TASK_MAX: number = 10;
  private static instance: UploadManager;
  private waitList: Upload[] = [];
  private taskMap: Map<string, UploadTask> = new Map(); // fileUrl → UploadTask
  private statusListeners: Set<UploadStatusListener> = new Set();
  private progressListeners: Set<UploadProgressListener> = new Set();
  private context: Context | null = null;
  private progressThrottleInterval: number = 1000; // 节流间隔（单位 ms）
  private lastProgressNotifyTime: Map<string, number> = new Map(); // fileUrl → timestamp

  private config: UploadConfig | null = null;

  private constructor() {
  }

  static getInstance(): UploadManager {
    if (!UploadManager.instance) {
      UploadManager.instance = new UploadManager();
    }
    return UploadManager.instance;
  }

  public init(context: Context, config: UploadConfig) {
    this.config = config;
    this.context = context;
    this.progressThrottleInterval = config.progressThrottleInterval;
  }

  public async upload(upload: Upload) {
    if (!upload || !upload.filePath) {
      return;
    }
    LogUtils.d(this.TAG, `Upload upload: ${JSON.stringify(upload)}`);
    this.waitList.push(upload);
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
    await this.createUploadTasks(toStart);
  }

  private async createUploadTasks(uploads: Upload[]) {
    for (const upload of uploads) {
      const filePath = upload.filePath;

      if (this.taskMap.has(filePath)) {
        LogUtils.i(this.TAG, `Task for ${filePath} already exists`);
        continue;
      }
      //
      const absolutePath =
        QTAppManager.getInstance().getESAppFilePath(this.context!) + "/" + filePath;
      upload.fileAbsolutePath = absolutePath;

      const task = new UploadTask(this.context!, this.config!);
      LogUtils.d(this.TAG, `createUploadTasks: absolutePath: ${absolutePath}`);
      this.taskMap.set(filePath, task);

      task.setUploadStatusListener((status: UploadStatus<UploadMessage>) => {
        try {
          this.statusListeners.forEach(l => l(status));
        } catch (e) {
          LogUtils.e(this.TAG, `Status listener error: ${e}`);
        }

        if (
          status.state === UploadState.SUCCESS ||
            status.state === UploadState.ERROR
        ) {
          this.taskMap.delete(filePath);
          this.flushBackgroundTask();
        }
      });
      task.setUploadProgressListener((progressStatus: UploadStatus<UploadProgress>) => {
        try {
          const filePath: string = progressStatus.upload?.filePath ?? "";
          const progress: number = progressStatus.data?.progress ?? -1
          const now = Date.now();
          const lastTime: number = this.lastProgressNotifyTime.get(filePath!) ?? 0;

          // 如果时间间隔超过 throttle 或任务已完成（100%），则触发回调
          if ((now - lastTime >= this.progressThrottleInterval) || progress === 100) {
            this.lastProgressNotifyTime.set(filePath!, now);
            this.progressListeners.forEach(listener => listener(progressStatus));
          }
        } catch (e) {
          LogUtils.e(this.TAG, `Progress listener error: ${e}`);
        }
      });

      LogUtils.d(this.TAG, `createUploadTasks: init upload task start: ${absolutePath}`);
      await task.upload(upload);
      LogUtils.d(this.TAG, `createUploadTasks: init upload task end: ${absolutePath}`);
    }
  }

  public start(upload: Upload) {
    LogUtils.d(this.TAG,
      `Upload start: ${JSON.stringify(upload)} ${this.taskMap.get(upload.filePath)}`);
    this.taskMap.get(upload.filePath)?.start();
  }

  public stop(upload: Upload) {
    LogUtils.d(this.TAG, `Upload stop: ${JSON.stringify(upload)}`);
    this.taskMap.get(upload.filePath)?.stop();
  }

  public pause(upload: Upload) {
    LogUtils.d(this.TAG, `Upload pause: ${JSON.stringify(upload)}`);
    this.taskMap.get(upload.filePath)?.pause();
  }

  public pauseAll() {
    LogUtils.d(this.TAG, `Upload pauseAll`);
    this.taskMap.forEach((task): Promise<void> => task.pause());
  }

  public resume(upload: Upload) {
    LogUtils.d(this.TAG, `Upload resume: ${JSON.stringify(upload)}`);
    this.taskMap.get(upload.filePath)?.resume();
  }

  public resumeAll() {
    LogUtils.d(this.TAG, `Upload resumeAll`);
    this.taskMap.forEach((task): Promise<void> => task.resume());
  }

  public cancel(upload: Upload) {
    LogUtils.d(this.TAG, `Upload cancel: ${JSON.stringify(upload)}`);
    this.taskMap.get(upload.filePath)?.cancel();
    this.taskMap.delete(upload.filePath);
  }

  public async release() {
    LogUtils.d(this.TAG, `Upload release`);
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

  public registerUploadStatusListener(listener: UploadStatusListener) {
    this.statusListeners.add(listener);
  }

  public unregisterUploadStatusListener(listener: UploadStatusListener) {
    this.statusListeners.delete(listener);
  }

  public registerUploadProgressListener(listener: UploadProgressListener) {
    this.progressListeners.add(listener);
  }

  public unregisterUploadProgressListener(listener: UploadProgressListener) {
    this.progressListeners.delete(listener);
  }
}
