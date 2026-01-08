import { PageManager } from "../components/router/PageManager";
import { TVView } from "../components/TVView";
import { TAG_FASTLIST, TAG_FOCUS } from "../Constant";
import { QTView } from "../QTTypes";
import { ExtendUtil } from "./ExtendUtil";
import { FocusFinder } from "./FocusFinder";
import { QTLog } from "./QTLog";
import { ViewUtils } from "./ViewUtils";

export class FocusUtils{

    static FOCUS_BEFORE_DESCENDANTS : number = 0
    static FOCUS_AFTER_DESCENDANTS : number = 1
    static FOCUS_BLOCK_DESCENDANTS : number = 2

    static requestFocus(view : QTView | null | undefined){
        let uid = ViewUtils.getViewUid(view)
        if(uid){
          let b = focusControl.requestFocus(uid)
          if(!b){
            QTLog.fatal(TAG_FOCUS,`exe requestFocus view :${ExtendUtil.debugView(view)} success:${b} uid:${uid}`)
          }else{
            QTLog.e(TAG_FOCUS,`exe requestFocus view :${ExtendUtil.debugView(view)} success:${b} uid:${uid}`)
          }
        }else{
          QTLog.fatal(TAG_FOCUS,`requestFocus fail uid is null view :${ExtendUtil.debugView(view)}`)
        }
      }

  static requestFocusById(uid : string | null | undefined) : boolean {
    if(uid){
      let b =  focusControl.requestFocus(uid)
      if(b){
        QTLog.e(TAG_FOCUS,`exe requestFocusById view uid:${uid} success:${b}`)
      }else{
        QTLog.fatal(TAG_FOCUS,`exe requestFocusById view uid:${uid} success:${b}`)
      }
      return b;
    }else{
      QTLog.fatal(TAG_FOCUS,`requestFocus fail uid is null view :${uid}`)
    }
    return false;
  }

  static requestViewGroupFocus(view : QTView | null | undefined,delay = 0){
      if(!view){
        return
      }
      QTLog.e(TAG_FOCUS,`requestViewGroupFocus focusable:${view.cssFocusable} ,this :`+ExtendUtil.debugView(view))
      //focusControl.requestFocus(ViewUtils.getViewUid(this));
      // this.getFocusManager()
      setTimeout(()=>{
        if(view.cssFocusable){
          FocusUtils.requestFocus(view)
        }else{
          let focusManager = PageManager.getPageHost(view)?.focusManager
          let nextFocus = focusManager?.findNextFocusWithFocused(view, FocusFinder.DIRECTION_DOWN,null)
          if(nextFocus){
            FocusUtils.requestFocusById(nextFocus.uid)
          }
        }
      },delay)
    }

    static focusSearchInViewGroup(root : QTView | null,focused :TVView | null,direction : number) : TVView | null | undefined{
      if(!root){
        return null;
      }
      let focusManager = PageManager.getPageHost(root)?.focusManager
      let nextFocus = focusManager?.findNextFocusWithFocused(root, direction,focused)
      return nextFocus;
    }

    static blockRootFocus(requestView : QTView){
      QTLog.w(TAG_FOCUS,`+++blockRootFocus called requestView:${ExtendUtil.debugView(requestView)}`)
    }

    static unBlockRootFocus(requestView: QTView){
      QTLog.e(TAG_FOCUS,`+++unBlockRootFocus called requestView:${ExtendUtil.debugView(requestView)}`)
    }

}