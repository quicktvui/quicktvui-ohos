import {NativeRenderContext} from 'hippy'
import { QTAny } from '../../QTTypes';
import { LayoutAttach } from '../fastlist/LayoutAttach';
import { QTFastListView } from "../fastlist/QTFastListView";

@Observed
export class WaterfallListView extends QTFastListView{
  pageIndex:number = -1;
  constructor(ctx: NativeRenderContext) {
    super(ctx);
    this.init()
  }

  init(){
    LayoutAttach.obtainLayoutAttach(this).name = 'WATERFALL_LISTVIEW'
    this.isVirtual = true;
    this.isHorizontal = false;
  }

  updateSections(data : QTAny,params: QTAny){
    if(data instanceof Array){
      this.setListWithPrams(data,params)
    }else{
      this.setListWithPrams(null,null)
    }
  }


}
