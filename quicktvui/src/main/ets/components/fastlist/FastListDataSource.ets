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
  TAG_LAYOUT as TAG_LAYOUT, TAG_QUICKTVUI as TAG_QUICKTVUI } from '../../Constant';
import {HippyMap,HippyArray,HippyAny} from 'hippy'
import {ItemView,getItemType, ItemTemplate} from './ItemView'
import assertNull from '@ohos/hypium/src/main/module/assert/assertNull';
import {buildRenderViewTraverse, PathUpdate,applyLayoutTraverse} from './TemplateViewManager'
import { NodeUtils } from '../../utils/NodeUtils';
import { QTFastItemView } from './QTFastItemView';
import { QTBaseComponentView } from '../QTBaseComponentView';
import { LayoutAttach } from './LayoutAttach';
import { CommonUtils } from '../../utils/CommonUtils';
import { QTView } from '../../QTTypes';


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
  private templates: HippyObservedArray<QTView> = [];
  private dataList: HippyObservedArray<QTView> = [];

  private ctx : NativeRenderContext;
  private templatesMap : Map<number,ItemTemplate> = new Map()

  public static  DEFAULT_TYPE : number = 1;
  public rootListId :number = -1;

  constructor(ctx : NativeRenderContext,dataList:HippyObservedArray<QTView>) {
    this.ctx = ctx;
    assertNull(ctx) ?? 'ctx is null'
    // this.mockData()
    this.dataList = dataList;
  }

  public setTemplates(templates : HippyObservedArray<QTView>){
    this.templates = templates;
    console.info(TAG_QUICKTVUI, `setTemplates total:${templates.length}`)
  }

  public itemIndexOfDataList(itemView:QTFastItemView) : number{
    return this.dataList.indexOf(itemView)
  }

  public registerTemplate(parent:QTView, child: QTView,childIndex: number,isVirtual : boolean  = false){
    let childTag =  child.tag
    // if(isVirtual && child instanceof QTBaseComponentView){
    //   console.error(QUICKTVUI_TAG,`registerTemplat isVirtual template ,childTag:${child.templateView?.tag},viewName:${child.viewType}`)
    //   childTag = child.templateView!!.tag
    // }
    let childViewName = child.viewType
    let node = NodeUtils.getNodeById(this.ctx,childTag)
    // let renderView = getRenderView(this.ctx,childTag)
    if(child == null || node == null){
      console.error(TAG_QUICKTVUI,`registerTemplate error renderView:${child},node:${node},viewName:${childViewName}`)
      return;
    }
    if(node?.props){
      let type =  getItemType(node.props)
      //如果用户没设，给一个默认的值
      if(!type){
         type = FastListDataSource.DEFAULT_TYPE
      }
      if(type && child){
        console.log(TAG_QUICKTVUI,`registerTemplate type:${type},node.props:${CommonUtils.hippyMap2String(node.props)}`)
        let it : ItemTemplate = new ItemTemplate(child,type,node.props)
        this.templatesMap.set(type,it)
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

  fillContent(renderView : QTView,wi : QTFastItemView){
    wi.isVirtual = true;
    wi.addSubRenderView(renderView,0)
    LayoutAttach.obtainLayoutAttach(wi).insertChild(LayoutAttach.obtainLayoutAttach(renderView),0)
  }


  public buildItem(fi: QTFastItemView,position:number){
    let item: ItemView = fi.itemView!!
    let type = getItemType(item.raw)
    if(!type){
      type = FastListDataSource.DEFAULT_TYPE
    }
    if(item.raw instanceof  Map){
        item.id = FastListDataSource.getIdFromData(item.raw)
    }
    if(!item.id){
      item.id = item.position +''
      console.error(TAG_QUICKTVUI,`put fallback id :${item.position}`)
    }
    if(type){
      let it = this.templatesMap.get(type);
      item.template = it;
      if(it){
        let  updates:Array<PathUpdate> = []
        //1. 遍历模板和数据，生成根布局
        let rv = buildRenderViewTraverse(this.rootListId,this.ctx,it.templateView,it.props,item.raw as HippyMap,null,0,updates)
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
          if(p.renderView instanceof  QTBaseComponentView){
            p.renderView.aboutToUpdate()
          }
        })
        //包裹一层fastItem，如果用户没有写的话
        // if(rv){
        //   rv = this.wrappedItemIfNeed(rv);
        // }
        //item.renderView = wrapped;
        this.fillContent(rv!!,fi)
        //3. 执行所有props
        updates?.map((p)=>{
          p.props.forEach((value,key)=>{
            // console.log(QUICKTVUI_TAG,`updates p :${p.renderView.viewType},prop:${key},value:${value}`)
            //更新所有属性
            let handle = false
            switch (key){
              case 'showIf':
                p.renderView.cssVisibility = value ? Visibility.Visible : Visibility.Hidden
                handle = true;
                break;
            }
            if(!handle){
              p.renderView.setProp(key,value)
            }
          })
        })
        //在属性全部执行完以后，计算layout
        if(fi && rv){
          if(fi instanceof QTFastItemView){
            fi.layoutItem(rv)
            console.error(TAG_LAYOUT,`setItem Width:${fi.cssWidth},height:${fi.cssHeight}`)
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

      }else{
        console.error(TAG_QUICKTVUI,'getData error template is null')
      }
    }else{
      console.error(TAG_QUICKTVUI,'getData type is undefined')
    }

    // return item.renderView as QTFastItemView
  }

  public preCreateAll(){

  }

  public getData(index: number): QTFastItemView {
    let fi = this.dataList[index] as QTFastItemView
    this.buildItem(fi,index)
    // console.log(TAG_QUICKTVUI,`getData index:${index}`)
    if(fi.cssWidth < 1 || fi.cssHeight < 1){
      console.error(TAG_LAYOUT,`getData layout Error index:${index}`)
    }
    // if(item.renderView){
    //   NodeUtils.printViewTreePretty(item.renderView,'',false)
    // }
    return fi as QTFastItemView
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
    console.log(TAG_QUICKTVUI,`dataSource:totalCount:${this.dataList.length}`)
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
    console.log(TAG_QUICKTVUI,'notifyReload called')
    this.listeners.forEach(listener => {
      listener.onDataReloaded();
    })
  }

  notifyDataAdd(index : number) {
    this.listeners.forEach(listener => {
      listener.onDataAdd(index)
    })
  }

  notifyDataAddRange(index : number,count:number) {
    this.listeners.forEach(listener => {
      listener.onDataReloaded()
    })
  }

  notifyDataRemove(index: number){
    this.listeners.forEach(listener => {
      listener.onDataDelete(index)
    })
  }

  notifyDataMove(from: number,to:number){
    this.listeners.forEach(listener => {
      listener.onDataMove(from,to)
    })
  }

  notifyDataChanged(start: number,count:number){
    this.listeners.forEach(listener => {
      listener.onDataReloaded()
    })
  }

  notifyDataChange(index: number){
    this.listeners.forEach(listener => {
      listener.onDataChange(index)
    })
  }

  mockData(){
    // const total = 100;
    // for(let i = 0; i < total; i++){
    //   let map : Map<string, HippyAny> = new Map()
    //   map.set('type',10001)
    //   let item = new ItemView(i,map)
    //   this.dataList.push(item)
    // }
    // this.notifyReload()
  }
}
