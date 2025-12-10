import {
  HippyRenderBaseView,
  HippyObservedArray,
  NativeRenderContext,
  HippyAny,
  HippyRenderCallback,
  HIPPY_COMPONENT_KEY_PREFIX,
  buildHippyRenderView
} from 'hippy'
import { TAG_FOCUS } from '../../Constant';
import { QTView } from '../../QTTypes';
import { ExtendUtil } from '../../utils/ExtendUtil';
import { FocusUtils } from '../../utils/FocusUtils';
import { QTLog } from '../../utils/QTLog';
import { FocusManager } from '../FocusManager';
import { QTBaseComponentView } from '../QTBaseComponentView';
import { TVView } from '../TVView';
import { IPage } from './IPage';
import { PageManager } from './PageManager';

@Observed
export class QTPageView extends QTBaseComponentView implements IPage {
  public event: QTPage | null = null
  public savedFocus: TVView | null = null;
  public focusManager: FocusManager = new FocusManager(this)
  public isDialogMode: boolean = false

  uiContext : UIContext | null = null;
  isFront : boolean = false;

  constructor(ctx: NativeRenderContext) {
    super(ctx)
  }

  setProp(propKey: string, propValue: HippyAny): boolean {
    switch (propKey) {
      case 'isDialogMode': {
        this.isDialogMode = propValue as boolean;
        return true;
      }
    }
    return super.setProp(propKey, propValue)
  }

  call(method: string, params: Array<HippyAny>, callback: HippyRenderCallback | null): void {
    if (this.event && this.event.call(method, params, callback)) {
      return;
    }
    super.call(method, params, callback)
  }

  notifyChildRequestFocus(child: QTView, focusedView: TVView): void {
    this.focusManager.setFocusedView(focusedView)
    QTLog.e(TAG_FOCUS, `QTPageView requestChildFocus focusedView:${focusedView?.uid}`)
  }

  dispatchKeyEvent(event: KeyEvent): boolean {

    if(this.isFront){
      return this.focusManager.dispatchKeyEvent(event)
    }else{
      return false;
    }
  }



  saveFocus() {
    this.savedFocus = this.focusManager.getFocusedView();
  }

  restoreFocus() {
    if (this.savedFocus != null) {
      FocusUtils.requestFocusById(this.savedFocus.uid)
      this.savedFocus = null;
    }
  }

  aboutToDisappear(){
    this.isFront = false;
    this.saveFocus()
    setTimeout(()=>{
      PageManager.unregisterPage(this.uid)
    },100)
  }

  aboutToAppear(){
    this.isFront = true;
    this.uid = `page-${this.tag}`
    PageManager.registerPage(this.uid,this)
    this.restoreFocus()
  }

  setPageUIContext(uiContext : UIContext){
    this.uiContext = uiContext;
    this.focusManager.uiContext = uiContext;
  }

}

@Component
export struct QTPage {
  @ObjectLink renderView: QTPageView
  @ObjectLink children: HippyObservedArray<HippyRenderBaseView>

  public call(method: string, params: Array<HippyAny>,
    callback: HippyRenderCallback | null): boolean {
    return false
  }

  aboutToAppear(): void {
    // QTLog.e(TAG_FOCUS,`+++page aboutToAppear this:${ExtendUtil.debugView(this.renderView)}`)
    this.renderView.event = this
    this.renderView.aboutToAppear()
    this.renderView.setPageUIContext(this.getUIContext())
  }

  aboutToDisappear() {
    // QTLog.e(TAG_FOCUS,`---page aboutToDisappear this:${ExtendUtil.debugView(this.renderView)}`)
    this.renderView.event = null
    this.renderView.aboutToDisappear()
  }

  build(): void {
    Stack() {
      ForEach(this.children, (item: HippyRenderBaseView) => {
        buildHippyRenderView(item, null)
      }, (item: HippyRenderBaseView) => item.tag + '')
      ContentSlot(this.renderView.childSlot)
    }
    .applyRenderViewBaseAttr(this.renderView)

  }
}

// base props for all components
@Extend(Stack)
function applyRenderViewBaseAttr($$: QTPageView) {
  .key(HIPPY_COMPONENT_KEY_PREFIX + $$.tag)
  .backgroundColor($$.cssBackgroundColor)
  .position({ x: $$.cssPositionX, y: $$.cssPositionY })
  .size({ width: $$.cssWidth, height: $$.cssHeight })
  .opacity($$.cssOpacity)
  .clip($$.cssOverflow)
  .visibility(($$ as HippyRenderBaseView).cssVisibility) // must add as, otherwise the compiler has error
  .zIndex($$.cssZIndex)
  .accessibilityText($$.cssAccessibilityLabel)
  // .focusable($$.cssFocusable)
  .border($$.cssBorder)
  .id(`page-${$$.tag}`)
  .shadow($$.cssShadow)
  .linearGradient($$.cssLinearGradient)
  .backgroundImage($$.cssBackgroundImage)
  .backgroundImageSize($$.cssBackgroundImageSize)
  .backgroundImagePosition($$.cssBackgroundImagePosition)
  .transform($$.cssMatrix)
  .rotate($$.cssRotate)
  .scale($$.cssScale)
  .translate($$.cssTranslate)
  .hitTestBehavior($$.hitTestBehavior)
}

