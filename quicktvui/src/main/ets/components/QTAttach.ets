import {HippyAny,HippyRenderBaseView} from 'hippy'
import { QTAny, QTView } from '../QTTypes';
import { ExtendUtil } from '../utils/ExtendUtil';

export class QTAttach{
  sid: string | null = null;
  name: string | null = null;
  viewType:string | null = null;
  private extra: Map<string,QTAny> | null = null;

  putExtra(key:string,value:QTAny){
    if(!this.extra){
      this.extra = new Map();
    }
    this.extra.set(key,value)
  }

  getExtra(key:string){
    return this.extra == null ? null :  this.extra.get(key);
  }

  public static findQTAttach(renderView:QTView) : QTAttach | null{
    let viewActor = ExtendUtil.findViewActor(renderView)
    if(viewActor){
      if(viewActor.attachedInfo instanceof QTAttach){
        return viewActor.attachedInfo;
      }
    }
    return null;
  }
}
