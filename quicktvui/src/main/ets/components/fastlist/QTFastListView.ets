
import {HippyObservedArray,NativeRenderContext,HippyAny,HippyRenderCallback,HippyArray,HippyMap,HippyEndBatchCallback} from 'hippy'
import { TAG_FASTLIST } from '../../Constant';
import { HRValueUtils } from '../../HRValueUtils';
import { QTAny, QTArray, QTMap, QTView } from '../../QTTypes';
import { CommonUtils } from '../../utils/CommonUtils';
import { ExtendUtil } from '../../utils/ExtendUtil';
import { NodeUtils } from '../../utils/NodeUtils';

import QTRenderBaseView from '../QTRenderBaseView';
import { FastListDataSource } from './FastListDataSource';
import { ItemView } from './ItemView';
import { LayoutAttach } from './LayoutAttach';
import { QTFastItemView } from './QTFastItemView';
import { QTFastList } from './QTFastList';


@Observed
export class QTFastListView extends QTRenderBaseView{

  public virtualChildren: HippyObservedArray<QTView> = new HippyObservedArray()
  isHorizontal : boolean = false;
  spanCount : string | null= null;
  initialPosition : number = 0;
  listSpace: number = 0;
  scroller: ListScroller = new ListScroller();
  scrollOffset: number =  0
  autofocusPosition: number = -1;
  dataSource: FastListDataSource | null = null;

  // private customTemplate: QTView | null = null;

  private endBatchCallback: HippyEndBatchCallback | null = null

  constructor(ctx: NativeRenderContext) {
    super(ctx)
  }


  exeScroll(){
    this.scroller.scrollToIndex(this.initialPosition)
  }

  getTemplate() : HippyObservedArray<QTView>{
    return this.templateView ? this.templateView.children : this.children
  }

  setCustomTemplate(customTemplate: QTView | null){
    this.templateView = customTemplate;
  }

  public prepareTemplate() {
    // this.bgColor = Color.Pink
    console.log(TAG_FASTLIST,`QTFastList: handleOnChildrenUpdated`)
    // NodeUtils.printViewTreePretty(this,'',false)
    if(this.isVirtual){
      if(!this.templateView){
        console.error(TAG_FASTLIST,`handleOnChildrenUpdated registerTemplate error for virtual FastList,this.templateView is null`)
      }
      this.templateView?.children.map((c,index)=>{
        this.dataSource?.registerTemplate(this,c,index,true)
      })
    }else{
      this.getTemplate().map((c,index)=>{
        // console.log(QUICKTVUI_TAG,`template: viewType：`+c.viewType+",node:"+NodeUtils.getNodeById(this.renderView.ctx,c.tag))
        this.dataSource?.registerTemplate(this,c,index,this.isVirtual)
      })
    }
    // this.dataSource?.notifyReload()
  }

  onUIAboutToAppear(ui : QTFastList){
    console.log(TAG_FASTLIST,`FastList onUIAboutToAppear`)
    this.setupDataSource(this.tag)
  }

  nativeSetupIfNeed(rootListID : number,customTemplate: QTView){
    if(!this.dataSource){
      this.setCustomTemplate(customTemplate)
      this.setupDataSource(rootListID)
    }
  }

  setupDataSource(rootListID : number){
    this.dataSource = new FastListDataSource(this.ctx,this.virtualChildren)
    this.dataSource.rootListId = rootListID
    this.dataSource.listView = this
    this.prepareTemplate()
    this.endBatchCallback = () =>{
      this.prepareTemplate()
    }
    this.ctx.getNativeRender().addEndBatchCallback(this.ctx.getRootId(),this.endBatchCallback)
    if (this.eventAttachedToWindow) {
      this.eventAttachedToWindow()
    }
  }

  onUIAboutToDisappear(){
    if(this.endBatchCallback){
      this.ctx.getNativeRender().removeEndBatchCallback(this.ctx.getRootId(),this.endBatchCallback)
    }
  }


  setProp(propKey: string, propValue: HippyAny): boolean {
    console.log(TAG_FASTLIST,`FastList:propKey:${propKey},value:${propValue}`)
    // if(propKey === 'attributes'){
    //   CommonUtils.printObject(propValue,'FastList setAttributes')
    // }
    switch (propKey){
      case "scrollOffset":
        this.scrollOffset = HRValueUtils.getNumber(propValue)
        return true;
      case "initPosition":
        let map = HRValueUtils.getMap(propValue)
        let position = HRValueUtils.getNumberValue('focusPosition',map,-1)
        if(position < 0){
          position = HRValueUtils.getNumberValue('position',map,-1)
        }
        let scrollToPosition = HRValueUtils.getNumberValue('scrollToPosition',map,-1)
        let scrollOffset = HRValueUtils.getNumberValue('scrollOffset',map,0)
        let target = HRValueUtils.getStringValue('target',map,null)
        let blockOthers = HRValueUtils.getBooleanValue('blockOthers',map,false)
        let alignCenter = HRValueUtils.getBooleanValue('alignCenter',map,false)
        let autofocus = HRValueUtils.getBooleanValue('autofocus',map,false)
        let delay = HRValueUtils.getNumberValue('delay',map,0)
        let nextTargetFocusPosition = HRValueUtils.getNumberValue('nextTargetFocusPosition',map,0)
        //TODO
        this.initialPosition = scrollToPosition
        if(delay > 0){
          setTimeout(()=>{
            this.exeScroll()
          },delay)
        }else{
          this.exeScroll()
        }
        return true;

      case "enableItemAnimator":
        return true;
      case "disableScrollOnFirstScreen":

        return true;
      case "taskPaused":

        return true;
      case "resetOnDetach":

        return true;

      case "scrollEnabled":

        return true;
      case "firstFocusChild":

        return true;

      case "enableFirstFocusAtStart":

        return true;

      case "enablePlaceholder":

        return true;
      case "refocusType":

        return true;
      case "onScrollEnable":

        return true;
      case "scrollYLesserReferenceValue":

        return true;
      case "scrollYGreaterReferenceValue":

        return true;
      case "layoutTargetPosition":

        return true;

      case "makeChildVisibleType":

        return true;

      case "makeChildVisibleClampBackward":

        return true;
      case "makeChildVisibleClampForward":

        return true;
      case "scrollThresholdHorizontal":

        return true;
      case "scrollThresholdVertical":

        return true;
      case "cachePool":

        return true;
      case "cachePoolName":

        return true;
      case "focusMemory":

        return true;
      case "pauseTaskOnHide":

        return true;
      case "setSelectChildPosition":

        return true;
      case "selectChildPosition":

        return true;
      case "shakePreCheckNumber":

        return true;
      case "placeholderFocusScale":

        return true;
      case "placeholderColorString":

        return true;
      case "placeholderColor":

        return true;
      case "placeholderBorderRadius":

        return true;
      case "preloadItemNumber":

        return true;
      case "endHintEnabled":

        return true;
      case "endShakeEnabled":

        return true;
      case "forceBlockFocusOnFail":

        return true;
      case "blockFocusOnFail":

        return true;
      case "enableSelectOnFocus":

        return true;
      case "nextTargetFocusPosition":

        return true;
      case "enableStatesOnFocus":

        return true;
      case "singleSelectPosition":

        return true;
      case "autofocusPosition":
        this.autofocusPosition = HRValueUtils.getNumber(propValue)
        return true;
      case "autoscrollPosition":
        this.initialPosition = HRValueUtils.getNumber(propValue)
        return true;
      case "autoscroll":
        let scroll = HRValueUtils.getArray(propValue as HippyArray)
        if(scroll){
          this.initialPosition = scroll[0] as number
          let force = scroll[1] as boolean
          let offset = scroll[2] as number
          this.exeScroll()
        }
        return true;
      case "list":
        let data = HRValueUtils.getArray(propValue as HippyArray)
        //this.onDataChanged(data)
        console.info(TAG_FASTLIST,`set list prop data:${data?.length} this:${ExtendUtil.debugView(this)}`)
        this.setListWithPrams(data,null)
        return true;
      case "sharedItemStore":
        return true;
      case "horizontal":
        this.isHorizontal  = HRValueUtils.getBoolean(propValue,true)
        return true;
      case "spanCount":
        let spanCount = HRValueUtils.getNumber(propValue)
        if(spanCount > 0){
          this.spanCount = ''
        }
        for(let i = 0; i < spanCount; i++){
          this.spanCount += '1fr'
          this.spanCount += ' '
        }
        if(this.spanCount && spanCount > 1){
          this.spanCount.substring(0,this.spanCount.length-1)
        }
        console.error(TAG_FASTLIST,`FastList set spanCount:${this.spanCount}:${ExtendUtil.debugView(this)}`)
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
        console.error(TAG_FASTLIST,`QTFastListView : 未实现propKey : ${propKey}`)
        return true;
      // default :
      //   console.warn(QUICKTVUI_TAG,`QTFastListView : 未知的未实现propKey : ${propKey}`)
      default:
        console.warn(`QTFastListView : 未知的未实现propKey : ${propKey}`)
    }
    return super.setProp(propKey, propValue)
  }


  public itemIndexOfDataList(itemView:QTFastItemView | null) : number{
    if(!itemView){
      return -1;
    }
    return this.virtualChildren.indexOf(itemView)
  }

  onDataChanged(data : HippyArray | null){
    console.debug(TAG_FASTLIST,`onDataChanged data size:${data ? data.length : 0} spanCount:${this.spanCount},this:${ExtendUtil.debugView(this)}`)
    if(data && data.length > 0){
      this.virtualChildren.push(...
        data?.map((item,index)=>{
          console.log(TAG_FASTLIST,`onDataChanged crate item :${CommonUtils.hippyAny2String(item)}`)
          //CommonUtils.printMapPretty(item as HippyMap,'FastListView:',false)
          let it =  new ItemView(index,item as HippyMap)
          return new QTFastItemView(this.ctx).init(this,it)
        })
      )
      this.notifyReload()
    }else{
      this.virtualChildren = []
      this.notifyReload()
    }
  }

  deleteItemRange(start : number,cout:number){
    this.virtualChildren.splice(start, cout)
    this.notifyReload()
  }

  updateItemRange(start : number,count:number,data:HippyArray){
    data?.forEach((item,index)=>{
      let itemIndex = index + start;
      let fi = this.virtualChildren[itemIndex]
      if(fi instanceof QTFastItemView){
        console.log(TAG_FASTLIST,`updateItemRange crate item :`)
        CommonUtils.printMapPretty(item as HippyMap,'FastListView:',false)
        // let it =  new ItemView(index + start,item as HippyMap)
        // fi.itemView = it
        CommonUtils.updateMap(fi.itemView?.raw,item as HippyMap)
        fi.updateTimes += 1
      }else{
        console.error(TAG_FASTLIST,`updateItemRange error item is null index:${itemIndex}`)
      }
    })
    // this.virtualChildren.splice(start,count,...replaced)
    if(count > 1){
      this.dataSource?.notifyDataChanged(start,count)
    }else{
      this.dataSource?.notifyDataChange(start)
    }
  }

  updateItemData(postion : number,data:HippyMap){
    let fi  = this.virtualChildren[postion]
    if(fi){
     let itemMap : QTMap | null | undefined=  (fi as QTFastItemView).itemView?.raw
      CommonUtils.updateMap(itemMap,data)
      this.dataSource?.notifyDataChange(postion)
    }else{
      console.warn(TAG_FASTLIST,`updateItemData error item on ${postion} is null`)
    }
  }

  insertItemRange(start : number,data:HippyArray){
    let replaced : HippyObservedArray<QTView>= []
    replaced.push(...
    data?.map((item,index)=>{
      console.log(TAG_FASTLIST,`insertItemRange crate item :`)
      CommonUtils.printMapPretty(item as HippyMap,'FastListView:',false)
      let it =  new ItemView(index + start,item as HippyMap)
      return new QTFastItemView(this.ctx).init(this,it)
    })
    )
    this.virtualChildren.splice(start,0,...replaced)
    this.dataSource?.notifyDataAddRange(start,data.length)
  }

  clearData(){
    this.virtualChildren = []
    this.notifyReload()
  }

  appendItem(data : HippyArray,deleteCount:number){
    console.log(TAG_FASTLIST,`appendItem dataSize:${data.length},deleteCount:${deleteCount}`)
      if(!this.virtualChildren || this.virtualChildren.length < 1){
        this.setListWithPrams(data,null)
      }else{
        let start = this.virtualChildren.length;
        let newData = data?.map((item,index)=>{
          console.log(TAG_FASTLIST,`insertItemRange crate item :`)
          CommonUtils.printMapPretty(item as HippyMap,'FastListView:',false)
          let it =  new ItemView(index + start,item as HippyMap)
          return new QTFastItemView(this.ctx).init(this,it)
        })
        this.virtualChildren.splice(this.virtualChildren.length - deleteCount,deleteCount,...newData)
        this.notifyReload()
      }
  }

  public notifyReload(){
    console.info(TAG_FASTLIST,`notifyReload`)
    this.dataSource?.notifyReload()
  }

  aboutToUpdate(): void {
    super.aboutToUpdate()
    this.prepareTemplate()
  }

  setListWithPrams(data:QTArray | null | undefined,params:QTAny | null | undefined){
    console.info(TAG_FASTLIST,`setListWithPrams data:${data?.length} this:${ExtendUtil.debugView(this)}`)
    if(data){
      this.onDataChanged(data)
    }else{
      this.onDataChanged(null)
    }
    this.scroller.scrollToIndex(this.initialPosition)
  }

  isGridLayout() : boolean{
    return this.spanCount != null && this.spanCount != undefined
  }

  call(method: string, params: Array<HippyAny>, callback: HippyRenderCallback | null): void {
    console.log(TAG_FASTLIST,`QTFastListView call function : ${method},params:${params}`)
      switch (method){
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
        case "useDiff":
        case "keyName":
          console.error(TAG_FASTLIST,`QTFastListView : 未实现的function : ${method}`)
          return;
      }

      switch (method){
        case 'scrollToIndex':

          break;
        case 'startScroll':

          break;
        case 'requestChildFocus':

          break;
        case 'setSelectChildPosition':

          break;
        case 'scrollToPositionWithOffset':

          break;
        case 'scrollToPosition':

          break;
        case 'updateItem':
          console.log(TAG_FASTLIST,`updateItem params length:${params.length}`)
          this.updateItemRange(params[0] as number,1,[params[1]])
          break;
        case 'updateItemRange':
          this.updateItemRange(params[0] as number,params[1] as number,params[2] as HippyArray)
          break;
        case 'insertItemRange':
          this.insertItemRange(params[0] as number,params[1] as HippyArray)
          break;
        case 'updateItemMatched':
          //TODO

          break;
        case 'deleteItemRange':
          let start = params[0] as number
          let count = params[1] as number
          console.info(TAG_FASTLIST,`deleteItemRange start:${start},end:${count}`)
          this.deleteItemRange(start,count)
          break;
        case 'setListDataWithParams':
          let dataArray = HRValueUtils.getArray(params)
          if(dataArray && dataArray[0]){
            this.setListWithPrams(dataArray[0] as QTArray,null)
          }else{
            this.setListWithPrams(null,null)
          }
          break;
        case 'setListData':
          console.error(TAG_FASTLIST,`setListData!!`)
          let data = HRValueUtils.getArray(params)
          this.setListWithPrams(data,null)
          break;
        case 'addListData':
          this.appendItem(params,0)
          break;
        case 'addListDataWithParams':
          this.appendItem(params[0] as HippyArray,params[1] as number)
          break;
        case 'scrollToTop':
          this.initialPosition = 0;
          this.exeScroll()
          break;
        case 'updateItemProps':

          break;
        case 'scrollToFocus':

          break;
        case 'dispatchItemFunction':

          break;
        case 'clearData':
          this.clearData()
          break;
        case 'setSpanCount':
          break;
        case 'searchReplaceItem':

          break;
      //with promise
        case 'dispatchItemFunctionWithPromise':

          break;
        case 'getScrollOffset':

          break;
      }
  }

}



