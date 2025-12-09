import { TAG_FASTLIST, TAG_FOCUS } from "../Constant";
import { QTView } from "../QTTypes";
import { ExtendUtil } from "../utils/ExtendUtil";
import { FocusFinder } from "../utils/FocusFinder";
import { QTLog } from "../utils/QTLog";
import { QTBaseComponentView } from "./QTBaseComponentView";
import { KeyCode } from "@kit.InputKit";
import { FocusUtils } from "../utils/FocusUtils";

export class FocusManager{

  rootView : QTView
  private focusedView : QTView | null = null;
  constructor(rootView: QTView) {
    this.rootView = rootView;
  }

  static getDirectionByKeyCode(keyCode:number) : number{
      switch (keyCode){
        case KeyCode.KEYCODE_DPAD_LEFT:
          return FocusFinder.DIRECTION_LEFT;
        case KeyCode.KEYCODE_DPAD_RIGHT:
          return FocusFinder.DIRECTION_RIGHT;
        case KeyCode.KEYCODE_DPAD_UP:
          return FocusFinder.DIRECTION_UP;
        case KeyCode.KEYCODE_DPAD_DOWN:
          return FocusFinder.DIRECTION_DOWN;
      }
      return -1;
  }

  dispatchKeyEvent(event: KeyEvent) : boolean{
    if(event.type == KeyType.Down){
      let direction = FocusManager.getDirectionByKeyCode(event.keyCode)
      if(direction > 0){
        let nextFocus = FocusFinder.findNextFocus(this.focusedView,this.rootView,direction)
        if(nextFocus){
          FocusUtils.requestFocus(nextFocus)
          this.focusedView = nextFocus;
        }
        QTLog.i(TAG_FOCUS,`dispatchKeyEvent find nextFocus :${ExtendUtil.debugView(nextFocus)}`)
        return true;
      }
    }
    return false;
  }

  setFocusedView(view : QTView | null){
    this.focusedView = view;
  }

  getFocusedView() : QTView | null{
    return this.focusedView;
  }

  static dispatchKeyEvent(view : QTView ,event : KeyEvent) : boolean {
    if(view instanceof  QTBaseComponentView){
      if(view.dispatchKeyEvent(event)){
        return true;
      }
    }

    if(view.children){
      for(let i = 0; i < view.children.length; i ++){
        if(FocusManager.dispatchKeyEvent(view.children[i],event)){
          return true;
        }
      }

    }
    return false;
  }
}