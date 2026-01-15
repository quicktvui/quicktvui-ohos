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
import BuildProfile from 'BuildProfile';

export class ApiAppLoader implements AppLoader {
  private data: EsData;

  constructor(data: EsData) {
    this.data = data
    console.info(`ApiAppLoader: data: ${JSON.stringify(data)}`);
  }

  /**
   * 主流程：获取信息 -> 检查本地多版本MD5 -> (清理/下载) -> 解压
   */
  async startLoad(): Promise<void> {
    try {
      console.info('ApiAppLoader: 开始请求应用信息...');
      const appInfo = await this.fetchAppInfo();

      this.data.appId = appInfo.es_package
      this.data.appVersion = appInfo.tvpackagever

      // 1. 获取该包名的根目录 (例如: .../files/app_rpk/apps/com.example.pkg)
      //    注意：这里不包含具体的版本号
      const packageRootDir = `${App.instance.context?.filesDir}/app_rpk/apps/${appInfo.es_package}`;
      const targetMd5 = appInfo.tvpackagemd5;

      let isCached = false;
      let cachedDir = '';

      // --- 新增逻辑：遍历包名下的所有版本目录，查找是否存在匹配的MD5文件 ---
      try {
        if (fs.accessSync(packageRootDir)) {
          const subFiles = fs.listFileSync(packageRootDir);

          for (const fileName of subFiles) {
            // 假设子文件是文件夹（版本号），构建潜在的MD5标记文件路径
            // 路径格式: .../apps/{包名}/{版本号}/{MD5值}
            const potentialVersionDir = `${packageRootDir}/${fileName}`;
            const potentialMd5File = `${potentialVersionDir}/${targetMd5}`;

            // 判断是否是文件夹且包含对应的MD5文件
            let hasMd5Marker = false;
            try {
              if (fs.statSync(potentialVersionDir).isDirectory() && fs.accessSync(potentialMd5File)) {
                hasMd5Marker = true;
              }
            } catch (e) {
              // 忽略访问异常
            }

            if (hasMd5Marker) {
              // ========================= 核心修复开始 =========================
              // 不仅要看MD5标记，还要检查关键内容 dist 目录是否存在
              const distDir = `${potentialVersionDir}/dist`;
              let isContentValid = false;
              try {
                if (fs.accessSync(distDir)) {
                  isContentValid = true;
                }
              } catch (e) {
                // dist 不存在或无法访问
              }

              if (isContentValid) {
                console.info(`ApiAppLoader: ✅ 在本地版本 [${fileName}] 中找到匹配MD5且内容完整: ${targetMd5}`);
                isCached = true;
                cachedDir = potentialVersionDir;
                // 暂时保持使用服务端返回的 versionName
                break;
              } else {
                console.warn(`ApiAppLoader: ⚠️ 发现损坏的缓存 (MD5存在但dist缺失): ${fileName}，将忽略并重新下载`);
                // 为了保险，尝试删除这个错误的标记文件，避免干扰
                try { fs.unlinkSync(potentialMd5File); } catch (e) {}
              }
              // ========================= 核心修复结束 =========================
            }
          }
        }
      } catch (e) {
        console.warn('ApiAppLoader: 检查本地缓存时出错 (可能目录不存在):', e);
      }

      // --- 决策分支 ---
      if (isCached) {
        console.info(`ApiAppLoader: 本地缓存校验通过，跳过下载。目标路径: ${cachedDir}`);

        // 【新增调用 1】: 如果命中缓存，打印缓存中的 dist 文件
        this.printDistFiles(cachedDir);

        console.info('ApiAppLoader: 加载流程全部完成');
        return; // 直接结束
      } else {
        console.info(`ApiAppLoader: 未在任何版本中找到匹配且完整的缓存，执行全量清理并重新下载`);
        // 删除整个包名目录 (清理所有旧版本)
        FileUtil.deleteDir(packageRootDir);
      }
      // -------------------------------------------------------------

      console.info(`ApiAppLoader: 获取信息成功，准备下载: ${appInfo.tvpackage}`);
      const download = await this.downloadPackage(appInfo);

      console.info(`ApiAppLoader: 下载并校验MD5成功，路径: ${download.path}`);

      // 重新获取具体版本的目标路径 (因为上面可能删除了，这里 getAppDir 会负责逻辑上的路径构建)
      // 注意：getAppDir 内部判断了 exists 则不创建，但我们上面 deleteDir 了，所以这里要在 unzip 前确保父目录存在
      const targetDir = this.getAppDir(appInfo);

      console.info(`ApiAppLoader: 开始解压到: ${targetDir}`);
      await this.unzip(download.path, targetDir);

      // --- 逻辑补充：解压完成后，写入MD5文件作为标记 ---
      try {
        const markerPath = `${targetDir}/${appInfo.tvpackagemd5}`;
        const file = fs.openSync(markerPath, fs.OpenMode.CREATE | fs.OpenMode.READ_WRITE);
        fs.closeSync(file);
        console.info(`ApiAppLoader: MD5标记文件已创建: ${markerPath}`);
      } catch (e) {
        console.error('ApiAppLoader: 创建MD5标记文件失败:', e);
      }
      // ---------------------------------------

      console.info('ApiAppLoader: 最终解压文件夹路径:', targetDir);

      // 【新增调用 2】: 下载解压完成后，打印新生成的 dist 文件
      this.printDistFiles(targetDir);

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
    console.info('ApiAppLoader: fetchAppInfo appBundleUri:', this.data.appBundleUri);
    return new Promise<AppInfo>((resolve, reject) => {
      const call = http.createHttp();
      call.request(
        this.data.appBundleUri,
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
            console.error('ApiAppLoader Http Request Failed:', JSON.stringify(error));
            reject(error);
            return;
          }

          if (response.responseCode !== 200) {
            reject(`ApiAppLoader Http Error Code: ${response.responseCode}`);
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
                reject(`ApiAppLoader Server Business Error: ${jsonResult.msg || 'Unknown'}`);
              }
            } catch (e) {
              console.error('ApiAppLoader Parse/Decode Error:', e);
              reject('ApiAppLoader Response parse failed');
            }
          } else {
            reject('ApiAppLoader Invalid response type');
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
        es_package: this.data.appId!,
        es_package_ver: this.data.appVersion || '',
        clientEsPackageVer: ''
      }
    };
    console.log('ApiAppLoader fetchAppInfo params: ' + JSON.stringify(params))
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
    // 如果目录不存在，创建它 (包括父目录)
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
    if (!App.instance.context || !this.data.appId || !this.data.appVersion) {
      console.warn('ApiAppLoader: Context or Package info missing when getting vendor file');
      return '';
    }

    // 2. 构建基础目录 (需与 getAppDir 逻辑保持一致)
    // 路径: /data/storage/.../files/app_rpk/apps/com.example/1.0.0
    const baseDir = `${App.instance.context.filesDir}/app_rpk/apps/${this.data.appId}/${this.data.appVersion}`;

    // 3. 拼接 dist/vendor.js
    const filePath = `${baseDir}/dist/vendor.js`;

    try {
      // accessSync 如果文件不存在会抛出异常，所以如果跑通了就是存在
      fs.accessSync(filePath);
      console.debug(`[ApiAppLoader] ✅ vendor.js exists at: ${filePath}`);
    } catch (e) {
      console.error(`[ApiAppLoader] ❌ vendor.js NOT FOUND at: ${filePath}`);
    }

    return filePath;
  }

  /**
   * 获取 index.js 的绝对路径
   * 路径规则: filesDir/app_rpk/apps/{包名}/{版本号}/dist/index.js
   */
  getIndexJsFile(): string {
    // 1. 安全检查
    if (!App.instance.context || !this.data.appId || !this.data.appVersion) {
      console.warn('ApiAppLoader: Context or Package info missing when getting index file');
      return '';
    }

    // 2. 构建基础目录
    const baseDir = `${App.instance.context.filesDir}/app_rpk/apps/${this.data.appId}/${this.data.appVersion}`;

    // 3. 拼接 dist/index.js
    const filePath = `${baseDir}/dist/index.js`;

    try {
      fs.accessSync(filePath);
      console.debug(`[ApiAppLoader] ✅ index.js exists at: ${filePath}`);
    } catch (e) {
      console.error(`[ApiAppLoader] ❌ index.js NOT FOUND at: ${filePath}`);
    }
    return filePath;
  }


  /**
   * [新增方法] 打印指定版本目录下 dist 文件夹内的文件列表和大小
   * @param appVersionDir 应用的版本根目录 (例如: .../apps/com.pkg/1.0.0)
   */
  /**
   * [调试专用] 打印解压目录下的真实结构
   */
  private printDistFiles(appVersionDir: string) {
    if (!BuildProfile.DEBUG) {
      return
    }
    console.info(`================= [Debug 文件结构分析] =================`);
    console.info(`检查目标根路径: ${appVersionDir}`);

    try {
      if (!fs.accessSync(appVersionDir)) {
        console.error(`❌ 严重错误: 版本根目录不存在! ${appVersionDir}`);
        return;
      }

      // 1. 打印根目录下的第一层内容 (看看是不是多了一层文件夹)
      const rootFiles = fs.listFileSync(appVersionDir);
      console.info(`📂 根目录包含 [${rootFiles.length}] 个项目: ${JSON.stringify(rootFiles)}`);

      if (rootFiles.length === 0) {
        console.warn(`⚠️ 警告: 根目录是空的！解压可能失败了，或者ZIP包是空的。`);
        return;
      }

      // 2. 尝试寻找 dist (原本的逻辑)
      const distPath = `${appVersionDir}/dist`;
      if (fs.accessSync(distPath)) {
        console.info(`✅ 成功发现 dist 目录: ${distPath}`);
        const distFiles = fs.listFileSync(distPath);
        console.info(`   dist 目录下包含: ${JSON.stringify(distFiles)}`);
      } else {
        console.warn(`❌ 在根目录下未找到 'dist' 文件夹。`);

        // 3. 智能推测：如果根目录下只有一个文件夹，打印那个文件夹里的内容
        if (rootFiles.length === 1) {
          const subDirName = rootFiles[0];
          const subDirPath = `${appVersionDir}/${subDirName}`;
          if (fs.statSync(subDirPath).isDirectory()) {
            console.info(`💡 提示: 发现唯一的子文件夹 [${subDirName}]，正在查看其内部...`);
            const subFiles = fs.listFileSync(subDirPath);
            console.info(`   [${subDirName}] 内部包含: ${JSON.stringify(subFiles)}`);

            if (subFiles.includes('dist')) {
              console.error(`🔥 结论: 目录结构多了一层！实际路径应该是: .../${subDirName}/dist`);
            }
          }
        }
      }

    } catch (e) {
      console.error(`[Debug] 文件结构分析发生异常:`, e);
    }
    console.info(`=======================================================`);
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
    }
    try {
      const fileMd5 = await FileUtil.calFileMd5(path);
      console.info(`MD5 Check - Expect: ${expectMd5}, Actual: ${fileMd5}`);
      return fileMd5.toLowerCase() === expectMd5.toLowerCase();
    } catch (e) {
      console.error('Calculate MD5 failed:', e);
      return false;
    }
  }

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
      this.task.off('failed');
      this.task.off('completed');
      this.task = null;
    }
  }
}