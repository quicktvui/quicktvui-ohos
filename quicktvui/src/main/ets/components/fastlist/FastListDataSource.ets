/*
 * Tencent is pleased to support the open source community by making
 * Hippy available.
 *
 * Copyright (C) 2022 THL A29 Limited, a Tencent company.
 * All rights reserved.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *   http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */
import {HippyObservedArray,NativeRenderContext,NativeRender,HRRect} from 'hippy'
import {
  TAG_FASTLIST,
  TAG_FAST_EVENT,
  TAG_LAYOUT as TAG_LAYOUT, TAG_QUICKTVUI as TAG_QUICKTVUI,
  TAG_REUSE } from '../../Constant';
import {HippyMap,HippyAny} from 'hippy'
import {ItemView,getItemType, ItemTemplate} from './ItemView'
import assertNull from '@ohos/hypium/src/main/module/assert/assertNull';
import {PathUpdate, PendingPathUpdate, TemplateViewManager} from './TemplateViewManager'
import { NodeUtils } from '../../utils/NodeUtils';
import { QTItemRootView } from './QTItemRootView';
import { QTBaseComponentView } from '../QTBaseComponentView';
import { LayoutAttach } from './LayoutAttach';
import { QTArray, QTMap, QTPendingListView, QTView } from '../../QTTypes';
import { FastListUtils } from './FastListUtils';
import { HRValueUtils } from '../../HRValueUtils';
import { QTPixelUtil } from '../../utils/QTPixelUtil';
import { QTFastFlexView } from './QTFastFlexView';
import { QTFastListView } from './QTFastListView';
import { QTLog } from '../../utils/QTLog';
import { ExtendUtil } from '../../utils/ExtendUtil';




// class ItemEntry{
//   position: number;
//   raw:HippyAny;
//   constructor(position: number, raw : HippyAny) {
//     this.position = position
//     this.raw = raw
//   }
// }

export class FastListDataSource implements IDataSource {
  private listeners: DataChangeListener[] = [];
  private dataList: HippyObservedArray<QTView> = [];

  private ctx : NativeRenderContext;
  private templatesMap : Map<number,ItemTemplate> = new Map()

  public static  DEFAULT_TYPE : number = 1;
  public rootListId :number = -1;
  public listView : QTPendingListView | null = null;
  public rootListView : QTFastListView | null = null;

  private bindEventDirty : boolean = true;
  private lastEventPosition = -1;

  private itemStore : QTView | null = null;
  templateViewManager : TemplateViewManager ;

  constructor(ctx : NativeRenderContext,dataList:HippyObservedArray<QTView>) {
    this.ctx = ctx;
    assertNull(ctx) ?? 'ctx is null'
    // this.mockData()
    this.dataList = dataList;
    this.templateViewManager = new TemplateViewManager();
  }

  public static getItemStoreFromParentList(parentList:QTFastListView) : QTView | null{
    let itemStore : QTView | null = null;
    parentList.children?.map((child)=>{
      if(child.viewType == 'ItemStoreView'){
        itemStore = child;
      }
    })
    return itemStore;
  }

  public registerParentItemStore(){
    QTLog.fatal(TAG_FASTLIST,`regist item registerParentItemStore ${ExtendUtil.debugView(this.listView)}`)
    if(this.listView){
      if(this.listView?.isVirtual && this.rootListId ==  -1){
        QTLog.fatal(TAG_FASTLIST,`regist item rootListID不可为空,return`)
        return;
      }
      if(this.listView.isVirtual && this.rootListId){
        let parentList = NodeUtils.getRenderView(this.ctx,this.rootListId)
        if(parentList instanceof QTFastListView){
          let itemStore=  FastListDataSource.getItemStoreFromParentList(parentList)
          if(!itemStore){
            QTLog.e(TAG_FASTLIST,`regist item itemStore :${itemStore},this rootListID:${this.rootListId},parentList:${ExtendUtil.debugView(parentList)}`)
          }
          itemStore?.children.map((c)=>{
            QTLog.d(TAG_FASTLIST,`regist item from rootList child :${ExtendUtil.debugView(c)}`)
            this.registerTemplate(c,true)
          })
        }else{
          QTLog.fatal(TAG_FASTLIST,`regist item store error parent :${parentList?.viewType},rootListID:${this.rootListId}，this:${ExtendUtil.debugView(this.listView)}`)
        }
      }else{
        QTLog.fatal(TAG_FASTLIST,`regist item error isVirtual :${this.listView.isVirtual},rootLitID:${this.rootListId},this:${ExtendUtil.debugView(this.listView)}`)
      }
    }else{
      QTLog.fatal(TAG_FASTLIST,`regist item error listView null `)
    }
  }

  public registerTemplates(templates : HippyObservedArray<QTView>,isVirtual : boolean  = false){
    templates?.map((child)=>{
      if(child.tag != -1){
        this.registerTemplate(child,isVirtual)
      }
    })
    if(this.itemStore){
      if(this.listView?.isVirtual && this.rootListId ==  -1){
        QTLog.fatal(TAG_FASTLIST,`rootListID不可为空,return`)
        return;
      }
        this.itemStore.children.map((c)=>{
          QTLog.d(TAG_FASTLIST,`register itemStore child:${c.viewType}`)
          this.registerTemplate(c,true)
        })
    }else{
      this.registerParentItemStore()
    }
    // this.notifyReload()

  }

  public itemIndexOfDataList(itemView:QTItemRootView) : number{
    return this.dataList.indexOf(itemView)
  }

  public registerTemplate( child: QTView,isVirtual : boolean  = false){
    let childTag =  child.tag
    let childViewName = child.viewType
    let node = NodeUtils.getNodeById(this.ctx,childTag)
    // let renderView = getRenderView(this.ctx,childTag)
    if(child == null || node == null){
      QTLog.d(TAG_FASTLIST,`registerTemplate error renderView:${child},node:${node},viewName:${childViewName}`)
      return;
    }
    if(node?.props){
      let type =  getItemType(node.props)
      //如果用户没设，给一个默认的值
      if(!type){
         type = FastListDataSource.DEFAULT_TYPE
      }
      if(type && child){
        QTLog.d(TAG_FASTLIST,`registerTemplate type:${type},viewType:${child.viewType} this ${ExtendUtil.debugView(this.listView)}`)
        if(child.viewType == 'ItemStoreView'){
          this.itemStore = child;
        }else{
          let it : ItemTemplate = new ItemTemplate(child,type,node.props)
          this.templatesMap.set(type,it)
        }
      }
    }
  }

  static getIdFromData(item : HippyAny) : string | null{
    let id : string | null = null
    if(item instanceof Map){
      if(item.has('_id')){
        id = item.get('_id') as string
      }
      if(!id && item.has('sid')){
        id = item.get('sid') as string
      }
    }
    return id
  }



  // wrappedItemIfNeed(renderView : QTView,item:ItemView) : QTFastItemView{
  //   if(renderView.viewType == 'FastItemView'){
  //     (renderView as QTFastItemView).itemView = item;
  //     return renderView as QTFastItemView;
  //   }else{
  //     let wi = new QTFastItemView(this.ctx)
  //     wi.itemView = item;
  //     wi.tag = -1
  //     wi.isVirtual = true;
  //     wi.viewType = 'FastItemView'
  //     // let layout = new HRRect(0,0,renderView.cssWidth,renderView.cssHeight)
  //     // QTPixelUtil.setScaledRenderViewFrame(wi,layout,null)
  //     wi.addSubRenderView(renderView,0)
  //     LayoutAttach.obtainLayoutAttach(wi).insertChild(LayoutAttach.obtainLayoutAttach(renderView),0)
  //     return wi;
  //   }
  // }

  fillContent(type:number,renderView : QTView,wi : QTItemRootView){
    wi.isVirtual = true;

    wi.setContent(type,renderView)
    LayoutAttach.obtainLayoutAttach(wi).virtualExtra.rootListId = this.rootListId

  }

  public getTemplateByType(type:number) : ItemTemplate | undefined{
    //先从itemStore里寻找
    // if(this.itemStore){
    //   this.itemStore.children.map((child)=>{
    //     let childTag =  child.tag
    //     let childViewName = child.viewType
    //     let node = NodeUtils.getNodeById(this.ctx,childTag)
    //     // let renderView = getRenderView(this.ctx,childTag)
    //     if(child == null || node == null){
    //       console.error(TAG_FASTLIST,`getTemplateByType in itemStore error renderView:${child},node:${node},viewName:${childViewName}`)
    //       return;
    //     }
    //   })
    // }

    let it = this.templatesMap.get(type);

    return it
  }

  public static findItemViewSize(props:QTMap,position:number,data:QTMap,layout:number[]){
      if(data.has('layout')){
        QTLog.d(TAG_FASTLIST,`findItemViewSize has Layout :${data.get('layout')}`)
        let array = data.get('layout') as QTArray
        for(let i = 0; i < 4; i ++){
          layout[i] = QTPixelUtil.getDimensionValue(array[i])
        }
        return;
      }
      if(data.has('size')){
        let array = data.get('size') as QTArray
        QTLog.d(TAG_FASTLIST,`findItemViewSize has size :${data.get('size')}`)
        layout[2] =  QTPixelUtil.getDimensionValue(array[0])
        layout[3] =  QTPixelUtil.getDimensionValue(array[1])
        return;
      }
      if(data.has('flexStyle')){
        QTLog.d(TAG_FASTLIST,`findItemViewSize has flexStyle :${data.get('flexStyle')}`)
        let map = data.get('flexStyle') as QTMap
        layout[0] =  QTPixelUtil.getDimensionValue(map.get('left'))
        layout[1] =  QTPixelUtil.getDimensionValue(map.get('top'))
        layout[2] =  QTPixelUtil.getDimensionValue(map.get('width'))
        layout[3] =  QTPixelUtil.getDimensionValue(map.get('height'))
      }
      if(layout[2] < 1 && data.has('width')){
        QTLog.d(TAG_FASTLIST,`findItemViewSize has width :${data.get('width')}`)
        layout[2] =  QTPixelUtil.getDimensionValue(data.get('width'))
      }
      if(layout[3] < 1 && data.has('height')){
        QTLog.d(TAG_FASTLIST,`findItemViewSize has height :${data.get('height')}`)
        layout[3] = QTPixelUtil.getDimensionValue(data.get('height'))
      }
      if(layout[2] < 1 || layout[3] < 1){
        if(props && props.has('style')){
          QTLog.d(TAG_FASTLIST,`findItemViewSize has style :${data.get('style')}`)
          if(layout[2] < 1){
            layout[2] = QTPixelUtil.getDimensionValue(props.get('width'))
          }
          if(layout[3] < 1){
            layout[3] = QTPixelUtil.getDimensionValue(props.get('height'))
          }
        }
      }

  }


  public buildItem(fi: QTItemRootView,position:number){
    let item: ItemView = fi.itemView!!
    let type = getItemType(item.raw)
    if(!type){
      type = FastListDataSource.DEFAULT_TYPE
    }
    // if(!fi.updateDirty && fi.children[0]){
    //   QTLog.w(TAG_FASTLIST,`buildItem position:${position} reutrn on content not empty`)
    //   return;
    // }
    if(item.raw instanceof  Map){
        item.id = FastListDataSource.getIdFromData(item.raw)
        let decoration = item.raw.get('decoration')
        if(decoration instanceof Map){
          fi.decoration.left = HRValueUtils.getNumberValue('left',decoration,0)
          fi.decoration.top = HRValueUtils.getNumberValue('top',decoration,0)
          fi.decoration.right = HRValueUtils.getNumberValue('right',decoration,0)
          fi.decoration.bottom = HRValueUtils.getNumberValue('bottom',decoration,0)
          QTPixelUtil.devPadding2Vp(fi.decoration)
        }
      fi.itemData = item.raw
    }
    fi.dataPosition = position

    if(!item.id){
      item.id = item.position +''
      console.error(TAG_QUICKTVUI,`put fallback id :${item.position}`)
    }
    let it = this.getTemplateByType(type);
    let singleTon = it?.props.has('singleton')
    if(type){
      LayoutAttach.obtainLayoutAttach(fi).virtualExtra.itemType = type;
      if(singleTon){
        QTLog.e(TAG_FASTLIST,`singleton Item type:${type},position:${position}`)
      }
      if(it){
        item.template = it;
        let updates:Array<PathUpdate> = []
        let rv : QTView | null = null;
        if(singleTon){
          if(item.template?.templateView){
            rv = item.template?.templateView
            if(rv.parentView && rv.parentView != fi){
              rv.parentView.removeSubView(rv)
            }
            this.fillContent(type,rv,fi)
            this.templateViewManager.gatherToUpdateMapTraverse(rv,it.templateView,it.props,item.raw as HippyMap,null,updates,true)
            //只处理tv-item的pending props
            // let u = gatherToUpdateMap(rv,it.props!!,item.raw!!,null)
            // if(u){
            //   updates.push(u)
            // }
            // updates.map((p)=>{
            //   QTLog.d(TAG_FASTLIST,`singleTon update viewType:${p.renderView.viewType},props:${p.props}`)
            // })
          }else{
            QTLog.fatal(TAG_FASTLIST,`singleton itemView error view is null`)
          }
        }else{
          if(fi.contentView){
            if(fi.contentType == type){
              // QTLog.d(TAG_REUSE,`buildItem use cached View pos:${position}`)
              //updates = fi.updates;
              rv = fi.contentView;
              // this.templateViewManager.gatherToUpdateMapTraverse(rv,it.templateView,it.props,item.raw as HippyMap,null,updates,false)
            }else{
              fi.pendingUpdates = []
              rv = this.templateViewManager.buildRenderViewTraverse(this.rootListId,this.ctx,it.templateView,it.props,item.raw as HippyMap,null,0,updates)
              this.fillContent(type,rv!!,fi)
              // fi.updates = updates;
            }
          }else{
            fi.pendingUpdates = []
            rv = this.templateViewManager.buildRenderViewTraverse(this.rootListId,this.ctx,it.templateView,it.props,item.raw as HippyMap,null,0,updates)
            this.fillContent(type,rv!!,fi)
            // fi.updates = updates;
          }
          //在属性全部执行完以后，计算layout

          //更新layout
          // updates?.map((p)=>{
          //   //更新尺寸
          //   let attach = LayoutAttach.obtainLayoutAttach(p.renderView);
          //   let layout = new HRRect(attach.getLeft(),attach.getTop(),attach.getWidth(),attach.getHeight());
          //   console.log(TAG_LAYOUT,`post update layout:layout:x:${layout.x},y:${layout.y},width:${layout.width},height:${layout.height} renderView:${p.renderView.viewType}:name:${attach.name}`)
          //   if(p.renderView === rv){
          //     //根view
          //     let rect = new HRRect(0,0,attach.getWidth(),attach.getHeight())
          //     QTPixelUtil.setScaledRenderViewFrame(wrapped,rect,null)
          //     QTPixelUtil.setScaledRenderViewFrame(p.renderView,rect,null)
          //   }else{
          //     QTPixelUtil.setScaledRenderViewFrame(p.renderView,layout,null)
          //   }
          //
          // })
        }
        //1. 遍历模板和数据，生成根布局
        // let wrapped = this.wrappedItemIfNeed(rv!!,item);
        //2. 预先执行所有update

        updates?.map((p)=>{
          //更新尺寸
          // let layout = new HRRect(p.layout[0],p.layout[1],p.layout[2],p.layout[3]);
          // if(p.renderView === rv){
          //   //根view
          //   QTPixelUtil.setScaledRenderViewFrame(wrapped,layout,null)
          //   QTPixelUtil.setScaledRenderViewFrame(p.renderView,new HRRect(0,0,p.layout[2],p.layout[3]),null)
          // }else{
          //   QTPixelUtil.setScaledRenderViewFrame(p.renderView,layout,null)
          // }
          if(p.pendingProps){
            let pendingProp = new PendingPathUpdate(p.renderView,p.pendingProps)
            fi.pendingUpdates.push(pendingProp)
          }
          if(p.renderView instanceof  QTBaseComponentView){
            p.renderView.aboutToUpdate()
          }
        })
        //包裹一层fastItem，如果用户没有写的话
        // if(rv){
        //   rv = this.wrappedItemIfNeed(rv);
        // }
        //item.renderView = wrapped;

        //3. 执行所有props
        TemplateViewManager.applyPatchUpdate(updates)

        if(fi && rv){
          if(fi instanceof QTItemRootView){
            fi.layoutItem(rv,this.listView instanceof  QTFastFlexView,singleTon)
            let layout : number[] = [0,0,0,0]
            if(singleTon){
              FastListDataSource.findItemViewSize(it.props,position,item.raw as QTMap,layout)
              QTLog.i(TAG_LAYOUT,`singleTon findItemViewSize width:${layout[2]},height:${layout[3]},cssWidth:${fi.cssWidth},cssHeight:${fi.cssHeight}，childWidth:${rv.cssWidth},childHeight:${rv.cssHeight}`)
              let itemWidth = fi.cssWidth
              let itemHeight = fi.cssHeight
              if(itemWidth < 1){
                itemWidth = QTPixelUtil.dev2Vp(layout[2]);
              }
              if(itemHeight < 1){
                itemHeight = QTPixelUtil.dev2Vp(layout[3]);
              }
              QTPixelUtil.setRenderViewLayout(fi,[0,0,itemWidth,itemHeight])
            }
          }else{
            console.error(TAG_FASTLIST,`buildItemError !!!`)
            // LayoutAttach.obtainLayoutAttach(item.renderView).calculateLayout(800,600)
            // applyLayoutTraverse(item.renderView)
            // //强制itemView的宽高与item内部一致
            // console.error(TAG_LAYOUT,`setItem Width:${LayoutAttach.obtainLayoutAttach(rv).getWidth()},height:${LayoutAttach.obtainLayoutAttach(rv).getHeight()}`)
            // QTPixelUtil.setScaledRenderViewFrame(item.renderView,new HRRect(0,0,
            // LayoutAttach.obtainLayoutAttach(rv).getWidth(),
            // LayoutAttach.obtainLayoutAttach(rv).getHeight()),null)
          }
        }else{
          console.error(TAG_QUICKTVUI,`error on rv is null`)
        }

      }else{
        QTLog.fatal(TAG_FASTLIST,`getData error type:${type} template is null position:${position},this;${ExtendUtil.debugView(this.listView)}`)
      }
    }else{
      QTLog.fatal(TAG_FASTLIST,'getData type is undefined')
    }

    // return item.renderView as QTFastItemView
  }

  public preCreateAll(){

  }

  public static updateItem(from: QTItemRootView,to: QTItemRootView){
    let updates:Array<PathUpdate> = []
    let rv : QTView | null = from.children[0];

    // gatherToUpdateMapTraverse(rv,it.templateView,it.props,item.raw as HippyMap,null,updates,true)
  }

  public getItemFromDataList(index : number){

  }

  public getData(index: number): QTItemRootView {
    let fi = this.dataList[index] as QTItemRootView
    let item: ItemView = fi.itemView!!
    let type = getItemType(item.raw)
    // if(!fi.contentType || fi.contentType != type || fi.updateDirty){
    if(true){
      try{
        this.buildItem(fi,index)
      }catch (error){
        QTLog.e(TAG_FASTLIST,`buildItem error :${error}`)
      }
      fi.updateDirty = false;
    }
    // QTLog.d(TAG_LAYOUT,`getData index:${index},data:${fi},this listView:${ExtendUtil.debugView(this.listView)},width:${fi.cssWidth},height:${fi.cssHeight}`)
    // console.log(TAG_FASTLIST,`getData index:${index}`)
    console.log(TAG_REUSE,`getData index:${index}`)
    if(fi.cssWidth < 1 || fi.cssHeight < 1){
      console.error(TAG_LAYOUT,`getData layout Error index:${index}`)
    }
    // if(item.renderView){
    //   NodeUtils.printViewTreePretty(item.renderView,'',false)
    // }
    if(this.bindEventDirty || this.lastEventPosition != index){
      FastListUtils.handleItemEvent(fi,FastListUtils.EVENT_BIND,true,index,this.listView!!)
      this.lastEventPosition = index;
      this.bindEventDirty = false;
    }

    return fi as QTItemRootView
  }

  makeBindEventDirty(){
    this.bindEventDirty = true;
  }

  // public setListData(rawList : HippyArray){
  //   this.dataList = []
  //   this.notifyReload()
  // }

  // setListDataInner(data : ItemView[]){
  //   this.dataList = data;
  //   this.itemCount = this.dataList.length
  // }

  // 添加新数据
  // public addData(item: ItemView): void {
  //   this.dataList.push(item);
  //   this.notifyDataAdd(this.dataList.length - 1);
  // }

  public totalCount(): number {
    // console.log(TAG_FASTLIST,`dataSource:totalCount:${this.dataList.length},this:${ExtendUtil.debugView(this.listView)}`)
    return this.dataList.length
  }

  registerDataChangeListener(listener: DataChangeListener): void {
    if (this.listeners.indexOf(listener) < 0) {
      this.listeners.push(listener);
    }
  }

  unregisterDataChangeListener(listener: DataChangeListener): void {
    const pos = this.listeners.indexOf(listener);
    if (pos >= 0) {
      this.listeners.splice(pos, 1);
    }
  }

  notifyReload() {
    QTLog.w(TAG_FASTLIST,`notifyReload called this:${ExtendUtil.debugView(this.listView)},data count:this.${this.dataList.length}`)
    this.listeners.forEach(listener => {
      listener.onDataReloaded();
    })
  }

  notifyDataAdd(index : number) {
    QTLog.w(TAG_FASTLIST,`notifyDataAdd index:${index}`)
    this.listeners.forEach(listener => {
      listener.onDataAdd(index)
    })
  }

  notifyDataAddRange(index : number,count:number) {
    QTLog.w(TAG_FASTLIST,`notifyDataAddRange index:${index},count:${count}`)
    this.listeners.forEach(listener => {
      listener.onDataReloaded()
    })
  }

  notifyDataRemove(index: number){
    QTLog.w(TAG_FASTLIST,`notifyDataRemove index:${index}`)
    this.listeners.forEach(listener => {
      listener.onDataDelete(index)
    })
  }

  notifyDataMove(from: number,to:number){
    QTLog.w(TAG_FASTLIST,`notifyDataMove from:${from},to:${to}`)
    this.listeners.forEach(listener => {
      listener.onDataMove(from,to)
    })
  }

  notifyDataChanged(start: number,count:number){
    QTLog.w(TAG_FASTLIST,`notifyDataChanged start:${start},count:${count}`)
    this.listeners.forEach(listener => {
      listener.onDataReloaded()
    })
  }

  notifyDataChange(index: number){
    QTLog.w(TAG_FASTLIST,`notifyDataChanged index:${index}`)
    this.listeners.forEach(listener => {
      listener.onDataChange(index)
    })
  }
}
