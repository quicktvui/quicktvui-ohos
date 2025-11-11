import { QTMediaSeriesView } from "./QTMediaSeriesView"
import {HippyObservedArray,HRDiv,HIPPY_COMPONENT_KEY_PREFIX,HippyRenderBaseView,buildHippyRenderView,HippyViewEvent,HippyMap,HippyEndBatchCallback} from 'hippy'
import { HREventUtils } from 'hippy/src/main/ets/renderer_native/utils/HREventUtils'
import { QTView } from "../../QTTypes";

interface VipInfo {
  enable: boolean;
  text: string;
}

interface vipTitleStyle {
  width: number; height: number;
}

interface MyComponentParams {
  title?: string;
  cover?: string;
  showVip?: boolean;
  floatText?: string;
  vip?: VipInfo; // <-- 这里直接使用你定义的类型
  vipTitleStyle?: vipTitleStyle;
  index2?: string;
};


@Component  
export struct  QTMediaSeries {
  @ObjectLink renderView: QTMediaSeriesView
  @ObjectLink children: HippyObservedArray<QTView>


  test : boolean = false

  aboutToAppear(): void {

    setTimeout(()=>{
      let event = new HippyViewEvent("onLoadPageData")
      let params = new Map<string, number>()
      params.set('page', 0)
      params.set('tag', this.renderView.tag)
      event.send(this.renderView.ctx, this.renderView.tag, params)
      console.error('ffefefe', ' this.renderView.tag' , this.renderView.tag)

    },1000)

  }

  build() {
    Stack() {

      List({ space: 20, initialIndex: 0 }) {
        ForEach(this.renderView.listData, (item: MyComponentParams,index:number) => {
          ListItem() {
            Text( item.title)
              .width('20%').height(100).fontSize(16)
              .textAlign(TextAlign.Center).borderRadius(10).backgroundColor(0xFFFFFF)
          }
        }, (item: string) => item)
      }
      .listDirection(Axis.Horizontal) // 排列方向

      ForEach(this.children, (item: HippyRenderBaseView) => {
        buildHippyRenderView(item, null)
      }, (item: HippyRenderBaseView) => item.tag + '')
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
