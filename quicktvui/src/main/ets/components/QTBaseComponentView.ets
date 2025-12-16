import { NodeContent } from '@kit.ArkUI'
import {
  NativeRenderContext,
  HippyAny,
  HippyCustomComponentView,
  HippyRenderCallback,
} from 'hippy'
import { TAG_FASTLIST, TAG_FOCUS, TAG_QUICKTVUI } from '../Constant';
import { HRValueUtils } from '../HRValueUtils';
import { QTView } from '../QTTypes';
import { ExtendUtil } from '../utils/ExtendUtil';
import { QTLog } from '../utils/QTLog';
import { LayoutAttach } from './fastlist/LayoutAttach';
import { QTActorHost } from './QTActorHost';
import { QTViewActor } from './QTViewActor';
import { QTVirtualView } from './QTVirtualView';
import { QTViewState, StateView } from './StateView';
import { TVView } from './TVView';

export class QTBaseComponentView extends HippyCustomComponentView  implements  QTActorHost,QTVirtualView,StateView,TVView{
  childSlot: NodeContent | null = null
  public templateView : QTView | null = null;
  qtPadding: Padding = { top: 0, right: 0, bottom: 0, left: 0 }
  public isVirtual : boolean = false;
  // TV扩展
  visibility: Visibility = Visibility.Visible
  sid: string = ''
  // uid:string = ''
  _uid:string = ''
  name: string = ''
  selected: boolean = false
  showonstate: string = 'normal' //
  showOnStateArray : number[] = []
  focus: boolean = false
  visible: boolean = false
  border: BorderOptions = {}   //模拟selected选中效果
  private currentStates: number[] = []


  public get uid(): string {
    if(this._uid){
      return this._uid
    }
    if(LayoutAttach.obtainLayoutAttach(this).uid){
      return LayoutAttach.obtainLayoutAttach(this)?.uid!!
    }
    if(this.tag > -1){
      return `real_${this.tag}`
    }else{
      //return LayoutAttach.obtainLayoutAttach(view)?.uid
      QTLog.e(TAG_FASTLIST,`getViewUid error invalid tag`)
      return ''
    }
  }

  // getter
  // getter
  // setter
  public set uid(value: string) {
    this._uid = value;
  }

  duplicateParentState: boolean = false

  autofocus:boolean = false;

  constructor(ctx: NativeRenderContext) {
    super(ctx)
  }

  setShowOnState(showOnState: number[]): void {
    this.showOnStateArray = showOnState;
    QTLog.w(TAG_FOCUS, `setShowOnState  showOnStateArray: ${JSON.stringify(this.showOnStateArray)}`);
  }

  setShowOnCustomState(showOnState: string[]): void {
    //throw new Error('setShowOnCustomState Method not implemented.');
  }

  setCustomState(state: string, on: boolean): void {
    //throw new Error('setCustomState Method not implemented.');
  }

  notifyChildSizeChanged(child: QTView, changedView: QTView, width: number, height: number): void {
    this.viewActor.notifyChildSizeChanged(child,changedView, width, height)
  }

  /**
   * 通知parent，子view内部请求焦点
   * @param child
   * @param focusedView
   */
  notifyChildRequestFocus(child:QTView,focusedView: TVView){
    if(this.parentView instanceof QTBaseComponentView){
      this.parentView.notifyChildRequestFocus(this,focusedView)
    }else{
      QTLog.w(TAG_FOCUS,`notifyChildRequestFocus fail parent:${ExtendUtil.debugView(this.parentView)},this:${ExtendUtil.debugView(this)}`)
    }
  }

  focusSearch(focused: TVView | null ,direction : number) : TVView | null{

   // let  nextFocus = FocusFinder.findNextFocus(focused,this)

    return null;
  }

  getDisplayChildren(){
    return this.children
  }


  // 更新状态数组的值
  private updateStateArray(): void {
    // 清空数组
    this.currentStates.length = 0
    // 根据selected和focus状态添加值
    if (this.selected) {
      this.currentStates.push(QTViewState.STATE_SELECTED);
    }
    if (this.focus) {
      this.currentStates.push(QTViewState.STATE_FOCUSED);
    }
    if(this.currentStates.length == 0 ){
      this.currentStates.push(QTViewState.STATE_NORMAL)
    }
  }


  protected handleShowOnState() {
    // if (this.showonstate.includes('normal')) {
    //   //不做处理
    // } else if (this.showonstate.includes('selected')) {
    //   //选中显示，未选中隐藏
    //   if (this.selected === true) {
    //     this.visibility = Visibility.Visible
    //   } else {
    //     this.visibility = Visibility.Hidden
    //   }
    // } else if (this.showonstate.includes('focused')) {
    //   //聚焦显示，失焦隐藏
    //   if (this.focus === true) {
    //     this.visibility = Visibility.Visible
    //   } else {
    //     this.visibility = Visibility.Hidden
    //   }
    // }
    // 先更新状态数组的值
    if(this.showOnStateArray.length > 0){
      this.updateStateArray();
      ///QTLog.w(TAG_FOCUS, `updateVisibility - currentStates: ${JSON.stringify(this.currentStates)}, showOnStateArray: ${JSON.stringify(this.showOnStateArray)}`);
      // 使用固定的状态数组调用handleShowOnState
      ExtendUtil.handleShowOnState(this, this.currentStates, this.showOnStateArray);
    }
    // 如果没有处理系统状态，再处理自定义状态
    // if (!result && this.showonstate.length > 0) {
    //   // 这里可以添加自定义状态的可见性逻辑
    //   this.visibility = this.visible ? Visibility.Visible : Visibility.Hidden;
    // }
  }

  /**
   * 通知焦点、背景图等状态改变
   */
  drawableStateChanged(){
    this.handleShowOnState()
  }

  public viewActor: QTViewActor =  new QTViewActor(this);

  onCreateByTemplate(templateView : QTView){

  }

  getPageUid() : string | null | undefined{
    return LayoutAttach.obtainLayoutAttach(this).pageUid
  }

  addSubRenderView(subView: QTView, index: number): void {
    LayoutAttach.obtainLayoutAttach(subView).pageUid =  this.getPageUid()
    if(!this.getPageUid()){
      QTLog.e(TAG_QUICKTVUI,`addSubRenderView pageUid:${this.getPageUid()},uid:${this.uid} this:${ExtendUtil.debugView(this)}`)
    }
    super.addSubRenderView(subView,index)
  }

  aboutToUpdate(){

  }

  isFocused(){
    return this.focus && this.cssFocusable
  }

  isSelected(){
    return this.selected;
  }

  isEventClick() : boolean{
    return this.isVirtual && LayoutAttach.obtainLayoutAttach(this).virtualExtra.eventClick
  }

  isEventFocus() : boolean{
    return this.isVirtual && LayoutAttach.obtainLayoutAttach(this).virtualExtra.eventFocus
  }

  addFocusables(views: TVView[],direction:number) : boolean{
    return this.viewActor.addFocusables(views,direction)
  }

  dispatchKeyEvent(event: KeyEvent): boolean {
   // QTLog.i(TAG_FOCUS,`dispatchKeyEvent :${event.keyText} code:${event.keyCode} this:${ExtendUtil.debugView(this)}`)
    return false;
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
      case 'showOnState':
        //this.showonstate = HRValueUtils.getString(propValue as HippyAny);
        ExtendUtil.configureShowOnState(this,propValue)
        QTLog.w(TAG_FOCUS,`setShowOnState :${propValue},this:${ExtendUtil.debugView(this)}`)
        this.handleShowOnState();
        return true;
        // case 'showOnState':
        //
        //   return true;
      case 'duplicateParentState':
        {
          this.duplicateParentState = HRValueUtils.getBoolean(propValue as HippyAny, true);
          // this.setDuplicate();
        }
        return true
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
