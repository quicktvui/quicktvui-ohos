import { EsData } from '../../EsData';
import { SignUtil } from '../../utils/SignUtil';
import { AppLoader } from './AppLoader';
import zlib from '@ohos.zlib';
import { fileIo as fs } from '@kit.CoreFileKit';
import { App } from '../../../App';
import request from '@ohos.request';
import { BusinessError } from '@ohos.base';
import { FileUtil } from '../../utils/FileUtil';
import { http } from '@kit.NetworkKit';

export class ApiAppLoader implements AppLoader {
  private data: EsData;

  constructor(data: EsData) {
    this.data = data
  }

  /**
   * 主流程：获取信息 -> 下载 -> 解压
   */
  async startLoad(): Promise<void> {
    try {
      console.info('ApiAppLoader: 开始请求应用信息...');
      const appInfo = await this.fetchAppInfo();

      console.info(`ApiAppLoader: 获取信息成功，准备下载: ${appInfo.tvpackage}`);
      const download = await this.downloadPackage(appInfo);

      console.info(`ApiAppLoader: 下载并校验MD5成功，路径: ${download.path}`);
      const targetDir = this.getAppDir(appInfo);

      console.info(`ApiAppLoader: 开始解压到: ${targetDir}`);
      await this.unzip(download.path, targetDir);

      console.info('ApiAppLoader: 加载流程全部完成');
    } catch (e) {
      console.error('ApiAppLoader: 流程异常:', JSON.stringify(e));
    }
  }

  /**
   * 1. 请求接口并解析 JSON
   */
  private fetchAppInfo(): Promise<AppInfo> {
    const requestData = this.generateRequestParams();

    return new Promise<AppInfo>((resolve, reject) => {
      const call = http.createHttp();
      call.request(
        'https://api.extscreen.com/extscreenapi/api/extend_screen/v2/hili/client/tvinfo',
        {
          method: http.RequestMethod.POST,
          extraData: new Uint8Array(requestData).buffer,
          header: {
            'Content-Type': 'application/octet-stream',
          },
          expectDataType: http.HttpDataType.ARRAY_BUFFER, // 期望二进制响应
          connectTimeout: 10000,
          readTimeout: 10000
        },
        (error: BusinessError, response: http.HttpResponse) => {
          if (error) {
            console.error('Http Request Failed:', JSON.stringify(error));
            reject(error);
            return;
          }

          if (response.responseCode !== 200) {
            reject(`Http Error Code: ${response.responseCode}`);
            return;
          }

          const result = response.result;
          if (result instanceof ArrayBuffer) {
            try {
              // 1. 解密
              const ret = SignUtil.decodeWithPublicKey(result);
              console.log('ApiAppLoader Response Decoded:', ret);

              // 2. 解析 JSON
              const jsonResult = JSON.parse(ret) as ServerResponse;

              // 3. 业务校验
              if (jsonResult.code === 200 && jsonResult.data) {
                resolve(jsonResult.data);
              } else {
                reject(`Server Business Error: ${jsonResult.msg || 'Unknown'}`);
              }
            } catch (e) {
              console.error('Parse/Decode Error:', e);
              reject('Response parse failed');
            }
          } else {
            reject('Invalid response type');
          }
        }
      );
    });
  }

  private generateRequestParams(): ArrayBuffer {
    const params: Params = {
      source: '', // 根据实际情况填写
      sdk_ver: '3.0',
      client: {
        es_package: this.data.packageName!,
        es_package_ver: this.data.versionName || '',
        clientEsPackageVer: ''
      }
    };
    return SignUtil.encodeWithPublicKey(JSON.stringify(params));
  }

  /**
   * 2. 下载并校验 MD5 (逻辑委托给 DownloadTask)
   */
  private downloadPackage(info: AppInfo): Promise<DownloadResult> {
    return new DownloadTask().start(App.instance.context!, {
      name: `${info.es_package}_${info.tvpackagever}.zip`, // 建议文件名带上版本号防止冲突
      url: info.tvpackage,
      md5: info.tvpackagemd5
    });
  }

  /**
   * 3. 解压文件
   */
  private unzip(zipFilePath: string, targetDir: string): Promise<void> {
    return new Promise<void>((resolve, reject) => {
      // 确保目标文件夹存在，如果存在建议先清空或覆盖，这里视业务逻辑而定
      if (!fs.accessSync(targetDir)) {
        fs.mkdirSync(targetDir, true);
      }

      zlib.decompressFile(zipFilePath, targetDir, {
        level: zlib.CompressLevel.COMPRESS_LEVEL_DEFAULT_COMPRESSION
      }).then(() => {
        resolve();
      }).catch((err: BusinessError) => {
        console.error('Unzip failed:', err);
        reject(err);
      });
    });
  }

  private getAppDir(appInfo: AppInfo): string {
    // 确保路径层级正确
    let dir = `${App.instance.context?.filesDir}/app_rpk/apps/${appInfo.es_package}/${appInfo.tvpackagever}`;
    if (!fs.accessSync(dir)) {
      fs.mkdirSync(dir, true);
    }
    return dir;
  }

  getAppName(): string {
    return ''; // 根据需求实现
  }

  getAppIcon(): string {
    return ''; // 根据需求实现
  }

  getVendorJsFile(): string {
    return '';
  }

  getIndexJsFile(): string {
    return '';
  }
}

// --- 接口定义 ---

// 服务端返回的最外层结构
interface ServerResponse {
  code: number;
  msg: string;
  data: AppInfo;
}

// 对应 Params
interface Params {
  source: string;
  client: Client;
  sdk_ver: string;
}

interface Client {
  es_package: string;
  es_package_ver: string;
  clientEsPackageVer: string;
}

// 对应日志中的 data 部分
interface AppInfo {
  es_package: string; // "es.hello.world"
  name: string; // "HelloWorld"
  tvpackage: string; // 下载链接
  tvpackagever: string; // "1.0.4"
  tvpackagemd5: string; // MD5
  icon?: string;
  updatePopupMessage?: string;
  // ... 其他字段可按需添加
}

interface Download {
  url: string;
  name: string;
  md5: string;
}

interface DownloadResult {
  path: string;
}

// --- 下载任务类 ---

class DownloadTask {
  private task: request.agent.Task | null = null;

  start(context: Context, download: Download): Promise<DownloadResult> {
    return new Promise<DownloadResult>(async (resolve, reject) => {
      // 临时下载路径 (Cache 目录)
      let tempPath = `${context.cacheDir}/${download.name}`;

      // 如果之前有残留文件，先删除，防止断点续传导致MD5校验失败（除非逻辑支持断点续传）
      try {
        if (fs.accessSync(tempPath)) {
          fs.unlinkSync(tempPath);
        }
      } catch (e) {
      }

      try {
        const config: request.agent.Config = {
          action: request.agent.Action.DOWNLOAD,
          url: download.url,
          mode: request.agent.Mode.FOREGROUND, // 建议前台或根据需求改为 BACKGROUND
          network: request.agent.Network.ANY,
          overwrite: true,
          saveas: `./${download.name}` // request.agent saveas 往往是相对于 cache/files 的相对路径或特定沙箱路径
        };

        this.task = await request.agent.create(context, config);

        this.task.on('failed', async (progress: request.agent.Progress) => {
          this._release();
          // 获取失败原因
          let info = await request.agent.show(this.task!.tid);
          console.error('Download Failed:', JSON.stringify(info));
          reject({
            code: -3001,
            data: info.reason || 'Download failed unknown'
          } as BusinessError<string>);
        });

        this.task.on('completed', async (progress: request.agent.Progress) => {
          this._release();

          // request.agent 下载完成后的实际物理路径通常需要通过 query 或约定获取
          // 这里假设下载到了 cacheDir 下（如果是 background 模式需要特别注意路径）
          // 由于上面 saveas 写法在不同 API 版本有差异，这里做个严谨处理：

          // 假设文件确实落在了 tempPath (或者根据 agent 的 saveas 逻辑)
          // 必须检查文件是否存在
          if (!fs.accessSync(tempPath)) {
            reject({ code: -3004, data: 'Downloaded file not found' });
            return;
          }

          console.info('Download completed, checking MD5...');
          const matched = await this.checkMd5(download.md5, tempPath);

          if (!matched) {
            console.error('MD5 Mismatch!');
            await fs.unlink(tempPath); // 删除损坏文件
            reject({
              code: -3003,
              data: 'md5 mismatch'
            } as BusinessError<string>);
            return;
          }

          resolve({
            path: tempPath // 返回已下载文件的路径，解压时直接用
          });
        });

        await this.task.start();

      } catch (error) {
        this._release();
        console.error('Download start error:', error);
        reject({
          code: -3002,
          data: error.message
        } as BusinessError<string>);
      }
    });
  }

  private async checkMd5(expectMd5: string, path: string): Promise<boolean> {
    // 假设 FileUtil.calFileMd5 是可靠的
    const fileMd5 = await FileUtil.calFileMd5(path);
    console.info(`MD5 Check - Expect: ${expectMd5}, Actual: ${fileMd5}`);
    return fileMd5.toLowerCase() === expectMd5.toLowerCase();
  }

  private _release() {
    if (this.task) {
      this.task.off('failed');
      this.task.off('completed');
      this.task = null;
    }
  }
}