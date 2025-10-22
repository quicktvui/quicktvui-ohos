import { TAG_QUICKTVUI } from "../Constant";

export class QTLog {
  static DEBUG = true;
  static setDebug(b : boolean){
    QTLog.DEBUG = b;
  }
  static d(tag:string,message:string){
      if(QTLog.DEBUG){
        console.debug(tag,message)
      }

  }
  static i(tag:string,message:string){
    if(QTLog.DEBUG){
      console.info(tag,message)
    }

  }
  static w(tag:string,message:string){
    if(QTLog.DEBUG){
      console.warn(tag,message)
    }

  }
  static e(tag:string,message:string){
    if(QTLog.DEBUG){
      console.error(tag,message)
    }
  }

  static fatal(tag:string,message:string){
      console.error(tag,message)
  }
}