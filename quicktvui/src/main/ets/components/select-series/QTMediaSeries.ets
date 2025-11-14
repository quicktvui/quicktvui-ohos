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
import { GeneratePageData, MyComponentParams } from './types/index';
import { TAG_MediaSeries } from '../../Constant';
import { ColorMetrics } from "@kit.ArkUI";

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
      Column() {
        List({ space: px2vp(this.renderView.initParam.itemGap), initialIndex: 0 }) {
          ForEach(this.renderView.listData, (item: MyComponentParams, index: number) => {
            ListItem() {
              Row() {
                Image(item.cover)
                  .width(px2vp(this.renderView.initParamTemplate.extra.imgWidth))
                  .height(px2vp(this.renderView.initParamTemplate.extra.imgHeight))
                Column() {
                  Text(item.title)
                    .fontSize(px2vp(this.renderView.initParamTemplate.titleSize))
                    .textAlign(TextAlign.Start)
                    .fontColor(item.showVip ? "#FFFFD97C" : "#FFFFFFFF")
                    .maxLines(3)
                    .textOverflow({ overflow: TextOverflow.Ellipsis })
                    .fontFamily('HarmonyOS Sans')
                }
                .width(px2vp(this.renderView.initParamTemplate.width -
                this.renderView.initParamTemplate.extra.imgWidth))
                .height(px2vp(this.renderView.initParamTemplate.height))
                .alignItems(HorizontalAlign.Start)
                .justifyContent(FlexAlign.Start)
                .padding(10)

                Text(item.floatText)
                  .position({
                    x: 10,
                    y: 70
                  })
                  .backgroundColor('#803E3838')
                  .fontColor(0xFFFFFF)
                  .borderRadius(4)
                  .padding({
                    left: 4,
                    right: 4
                  })
                  .fontFamily('HarmonyOS Sans')
                  .fontSize(px2vp(this.renderView.initParamTemplate.floatTitleSize))
                Image(item.cover)
                  .position({
                    x: -60,
                    y: 70
                  })
                  .width(30)
                  .aspectRatio(1)
                  .borderRadius(20)
              }
              .width(px2vp(this.renderView.initParamTemplate.width))
              .height(px2vp(this.renderView.initParamTemplate.height))
              .backgroundColor('#80988787')
              .alignItems(VerticalAlign.Top)
            }
          }, (item: string) => item)
        }
        .scrollBar(BarState.Off)
        .listDirection(Axis.Horizontal) // 排列方向

        if (this.renderView.initParam.enableGroup) {
          Column() {
            List({ space: px2vp(this.renderView.initParamGroup.itemGap), scroller: this.renderView.navTitleScroller }) {
              ForEach(this.renderView.generatePageData, (item: GeneratePageData, index: number) => {
                ListItem() {
                  Column() {
                    Text(item.title)
                      .fontSize(px2vp(this.renderView.initParamGroup.textSize))
                      .textAlign(TextAlign.Center)
                      .fontFamily('HarmonyOS Sans')
                      .fontColor(this.renderView.currentTitleId === index ? '#FFFFFF' :
                      this.renderView.initParamGroup.textColor.normal)
                      .onClick(() => {
                        // this.listChange(index, true);
                      })
                      .onFocus(() => {
                        // this.listChange(index, true);
                      })
                      .focusable(true)
                    // .focusBox({
                    //   strokeColor: ColorMetrics.rgba(0, 0, 0, 0),
                    // })
                    Text(' ') {
                    }
                    .width(24)
                    .height(3)
                    .backgroundColor('#ffffff')
                    .borderRadius(2)
                    .margin({ top: 4 })
                    .visibility(this.renderView.currentTitleId === index ? Visibility.Visible : Visibility.Hidden)
                  }
                  .width(px2vp(this.renderView.initParamGroup.itemWidth))
                  .height(px2vp(this.renderView.initParamGroup.itemHeight))
                }
              }, (item: GeneratePageData) => JSON.stringify(item.title))
            }
            .scrollBar(BarState.Off)
            .listDirection(Axis.Horizontal)
          }
          .alignItems(HorizontalAlign.Start)
          .width('100%')
        }

        ForEach(this.children, (item: HippyRenderBaseView) => {
          buildHippyRenderView(item, null)
        }, (item: HippyRenderBaseView) => item.tag + '')
      }
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
