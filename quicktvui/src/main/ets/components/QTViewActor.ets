import { QTAny, QTBaseView, QTView } from "../QTTypes"
import { LayoutAttach } from "./fastlist/LayoutAttach"
import {HippyRenderBaseView} from 'hippy'
import { TAG_FASTLIST, TAG_FOCUS, TAG_LAYOUT, TAG_QUICKTVUI } from "../Constant"
import { QTAttach } from "./QTAttach"
import { ExtendUtil } from "../utils/ExtendUtil"
import { QTLog } from "../utils/QTLog"
import { TVView } from "./TVView"
import { QTBaseComponentView } from "./QTBaseComponentView"

export class QTViewActor{

  constructor(hostView: HippyRenderBaseView) {
    this.hostView = hostView
  }

  //add by zhaopeng@quicktvui 添加attach方便扩展
  attachedInfo : QTAttach | null = null;

  hostView : QTView

  notifyChildSizeChanged(child:QTView,changedView:QTView,childWidth: number, childHeight: number){
    let la = LayoutAttach.findLayoutAttach(this.hostView)
    let width = childWidth
    let height = childHeight
    if(la){
      if(la.isAutoWidth && la.isAutoHeight){
        la.setFixedWidth(childWidth + la.getPaddingLeft() + la.getPaddingRight())
        la.setFixedHeight(childHeight + la.getPaddingTop() + la.getPaddingBottom())
        width= la.fixedWidth
        height = la.fixedHeight
      }else{
        if(la.isAutoWidth || (!la.getStyleWidth()) || la.getStyleWidth() < 1 ){
          la.setFixedWidth(childWidth + la.getPaddingLeft() + la.getPaddingRight())
          width = la.fixedWidth
        }
        if(la.isAutoHeight || (!la.getStyleHeight()) || la.getStyleHeight() < 1){
          la.setFixedHeight(childHeight + la.getPaddingTop() + la.getPaddingBottom())
          height = la.fixedHeight
        }
      }
    }
    if(this.hostView?.parentView){
      let parent = this.hostView.parentView  as QTBaseView
      if(parent){
        parent.notifyChildSizeChanged?.(this.hostView,changedView,width,height)
      }else{
        QTLog.w(TAG_LAYOUT,`notifyChildSizeChanged 2 return on parent invalid:${ExtendUtil.debugView(this.hostView)},parent:${ExtendUtil.debugView(this.hostView?.parentView)}`)
      }
    }else{
      // QTLog.w(TAG_LAYOUT,`notifyChildSizeChanged return on parent invalid:${ExtendUtil.debugView(this.hostView)},parent:${ExtendUtil.debugView(this.hostView?.parentView)}`)
    }

  }

  addFocusables(views: TVView[],direction:number) : boolean{
    //FocusUtils.requestFocus(this.hostView)
    let view = this.hostView
    let canTakeFocus = view.cssFocusable
    if(canTakeFocus ){
      if(this.hostView instanceof QTBaseComponentView){
        if(this.hostView.isAttached){
          QTLog.d(TAG_FOCUS,`addFocusables by view Actor this : ${ExtendUtil.debugView(this.hostView)}`)
          if(this.hostView.descendantFocusability != 2){
            views.push(this.hostView)
          }
        }else{
          QTLog.w(TAG_FOCUS,`addFocusables return on detached  this : ${ExtendUtil.debugView(this.hostView)}`)
        }
      }else{
        QTLog.w(TAG_FOCUS,`addFocusables canTakeFocus reutrn  this : ${ExtendUtil.debugView(this.hostView)}`)
      }

      return true;
    }
    return false;
  }





}

