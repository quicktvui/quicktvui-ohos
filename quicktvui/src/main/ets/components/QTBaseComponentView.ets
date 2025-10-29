import { NodeContent } from '@kit.ArkUI'
import {
  NativeRenderContext,
  HippyAny,
  HippyCustomComponentView,
  HippyRenderCallback,
} from 'hippy'
import { HRValueUtils } from '../HRValueUtils';
import { QTView } from '../QTTypes';
import { LayoutAttach } from './fastlist/LayoutAttach';
import { QTActorHost } from './QTActorHost';
import { QTViewActor } from './QTViewActor';
import { QTVirtualView } from './QTVirtualView';

export class QTBaseComponentView extends HippyCustomComponentView  implements  QTActorHost,QTVirtualView{
  childSlot: NodeContent | null = null
  public templateView : QTView | null = null;
  qtPadding: Padding = { top: 0, right: 0, bottom: 0, left: 0 }
  public isVirtual : boolean = false;

  // TV扩展
  visibility: Visibility = Visibility.Visible
  sid: string = ''
  name: string = ''
  selected: boolean = false
  showonstate: string = 'normal'
  focus: boolean = false
  visible: boolean = false
  border: BorderOptions = {}   //模拟selected选中效果


  constructor(ctx: NativeRenderContext) {
    super(ctx)
  }

  notifyChildSizeChanged(child: QTView, changedView: QTView, width: number, height: number): void {
    this.viewActor.notifyChildSizeChanged(child,changedView, width, height)
  }

  public viewActor: QTViewActor =  new QTViewActor(this);

  onCreateByTemplate(templateView : QTView){

  }

  aboutToUpdate(){

  }

  isEventClick() : boolean{
    return this.isVirtual && LayoutAttach.obtainLayoutAttach(this).virtualExtra.eventClick
  }

  setProp(propKey: string, propValue: HippyAny): boolean {
    // console.info(TAG_QUICKTVUI,`QTRenderBaseView setProp:${propKey},propValue:${propValue}`)
    switch (propKey){
      case 'sid':
        let sid = HRValueUtils.getString(propValue)
        LayoutAttach.obtainLayoutAttach(this).sid = sid
        if(sid){
          this.sid = sid;
        }else{
          this.sid = ''
        }
        return true;
      case 'name':
        let name = HRValueUtils.getString(propValue)
        LayoutAttach.obtainLayoutAttach(this).name = name
        if(name){
          this.name = name;
        }else{
          this.name = ''
        }
        return true;
      case "clipChildren":
        this.cssOverflow = HRValueUtils.getBoolean(propValue,true)
        return true;
    }
    return super.setProp(propKey, propValue)
  }


  call(method: string, params: Array<HippyAny>, callback: HippyRenderCallback | null): void {
    //
    if (method == "getEsInfo") {
      if (callback) {
        const info = new Map<string, HippyAny>()
        callback(info)
      }
    }
  }
}
