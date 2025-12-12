import {HippyObservedArray,HippyRenderBaseView} from 'hippy'
export interface TVView{
  //必须和view有uid
  uid:string;
  //子view，可以空
  children: HippyObservedArray<HippyRenderBaseView>
  //view类型
  viewType:string
}