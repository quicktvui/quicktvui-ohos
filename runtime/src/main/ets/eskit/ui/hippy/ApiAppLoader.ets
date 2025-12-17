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

      //
      this.data.packageName = appInfo.es_package
      this.data.versionName = appInfo.tvpackagever

      // 获取解压目标文件夹路径 (注意：getAppDir 会自动创建该文件夹，所以下面需要判断是否需要清理)
      const targetDir = this.getAppDir(appInfo);

      // --- 新增逻辑 2：校验本地版本和MD5 ---
      // 这里的 targetDir 包含了版本号，所以路径存在即代表“版本文件夹名字一致”
      const md5MarkerFile = `${targetDir}/${appInfo.tvpackagemd5}`;

      if (fs.accessSync(md5MarkerFile)) {
        console.info(`ApiAppLoader: 本地已存在匹配版本且MD5校验一致，跳过下载: ${md5MarkerFile}`);
        console.info('ApiAppLoader: 最终解压文件夹路径:', targetDir);
        console.info('ApiAppLoader: 加载流程全部完成');
        return; // 直接结束
      } else {
        console.info(`ApiAppLoader: 本地缓存不存在或MD5不一致，执行清理并重新下载`);
        // 删除该版本目录，确保环境干净
        FileUtil.deleteDir(targetDir);
      }
      // ------------------------------------

      console.info(`ApiAppLoader: 获取信息成功，准备下载: ${appInfo.tvpackage}`);
      const download = await this.downloadPackage(appInfo);

      console.info(`ApiAppLoader: 下载并校验MD5成功，路径: ${download.path}`);

      // 注意：getAppDir 之前可能创建了文件夹被我们删除了，或者 unzip 内部会处理创建
      console.info(`ApiAppLoader: 开始解压到: ${targetDir}`);
      await this.unzip(download.path, targetDir);

      // --- 新增逻辑 1：保存 MD5 值作为文件名 ---
      try {
        const markerPath = `${targetDir}/${appInfo.tvpackagemd5}`;
        // 创建一个空文件，文件名即为 MD5
        const file = fs.openSync(markerPath, fs.OpenMode.CREATE | fs.OpenMode.READ_WRITE);
        fs.closeSync(file);
        console.info(`ApiAppLoader: MD5标记文件已创建: ${markerPath}`);
      } catch (e) {
        console.error('ApiAppLoader: 创建MD5标记文件失败:', e);
      }
      // ---------------------------------------

      console.info('ApiAppLoader: 最终解压文件夹路径:', targetDir);

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


// {
//   "msg": "",
//   "code": 200,
//   "data": {
//     "es_package_ver": "",
//     "updatePopupTitle": "新版本",
//     "appletsid": 657,
//     "icon": "https://extcdn.hsrc.tv/exscreen/icon/3286b6e705e91a84c42a4211536fb1dd.jpeg",
//     "refresh": false,
//     "sdks": "",
//     "minPluginVerCode": "",
//     "updatePopupMessage": "",
//     "tvpackagemd5": "7bc4554a824213f91bc4070fd0b0c63e",
//     "tvpackage": "https://extcdn.hsrc.tv/exscreen/pkg/24ad3b6165134457b44ad0eacd567bc5.zip",
//     "tvpackagever": "1.2.0",
//     "name": "HarmonyOS",
//     "es_package": "es.harmony.os.tv",
//     "updatePopupSwitch": 0,
//     "circle_logo": "https://extcdn.hsrc.tv/exscreen/icon/2cf288e8d9826545a4015e350b043616.jpeg",
//     "sdke": ""
//   }
// }
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
      console.info('Debug Path - filesDir:', context.filesDir);
      console.info('Debug Path - cacheDir:', context.cacheDir);

      // 1. 临时下载路径 (这是加密的原始文件)
      // // 注意：request.agent saveas 往往是相对于沙箱 cache 或 files 目录，这里我们假设最终能通过绝对路径访问
      const tempFileName = `enc_${download.name}`; // 加个前缀区分
      const tempPath = `${context.cacheDir}/${tempFileName}`;
      //
      // // ========================= 修改开始 ======测试===================
      //
      // // 2. 解密后的最终路径 -> 改为 filesDir 下的特定目录
      // // filesDir 在 "Device File Browser" 中位于 /data/app/el2/100/base/<包名>/haps/entry/files/
      // const exportDir = `${context.filesDir}/downloaded_pkg`;
      //
      // // 确保目录存在
      // if (!fs.accessSync(exportDir)) {
      //   fs.mkdirSync(exportDir, true);
      // }

      // const finalPath = `${exportDir}/${download.name}`;
      // ========================= 修改结束 =========================

      // 2. 解密后的最终路径 (用于 MD5 校验和后续解压)
      //
      const finalPath = `${context.cacheDir}/${download.name}`;
      console.info('Debug Path - Expecting decrypted file at:', finalPath);
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

          console.log('Download check - Context CacheDir:', context.cacheDir);
          console.log('Download check - Trying to access:', tempPath);
          console.log('Download check - File exists?:', fs.accessSync(tempPath));

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
            await FileUtil.decryptRpk(tempPath, finalPath);
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