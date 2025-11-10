import {
  HippyObservedArray,
  NativeRenderContext,
  HippyAny,
  HIPPY_COMPONENT_KEY_PREFIX,
  HippyRenderCallback,
  buildHippyRenderView,
} from 'hippy'
import { TAG_FASTLIST, TAG_FAST_EVENT, TAG_LAYOUT, TAG_QUICKTVUI, TAG_REUSE } from '../../Constant';
import { QTPendingListView, QTView } from '../../QTTypes';
import { QTPixelUtil } from '../../utils/QTPixelUtil';
import { QTBaseComponentView } from '../QTBaseComponentView';
import QTRenderBaseView from '../QTRenderBaseView';
import { FastListUtils } from './FastListUtils';
import { ItemView } from './ItemView';
import { LayoutAttach } from './LayoutAttach';
import { applyLayoutTraverse, applyLayoutTraverseWithSkip, PathUpdate } from './TemplateViewManager';


@Observed
export class QTFastItemView extends QTRenderBaseView{


  constructor(ctx: NativeRenderContext) {
    super(ctx)
  }

  onAboutToReuse(){

  }


  setProp(propKey: string, propValue: HippyAny): boolean {
    switch (propKey) {
      case "focusScrollTarget":

        return true;
      case "firstFocusChild":

        return true;
      case "list":

        return true;
      case "sharedItemStore":

        return true;

    }
    return super.setProp(propKey, propValue)
  }

  call(method: string, params: Array<HippyAny>, callback: HippyRenderCallback | null): void {

    if (callback) {
      switch (method) {
        case 'dispatchItemFunctionWithPromise':

          break;
      }
    } else {
      switch (method) {
        case 'updateInstance':

          break;
        case 'updateItem':

          break;
        case 'batch':

          break;
        case 'updateItemProps':

          break;
        case 'dispatchItemFunction':

          break;
      }
    }

  }
}

@Reusable
@Component
export struct QTFastItem {
  @ObjectLink renderView: QTFastItemView
  @ObjectLink children: HippyObservedArray<QTView>

  build(): void {
    if(this.renderView.isEventClick()){
      Stack() {
        ForEach(this.children, (item: QTView) => {
          buildHippyRenderView(item, null)
        }, (item: QTView,index:number) => item.tag + ''+index)
      }
      .applyRenderViewBaseAttr(this.renderView)
      .onClick((event=>{
        FastListUtils.handleItemClick(this.renderView)
      }))
    }else{
      Stack() {
        ForEach(this.children, (item: QTView) => {
          buildHippyRenderView(item, null)
        }, (item: QTView,index:number) => item.tag + ''+index)
      }
      .applyRenderViewBaseAttr(this.renderView)
    }
  }

  aboutToAppear(): void {

  }

  aboutToRecycle(): void {
  }

  aboutToReuse(params: Record<string, Object>): void {
    this.renderView.onAboutToReuse()
  }
}

@Extend(Stack)
function applyRenderViewBaseAttr($$: QTBaseComponentView) {
  .key(HIPPY_COMPONENT_KEY_PREFIX + $$.tag)
  .backgroundColor($$.cssBackgroundColor)
  .position({x: $$.cssPositionX, y: $$.cssPositionY})
  .size({width:$$.cssWidth, height: $$.cssHeight})
  .opacity($$.cssOpacity)
  .clip($$.cssOverflow)
  .visibility(($$ as QTView).cssVisibility) // must add as, otherwise the compiler has error
  .zIndex($$.cssZIndex)
  .accessibilityText($$.cssAccessibilityLabel)
  .focusable($$.cssFocusable)
  .border($$.cssBorder)
  .shadow($$.cssShadow)
  .linearGradient($$.cssLinearGradient)
  .backgroundImage($$.cssBackgroundImage)
  .backgroundImageSize($$.cssBackgroundImageSize)
  .backgroundImagePosition($$.cssBackgroundImagePosition)
  .transform($$.cssMatrix)
  .rotate($$.cssRotate)
  .scale($$.cssScale)
  .translate($$.cssTranslate)
  .hitTestBehavior($$.hitTestBehavior)
  .onClick($$.eventClick)
  //tv basic
  .key($$.name)
  .id($$.sid)
  .visibility($$.visibility)
}
