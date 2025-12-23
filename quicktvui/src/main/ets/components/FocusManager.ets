import { TAG_CLICK, TAG_FASTLIST, TAG_FOCUS, TAG_PAGE } from "../Constant";
import { QTView } from "../QTTypes";
import { FocusFinder } from "../utils/FocusFinder";
import { QTLog } from "../utils/QTLog";
import { QTBaseComponentView } from "./QTBaseComponentView";
import { KeyCode } from "@kit.InputKit";
import { FocusUtils } from "../utils/FocusUtils";
import { TVView } from "./TVView";
import { ExtendUtil } from "../utils/ExtendUtil";
import { QTPageView } from "./router/QTPageView";
import { inspector } from "@kit.ArkUI";
import { QTFastList } from "./fastlist/QTFastList";
import { QTDivView, QTFastListView, QTTabsView } from "../../../../Index";
import { ViewUtils } from "../utils/ViewUtils";

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

  focusSearchInDescendants(focused: TVView | null , direction : number,rootView:QTView | null) : TVView | null{
    if(!rootView){
      return null;
    }
    let result : TVView | null | undefined = null;
    if(ViewUtils.asViewGroup(rootView)){
      result = ViewUtils.asViewGroup(rootView)?.focusSearch(focused,direction);
      if(result){
        return result;
      }
    }
    let children = rootView instanceof QTBaseComponentView ?  rootView.getDisplayChildren() : rootView.children;
    for (let i = 0; i < children.length; i++) {
      let child = children[i]
        result = this.focusSearchInDescendants(focused,direction,child)
        if(result != null){
          return result;
        }
    }
    return null;
  }

  findNextFocus(parent: QTView,direction = FocusFinder.DIRECTION_DOWN) : TVView | null{
    let nextFocus = FocusFinder.findNextFocus(this.focusedView,parent,direction)
    return nextFocus;
  }

  findNextFocusWithFocused(parent: QTView,direction = FocusFinder.DIRECTION_DOWN,focused:TVView | null) : TVView | null{
    let nextFocus = FocusFinder.findNextFocus(focused,parent,direction)
    return nextFocus;
  }

  // public requestFocus(parent : QTView,direction)

  dispatchKeyEvent(event: KeyEvent) : boolean{
    if(!this.uiContext){
      QTLog.e(TAG_FOCUS,`dispatchKeyEvent error uiContext null`)
      return false;
    }
    if(event.type == KeyType.Down){
      let direction = FocusManager.getDirectionByKeyCode(event.keyCode)
      if(direction > 0){
        let nextFocus : TVView | null = null;
        nextFocus = this.focusSearchInDescendants(this.focusedView,direction,this.rootView);
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
      QTLog.i(TAG_PAGE,`dispatchKeyEvent view: ${ExtendUtil.debugView(view)}`)
      if(view.dispatchKeyEvent(event)){
        return true;
      }
    }
    if(view instanceof QTPageView){
      if(view.isFront){
        if(view.children){
          for(let i = 0; i < view.children.length; i ++){
            if(FocusManager.dispatchKeyEvent(view.children[i],event)){
              return true;
            }
          }
        }
      }
    }else{
      if(view.children){
        for(let i = 0; i < view.children.length; i ++){
          if(FocusManager.dispatchKeyEvent(view.children[i],event)){
            return true;
          }
        }
      }
    }
    return false;
  }
}