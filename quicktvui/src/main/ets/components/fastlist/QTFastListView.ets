
import {HippyObservedArray,NativeRenderContext,HippyAny,HippyRenderCallback,HippyArray,HippyMap} from 'hippy'
import { TAG_FASTLIST, TAG_QUICKTVUI } from '../../Constant';
import { HRValueUtils } from '../../HRValueUtils';
import { QTAny, QTArray, QTMap, QTView } from '../../QTTypes';
import { CommonUtils } from '../../utils/CommonUtils';
import { ExtendUtil } from '../../utils/ExtendUtil';

import QTRenderBaseView from '../QTRenderBaseView';
import { ItemView } from './ItemView';
import { QTFastItemView } from './QTFastItemView';
import { QTFastList } from './QTFastList';


@Observed
export class QTFastListView extends QTRenderBaseView{

  public uiCtx: UIContext | null = null
  public virtualChildren: HippyObservedArray<QTView> = new HippyObservedArray()
  public ui : QTFastList | null = null;
  isHorizontal : boolean = false;
  spanCount : string | null= null;

  constructor(ctx: NativeRenderContext) {
    super(ctx)
  }


  setProp(propKey: string, propValue: HippyAny): boolean {
    console.log(TAG_QUICKTVUI,`FastList:propKey:${propKey},value:${propValue}`)
    // if(propKey === 'attributes'){
    //   CommonUtils.printObject(propValue,'FastList setAttributes')
    // }
    switch (propKey){
      case "scrollOffset":

        return true;
      case "initPosition":

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

        return true;
      case "autoscrollPosition":

        return true;
      case "autoscroll":

        return true;
      case "list":
        let data = HRValueUtils.getArray(propValue as HippyArray)
        this.onDataChanged(data)
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
        console.error(TAG_QUICKTVUI,`FastList set spanCount:${this.spanCount}:${ExtendUtil.debugView(this)}`)
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
        console.error(TAG_QUICKTVUI,`QTFastListView : 未实现propKey : ${propKey}`)
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
    console.debug(TAG_QUICKTVUI,`onDataChanged data size:${data ? data.length : 0} spanCount:${this.spanCount},this:${ExtendUtil.debugView(this)}`)
    if(data && data.length > 0){
      this.virtualChildren.push(...
        data?.map((item,index)=>{
          console.log(TAG_QUICKTVUI,`onDataChanged crate item :`)
          CommonUtils.printMapPretty(item as HippyMap,'FastListView:',false)
          let it =  new ItemView(index,item as HippyMap)
          return new QTFastItemView(this.ctx).init(this,it)
        })
      )
      this.ui?.notifyReload()
    }else{
      this.virtualChildren = []
      this.ui?.notifyReload()
    }
  }

  deleteItemRange(start : number,cout:number){
    this.virtualChildren.splice(start, cout)
    this.ui?.notifyReload()
  }

  updateItemRange(start : number,count:number,data:HippyArray){
    let replaced : HippyObservedArray<QTView>= []
    replaced.push(...
      data?.map((item,index)=>{
        console.log(TAG_QUICKTVUI,`updateItemRange crate item :`)
        CommonUtils.printMapPretty(item as HippyMap,'FastListView:',false)
        let it =  new ItemView(index + start,item as HippyMap)
        return new QTFastItemView(this.ctx).init(this,it)
      })
    )
    this.virtualChildren.splice(start,count,...replaced)
    if(count > 1){
      this.ui?.dataSource?.notifyDataChanged(start,count)
    }else{
      this.ui?.dataSource?.notifyDataChange(start)
    }
  }

  updateItemData(postion : number,data:HippyMap){
    let fi  = this.virtualChildren[postion]
    if(fi){
     let itemMap : QTMap | null | undefined=  (fi as QTFastItemView).itemView?.raw
      CommonUtils.updateMap(itemMap,data)
      this.ui?.dataSource?.notifyDataChange(postion)
    }else{
      console.warn(TAG_FASTLIST,`updateItemData error item on ${postion} is null`)
    }
  }

  insertItemRange(start : number,data:HippyArray){
    let replaced : HippyObservedArray<QTView>= []
    replaced.push(...
    data?.map((item,index)=>{
      console.log(TAG_QUICKTVUI,`insertItemRange crate item :`)
      CommonUtils.printMapPretty(item as HippyMap,'FastListView:',false)
      let it =  new ItemView(index + start,item as HippyMap)
      return new QTFastItemView(this.ctx).init(this,it)
    })
    )
    this.virtualChildren.splice(start,0,...replaced)
    this.ui?.dataSource?.notifyDataAddRange(start,data.length)
  }

  clearData(){
    this.virtualChildren = []
    this.ui?.notifyReload()
  }

  appendItem(data : HippyArray){
      if(!this.virtualChildren || this.virtualChildren.length < 1){
        this.setListWithPrams(data,null)
      }else{
        let start = this.virtualChildren.length;
        this.virtualChildren.push(...
          data?.map((item,index)=>{
            console.log(TAG_QUICKTVUI,`insertItemRange crate item :`)
            CommonUtils.printMapPretty(item as HippyMap,'FastListView:',false)
            let it =  new ItemView(index + start,item as HippyMap)
            return new QTFastItemView(this.ctx).init(this,it)
          })
        )
        this.ui?.notifyReload()
      }
  }

  aboutToUpdate(): void {
    super.aboutToUpdate()
    if(this.ui){
      this.ui.handleOnChildrenUpdated()
    }
  }

  setListWithPrams(data:QTArray | null | undefined,params:QTAny | null | undefined){
    if(data){
      console.info(TAG_FASTLIST,`setListWithPrams data:${data?.length}`)
      this.onDataChanged(data)
    }else{
      this.onDataChanged(null)
    }
  }

  call(method: string, params: Array<HippyAny>, callback: HippyRenderCallback | null): void {
    console.log(TAG_QUICKTVUI,`QTFastListView call function : ${method},params:${params}`)
    this.uiCtx?.runScopedTask(() => {
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
          console.error(TAG_QUICKTVUI,`QTFastListView : 未实现的function : ${method}`)
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
          this.updateItemRange(params[0] as number,1,params[1] as HippyArray)
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
          console.info(TAG_QUICKTVUI,`setListData data:${HRValueUtils.getArray(params)}`)
          let data = HRValueUtils.getArray(params)
          this.setListWithPrams(data,null)
          break;
        case 'addListData':
          this.appendItem(params[0] as HippyArray)
          break;
        case 'addListDataWithParams':
          this.appendItem(params[0] as HippyArray)
          break;
        case 'scrollToTop':

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
    })
  }

}



