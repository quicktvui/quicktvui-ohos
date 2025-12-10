import {HippyObservedArray,HippyRenderBaseView} from 'hippy'
export interface TVView{
  uid:string;
  children: HippyObservedArray<HippyRenderBaseView>
  viewType:string
}