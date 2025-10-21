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
import {HippyObservedArray,NativeRenderContext} from 'hippy'
import {
  TAG_QUICKTVUI as TAG_QUICKTVUI, TAG_TABS} from '../../Constant';
import {HippyAny} from 'hippy'
import assertNull from '@ohos/hypium/src/main/module/assert/assertNull';

import { TabPageData } from './QTTabsView';



export class TabsDataSource implements IDataSource {
  private listeners: DataChangeListener[] = [];
  tabsData: HippyObservedArray<TabPageData> = new HippyObservedArray()

  private ctx : NativeRenderContext;

  public static  DEFAULT_TYPE : number = 1;
  public rootListId :number = -1;


  constructor(ctx : NativeRenderContext,tabsData: HippyObservedArray<TabPageData>) {
    this.ctx = ctx;
    assertNull(ctx) ?? 'ctx is null'
    this.tabsData = tabsData;
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





  public getData(index: number): TabPageData {
    console.log(TAG_TABS,`getData:${index}`)
    return this.tabsData[index]
  }


  public totalCount(): number {
    console.log(TAG_TABS,`dataSource:totalCount:${this.tabsData.length}`)
    return this.tabsData.length
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
    console.log(TAG_TABS,'notifyReload called')
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

}
