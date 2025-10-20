import {NativeRenderContext,HippyAny,HippyRenderCallback} from 'hippy'
import {  TAG_QUICKTVUI } from '../Constant'
import { QTView } from '../QTTypes';
import { QTPixelUtil } from '../utils/QTPixelUtil';
import { LayoutAttach } from './fastlist/LayoutAttach';
import { QTBaseComponentView } from './QTBaseComponentView';


export default abstract class QTRenderBaseView extends  QTBaseComponentView{


  constructor(ctx: NativeRenderContext) {
    super(ctx)
  }

  setProp(propKey: string, propValue: HippyAny): boolean {
    return super.setProp(propKey, propValue)
  }

  call(method: string, params: Array<HippyAny>, callback: HippyRenderCallback | null): void {
    console.info(TAG_QUICKTVUI,`call in RenderView method:${method},params:${params}`)
  }

  // // 自定义测量方法。只有 HippyAPIProvider getCustomMeasureRenderViews 方法里指定的自定义组件才会调用该方法。
  // customMeasure(width: number, widthMode: HRMeasureMode, height: number, heightMode: HRMeasureMode): HRMeasureResult {
  //   return new HRMeasureResult(0, 0)
  // }


  // notifyChildSizeChanged(child:QTView,changedView:QTView,width: number, height: number){
  //   let la = LayoutAttach.findLayoutAttach(this)
  //   if(la){
  //     if(la.isAutoWidth){
  //       la.setFixedWidth(child.cssWidth + la.getPaddingLeft() + la.getPaddingRight())
  //       QTPixelUtil.setRenderViewLayout(this,[this.cssPositionX,this.cssPositionY,la.fixedWidth,this.cssHeight])
  //     }
  //     if(la.isAutoHeight){
  //       la.setFixedHeight(child.cssHeight + la.getPaddingTop() + la.getPaddingBottom())
  //       QTPixelUtil.setRenderViewLayout(this,[this.cssPositionX,this.cssPositionY,this.cssWidth,la.fixedHeight])
  //     }
  //   }
  //   if(this.parentView instanceof QTRenderBaseView){
  //     this.parentView.notifyChildSizeChanged(this,changedView,width,height)
  //   }
  // }


}
