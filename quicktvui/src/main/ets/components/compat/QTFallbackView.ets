
import {HippyRenderBaseView,HippyObservedArray,HRDiv,NativeRenderContext,HippyAny,HippyRenderCallback,HIPPY_COMPONENT_KEY_PREFIX,buildHippyRenderView} from 'hippy'
import { QTDivView } from '../div/QTDivView';
import { FastListUtils } from '../fastlist/FastListUtils';
import { QTBaseComponentView } from '../QTBaseComponentView';
import QTRenderBaseView from '../QTRenderBaseView';


@Observed
export class QTFallbackView extends QTRenderBaseView{
  cssFocusable: boolean | null = true;
  constructor(ctx: NativeRenderContext) {
    super(ctx)
  }

  setProp(propKey: string, propValue: HippyAny): boolean {
    return super.setProp(propKey, propValue)
  }



}

@Component
export struct  QTFallback {
  @ObjectLink renderView: QTFallbackView
  @ObjectLink children: HippyObservedArray<HippyRenderBaseView>

  build(): void {
    if(this.renderView.isEventClick()){
      Stack() {
        ForEach(this.children, (item: HippyRenderBaseView) => {
          buildHippyRenderView(item, null)
        }, (item: HippyRenderBaseView) => item.tag + '')
        ContentSlot(this.renderView.childSlot)
      }
      .applyRenderViewBaseAttr(this.renderView)
      .onClick((event=>{
        FastListUtils.handleItemClick(this.renderView)
      }))
    }else{
      Stack() {
        ForEach(this.children, (item: HippyRenderBaseView) => {
          buildHippyRenderView(item, null)
        }, (item: HippyRenderBaseView) => item.tag + '')
        ContentSlot(this.renderView.childSlot)
      }
      .applyRenderViewBaseAttr(this.renderView)
      // .backgroundColor(Color.Pink)
    }
  }

  aboutToAppear(): void {
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
  .visibility(($$ as HippyRenderBaseView).cssVisibility) // must add as, otherwise the compiler has error
  .zIndex($$.cssZIndex)
  .accessibilityText($$.cssAccessibilityLabel)
  // .focusable($$.cssFocusable)
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
  .key($$.name)
  .id($$.sid)
  .visibility($$.visibility)
}

