import { QTMediaSeriesView } from "./QTMediaSeriesView"
import {HippyObservedArray,HRDiv,HIPPY_COMPONENT_KEY_PREFIX,HippyRenderBaseView,buildHippyRenderView,HippyViewEvent,HippyMap,HippyEndBatchCallback} from 'hippy'
import { HREventUtils } from 'hippy/src/main/ets/renderer_native/utils/HREventUtils'
import { QTView } from "../../QTTypes";

@Component  
export struct  QTMediaSeries {
  @ObjectLink renderView: QTMediaSeriesView
  @ObjectLink children: HippyObservedArray<QTView>


  test : boolean = false

  aboutToAppear(): void {

    setTimeout(()=>{
      let event = new HippyViewEvent("onLoadPageData")
      let params = new Map<string, string|number>()
      params.set('page', 1)
      params.set('tag', this.renderView.tag)
      event.send(this.renderView.ctx, this.renderView.tag, params)


    },1000)

  }

  build() {
    Stack() {
      Text("This is a custom component A.")
      ForEach(this.children, (item: HippyRenderBaseView) => {
        buildHippyRenderView(item, null)
      }, (item: HippyRenderBaseView) => item.tag + '')
      // 该自定义组件有Hippy子组件或其它自定义子组件时，必须加Slot来衔接子组件
      ContentSlot(this.renderView.childSlot)
    }
    .applyRenderViewBaseAttr(this.renderView)
  }

  aboutToDisappear() {
    if (this.renderView.eventDetachedFromWindow) {
      this.renderView.eventDetachedFromWindow()
    }
    this.renderView.onUIAboutToDisappear()
  }

}



@Extend(Stack)
function applyRenderViewBaseAttr($$: QTMediaSeriesView) {
  .key(HIPPY_COMPONENT_KEY_PREFIX + $$.tag)
  .backgroundColor($$.cssBackgroundColor)
  .position({x: $$.cssPositionX, y: $$.cssPositionY})
  .size({width:$$.cssWidth, height: $$.cssHeight})
  .opacity($$.cssOpacity)
  .clip($$.cssOverflow)
  .visibility(($$ as QTMediaSeriesView).cssVisibility) // must add as, otherwise the compiler has error
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
