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
import { TAG_FASTLIST } from '../../Constant';
import { HRValueUtils } from '../../HRValueUtils';
import { QTView } from '../../QTTypes';
import { QTLog } from '../../utils/QTLog';
import { QTBaseComponentView } from '../QTBaseComponentView';
import QTRenderBaseView from '../QTRenderBaseView';
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

  onDataChanged(data : HippyArray | null){
    QTLog.d(TAG_FASTLIST,`FastFlex:onDataChanged rootListID:${LayoutAttach.obtainLayoutAttach(this).virtualExtra.rootListId}`)
    this.virtualChildren = []
    this.dataSource?.setPlaceholderEnabled(this.enablePlaceholder)
    if(this.dataSource && data && data.length > 0){
      for(let  i = 0; i < data.length; i++){
        let item : ItemView = new ItemView(i,data[i] as HippyMap);
        // this.dataSource?.buildItem(item,i)
        let fi : QTItemRootView =  new QTItemRootView(this.ctx).init(this,item)
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
    }else{
      this.virtualChildren = []
    }
  }

  keyGenerate(item : QTView,index : number) : string{
    if(item instanceof QTItemRootView){
      let id = LayoutAttach.obtainLayoutAttach(item).sid
      if(id){
        console.debug(TAG_FASTLIST,`FastFlex:keyGenerate id from sid:${id}`)
        return id
      }
      if(item.itemView){
        id =  item.itemView.getItemId()
        if(id){
          console.debug(TAG_FASTLIST,`FastFlex:keyGenerate id by item:${id}`)
          return LayoutAttach.obtainLayoutAttach(item).virtualExtra.itemType + ''+ id;
        }
      }
    }
    return 'view-'+index
  }

  addFocusables(views: QTView[], direction: number): boolean {
    if (this.virtualChildren && this.virtualChildren.length > 0) {
      this.virtualChildren.forEach((child: QTView) => {
        if(child instanceof QTBaseComponentView){
          child.addFocusables(views,direction)
        }else if (child.cssFocusable === true) {
          views.push(child);
        }
      });
    }
    return true;
  }

  setProp(propKey: string, propValue: HippyAny): boolean {
    switch (propKey) {
      case "cachePool":
        QTLog.d(TAG_FASTLIST,`FastFlex:setCachePool :${propValue}`)
        return true;
      case "firstFocusChild":
        QTLog.d(TAG_FASTLIST,`FastFlex:firstFocusChild :${propValue}`)
        return true;
      case "list":
        if(propValue instanceof Array){
          QTLog.d(TAG_FASTLIST,`FastFlex:setListData:${HRValueUtils.getArray(propValue)}`)
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
        }).reuseId(item.getReuseId())
      },(item : QTItemRootView,index)=>{
        return this.renderView.keyGenerate(item,index)
      })
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
    if(this.endBatchCallback){
      this.renderView.ctx.getNativeRender().removeEndBatchCallback(this.renderView.ctx.getRootId(),this.endBatchCallback)
    }
  }

}

@Extend(Row)
function applyRenderViewBaseAttr($$: QTFastFlexView) {
  .key(HIPPY_COMPONENT_KEY_PREFIX + $$.tag)
  .backgroundColor($$.cssBackgroundColor)
  .position({x: $$.cssPositionX, y: $$.cssPositionY})
  .size({width:$$.cssWidth, height: $$.cssHeight})
  .opacity($$.cssOpacity)
  .clip($$.cssOverflow)
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
  .key($$.name)
  .id($$.sid)
  .visibility($$.visibility)
}
