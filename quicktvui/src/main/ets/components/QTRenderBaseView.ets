import {NativeRenderContext,HippyAny,HippyRenderCallback,HippyCustomComponentView,HippyRenderBaseView} from 'hippy'
import {  TAG_QUICKTVUI } from '../Constant'
import { QTView } from '../QTTypes';
import { QTBaseComponentView } from './QTBaseComponentView';

type InsertListener = (childTag: number, childViewName: string, childIndex: number)=>void;

export default abstract class QTRenderBaseView extends  QTBaseComponentView{

  private listeners: InsertListener[] = [];


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

  addSubRenderView(subView: QTView, index: number): void {
    super.addSubRenderView(subView,index)
  }

  onChildInserted(childTag: number, childViewName: string, childIndex: number): void {

    this.listeners.forEach(listener => {
      listener(childTag,childViewName,childIndex);
    });
  }

  onChildRemoved(childTag: number, childViewName: string, childIndex: number): void {

  }


  notifyChildSizeChanged(child:QTView,changedView:QTView,width: number, height: number){

    if(this.parentView instanceof QTRenderBaseView){
      this.parentView.notifyChildSizeChanged(this,changedView,width,height)
    }
  }


  // 注册监听器
  addListener(listener: InsertListener): void {
    this.listeners.push(listener);
  }

  // 移除监听器
  removeListener(listener: InsertListener): void {
    const index = this.listeners.indexOf(listener);
    if (index !== -1) {
      this.listeners.splice(index, 1);
    }
  }

  clearListener():void{
    this.listeners = []
  }


}
