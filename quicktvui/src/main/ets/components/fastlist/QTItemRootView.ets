import { LogUtil } from '@ohos/lottie';
import {
  HippyObservedArray,
  NativeRenderContext,
  HippyAny,
  HIPPY_COMPONENT_KEY_PREFIX,
  HippyRenderCallback,
  buildHippyRenderView,
} from 'hippy'
import { TAG_FASTLIST, TAG_FAST_EVENT, TAG_FOCUS, TAG_LAYOUT, TAG_QUICKTVUI, TAG_REUSE } from '../../Constant';
import { QTAny, QTMap, QTPendingListView, QTView } from '../../QTTypes';
import { CommonUtils } from '../../utils/CommonUtils';
import { ExtendUtil } from '../../utils/ExtendUtil';
import { QTLog } from '../../utils/QTLog';
import { QTPixelUtil } from '../../utils/QTPixelUtil';
import { QTDivView } from '../div/QTDivView';
import { QTBaseComponentView } from '../QTBaseComponentView';
import QTRenderBaseView from '../QTRenderBaseView';
import { TVView } from '../TVView';
import { FastListUtils } from './FastListUtils';
import { ItemView } from './ItemView';
import { LayoutAttach } from './LayoutAttach';
import { QTFastFlexView } from './QTFastFlexView';
import { QTFastItemView } from './QTFastItemView';
import { QTFastListView } from './QTFastListView';
import { PathUpdate, PendingPathUpdate, TemplateViewManager } from './TemplateViewManager';
import { VirtualViewRegistry } from './VirtualViewRegistry';

const PREFIX_KEY = "ITEMROOT"

export class ElementNode{
  template:QTView | null = null;
  rootNode:ElementNode | null = null;
  boundView:QTView | null = null;
  children : ElementNode[] = []
}

@Observed
export class QTItemRootView extends QTRenderBaseView{

  reuse(view: QTItemRootView) {
    QTLog.e(TAG_REUSE,`reuse this:${this.dataPosition} ,data:${CommonUtils.hippyMap2String(view.itemData)}`)
      // setTimeout(()=>{
        if(view.itemData) {
          this.updateItemPendingProps(view.itemData)
        }
      // },100)
  }

  static __idx:number = 0;
  __serialNumber: string = '';

  itemView:ItemView |  null = null;
  parentList : QTPendingListView | null = null;
  dataPosition : number = -1;
  decoration :Padding = { top: 0, right: 0, bottom: 0, left: 0 }
  itemData : QTMap | null = null;
  //
  updateTimes = 0

  viewType: string = 'QTItemRootView'

  updateDirty = true;
  contentType : number = -1;

  contentView : QTView | null = null;

  // rootNode : ElementNode | null = null;
  updates:Array<PathUpdate> = []
  pendingUpdates:Array<PendingPathUpdate> = []

  public enablePlaceholder : boolean  = false;

  constructor(ctx: NativeRenderContext) {
    super(ctx)
    this.__serialNumber = PREFIX_KEY + QTItemRootView.__idx++;
    VirtualViewRegistry.getInstance().registerView(this)
  }

  init(parent : QTPendingListView,item:ItemView): QTItemRootView{
    this.parentList = parent;
    this.itemView = item
    return this;
  }

  setContent(type: number, renderView: QTView) {
    if(this.contentView){
      LayoutAttach.obtainLayoutAttach(this).removeChild(LayoutAttach.obtainLayoutAttach(this.contentView))
      this.removeSubView(this.contentView)
    }
    this.contentView = renderView;
    LayoutAttach.obtainLayoutAttach(this).insertChild(LayoutAttach.obtainLayoutAttach(renderView),0)
    this.addSubRenderView(renderView,0)
    if(renderView instanceof QTBaseComponentView){
      renderView.duplicateParentState = true;
    }
    this.contentType = type;
    this.updateDirty = false;
  }

  addFocusables(views: TVView[], direction: number): boolean {
    if(!super.addFocusables(views,direction)){
      //证明自身是不可获焦的
      if (this.children && this.children.length > 0) {
        this.children.forEach((child: QTView) => {
          if(child instanceof QTBaseComponentView){
            child.addFocusables(views,direction)
          }else if (child.cssFocusable === true) {
            //views.push(child);
            QTLog.e(TAG_FOCUS,`addFocusables skip focusable view : ${ExtendUtil.debugView(child)}`)
          }
        });
      }
    }
    return true;
  }


  notifyChildSizeChanged(child: QTView, changedView: QTView, width: number, height: number): void {
    //主里直接阻断向上，只处理一层
    //super.notifyChildSizeChanged
    // let changed = child.cssWidth != this.cssWidth
    // if(!changed){
    //   changed = child.cssHeight != this.cssHeight
    // }
    // console.info(TAG_LAYOUT,`notifyChildSizeChanged on FastItem,isVirtual${this.isVirtual} changeViewType:${changedView.viewType},width:${width},height:${height},child width:${LayoutAttach.obtainLayoutAttach(child).fixedWidth},changed:${changed}`)
    if(true){
      this.calculateLayout()
      LayoutAttach.obtainLayoutAttach(this).setFixedWidth(LayoutAttach.obtainLayoutAttach(child).getWidth())
      LayoutAttach.obtainLayoutAttach(this).setFixedHeight(LayoutAttach.obtainLayoutAttach(child).getHeight())
      // LayoutAttach.obtainLayoutAttach(this).setPosition(LayoutAttach.obtainLayoutAttach(child).getLeft(),LayoutAttach.obtainLayoutAttach(child).getTop())
      //这里跳过changedView，解决文本通知parent变化，parent变化再让文本变化，导致死循环
      TemplateViewManager.applyLayoutTraverse4AutoSize(this,changedView)
      // console.warn(TAG_LAYOUT,`set FastItem size:[${childView.cssWidth},height:${childView.cssHeight}]`)
      //QTPixelUtil.setRenderViewLayout(this,[0,0,child.cssWidth,child.cssHeight]);
      this.letItemMatchChildPosition(child)
      //QTLog.e(TAG_LAYOUT,`notifyChildSizeChanged parentView:${ExtendUtil.debugView(this.parentList)},dataPosition:${this.dataPosition},this.cssWidth:${this.cssWidth}`)
      // if(this.parentList instanceof QTFastListView && this.dataPosition){
      //   this.parentList.notifyItemChanged(this.dataPosition)
      // }
    }

  }

  notifyChildRequestFocus(child: QTView, focusedView: TVView): void {
    if(this.parentList instanceof QTBaseComponentView){
      this.parentList.notifyChildRequestFocus(this,focusedView)
    }else{
      QTLog.w(TAG_FOCUS,`notifyChildRequestFocus fail parent:${ExtendUtil.debugView(this.parentList)},this:${ExtendUtil.debugView(this)}`)
    }
  }

  clearFocusChild(){
    this.focusChild = null;
    if(this.parentList instanceof QTBaseComponentView){
      this.parentList.clearFocusChild();
    }
  }

  getReuseId():string | null{
    if(this.itemView?.template?.templateView){
      return  `tp-${this.itemView?.template?.templateView.tag}-type-${LayoutAttach.obtainLayoutAttach(this).virtualExtra.itemType}`
    }else{
      return `type${LayoutAttach.obtainLayoutAttach(this).virtualExtra.itemType}`
    }
  }


  letItemMatchChildPosition(childView : QTView){
    let childLa = LayoutAttach.obtainLayoutAttach(childView)
    let itemLa = LayoutAttach.obtainLayoutAttach(this)
    // QTLog.w(TAG_LAYOUT,`letItemMatchChildPosition ,child left:${childLa.getLeft()},childTOp:${childLa.getTop()} childView:${ExtendUtil.debugView(childView)}`)
    // QTLog.e(TAG_LAYOUT,`letItemMatchChildPosition ,itemLa left:${itemLa.getLeft()},TOp:${itemLa.getTop()}`)
    if(this.parentList instanceof QTFastFlexView){
      QTPixelUtil.setRenderViewLayout(this,[childLa.getLeft(),childLa.getTop(),itemLa.fixedWidth,itemLa.fixedHeight]);
      // childLa.setPosition(0,0)
      QTPixelUtil.setRenderViewLayout(childView,[0,0,childView.cssWidth,childView.cssHeight]);
    }
  }

  calculateLayout(){
    if(this.parentView){
      LayoutAttach.obtainLayoutAttach(this).calculateLayout(this.parentView.cssWidth,this.parentView.cssHeight)
    }else{
      //fixme 暂时写死
      LayoutAttach.obtainLayoutAttach(this).calculateLayout(1920,1080)
    }
  }

  layoutItem(childView:QTView ,flexLayout: boolean,singleton:boolean | undefined){
    if(singleton){
        QTLog.i(TAG_LAYOUT,`layoutItem singleton childView:${ExtendUtil.debugView(childView)},childWidth:${childView.cssWidth},childHeight:${childView.cssHeight}`)
        LayoutAttach.obtainLayoutAttach(this).setFixedWidth(LayoutAttach.obtainLayoutAttach(childView).getWidth())
        LayoutAttach.obtainLayoutAttach(this).setFixedHeight(LayoutAttach.obtainLayoutAttach(childView).getHeight())
        QTPixelUtil.setRenderViewLayout(childView,[0,0,childView.cssWidth,childView.cssHeight]);
        QTPixelUtil.setRenderViewLayout(this,[0,0,childView.cssWidth,childView.cssHeight]);
    }else{
      this.calculateLayout()
      let itemLa = LayoutAttach.obtainLayoutAttach(this)
      let childLa = LayoutAttach.obtainLayoutAttach(childView)
      itemLa.setFixedWidth(childLa.getWidth())
      itemLa.setFixedHeight(childLa.getHeight())
      // if(childLa.getLeft() > 0 && childLa.getTop() > 0){
      //
      // }
      // itemLa.setPosition(childLa.getLeft(),childLa.getTop())
      TemplateViewManager.applyLayoutTraverse(this)
      // console.warn(TAG_LAYOUT,`set FastItem size:[${childView.cssWidth},height:${childView.cssHeight}]`)
      // QTLog.w(TAG_LAYOUT,`layoutItem felxLayout:${flexLayout},child left:${childLa.getLeft()},childTOp:${childLa.getTop()} childView:${ExtendUtil.debugView(childView)}`)
      if(flexLayout){
        this.letItemMatchChildPosition(childView)
      }else{
        if(childView instanceof QTFastItemView){
          itemLa.setFixedWidth(childView.getContentWidth())
          itemLa.setFixedHeight(childView.getContentHeight())
          QTPixelUtil.setRenderViewLayout(this,[0,0,childView.getContentWidth(),childView.getContentHeight()]);
        }else{
          QTPixelUtil.setRenderViewLayout(this,[0,0,childView.cssWidth,childView.cssHeight]);
        }
        // this.letItemMatchChildPosition(childView)
      }
    }


  }
  onAboutToReuse(params: Record<string, Object>){
    if(this.children[0]){
      QTPixelUtil.setRenderViewLayout(this,[this.children[0].cssPositionX,this.children[0].cssPositionY,this.children[0].cssWidth,this.children[0].cssHeight]);
      QTPixelUtil.setRenderViewLayout(this.children[0],[0,0,this.children[0].cssWidth,this.children[0].cssHeight]);
    }
    this.updateDirty = true;
    // let item = this.parentList?.dataSource.
    //this.pendingUpdates
  }

  updateItemPendingProps(itemData: QTMap){
    QTLog.d(TAG_REUSE,`updateItemPendingProps pendingUpdates size:${this.pendingUpdates.length}`)
    if(this.pendingUpdates){
      this.pendingUpdates.forEach((p)=>{
        TemplateViewManager.applyPendingProp(p.renderView,p.pendingProps,itemData)
      })
    }
  }


  setProp(propKey: string, propValue: HippyAny): boolean {
    return super.setProp(propKey, propValue)
  }

  call(method: string, params: Array<HippyAny>, callback: HippyRenderCallback | null): void {



  }


}

@Builder
function buildPlaceholder(itemView: QTItemRootView){
  if(itemView.enablePlaceholder){
    // Stack().width(itemView.cssWidth).height(itemView.cssHeight)
    //   .position({x:0,y:0})
    //   .backgroundColor(Color.Gray)
  }
}


@Reusable
@Component
export struct QTItemRoot {
  @ObjectLink renderView: QTItemRootView
  @ObjectLink children: HippyObservedArray<QTView>

  build(): void {
    if(this.renderView.isEventClick()){
      Stack() {
        buildPlaceholder(this.renderView)
        ForEach(this.children, (item: QTView) => {
          buildHippyRenderView(item, null)
        }, (item: QTView,index:number) => this.renderView.__serialNumber)
      }
      .applyRenderViewBaseAttr(this.renderView)
      .onAttach(()=>{
        QTLog.i(TAG_REUSE,`++onItemAttach position:${this.renderView.dataPosition}`)
      })
      .onDetach(()=>{
        QTLog.i(TAG_REUSE,`--onDetach position:${this.renderView.dataPosition}`)
      })
      .onClick((event=>{
        FastListUtils.handleItemClick(this.renderView)
      }))
    }else{
      Stack() {
        buildPlaceholder(this.renderView)
        ForEach(this.children, (item: QTView) => {
          buildHippyRenderView(item, null)
        }, (item: QTView,index:number) => this.renderView.__serialNumber)
      }
      .applyRenderViewBaseAttr(this.renderView)
      // .width(this.renderView.contentView?.cssWidth)
      // .height(this.renderView.contentView?.cssHeight)
      .onAttach(()=>{
        QTLog.i(TAG_REUSE,`++onItemAttach position:${this.renderView.dataPosition}`)
      })
      .onDetach(()=>{
        QTLog.i(TAG_REUSE,`--onDetach position:${this.renderView.dataPosition}`)
      })
    }
  }

  aboutToAppear(): void {

  }

  aboutToRecycle(): void {
    QTLog.i(TAG_REUSE,`--aboutToRecycle dataPosition:${this.renderView.dataPosition}`)
  }

  aboutToReuse(params: Record<string, Object>): void {
    console.warn(TAG_REUSE,`++aboutToReuse dataPosition:${this.renderView.dataPosition}，itemView:${params['itemView']}`)

    let view = params['renderView'] as QTView
    console.warn(TAG_REUSE,`aboutToReuse view:${ExtendUtil.debugView(view)}`);

    //this.renderView.onAboutToReuse(params)
    if(view instanceof QTItemRootView){
      this.renderView.reuse(view)
    }

  }
}

@Extend(Stack)
function applyRenderViewBaseAttr($$: QTBaseComponentView) {
  .key(HIPPY_COMPONENT_KEY_PREFIX + $$.tag)
  .backgroundColor($$.cssBackgroundColor)
  .position({x: $$.cssPositionX, y: $$.cssPositionY})
  .size({width:$$.cssWidth, height: $$.cssHeight})
  .opacity($$.cssOpacity)
  .clip(false)
  .visibility(($$ as QTView).cssVisibility) // must add as, otherwise the compiler has error
  .zIndex($$.cssZIndex)
  .accessibilityText($$.cssAccessibilityLabel)
  // .focusable($$.cssFocusable)
  .border($$.cssBorder)
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
  .onClick($$.eventClick)
  //tv basic
  .key($$.name)
  .id($$.sid)
  .visibility($$.visibility)
}
