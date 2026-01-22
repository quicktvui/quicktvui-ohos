import {NativeRenderContext} from 'hippy'
import { TAG_FASTLIST, TAG_TABS } from '../../Constant';
import { QTAny, QTArray, QTView } from '../../QTTypes';
import { ExtendUtil } from '../../utils/ExtendUtil';
import { QTLog } from '../../utils/QTLog';
import { LayoutAttach } from '../fastlist/LayoutAttach';
import { QTFastListView } from "../fastlist/QTFastListView";
import { VirtualViewRegistry } from '../fastlist/VirtualViewRegistry';

@Observed
export class WaterfallListView extends QTFastListView{
  pageIndex:number = -1;
  constructor(ctx: NativeRenderContext,parentView: QTView) {
    super(ctx);
    this.parentView = parentView
    VirtualViewRegistry.getInstance().registerView(this)
    this.init()
  }

  init(){
    LayoutAttach.obtainLayoutAttach(this).name = 'WATERFALL_LISTVIEW'
    this.viewType = "WaterfallListView"
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

  public scrollToTop(smooth?: boolean): void {
    QTLog.i(TAG_TABS,`WaterfallListView scrollToTop smooth :${smooth},this:${ExtendUtil.debugView(this)}`)
    super.scrollToTop(smooth)
  }

  onDataChanged(data: QTArray | null): void {
    super.onDataChanged(data)
    QTLog.d(TAG_TABS,"WaterfallListView onDataChanged")
  }

  onDidScroll(scrollOffset: number, scrollState: ScrollState): void {
    super.onDidScroll(scrollOffset,scrollState)
    QTLog.d(TAG_TABS,`onDidScroll scrolledY:${this.onScrolledOffset}`)
  }


  onUIAboutToDisappear(): void {
    // this.scrollToTop(false)
  }

}
