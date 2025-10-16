import {HippyMap,HippyRenderBaseView,HippyAny} from 'hippy'
import { TAG_CLICK, TAG_FAST_EVENT } from '../../Constant'
import { ExtendUtil } from '../../utils/ExtendUtil'
import { ItemView } from './ItemView'
import { LayoutAttach } from './LayoutAttach'
import { QTFastFlexView } from './QTFastFlexView'
import { QTFastListView } from './QTFastListView'
import { QTPendingListView, QTView } from '../../QTTypes'
import { CommonUtils } from '../../utils/CommonUtils'
import { QTFastItemView } from './QTFastItemView'

export class FastListUtils{

  static EVENT_CLICK = 'onItemClick'
  static EVENT_BIND = 'onBindItem'
  static EVENT_UNBIND = 'onItemRecycled'
  static EVENT_ATTACH = 'onAttachedToWindow'
  static EVENT_DETACH = 'onDetachedFromWindow'

  static handleItemClick(clickView :QTView){
    console.info(TAG_CLICK,`onClick rootID:${LayoutAttach.obtainLayoutAttach(clickView).virtualExtra.rootListId}`)
    let rootListId = LayoutAttach.obtainLayoutAttach(clickView).virtualExtra.rootListId
    if(rootListId != -1){
      let fastItem : QTFastItemView | null = FastListUtils.findItemView(clickView)
      let itemView :ItemView | null | undefined = fastItem?.itemView
      if(!itemView){
        console.error(TAG_CLICK,"handleItemClick error findItemView null ")
        return;
      }
      let parentList : QTPendingListView | null = FastListUtils.findListParent(fastItem)
      let itemPosition  = -1
      if(parentList){
        itemPosition = parentList.itemIndexOfDataList(fastItem)
      }else{
        console.error(TAG_CLICK,`handleItemClick error find pendingList null ,itemView parent:${itemView.renderView?.parentView}`)
      }
      let itemRaw = itemView.raw
      let name = LayoutAttach.obtainLayoutAttach(clickView).name
      let sid = LayoutAttach.obtainLayoutAttach(clickView).sid
      let index = clickView.parentView?.children.indexOf(clickView)
      let map = new Map<string,HippyAny>()
      let parentPosition = -1;
      if(parentList){
        let parentItem : QTFastItemView  | null = FastListUtils.findItemView(parentList as QTView)
        if(parentItem){
            parentPosition = FastListUtils.findItemPosition(parentItem)
        }else{
          console.warn(TAG_CLICK,"handleItemClick find parentItem null ")
        }
      }
      //basic
      map.set('index',index)
      map.set('sid',sid)
      map.set('position',itemPosition)
      map.set('name',name)
      if(itemRaw){
        map.set('item',itemRaw)
      }
      map.set('parentPosition',parentPosition)
      console.log(TAG_CLICK,`sendd onItemClick data:${CommonUtils.hippyMap2String(map)} `)
      ExtendUtil.sendUIEvent(clickView.ctx,rootListId,FastListUtils.EVENT_CLICK,map)
    }else{
      console.error(TAG_CLICK,`handleItemClick error rootListId is -1 clickView:${ExtendUtil.debugView(clickView)}`)
    }
  }

  static handleItemEvent(fi:QTFastItemView,eventName:string,templateEventEnable:boolean,position : number,listView:QTPendingListView){
    let rootListId = LayoutAttach.obtainLayoutAttach(fi).virtualExtra.rootListId
    if(rootListId != -1){
      let map = new Map<string,HippyAny>()
      map.set('position',position)
      map.set('name',LayoutAttach.obtainLayoutAttach(listView).name)
      ExtendUtil.sendUIEvent(fi.ctx,rootListId,eventName,map)
      console.log(TAG_FAST_EVENT,`handleItemEvent eventName:${eventName}, rootID:${rootListId},position:${position} data:${CommonUtils.hippyMap2String(map)} `)
      if(templateEventEnable){
        let templateView = fi.itemView?.template?.templateView
        if(templateView){
          map.set('item',fi.itemView?.raw)
          ExtendUtil.sendUIEvent(fi.ctx,templateView.tag,eventName,map)
        }
      }
      // console.log(TAG_FAST_EVENT,`handleItemEvent eventName:${eventName}, rootID:${rootListId},position:${position} data:${CommonUtils.hippyMap2String(map)} `)
    }else{
      console.error(TAG_FAST_EVENT,`handleItemEvent error rootListId is -1 eventName:${eventName}`)
    }

  }

  static findItemView(view:QTView | null) : QTFastItemView | null{
    if(view == null){
      return null;
    }
    if(view instanceof QTFastItemView){
      return view;
    }
    return FastListUtils.findItemView(view.parentView)
  }

  static findListParent(fastItem: QTFastItemView  |  null) : QTPendingListView | null{
    if(fastItem == null){
      return null;
    }
    return fastItem.parentList
  }

  static findItemPosition(view:QTView | null) : number{
    let fi :QTFastItemView | null = FastListUtils.findItemView(view)
    if(!fi){
      return -1;
    }
    let parentView = FastListUtils.findListParent(fi)
    if(parentView instanceof QTFastListView){
      return parentView.itemIndexOfDataList(fi)
    }
    if(parentView instanceof QTFastFlexView){
      return parentView.itemIndexOfDataList(fi)
    }
    return -1;
  }



}
