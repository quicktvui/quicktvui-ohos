import { TAG_CLICK, TAG_FASTLIST, TAG_FOCUS } from "../Constant";
import { QTView } from "../QTTypes";
import { FocusFinder } from "../utils/FocusFinder";
import { QTLog } from "../utils/QTLog";
import { QTBaseComponentView } from "./QTBaseComponentView";
import { KeyCode } from "@kit.InputKit";
import { FocusUtils } from "../utils/FocusUtils";
import { TVView } from "./TVView";

export class FocusManager{

  rootView : QTView
  private focusedView : TVView | null = null;
  uiContext: UIContext | null = null;

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

  focusSearchInDescendants(focused: TVView | null , direction : number) : TVView | null{
    for (let i = 0; i < this.rootView.children.length; i++) {
      let child = this.rootView.children[i]
      if(child  instanceof  QTBaseComponentView){
        let nextFocus = child.focusSearch(focused,direction)
        if(nextFocus != null){
          return nextFocus;
        }
      }
    }
    return null;
  }

  dispatchKeyEvent(event: KeyEvent) : boolean{
    if(!this.uiContext){
      QTLog.e(TAG_FOCUS,`dispatchKeyEvent error uiContext null`)
      return false;
    }
    if(event.type == KeyType.Down){
      let direction = FocusManager.getDirectionByKeyCode(event.keyCode)
      if(direction > 0){
        let nextFocus : TVView | null = null;
        nextFocus = this.focusSearchInDescendants(this.focusedView,direction);
        if(!nextFocus){
          nextFocus = FocusFinder.findNextFocus(this.focusedView,this.rootView,direction)
        }
        QTLog.i(TAG_FOCUS,`dispatchKeyEvent curentFocus:${this.focusedView?.uid} ,find nextFocus :${nextFocus?.uid}`)
        if(nextFocus){
          FocusUtils.requestFocusById(nextFocus.uid)
          this.focusedView = nextFocus;
        }
        return true;
      }
    }
    return false;
  }

  setFocusedView(view : TVView | null){
    this.focusedView = view;
  }

  getFocusedView() : TVView | null{
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