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

  /**
   * 获取 vendor.js 的绝对路径
   * 路径规则: filesDir/app_rpk/apps/{包名}/{版本号}/dist/vendor.js
   */
  getVendorJsFile(): string {
    // 1. 安全检查：确保 Context 和必要的包信息存在
    if (!App.instance.context || !this.data.packageName || !this.data.versionName) {
      console.warn('ApiAppLoader: Context or Package info missing when getting vendor file');
      return '';
    }

    // 2. 构建基础目录 (需与 getAppDir 逻辑保持一致)
    // 路径: /data/storage/.../files/app_rpk/apps/com.example/1.0.0
    const baseDir = `${App.instance.context.filesDir}/app_rpk/apps/${this.data.packageName}/${this.data.versionName}`;

    // 3. 拼接 dist/vendor.js
    const filePath = `${baseDir}/dist/vendor.js`;

    // 4. (可选) 检查文件是否存在，如果业务需要严格验证可取消注释
    /*
    if (!fs.accessSync(filePath)) {
      console.warn(`ApiAppLoader: Vendor file not found at ${filePath}`);
      return '';
    }
    */
    return filePath;
  }

  /**
   * 获取 index.js 的绝对路径
   * 路径规则: filesDir/app_rpk/apps/{包名}/{版本号}/dist/index.js
   */
  getIndexJsFile(): string {
    // 1. 安全检查
    if (!App.instance.context || !this.data.packageName || !this.data.versionName) {
      console.warn('ApiAppLoader: Context or Package info missing when getting index file');
      return '';
    }

    // 2. 构建基础目录
    const baseDir = `${App.instance.context.filesDir}/app_rpk/apps/${this.data.packageName}/${this.data.versionName}`;

    // 3. 拼接 dist/index.js
    const filePath = `${baseDir}/dist/index.js`;

    return filePath;
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

export class DownloadTask {
  private task: request.agent.Task | null = null;

  /**
   * 启动下载 -> 解密 -> 校验 MD5
   */
  start(context: Context, download: Download): Promise<DownloadResult> {
    return new Promise<DownloadResult>(async (resolve, reject) => {
      // 1. 临时下载路径 (这是加密的原始文件)
      // 注意：request.agent saveas 往往是相对于沙箱 cache 或 files 目录，这里我们假设最终能通过绝对路径访问
      const tempFileName = `enc_${download.name}`; // 加个前缀区分
      const tempPath = `${context.cacheDir}/${tempFileName}`;

      // 2. 解密后的最终路径 (用于 MD5 校验和后续解压)
      const finalPath = `${context.cacheDir}/${download.name}`;

      // 清理旧文件
      this.cleanFile(tempPath);
      this.cleanFile(finalPath);

      try {
        const config: request.agent.Config = {
          action: request.agent.Action.DOWNLOAD,
          url: download.url,
          mode: request.agent.Mode.FOREGROUND,
          network: request.agent.Network.ANY,
          overwrite: true,
          saveas: `./${tempFileName}` // 下载为加密文件名
        };

        this.task = await request.agent.create(context, config);

        this.task.on('failed', async (progress: request.agent.Progress) => {
          this._release();
          let info = await request.agent.show(this.task!.tid);
          console.error('Download Failed:', JSON.stringify(info));
          reject({
            code: -3001,
            data: info.reason || 'Download failed unknown'
          } as BusinessError<string>);
        });

        this.task.on('completed', async (progress: request.agent.Progress) => {
          this._release();

          // 检查下载的原始文件是否存在
          if (!fs.accessSync(tempPath)) {
            reject({ code: -3004, data: 'Downloaded raw file not found' });
            return;
          }

          try {
            console.info('Download completed. Start Decrypting RPK...');

            // --- 核心修改：先解密 ---
            // 将 tempPath (加密) 解密到 finalPath (明文)
            await this.decryptRpk(tempPath, finalPath);
            console.info('Decrypt success. Start checking MD5...');

            // --- 核心修改：解密后删除原始加密文件 (可选，节省空间) ---
            this.cleanFile(tempPath);

            // --- 核心修改：校验解密后文件的 MD5 ---
            // 注意：这里假设服务器给的 MD5 是针对【解密后】文件的
            const matched = await this.checkMd5(download.md5, finalPath);

            if (!matched) {
              console.error('MD5 Mismatch after decrypt!');
              this.cleanFile(finalPath); // 删除无效文件
              reject({
                code: -3003,
                data: 'md5 mismatch'
              } as BusinessError<string>);
              return;
            }

            console.info('MD5 Check Passed.');
            resolve({
              path: finalPath // 返回解密后的路径供 ApiAppLoader 解压
            });

          } catch (e) {
            console.error('Process error (Decrypt/MD5):', e);
            this.cleanFile(tempPath);
            this.cleanFile(finalPath);
            reject({
              code: -3005,
              data: `Process failed: ${e.message}`
            } as BusinessError<string>);
          }
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

  /**
   * ArkTS 版的 decryptRpk 实现
   * 读取 originFile，交换首尾 100 字节，写入 decryptFile
   */
  private async decryptRpk(originPath: string, decryptPath: string): Promise<void> {
    try {
      // 1. 读取源文件
      let srcFile = await fs.open(originPath, fs.OpenMode.READ_ONLY);
      let stat = await fs.stat(srcFile.fd);
      // 注意：如果文件特别大，建议不要一次性 new ArrayBuffer，而是分块读写。
      // 这里假设 RPK 文件大小适中（几十MB以内），保持原 Java 逻辑一次性读入。
      let buffer = new ArrayBuffer(stat.size);

      await fs.read(srcFile.fd, buffer);
      await fs.close(srcFile);

      // 2. 字节交换逻辑
      let bytes = new Uint8Array(buffer);
      const len = bytes.length;
      const loopCount = 100;

      for (let i = 0; i < loopCount; i++) {
        // 防止文件极小越界
        if (i >= len) {
          break;
        }

        let tmp = bytes[i];
        let targetIndex = len - i - 1;

        if (targetIndex >= 0 && targetIndex < len) {
          bytes[i] = bytes[targetIndex];
          bytes[targetIndex] = tmp;
        }
      }
      // 3. 写入目标文件
      // CREATE: 不存在则创建, TRUNC: 存在则清空重写
      let destFile = await fs.open(decryptPath, fs.OpenMode.READ_WRITE | fs.OpenMode.CREATE | fs.OpenMode.TRUNC);
      await fs.write(destFile.fd, buffer);
      await fs.close(destFile);

    } catch (e) {
      // 异常时尝试清理
      this.cleanFile(decryptPath);
      throw new Error(`Decrypt RPK failed: ${e.message}`);
    }
  }

  private async checkMd5(expectMd5: string, path: string): Promise<boolean> {
    if (!expectMd5) {
      return true;
    } // 如果服务端没下发MD5，默认通过
    try {
      const fileMd5 = await FileUtil.calFileMd5(path);
      console.info(`MD5 Check - Expect: ${expectMd5}, Actual: ${fileMd5}`);
      return fileMd5.toLowerCase() === expectMd5.toLowerCase();
    } catch (e) {
      console.error('Calculate MD5 failed:', e);
      return false;
    }
  }

  // 辅助清理文件方法
  private cleanFile(path: string) {
    try {
      if (fs.accessSync(path)) {
        fs.unlinkSync(path);
      }
    } catch (ignore) {
    }
  }

  private _release() {
    if (this.task) {
      // request.agent 提供的 off 方法可能因 API 版本不同而有所差异
      // 这里的逻辑主要是为了断开引用
      this.task.off('failed');
      this.task.off('completed');
      this.task = null;
    }
  }
}