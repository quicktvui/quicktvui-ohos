import { NodeContent } from '@kit.ArkUI'
import {
  NativeRenderContext,
  HippyAny,
  HippyCustomComponentView,
  HippyRenderCallback,
  HippyRenderBaseView,
  HippyArray,
  HippyMap
} from 'hippy'
import { TAG_QUICKTVUI } from '../Constant';
import { HRValueUtils } from '../HRValueUtils';
import { QTView } from '../QTTypes';
import { CommonUtils } from '../utils/CommonUtils';
import { LayoutAttach } from './fastlist/LayoutAttach';

export class QTBaseComponentView extends HippyCustomComponentView {
  childSlot: NodeContent | null = null
  public templateView : QTView | null = null;
  qtPadding: Padding = { top: 0, right: 0, bottom: 0, left: 0 }
  public isVirtual : boolean = false;
  constructor(ctx: NativeRenderContext) {
    super(ctx)
  }

  onCreateByTemplate(templateView : QTView){

  }

  aboutToUpdate(){

  }

  setProp(propKey: string, propValue: HippyAny): boolean {
    // console.info(TAG_QUICKTVUI,`QTRenderBaseView setProp:${propKey},propValue:${propValue}`)
    switch (propKey){
      case 'sid':
        LayoutAttach.obtainLayoutAttach(this).sid = HRValueUtils.getString(propValue)
        return true;
      case 'name':
        LayoutAttach.obtainLayoutAttach(this).name = HRValueUtils.getString(propValue)
        return true;
      case "clipChildren":
        this.cssOverflow = HRValueUtils.getBoolean(propValue,true)
        return true;
    }
    return super.setProp(propKey, propValue)
  }


  call(method: string, params: Array<HippyAny>, callback: HippyRenderCallback | null): void {
    //
    if (method == "getEsInfo") {
      if (callback) {
        const info = new Map<string, HippyAny>()
        callback(info)
      }
    }
  }
}
