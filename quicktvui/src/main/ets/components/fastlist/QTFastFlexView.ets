import {
  HIPPY_COMPONENT_KEY_PREFIX,
  HippyObservedArray,
  NativeRenderContext,
  HippyAny,
  HippyMap,
  HippyArray,
  HippyRenderCallback,
  HippyEndBatchCallback,
  HippyRenderBaseView
} from 'hippy'
import { TAG_QUICKTVUI } from '../../Constant';
import { HRValueUtils } from '../../HRValueUtils';
import { QTView } from '../../QTTypes';
import { CommonUtils } from '../../utils/CommonUtils';
import { NodeUtils } from '../../utils/NodeUtils';
import QTRenderBaseView from '../QTRenderBaseView';
import { FastListDataSource } from './FastListDataSource';
import { ItemView, renderItem } from './ItemView';
import { QTFastItem, QTFastItemView } from './QTFastItemView';


@Observed
export class QTFastFlexView extends QTRenderBaseView {
  public virtualChildren: HippyObservedArray<QTView> = new HippyObservedArray()
  dataSource: FastListDataSource | null = null;

  constructor(ctx: NativeRenderContext) {
    super(ctx)
    this.dataSource = new FastListDataSource(ctx,this.virtualChildren)
  }

  onChildInserted(childTag: number, childViewName: string, childIndex: number): void {
    console.error(TAG_QUICKTVUI,`QTFastFlexView onChildInserted tag :${childTag},childViewName:${childViewName},childIndex:${childIndex}`)
  }

  public itemIndexOfDataList(itemView:QTView | null) : number{
    if(!itemView){
      return -1;
    }
    return this.virtualChildren.indexOf(itemView)
  }

  aboutToUpdate(): void {
    let children = this.templateView?.children
    console.error(TAG_QUICKTVUI,`QTFastFlexView aboutToUpdate!! children size:${children?.length}`)
    NodeUtils.printViewTreePretty(this,'',false)
    children?.map((c,index)=>{
      if(c.tag != -1){
        console.log(TAG_QUICKTVUI,`QTFastFlexView template: viewType：`+c.viewType+",node:"+NodeUtils.getNodeById(this.ctx,c.tag))
        this.dataSource?.registerTemplate(this.templateView!!,c,index,this.isVirtual)
      }else{
        console.error(TAG_QUICKTVUI,`QTFastFlexView registerTemplate error child id is -1`)
      }

    })
  }

  onDataChanged(data : HippyArray | null){
    if(data && data.length > 0){
      for(let  i = 0; i < data.length; i++){
        let item : ItemView = new ItemView(i,data[i] as HippyMap);
        // this.dataSource?.buildItem(item,i)
        let fi : QTFastItemView=  new QTFastItemView(this.ctx).init(this,item)
        this.dataSource?.buildItem(fi,i)
        this.virtualChildren.push(fi)
        // console.log(QUICKTVUI_TAG,`FastFlex put item index:${i},data:`)
        CommonUtils.printMapPretty(item.raw as HippyMap,'FastFlex:',false)
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

  setProp(propKey: string, propValue: HippyAny): boolean {
    switch (propKey) {
      case "cachePool":
        console.log(TAG_QUICKTVUI,`FastFlex:setCachePool :${propValue}`)
        return true;
      case "firstFocusChild":
        console.log(TAG_QUICKTVUI,`FastFlex:firstFocusChild :${propValue}`)
        return true;
      case "list":
        if(propValue instanceof Array){
          console.log(TAG_QUICKTVUI,`FastFlex:setListData:${HRValueUtils.getArray(propValue)}`)
          this.onDataChanged(HRValueUtils.getArray(propValue))
        }else{
          console.error(TAG_QUICKTVUI,`FastFlex:setListData error list is not array propValue:${propValue}`)
        }
        return true;
      case "sharedItemStore":
        console.log(TAG_QUICKTVUI,`FastFlex:sharedItemStore :${propValue}`)
        return true;

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
        console.error(TAG_QUICKTVUI,`QTFastFlexView : 未实现propKey : ${propKey}`)
        return true;
      default:
        console.warn(TAG_QUICKTVUI,`QTFastFlexView : 未知的未实现propKey : ${propKey}`)
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
        console.error(TAG_QUICKTVUI,`QTFastFlexView : 未实现的function : ${method}`)
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
    console.log(TAG_QUICKTVUI,`QTFastFlexView: handleOnChildrenUpdated children:${this.children.length}`)

  }

  build(): void {
    Row() {
      ForEach(this.renderView.virtualChildren,(item : QTFastItemView)=>{
        QTFastItem({
          renderView:item as QTFastItemView,
          children: item.children,
        })
      },(item : QTFastItemView,index)=>{
        return item.itemView!!.id as string
      })
      // ContentSlot(this.renderView.childSlot)
    }
    .backgroundColor(Color.Blue)
    .applyRenderViewBaseAttr(this.renderView)
  }



  aboutToAppear(): void {
    console.error(TAG_QUICKTVUI,`QTFastFlex aboutToAppear`)
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
}
