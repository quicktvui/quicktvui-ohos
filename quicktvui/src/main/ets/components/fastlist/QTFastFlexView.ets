import {
  HIPPY_COMPONENT_KEY_PREFIX,
  HippyObservedArray,
  NativeRenderContext,
  HippyAny,
  HippyMap,
  HippyArray,
  HippyRenderCallback,
  HippyEndBatchCallback,
} from 'hippy'
import { TAG_FASTLIST, TAG_FOCUS, TAG_REUSE } from '../../Constant';
import { HRValueUtils } from '../../HRValueUtils';
import { QTAny, QTView } from '../../QTTypes';
import { ExtendUtil } from '../../utils/ExtendUtil';
import { QTLog } from '../../utils/QTLog';
import { QTBaseComponentView } from '../QTBaseComponentView';
import QTRenderBaseView from '../QTRenderBaseView';
import { TVView } from '../TVView';
import { FastListDataSource } from './FastListDataSource';
import { ItemView, renderItem } from './ItemView';
import { LayoutAttach } from './LayoutAttach';
import { QTItemRoot, QTItemRootView } from './QTItemRootView';


@Observed
export class QTFastFlexView extends QTRenderBaseView {
  public virtualChildren: HippyObservedArray<QTView> = new HippyObservedArray()
  dataSource: FastListDataSource | null = null;
  enablePlaceholder : boolean  = false;

  constructor(ctx: NativeRenderContext) {
    super(ctx)
    this.dataSource = new FastListDataSource(ctx,this.virtualChildren)
    this.dataSource.listView = this;
    this.dataSource.setPlaceholderEnabled(false)
    this.clipChildren = false;
  }

  setRootListID(rootListID:number){
    this.dataSource!!.rootListId = rootListID;
    this.dataSource!!.registerParentItemStore()
  }

  onChildInserted(childTag: number, childViewName: string, childIndex: number): void {
    console.error(TAG_FASTLIST,`QTFastFlexView onChildInserted tag :${childTag},childViewName:${childViewName},childIndex:${childIndex}`)
  }

  public itemIndexOfDataList(itemView:QTView | null) : number{
    if(!itemView){
      return -1;
    }
    return this.virtualChildren.indexOf(itemView)
  }

  aboutToUpdate(): void {
    let children = this.templateView?.children
    // console.error(TAG_FASTLIST,`QTFastFlexView aboutToUpdate!! children size:${children?.length}`)
    // NodeUtils.printViewTreePretty(this,'',false)
    // children?.map((c,index)=>{
    //   if(c.tag != -1){
    //     QTLog.d(TAG_FASTLIST,`QTFastFlexView template: viewType：`+c.viewType+",node:"+NodeUtils.getNodeById(this.ctx,c.tag))
    //     this.dataSource?.registerTemplate(c,this.isVirtual)
    //   }else{
    //     console.error(TAG_FASTLIST,`QTFastFlexView registerTemplate error child id is -1`)
    //   }
    // })
    if(children){
      this.dataSource?.registerTemplates(children,this.isVirtual)
    }
  }

  getPageUid(): string | null | undefined {
    if(this.templateView){
      let templateAttach = LayoutAttach.obtainLayoutAttach(this.templateView);
      if(templateAttach.pageUid){
        return templateAttach.pageUid
      }
    }
    return super.getPageUid();
  }

  onDataChanged(data : HippyArray | null){
    QTLog.d(TAG_FASTLIST,`FastFlex:onDataChanged rootListID:${LayoutAttach.obtainLayoutAttach(this).virtualExtra.rootListId}`)
    this.virtualChildren.length = 0;
    this.dataSource?.setPlaceholderEnabled(this.enablePlaceholder)
    if(this.dataSource && data && data.length > 0){
      for(let  i = 0; i < data.length; i++){
        let item : ItemView = new ItemView(i,data[i] as HippyMap);
        // this.dataSource?.buildItem(item,i)
        let fi : QTItemRootView =  new QTItemRootView(this.ctx).init(this,item)
        LayoutAttach.obtainLayoutAttach(fi).pageUid = this.getPageUid();
        this.dataSource.buildItem(fi,i)
        fi.enablePlaceholder = this.enablePlaceholder
        this.virtualChildren.push(fi)
        //CommonUtils.printMapPretty(item.raw as HippyMap,'FastFlex:',false)
      }
      // this.dataList.push(...
      //   data?.map((item,index)=>{
      //     return new ItemView(index,item as HippyMap)
      //   })
      // )
    }
  }

  getDisplayChildren(): HippyObservedArray<QTView> {
    return this.virtualChildren;
  }

  keyGenerate(item : QTView,index : number) : string{
    let key : string | null = ''

    if (item instanceof QTItemRootView && item.itemView){
      if(item.uid){
        return item.uid
      }
      key =  item.itemView.getItemForEachKey();
      if(!key){
        key = item.itemView.getItemId();
      }
      if(!key){
        key = item.uid;
      }
    } else{
      key =  'view-' + index
    }
    if(!key){
      QTLog.e(TAG_FASTLIST,`keyGenerate fail item:${ExtendUtil.debugView(this)},index:${index}`)
    }else{
      QTLog.d(TAG_FASTLIST,`keyGenerate key:${key} item ${ExtendUtil.debugView(item)},index:${index}`)
    }
    return key ?? '';
    /*if(item instanceof QTItemRootView){
      let id = LayoutAttach.obtainLayoutAttach(item).sid
      if(id){
        QTLog.d(TAG_REUSE,`keyGenerate id from sid:${id}`)
        return id +'-'+ item.updateTimes
      }
      if(item.itemView){
        id =  item.itemView.getItemId()
        if(id){
          QTLog.d(TAG_REUSE,`keyGenerate id by item:${id}`)
          return LayoutAttach.obtainLayoutAttach(item).virtualExtra.itemType + ''+ id + '-'+item.updateTimes;
        }else{
          // QTLog.d(TAG_REUSE,`keyGenerate id with fi-:${index}-${item.updateTimes}`)
        }
        return `fi-:${index}-${item.updateTimes}`
      }
    }else{
      // QTLog.d(TAG_REUSE,`keyGenerate use fallback -:${index}`)
    }
    return 'view-'+index*/
  }

  addFocusables(views: TVView[], direction: number): boolean {
    QTLog.w(TAG_FOCUS,`FastFlex addFocusables uid:${this.uid} ,virtualChildren length:${this.virtualChildren.length}`)
    if (this.virtualChildren && this.virtualChildren.length > 0) {
      this.virtualChildren.forEach((child: QTView) => {
        QTLog.d(TAG_FOCUS,`FastFlex add child :${ExtendUtil.debugView(child)},parent:${this.uid}`)
        if(child instanceof QTBaseComponentView){
          // QTLog.d(TAG_FOCUS,`FastFlex add child uid:${child.uid},parent:${this.uid}`)
          child.addFocusables(views,direction)
        }else if (child.cssFocusable === true) {
          QTLog.e(TAG_FOCUS,`addFocusables skip focusable view : ${ExtendUtil.debugView(child)}`)
        }
      });
    }
    return true;
  }

  setProp(propKey: string, propValue: HippyAny): boolean {
    if(this.isRecycled){
      QTLog.w(TAG_REUSE,`FastFlex set prop return on reyclced key:${propKey}`)
      return true;
    }
    switch (propKey) {
      case "cachePool":
        QTLog.d(TAG_FASTLIST,`FastFlex:setCachePool :${propValue}`)
        return true;
      case "firstFocusChild":
        QTLog.d(TAG_FASTLIST,`FastFlex:firstFocusChild :${propValue}`)
        return true;
      case "list":
        if(propValue instanceof Array){
          QTLog.w(TAG_REUSE,`FastFlex:setListData this:${this.uid}  recycled:${this.isRecycled} data:${HRValueUtils.getArray(propValue)}`)
          this.onDataChanged(HRValueUtils.getArray(propValue))
        }else{
          console.error(TAG_FASTLIST,`FastFlex:setListData error list is not array propValue:${propValue}`)
        }
        return true;
      case "sharedItemStore":
        QTLog.d(TAG_FASTLIST,`FastFlex:sharedItemStore :${propValue}`)
        return true;
      case "enablePlaceholder":
        QTLog.i(TAG_FASTLIST,`FastFlex:enablePlaceholder :${propValue}`)
        this.enablePlaceholder = HRValueUtils.getBoolean(propValue,true);
        this.dataSource?.setPlaceholderEnabled(this.enablePlaceholder)
        this.virtualChildren?.map((fi)=>{
          if(fi instanceof QTItemRootView){
            fi.enablePlaceholder = this.enablePlaceholder
          }
        })
        return true;
      break;

    }
    //不支持或者不处理的key
    switch (propKey) {
      case "display":
      case "setData":
      case "suspendUpdateTaskOnPause":
      case "listenBoundEvent":
      case "verticalScrollBarEnabled":
      case "horizontalScrollBarEnabled":
      case "checkScrollOffsetOnStateChanged":
      case "scrollEventThrottle":
      case "enableScrollOffsetEvent":
      case "listenFocusSearchOnFail":
      case "useAdvancedFocusSearch":
      case "negativeKeyTime":
      case "postContentDelay":
      case "placeholderPostDelay":
      case "initFocusPositionAfterLayout":
      case "enableGridLoad":
      case "enableKeepFocus":
      case "disableScroll":
      case "scrollFactor":
      case "setLoadDelayTime":
      case "autofocusPositionInfiniteMode":
      case "autoscrollInfiniteMode":
      case "autoSelectPosition":
      case "useLayoutAnimation":
      case "useDiff":
      case "keyName":

        console.error(TAG_FASTLIST,`QTFastFlexView : 未实现propKey : ${propKey}`)
        return true;
      default:
        console.warn(TAG_FASTLIST,`QTFastFlexView : 未知的未实现propKey : ${propKey}`)
        break;
    }
    return super.setProp(propKey, propValue)
  }

  call(method: string, params: Array<HippyAny>, callback: HippyRenderCallback | null): void {

    switch (method) {
      case 'scrollToPositionWithOffsetInfiniteMode':
      case 'setGroupChildSelectByItemPosition':
      case 'refreshListData':
      case 'requestItemLayout':
      case 'destroy':
      case 'recycle':
      case 'prepareForRecycle':
      case 'setDisplay':
      case 'changeDisplayState':
      case 'notifySaveInstance':
      case 'notifyRestoreInstance':
      case 'clearAllPostTask':
      case 'clearPostTaskByCate':
      case 'pausePostTask':
      case 'resumePostTask':
      case 'requestLayoutManual':
      case 'setBackgroundColor':
      case 'setCustomStateEnableOnFocus':
      case 'setItemCustomState':
      case 'scheduleLayoutAnimation':
        console.error(TAG_FASTLIST,`QTFastFlexView : 未实现的function : ${method}`)
        return;
    }

    switch (method) {
      case 'updateItem':

        break;
    }
  }
}

@Component
export struct QTFastFlex {
  @ObjectLink renderView: QTFastFlexView
  @ObjectLink children: HippyObservedArray<QTView>
  private endBatchCallback: HippyEndBatchCallback | null = null

  private handleOnChildrenUpdated() {
    QTLog.d(TAG_FASTLIST,`QTFastFlexView: handleOnChildrenUpdated children:${this.children.length}`)

  }

  build(): void {
    Row() {
      ForEach(this.renderView.virtualChildren,(item : QTItemRootView)=>{
        QTItemRoot({
          renderView:item as QTItemRootView,
          children: item.children,
        })
          // .reuseId(item.getReuseId())
      },(item : QTItemRootView,index)=>{
        return this.renderView.keyGenerate(item,index)
      })
      // Text(`FLEX:uid:${this.renderView.uid}`)
      //   .width(200)
      //   .height(50)
      //   .fontSize(16)
      //   .fontColor(Color.White)
      //   .backgroundColor(Color.Black)
      //   .zIndex(9999)
      // ContentSlot(this.renderView.childSlot)
    }
    .applyRenderViewBaseAttr(this.renderView)
    // .backgroundColor(Color.Blue)
  }



  aboutToAppear(): void {
    // this.endBatchCallback = () =>{
    // }
    // this.renderView.ctx.getNativeRender().addEndBatchCallback(this.renderView.ctx.getRootId(),this.endBatchCallback)
  }

  getSid(){
    return ''
  }

  aboutToDisappear(): void {
    // if(this.endBatchCallback){
    //   this.renderView.ctx.getNativeRender().removeEndBatchCallback(this.renderView.ctx.getRootId(),this.endBatchCallback)
    // }
  }

  aboutToReuse(params: Record<string, Object>): void {
    this.renderView.isRecycled = false;
    QTLog.w(TAG_REUSE,`FastFlex +++ aboutToReuse this:${this.renderView.uid}`)
    // let view = params['renderView'] as QTView
    // if(view instanceof QTFastFlexView){
    //
    //   for(let i = 0; i < this.renderView.virtualChildren.length;  i++){
    //     QTLog.w(TAG_REUSE,`FastFlex this child:${ExtendUtil.debugView(this.renderView.virtualChildren[i])}`)
    //   }
    //   QTLog.e(TAG_REUSE,`-----------------------------------------`)
    //   for(let i = 0; i < view.virtualChildren.length;  i++){
    //     QTLog.w(TAG_REUSE,`FastFlex reuse view child:${ExtendUtil.debugView(view.virtualChildren[i])}`)
    //   }
    //   QTLog.e(TAG_REUSE,`-----FastFlex aboutToReuse view:${ExtendUtil.debugView(view)} children count:${view.virtualChildren.length},this childrenCount:${this.renderView.virtualChildren.length}`);
    // }

    //this.renderView.onAboutToReuse(params)
    // if(view instanceof QTItemRootView){
    //   this.renderView.reuse(view)
    // }
  }

  aboutToRecycle(): void {
    this.renderView.isRecycled = true;
    QTLog.e(TAG_REUSE,`FastFlex --- aboutToRecycle  this:${this.renderView.uid}`)
    // for(let i = 0; i < this.renderView.virtualChildren.length;  i++){
    //   QTLog.e(TAG_REUSE,`FastFlex aboutToRecycle this child:${ExtendUtil.debugView(this.renderView.virtualChildren[i])}`)
    // }
  }

}

@Extend(Row)
function applyRenderViewBaseAttr($$: QTFastFlexView) {
  // .key(HIPPY_COMPONENT_KEY_PREFIX + $$.tag)
  .backgroundColor($$.cssBackgroundColor)
  .position({x: $$.cssPositionX, y: $$.cssPositionY})
  .size({width:$$.cssWidth, height: $$.cssHeight})
  .opacity($$.cssOpacity)
  .clip($$.clipChildren)
  .visibility(($$ as QTFastFlexView).cssVisibility) // must add as, otherwise the compiler has error
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
  .key($$.uid? $$.uid : `real_${$$.tag}`)
  .id($$.uid? $$.uid : `real_${$$.tag}`)
  .visibility($$.visibility)
}
