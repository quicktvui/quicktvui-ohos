import {
  HippyEngineContext,
  HippyAny,
  HippyModulePromise,
  HippyNativeModule,
  LogUtils,
  HippyMap,
} from 'hippy';

import { BaseModule } from './BaseModule';
import { fileIo as fs, ReadOptions } from '@kit.CoreFileKit';
import { buffer } from '@kit.ArkTS';
import QTAppManager from '../quick/QTAppManager';

/**
 * 文件操作模块
 */
@HippyNativeModule({ name: "ESFileModule" })
export class ESFileModule extends BaseModule {
  public static readonly NAME: string = 'ESFileModule'
  public readonly TAG: string = 'ESFileModule'

  constructor(ctx: HippyEngineContext) {
    super(ctx)
  }

  initialize(): void {
  }

  public call(method: string, params: Array<HippyAny>, promise: HippyModulePromise): HippyAny {
    switch (method) {
      //
      case 'open': {
        try {
          const map = params[0] as HippyMap
          const pathname = map.get('pathname') as string
          const rootFilePath =
            QTAppManager.getInstance().getESAppFilePath(this.ctx.getAbilityContext())
          const exists = fs.accessSync(rootFilePath)
          if (!exists) {
            fs.mkdirSync(rootFilePath, true)
          }
          const file =
            fs.openSync(rootFilePath + "/" + pathname, fs.OpenMode.READ_WRITE | fs.OpenMode.CREATE)
          if (promise) {
            promise.resolve(file.fd)
          }
        } catch (error) {
          LogUtils.e(this.TAG, `ESFileModule open error message:${error.message}`);
          if (promise) {
            promise.reject(JSON.stringify(error))
          }
        }
        break;
      }
    //
      case 'newESFile': {
        try {
          const map = params[0] as HippyMap
          const pathname = map.get('pathname') as string
          const rootFilePath = this.ctx.getAbilityContext().filesDir
          const file =
            fs.openSync(rootFilePath + "/" + pathname, fs.OpenMode.READ_WRITE | fs.OpenMode.CREATE)
          if (promise) {
            promise.resolve(file.fd)
          }
        } catch (error) {
          LogUtils.e(this.TAG, `ESFileModule newFile error message:${error.message}`);
          if (promise) {
            promise.reject(JSON.stringify(error))
          }
        }
        break;
      }
    //
      case 'access': {
        try {
          const map = params[0] as HippyMap
          const pathname = map.get('pathname') as string
          const rootFilePath =
            QTAppManager.getInstance().getESAppFilePath(this.ctx.getAbilityContext())
          LogUtils.i(this.TAG,
            `ESFileModule op: access start: ${rootFilePath + "/" + pathname}`);
          const exist = fs.accessSync(rootFilePath + "/" + pathname)
          LogUtils.i(this.TAG,
            `ESFileModule op: access ${rootFilePath + "/" + pathname} ret:${exist}`);
          if (promise) {
            promise.resolve(exist)
          }
        } catch (error) {
          LogUtils.e(this.TAG, `ESFileModule access error message:${error.message}`);
          if (promise) {
            promise.reject(JSON.stringify(error))
          }
        }
        break;
      }
    //
      case 'close': {
        try {
          const map = params[0] as HippyMap
          const fd = map.get('id') as number
          LogUtils.i(this.TAG, `ESFileModule close fd:${fd}`);
          fs.closeSync(fd)
          if (promise) {
            promise.resolve(true)
          }
        } catch (error) {
          LogUtils.e(this.TAG, `ESFileModule close error message:${error.message}`);
          if (promise) {
            promise.reject(JSON.stringify(error))
          }
        }
        break;
      }
    //
      case 'stat': {
        try {
          const map = params[0] as HippyMap
          const pathname = map.get('pathname') as string
          const rootFilePath =
            QTAppManager.getInstance().getESAppFilePath(this.ctx.getAbilityContext())
          const stat: fs.Stat = fs.statSync(rootFilePath + "/" + pathname)
          LogUtils.i(this.TAG,
            `ESFileModule op: stat file: ${rootFilePath + "/" + pathname} ret:${stat}`);
          if (promise) {
            const info = new Map<string, HippyAny>()
            info.set("ino", stat.ino.toString())
            info.set("mode", stat.mode)
            info.set("uid", stat.uid)
            info.set("gid", stat.gid)
            info.set("size", stat.size)
            info.set("atime", stat.atime)
            info.set("mtime", stat.mtime)
            info.set("ctime", stat.ctime)
            info.set("atimeNs", stat.atimeNs?.toString())
            info.set("mtimeNs", stat.mtimeNs?.toString())
            info.set("ctimeNs", stat.ctimeNs?.toString())
            info.set("isBlockDevice", stat.isBlockDevice())
            info.set("isCharacterDevice", stat.isCharacterDevice())
            info.set("isDirectory", stat.isDirectory())
            info.set("isFIFO", stat.isFIFO())
            info.set("isSocket", stat.isSocket())
            info.set("isSymbolicLink", stat.isSymbolicLink())
            promise.resolve(info)
          }
        } catch (error) {
          LogUtils.e(this.TAG, `ESFileModule stat error message:${error.message}`);
          if (promise) {
            promise.reject(JSON.stringify(error))
          }
        }
        break;
      }
    //
      case 'isDirectory': {
        try {
          const map = params[0] as HippyMap
          const pathname = map.get('pathname') as string
          const rootFilePath =
            QTAppManager.getInstance().getESAppFilePath(this.ctx.getAbilityContext())
          const stat: fs.Stat = fs.statSync(rootFilePath + "/" + pathname)
          LogUtils.i(this.TAG, `ESFileModule op: isDirectory file: ${rootFilePath + "/" +
            pathname} ret:${stat.isDirectory()}`);
          if (promise) {
            promise.resolve(stat.isDirectory())
          }
        } catch (error) {
          LogUtils.e(this.TAG, `ESFileModule stat error message:${error.message}`);
          if (promise) {
            promise.reject(JSON.stringify(error))
          }
        }
        break;
      }
    //
      case 'isFile': {
        try {
          const map = params[0] as HippyMap
          const pathname = map.get('pathname') as string
          const rootFilePath =
            QTAppManager.getInstance().getESAppFilePath(this.ctx.getAbilityContext())
          const stat: fs.Stat = fs.statSync(rootFilePath + "/" + pathname)
          LogUtils.i(this.TAG, `ESFileModule op: isDirectory file: ${rootFilePath + "/" +
            pathname} ret:${stat.isFile()}`);
          if (promise) {
            promise.resolve(stat.isFile())
          }
        } catch (error) {
          LogUtils.e(this.TAG, `ESFileModule stat error message:${error.message}`);
          if (promise) {
            promise.reject(JSON.stringify(error))
          }
        }
        break;
      }
    //
      case 'unlink': {
        try {
          const map = params[0] as HippyMap
          const pathname = map.get('pathname') as string
          const rootFilePath =
            QTAppManager.getInstance().getESAppFilePath(this.ctx.getAbilityContext())
          LogUtils.i(this.TAG, `ESFileModule op: unlink path :${rootFilePath + "/" + pathname}`);
          fs.unlinkSync(rootFilePath + "/" + pathname)
          promise.resolve(true)
        } catch (error) {
          LogUtils.e(this.TAG, `ESFileModule unlink error message:${error.message}`);
          if (promise) {
            promise.reject(JSON.stringify(error))
          }
        }
        break;
      }
    //
      case 'mkdir': {
        try {
          const map = params[0] as HippyMap
          const pathname = map.get('pathname') as string
          const recursion = map.get('recursion') as boolean
          const rootFilePath =
            QTAppManager.getInstance().getESAppFilePath(this.ctx.getAbilityContext())
          LogUtils.i(this.TAG, `ESFileModule op: mkdir path :${rootFilePath + "/" + pathname}`);
          fs.mkdirSync(rootFilePath + "/" + pathname, recursion ?? false)
          promise.resolve(true)
        } catch (error) {
          LogUtils.e(this.TAG, `ESFileModule mkdir error message:${error.message}`);
          if (promise) {
            promise.reject(JSON.stringify(error))
          }
        }
        break;
      }
    //
      case 'listFile': {
        try {
          const map = params[0] as HippyMap
          const pathname = map.get('pathname') as string
          const rootFilePath =
            QTAppManager.getInstance().getESAppFilePath(this.ctx.getAbilityContext())
          const files: string[] = fs.listFileSync(rootFilePath + "/" + pathname)
          promise.resolve(files)
        } catch (error) {
          LogUtils.e(this.TAG, `ESFileModule listFile error message:${error.message}`);
          if (promise) {
            promise.reject(JSON.stringify(error))
          }
        }
        break;
      }
    //
      case 'rmdir': {
        try {
          const map = params[0] as HippyMap
          const pathname = map.get('pathname') as string
          const rootFilePath =
            QTAppManager.getInstance().getESAppFilePath(this.ctx.getAbilityContext())
          fs.rmdirSync(rootFilePath + "/" + pathname)
          LogUtils.e(this.TAG,
            `ESFileModule rmdir success. path: ${rootFilePath + "/" + pathname}`);
          promise.resolve(true)
        } catch (error) {
          LogUtils.e(this.TAG, `ESFileModule rmdir error message:${error.message}`);
          if (promise) {
            promise.reject(JSON.stringify(error))
          }
        }
        break;
      }
    //
      case 'moveFile': {
        try {
          const map = params[0] as HippyMap
          const src = map.get('src') as string
          const dest = map.get('dest') as string
          const rootFilePath =
            QTAppManager.getInstance().getESAppFilePath(this.ctx.getAbilityContext())
          LogUtils.e(this.TAG,
            `ESFileModule moveFile file. src: ${rootFilePath + "/" + src}  dest:${rootFilePath +
              "/" + dest}`);

          fs.moveFileSync(rootFilePath + "/" + src, rootFilePath + "/" + dest)
          promise.resolve(true)
        } catch (error) {
          LogUtils.e(this.TAG, `ESFileModule moveFile error message:${error.message}`);
          if (promise) {
            promise.reject(JSON.stringify(error))
          }
        }
        break;
      }
    //
      case 'rename': {
        try {
          const map = params[0] as HippyMap
          const src = map.get('src') as string
          const dest = map.get('dest') as string
          const rootFilePath =
            QTAppManager.getInstance().getESAppFilePath(this.ctx.getAbilityContext())
          LogUtils.e(this.TAG,
            `ESFileModule rename file. src: ${rootFilePath + "/" + src}  dest:${rootFilePath +
              "/" + dest}`);
          fs.renameSync(rootFilePath + "/" + src, rootFilePath + "/" + dest)
          promise.resolve(true)
        } catch (error) {
          LogUtils.e(this.TAG, `ESFileModule rename error message:${error.message}`);
          if (promise) {
            promise.reject(JSON.stringify(error))
          }
        }
        break;
      }
    //
      case 'read': {
        try {
          const map = params[0] as HippyMap
          const pathname = map.get('pathname') as string
          const rootFilePath =
            QTAppManager.getInstance().getESAppFilePath(this.ctx.getAbilityContext())
          const file = fs.openSync(rootFilePath + "/" + pathname, fs.OpenMode.READ_ONLY)
          const arrayBuffer = new ArrayBuffer(1024);
          const readOptions: ReadOptions = {
            offset: 0,
            length: arrayBuffer.byteLength
          };
          const readLen: number = fs.readSync(file.fd, arrayBuffer, readOptions)
          const buf = buffer.from(arrayBuffer, 0, readLen);
          if (promise) {
            promise.resolve(buf.toString())
          }
        } catch (error) {
          LogUtils.e(this.TAG, `ESFileModule read error message:${error.message}`);
          if (promise) {
            promise.reject(JSON.stringify(error))
          }
        }
        break;
      }
    //
      case 'write': {
        try {
          const map = params[0] as HippyMap
          const pathname = map.get('pathname') as string
          const content = map.get('content') as string

          const rootFilePath =
            QTAppManager.getInstance().getESAppFilePath(this.ctx.getAbilityContext())
          const file = fs.openSync(rootFilePath + "/" + pathname, fs.OpenMode.WRITE_ONLY)
          const count: number = fs.writeSync(file.fd, content)
          if (promise) {
            promise.resolve(count)
          }
        } catch (error) {
          LogUtils.e(this.TAG, `ESFileModule write error message:${error.message}`);
          if (promise) {
            promise.reject(JSON.stringify(error))
          }
        }
        break;
      }
      case 'getPath': {
        try {
          const map = params[0] as HippyMap
          const pathname = map.get('pathname') as string
          if (promise) {
            promise.resolve(pathname)
          }
        } catch (error) {
          LogUtils.e(this.TAG, `ESFileModule getPath error message:${error.message}`);
          if (promise) {
            promise.reject(JSON.stringify(error))
          }
        }
        break;
      }
      case 'getAbsolutePath': {
        try {
          const map = params[0] as HippyMap
          const pathname = map.get('pathname') as string
          const rootFilePath =
            QTAppManager.getInstance().getESAppFilePath(this.ctx.getAbilityContext())
          if (promise) {
            promise.resolve(rootFilePath + "/" + pathname)
          }
        } catch (error) {
          LogUtils.e(this.TAG, `ESFileModule getPath error message:${error.message}`);
          if (promise) {
            promise.reject(JSON.stringify(error))
          }
        }
        break;
      }
      default:
        super.call(method, params, promise);
    }
    return null;
  }
}
