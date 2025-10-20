import {HippyAny,HippyRenderBaseView,EventDispatcher,HREventUtils,NativeRenderContext} from 'hippy'
import { QTAttach } from '../components/QTAttach';
import { QTViewActor } from '../components/QTViewActor';
import { QTView } from '../QTTypes';
import { QTCompatUtil } from './QTCompatUtil';

export class ExtendUtil{
  static debugView(view:QTView | null) : string{
    if(view  == null ){
      return 'null'
    }
    let className = view.viewType;
    let sid = 'null'
    let name = 'null'
    let attach = QTAttach.findQTAttach(view);
    if(attach){
      if(attach.sid){
        sid = attach.sid;
      }
      if(attach.name){
        name = attach.name;
      }
    }
    let desc = -1;
    return `${className}{ ${view.tag} ${sid} ${name} [${view.cssPositionX},${view.cssPositionY},${view.cssWidth},${view.cssHeight}] [${view.cssVisibility}] }
    `
  }

  static sendUIEvent(ctx: NativeRenderContext,nodeId:number,eventName:string,params:HippyAny){
    HREventUtils.sendComponentEvent(ctx,nodeId,eventName,params)
  }
  static sendViewEvent(view:QTView,eventName:string,params:HippyAny){
    HREventUtils.sendComponentEvent(view.ctx,view.tag,eventName,params)
  }

  static findViewActor(view : QTView | null): QTViewActor | undefined {
     return QTCompatUtil.getQTBaseView(view)?.viewActor
  }


}
