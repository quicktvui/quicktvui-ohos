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
import util from '@ohos.util';


export class ApiAppLoader implements AppLoader {
  private data: EsData;

  constructor(data: EsData) {
    this.data = data
  }

  async startLoad(): Promise<void> {
    const appInfo = await this.fetchAppInfo()
    const download = await this.downloadPackage(appInfo)
    await this.unzip(download.path, this.getAppDir(appInfo))
  }

  private fetchAppInfo(): Promise<AppInfo> {
    const data = this.generateRequestParams()
    return new Promise<AppInfo>((resolve, reject) => {
      const call = http.createHttp()
      call.request(
        'https://api.extscreen.com/extscreenapi/api/extend_screen/v2/hili/client/tvinfo',
        {
          method: http.RequestMethod.POST,
          extraData: new Uint8Array(data).buffer,
          header: {
            'Content-Type': 'application/octet-stream', // 通用二进制类型
          },
          expectDataType: http.HttpDataType.ARRAY_BUFFER  // 如果期望二进制响应
        },
        (error: BusinessError, response: http.HttpResponse) => {
          const result = response.result
          if (typeof result === 'string') {
            //TODO
            return
          }
          if (result instanceof ArrayBuffer) {
            console.log('===================结果======START========>>>>:', result.byteLength)
            const ret = SignUtil.decodeWithPublicKey(result)
            console.log('===================结果======END========>>>>:', ret)
            return
          }
          console.log('object result:', JSON.stringify(result))
        })

      resolve({
        es_package: 'es.hello.world',
        tvpackagever: '1.0.0',
        tvpackage: 'http://192.168.7.7/pub/ohos/test.zip',
        tvpackagemd5: 'c84b9bc578478416b14d59d4dd316f30'
      } as AppInfo)
    })
  }

  private arrayBufferToString(buffer: ArrayBuffer): string {
    return new util.TextDecoder('utf-8').decode(
      new Uint8Array(buffer)
    )
  }

  private generateRequestParams(): ArrayBuffer {
    const params: Params = {
      // TODO device info
      // channel
      source: '',
      sdk_ver: '2.61',
      // request app data
      client: {
        es_package: this.data.packageName!,
        es_package_ver: this.data.versionName || '',
        clientEsPackageVer: ''
      }
    }
    return SignUtil.encodeWithPublicKey(JSON.stringify(params))
  }

  private downloadPackage(info: AppInfo): Promise<DownloadResult> {
    return new DownloadTask().start(App.instance.context!, {
      name: info.es_package + '.zip',
      url: info.tvpackage,
      md5: info.tvpackagemd5
    })
  }

  private unzip(file: string, path: string): Promise<void> {
    return new Promise<void>(async (resolve, reject) => {
      await zlib.decompressFile(file, path, {
        level: zlib.CompressLevel.COMPRESS_LEVEL_DEFAULT_COMPRESSION
      })
    })
  }

  private getAppDir(appInfo: AppInfo): string {
    let dir = `${App.instance.context?.filesDir}/app_rpk/apps/${appInfo.es_package}/${appInfo.tvpackagever}`
    fs.mkdirSync(dir, true)
    return dir
  }

  getAppName(): string {
    return '';
  }

  getAppIcon(): string {
    return ''
  }

  getVendorJsFile(): string {
    return ''
  }

  getIndexJsFile(): string {
    return ''
  }
}

interface Params {
  source: string
  client: Client
  sdk_ver: string
}

interface Client {
  es_package: string
  es_package_ver: string
  clientEsPackageVer: string
}

interface AppInfo {
  es_package: string // 包名
  tvpackage: string // 下载链接
  tvpackagever: string
  tvpackagemd5: string
}

class DownloadTask {
  private task: request.agent.Task | null = null

  start(context: Context, download: Download): Promise<DownloadResult> {
    return new Promise<DownloadResult>(async (resolve, reject) => {
      let path = context.cacheDir + `/${download.name}.part`
      try {
        this.task = await request.agent.create(context, {
          action: request.agent.Action.DOWNLOAD,
          url: download.url,
          mode: request.agent.Mode.BACKGROUND,
          network: request.agent.Network.ANY,
          overwrite: true,
          saveas: path
        } as request.agent.Config)

        this.task.on('failed', async (progress: request.agent.Progress) => {
          this._release()
          let ti = await request.agent.show(this.task!.tid)
          reject({
            code: -3001,
            data: ti.reason
          } as BusinessError<string>)
        })
        this.task.on('completed', async (progress: request.agent.Progress) => {
          this._release()
          let matched = await this.checkMd5(download.md5, path)
          if (!matched) {
            await fs.unlink(path)
            reject({
              code: -3003,
              data: 'md5 mismatch'
            } as BusinessError<string>)
            return
          }
          let zipPath = context.filesDir + `/${download.name}`
          await fs.rename(path, zipPath)
          resolve({
            path: zipPath
          })
        })
        await this.task.start()
      } catch (error) {
        this._release()
        reject({
          code: -3002,
          data: error.message
        } as BusinessError<string>)
      }
    })
  }

  private async checkMd5(md5: string, path: string) {
    return await FileUtil.calFileMd5(path) == md5
  }

  private _release() {
    this.task?.off('failed')
    this.task?.off('completed')
    this.task = null
  }
}

interface Download {
  url: string
  name: string
  md5: string
}

interface DownloadResult {
  path: string
}