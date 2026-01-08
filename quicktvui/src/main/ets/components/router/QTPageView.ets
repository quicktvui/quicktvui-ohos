import {
  HippyRenderBaseView,
  HippyObservedArray,
  NativeRenderContext,
  HippyAny,
  HippyRenderCallback,
  HIPPY_COMPONENT_KEY_PREFIX,
  buildHippyRenderView
} from 'hippy'
import { TAG_FOCUS, TAG_PAGE, TAG_QUICKTVUI, TAG_TABS } from '../../Constant';
import { QTView } from '../../QTTypes';
import { ExtendUtil } from '../../utils/ExtendUtil';
import { FocusUtils } from '../../utils/FocusUtils';
import { QTLog } from '../../utils/QTLog';
import { LayoutAttach } from '../fastlist/LayoutAttach';
import { FocusManager } from '../FocusManager';
import { QTBaseComponentView } from '../QTBaseComponentView';
import { TVView } from '../TVView';
import { IPage } from './IPage';
import { PageManager } from './PageManager';

@Observed
export class QTPageView extends QTBaseComponentView implements IPage {
  public event: QTPage | null = null
  public savedFocusUid: string | undefined = undefined;
  public focusManager: FocusManager = new FocusManager(this)
  public isDialogMode: boolean = false
  static pageNumber = 0;

  uiContext : UIContext | null = null;
  isFront : boolean = false;

  constructor(ctx: NativeRenderContext) {
    super(ctx)
    LayoutAttach.obtainLayoutAttach(this).uid = `page-${QTPageView.pageNumber}`
    QTPageView.pageNumber ++
    LayoutAttach.obtainLayoutAttach(this).pageUid = this.uid
  }

  setProp(propKey: string, propValue: HippyAny): boolean {
    switch (propKey) {
      case 'isDialogMode': {
        QTLog.i(TAG_PAGE,`setDialogMode:${propValue} this:${ExtendUtil.debugView(this)}`)
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
    QTLog.d(TAG_PAGE,`dispatchKeyEvent this page is Front ${this.isFront} uid: ${this.uid}`)
    if(this.isFront && PageManager.isFrontPage(this.uid)){
      return this.focusManager.dispatchKeyEvent(event)
    }else{
      return false;
    }
  }

  getPageUid(): string | null | undefined {
    return this.uid
  }

  addSubRenderView(subView: QTView, index: number): void {
    QTLog.d(TAG_QUICKTVUI,`--------QTPageView pageUid:${LayoutAttach.obtainLayoutAttach(this).pageUid},uid:${this.uid} this:${ExtendUtil.debugView(this)}`)

    super.addSubRenderView(subView,index)
  }


  saveFocus() {
    this.savedFocusUid = this.focusManager.getFocusedView()?.uid;
  }

  restoreFocus() {
    if (this.savedFocusUid != null) {
        let b = FocusUtils.requestFocusById(this.savedFocusUid)

        if(!b){
          QTLog.e(TAG_FOCUS,`restoreFocus fail view may has destoryed uid:${this.savedFocusUid} request focus from page`)
          FocusUtils.requestViewGroupFocus(this)
        }
        this.savedFocusUid = undefined;
    }
  }

  aboutToDisappear(){
    QTLog.w(TAG_PAGE,`----aboutToDisappear page id :${this.uid}`)
    this.isFront = false;
    this.saveFocus()
    setTimeout(()=>{
      PageManager.unregisterPage(this.uid)
    },100)
  }

  onDestroy(): void {
    this.savedFocusUid = undefined;
  }

  aboutToAppear(){
    this.isFront = true;
    // this.uid = `page-${this.tag}`
    QTLog.i(TAG_PAGE,`+++++aboutToAppear page id :${this.uid}`)
    PageManager.registerPage(this.uid,this)
    PageManager.markPageToFront(this.uid)
    setTimeout(()=>{
      this.restoreFocus()
    },100)
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
  .id($$.uid)
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

