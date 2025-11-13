import { QTMediaSeriesView } from "./QTMediaSeriesView"
import {
  HippyObservedArray,
  HRDiv,
  HIPPY_COMPONENT_KEY_PREFIX,
  HippyRenderBaseView,
  buildHippyRenderView,
  HippyViewEvent,
  HippyMap,
  HippyEndBatchCallback
} from 'hippy'
import { HREventUtils } from 'hippy/src/main/ets/renderer_native/utils/HREventUtils'
import { QTView } from "../../QTTypes";
import { MyComponentParams } from './types/index';
import { TAG_MediaSeries } from '../../Constant';

@Component
export struct QTMediaSeries {
  @ObjectLink renderView: QTMediaSeriesView
  @ObjectLink children: HippyObservedArray<QTView>
  test: boolean = false

  aboutToAppear(): void {

    setTimeout(() => {
      let event = new HippyViewEvent("onLoadPageData")
      let params = new Map<string, number>()
      params.set('page', 0)
      params.set('tag', this.renderView.tag)
      event.send(this.renderView.ctx, this.renderView.tag, params)
      console.log(TAG_MediaSeries, `HippyViewEvent send :${this.renderView.tag}`)
    }, 0)

  }

  build() {
    Stack() {

      List({ space: 20, initialIndex: 0 }) {
        ForEach(this.renderView.listData, (item: MyComponentParams,index:number) => {
          ListItem() {
            Row() {
              Image(item.cover)
                .width('45%')
                .height('100%')
                .borderRadius({
                  topLeft: 10,
                  bottomLeft: 10
                })
              Column(){
                Text(item.title)
                  .fontSize(px2vp(28))
                  .textAlign(TextAlign.Start)
                  .fontColor(item.showVip?"#FFFFD97C":"#FFFFFFFF")
                  .maxLines(3)
                  .textOverflow({ overflow: TextOverflow.Ellipsis })
              }
              .width('55%')
              .height(px2vp(160))
              .alignItems(HorizontalAlign.Start)
              .justifyContent(FlexAlign.Start)
              .padding(10)
              Text(item.floatText)
                .position({
                  x: 10,
                  y: 76
                })
                .backgroundColor('#803E3838')
                .fontColor(0xFFFFFF)
                .borderRadius(4)
                .padding({
                  left: 4,
                  right: 4
                })
              Image(item.cover)
                .position({
                  x: -70,
                  y: 70
                })
                .width(40)
                .aspectRatio(1)
                .borderRadius(20)
            }
            .width('30%')
            .height(px2vp(160))
            .borderRadius(10)
            .backgroundColor('#80988787')
            .alignItems(VerticalAlign.Top)
          }
        }, (item: string) => item)
      }
      .scrollBar(BarState.Off)
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
  .position({ x: $$.cssPositionX, y: $$.cssPositionY })
  .size({ width: $$.cssWidth, height: $$.cssHeight })
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
