import { LogUtil } from '@ohos/lottie';
import {
  HippyObservedArray,
  NativeRenderContext,
  HippyAny,
  HIPPY_COMPONENT_KEY_PREFIX,
  HippyRenderCallback,
  buildHippyRenderView,
} from 'hippy'
import { TAG_FASTLIST, TAG_FAST_EVENT, TAG_LAYOUT, TAG_QUICKTVUI, TAG_REUSE } from '../../Constant';
import { QTAny, QTMap, QTPendingListView, QTView } from '../../QTTypes';
import { CommonUtils } from '../../utils/CommonUtils';
import { ExtendUtil } from '../../utils/ExtendUtil';
import { QTLog } from '../../utils/QTLog';
import { QTPixelUtil } from '../../utils/QTPixelUtil';
import { QTBaseComponentView } from '../QTBaseComponentView';
import QTRenderBaseView from '../QTRenderBaseView';
import { FastListUtils } from './FastListUtils';
import { ItemView } from './ItemView';
import { LayoutAttach } from './LayoutAttach';
import { QTFastListView } from './QTFastListView';
import { PathUpdate, PendingPathUpdate, TemplateViewManager } from './TemplateViewManager';
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

  constructor(ctx: NativeRenderContext) {
    super(ctx)
    this.__serialNumber = PREFIX_KEY + QTItemRootView.__idx++;
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
    this.contentType = type;
    this.updateDirty = false;
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
      //这里跳过changedView，解决文本通知parent变化，parent变化再让文本变化，导致死循环
      TemplateViewManager.applyLayoutTraverse4AutoSize(this,changedView)
      // console.warn(TAG_LAYOUT,`set FastItem size:[${childView.cssWidth},height:${childView.cssHeight}]`)
      QTPixelUtil.setRenderViewLayout(this,[0,0,child.cssWidth,child.cssHeight]);
      //QTLog.e(TAG_LAYOUT,`notifyChildSizeChanged parentView:${ExtendUtil.debugView(this.parentList)},dataPosition:${this.dataPosition},this.cssWidth:${this.cssWidth}`)
      // if(this.parentList instanceof QTFastListView && this.dataPosition){
      //   this.parentList.notifyItemChanged(this.dataPosition)
      // }
    }

  }

  getReuseId():string | null{
    if(this.itemView?.template?.templateView){
      return  `tp-${this.itemView?.template?.templateView.tag}-type-${LayoutAttach.obtainLayoutAttach(this).virtualExtra.itemType}`
    }else{
      return `type${LayoutAttach.obtainLayoutAttach(this).virtualExtra.itemType}`
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
      LayoutAttach.obtainLayoutAttach(this).setFixedWidth(LayoutAttach.obtainLayoutAttach(childView).getWidth())
      LayoutAttach.obtainLayoutAttach(this).setFixedHeight(LayoutAttach.obtainLayoutAttach(childView).getHeight())
      TemplateViewManager.applyLayoutTraverse(this)
      // console.warn(TAG_LAYOUT,`set FastItem size:[${childView.cssWidth},height:${childView.cssHeight}]`)
      if(flexLayout){
        QTPixelUtil.setRenderViewLayout(this,[childView.cssPositionX,childView.cssPositionY,childView.cssWidth,childView.cssHeight]);
        QTPixelUtil.setRenderViewLayout(childView,[0,0,childView.cssWidth,childView.cssHeight]);
      }else{
        QTPixelUtil.setRenderViewLayout(this,[0,0,childView.cssWidth,childView.cssHeight]);
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

@Reusable
@Component
export struct QTItemRoot {
  @ObjectLink renderView: QTItemRootView
  @ObjectLink children: HippyObservedArray<QTView>

  build(): void {
    if(this.renderView.isEventClick()){
      Stack() {
        ForEach(this.children, (item: QTView) => {
          buildHippyRenderView(item, null)
        }, (item: QTView,index:number) => this.renderView.__serialNumber)
      }
      .applyRenderViewBaseAttr(this.renderView)
      .onAttach(()=>{
        console.log(TAG_REUSE,`++onItemAttach position:${this.renderView.dataPosition}`)
      })
      .onDetach(()=>{
        console.log(TAG_REUSE,`--onDetach position:${this.renderView.dataPosition}`)
      })
      .onClick((event=>{
        FastListUtils.handleItemClick(this.renderView)
      }))
    }else{
      Stack() {
        ForEach(this.children, (item: QTView) => {
          buildHippyRenderView(item, null)
        }, (item: QTView,index:number) => this.renderView.__serialNumber)
      }
      .applyRenderViewBaseAttr(this.renderView)
      // .width(this.renderView.contentView?.cssWidth)
      // .height(this.renderView.contentView?.cssHeight)
      .onAttach(()=>{
        console.log(TAG_REUSE,`++onItemAttach position:${this.renderView.dataPosition}`)
      })
      .onDetach(()=>{
        console.log(TAG_REUSE,`--onDetach position:${this.renderView.dataPosition}`)
      })
    }
  }

  aboutToAppear(): void {

  }

  aboutToRecycle(): void {
    console.log(TAG_REUSE,`--aboutToRecycle dataPosition:${this.renderView.dataPosition}`)
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
  .clip($$.cssOverflow)
  .visibility(($$ as QTView).cssVisibility) // must add as, otherwise the compiler has error
  .zIndex($$.cssZIndex)
  .accessibilityText($$.cssAccessibilityLabel)
  .focusable($$.cssFocusable)
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
