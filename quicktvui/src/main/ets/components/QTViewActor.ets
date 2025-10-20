import { QTAny, QTBaseView, QTView } from "../QTTypes"
import { QTPixelUtil } from "../utils/QTPixelUtil"
import { LayoutAttach } from "./fastlist/LayoutAttach"
import {HippyRenderBaseView} from 'hippy'
import { TAG_QUICKTVUI } from "../Constant"
import { QTAttach } from "./QTAttach"

export class QTViewActor{
  constructor(hostView: HippyRenderBaseView) {
    this.hostView = hostView
  }

  //add by zhaopeng@quicktvui 添加attach方便扩展
  attachedInfo : QTAttach | null = null;

  hostView : QTView

  notifyChildSizeChanged(child:QTView,changedView:QTView,width: number, height: number){
    let la = LayoutAttach.findLayoutAttach(this.hostView)
    if(la){
      if(la.isAutoWidth){
        la.setFixedWidth(child.cssWidth + la.getPaddingLeft() + la.getPaddingRight())
        QTPixelUtil.setRenderViewLayout(this.hostView,[this.hostView.cssPositionX,this.hostView.cssPositionY,la.fixedWidth,this.hostView.cssHeight])
      }
      if(la.isAutoHeight){
        la.setFixedHeight(child.cssHeight + la.getPaddingTop() + la.getPaddingBottom())
        QTPixelUtil.setRenderViewLayout(this.hostView,[this.hostView.cssPositionX,this.hostView.cssPositionY,this.hostView.cssWidth,la.fixedHeight])
      }
    }
    if(this.hostView?.parentView){
      let parent = this.hostView.parentView  as QTBaseView
      if(parent){
        console.log(TAG_QUICKTVUI,'notifyChildSizeChanged by QTActorHost')
        parent.notifyChildSizeChanged?.(this.hostView,changedView,width,height)
      }
    }

  }





}

