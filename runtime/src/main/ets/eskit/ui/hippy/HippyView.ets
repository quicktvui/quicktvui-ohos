import { createHippyEngine, EngineInitParams, EngineInitStatus, HippyEngine, HippyLibrary, HippyRoot } from 'hippy'
import { RuntimeAPIProvider } from '../../../api/RuntimeAPIProvider'
import { QTAPIProvider } from 'quicktvui'
import request from '@ohos.request'
import { BusinessError, zlib } from '@kit.BasicServicesKit'
import { SignUtil } from '../../utils/SignUtil'
import { fileIo as fs } from '@kit.CoreFileKit'
import { FileUtil } from '../../utils/FileUtil'
import { AppContext } from '../../AppContext'
import { LoadStatus } from '../../LoadStatus'


@Component
export struct HippyView {
  @Consume('appContext')
  private appContext: AppContext

  aboutToAppear(): void {
    this.startLoadEsApp()
  }

  private async startLoadEsApp() {
    try {
      const appInfo = await this.fetchAppInfo()
      const download = await this.downloadPackage(appInfo)
      await this.unzip(download.path, this.getAppDir(appInfo))
      // const success = await this.initEngine()
    } catch (error) {
      console.log('发生异常', error)
      this.appContext.loadResult = {
        status: LoadStatus.FAIL,
        exception: this.parseException(error)
      }
    }
  }

  private parseException(error: Error): BusinessError<string> {
    return (error as BusinessError)?.data !== undefined ? error as BusinessError<string> : {
      code: -1,
      data: '未知异常:' + error.message
    } as BusinessError<string>
  }

  private getAppDir(appInfo: AppInfo): string {
    let dir = `${this.abilityContext?.filesDir}/app_rpk/apps/${appInfo.es_package}/${appInfo.tvpackagever}`
    fs.mkdirSync(dir, true)
    return dir
  }

  build() {
    HippyRoot({}).expandSafeArea()
  }

  //region 应用下载

  private fetchAppInfo(): Promise<AppInfo> {
    return new Promise<AppInfo>((resolve, reject) => {
      //   const call = http.createHttp()
      //   call.request(
      //     // 'https://',
      //     {
      //       method: http.RequestMethod.POST,
      //       extraData: this.generateRequestParams()
      //     },
      //     (error: BusinessError, response: http.HttpResponse) => {
      //       console.log('')
      //     })

      resolve({
        es_package: 'es.hello',
        tvpackagever: '1.0.0',
        tvpackage: 'http://192.168.7.7/pub/ohos/test.zip',
        tvpackagemd5: 'c84b9bc578478416b14d59d4dd316f30'
      } as AppInfo)
    })
  }

  private generateRequestParams(): ArrayBuffer {
    let data = this.appContext.data
    const params: Params = {
      // TODO device info
      // channel
      source: '',
      // request app data
      client: {
        es_package: data.packageName,
        es_package_ver: data.versionName,
        clientEsPackageVer: ''
      }
    }
    return SignUtil.encodeWithPublicKey(JSON.stringify(params))
  }

  private downloadPackage(info: AppInfo): Promise<DownloadResult> {
    return new DownloadTask().start(this.abilityContext!, {
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

  //endregion

  //region 引擎创建

  @StorageLink('libHippy') private libHippy: HippyLibrary | null = null
  @StorageLink('abilityContext') private abilityContext: Context | null = null
  private hippyEngine: HippyEngine | null = null

  private initEngine(): Promise<boolean> {
    return new Promise<boolean>((resolve, reject) => {
      this.hippyEngine = createHippyEngine(this.createEngineInitParams())
      this.hippyEngine.initEngine({
        onInitialized: (statusCode: EngineInitStatus, msg: string) => {
          if (statusCode == EngineInitStatus.STATUS_OK) {
            resolve(true)
          } else {
            reject({
              code: statusCode.valueOf(),
              data: msg
            } as BusinessError<string>)
          }
        }
      })
    })
  }

  private createEngineInitParams(): EngineInitParams {
    const params = new EngineInitParams(this.libHippy!, this.abilityContext!, this.getUIContext())
    params.debugMode = false
    params.enableLog = true
    params.enableArkCApi = false
    params.providers = [
      new RuntimeAPIProvider(),
      new QTAPIProvider()
    ]
    return params
  }

  //endregion
}

interface Params {
  source: string
  client: Client
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