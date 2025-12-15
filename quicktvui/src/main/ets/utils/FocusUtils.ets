import { TAG_FASTLIST, TAG_FOCUS } from "../Constant";
import { QTView } from "../QTTypes";
import { ExtendUtil } from "./ExtendUtil";
import { QTLog } from "./QTLog";
import { ViewUtils } from "./ViewUtils";

export class FocusUtils{

    static requestFocus(view : QTView | null | undefined){
        let uid = ViewUtils.getViewUid(view)
        if(uid){
          QTLog.e(TAG_FOCUS,`exe requestFocus view :${ExtendUtil.debugView(view)}`)
          focusControl.requestFocus(uid)
        }else{
          QTLog.e(TAG_FOCUS,`requestFocus fail uid is null view :${ExtendUtil.debugView(view)}`)
        }
      }

  static requestFocusById(uid : string | null | undefined){
    if(uid){
      QTLog.e(TAG_FOCUS,`exe requestFocus view :${uid}`)
      focusControl.requestFocus(uid)
    }else{
      QTLog.e(TAG_FOCUS,`requestFocus fail uid is null view :${uid}`)
    }
  }
}