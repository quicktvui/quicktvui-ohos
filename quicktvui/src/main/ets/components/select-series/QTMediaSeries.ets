import { QTMediaSeriesView } from "./QTMediaSeriesView"
import {
  HippyObservedArray,
  HRDiv,
  HIPPY_COMPONENT_KEY_PREFIX,
  HippyRenderBaseView,
  buildHippyRenderView,
  HippyViewEvent,
  HippyMap,
  HippyAny,
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
    if (this.renderView.listData.totalCount() != 0) {
      return
    }
    let event = new HippyViewEvent("onLoadPageData")
    let params = new Map<string, number>()
    params.set('page', this.renderView.pageNum++)
    params.set('tag', this.renderView.tag)
    event.send(this.renderView.ctx, this.renderView.tag, params)
    console.log(TAG_MediaSeries, `HippyViewEvent send :${this.renderView.tag}`)
  }

  @Builder
  buildFocusBorder(){
    Stack() {
      Rect({
        width: px2vp(this.renderView.initParamTemplate.width + 4),
        height: px2vp(this.renderView.initParamTemplate.height + 4),
        radius: px2vp(8),
      }).fill(Color.Transparent) // 透明填充
        .stroke(Color.White)
        .strokeWidth(px2vp(2)) // 边框宽度

      Rect({
        width: px2vp(this.renderView.initParamTemplate.width),
        height: px2vp(this.renderView.initParamTemplate.height),
        radius: px2vp(4),
      }).fill(Color.Transparent) // 透明填充
        .stroke(Color.Black)
        .position({ x: px2vp(2), y: px2vp(2) })
        .strokeWidth(px2vp(1)) // 边框宽度
    }
    .width(px2vp(this.renderView.initParamTemplate.width + 4))
    .height(px2vp(this.renderView.initParamTemplate.height + 4))
    .position({ x: -2, y: -2 })
  }

  build() {
    Stack() {
      Column() {
        List({ space: px2vp(this.renderView.initParam.itemGap), initialIndex: 0, scroller: this.renderView.scroller }) {
          LazyForEach(this.renderView.listData, (item: MyComponentParams, index: number) => {
            ListItem() {
              Stack(){
                if (this.renderView.focusStr == item.key){
                  this.buildFocusBorder()
                }
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
                }
                .width(px2vp(this.renderView.initParamTemplate.width))
                .height(px2vp(this.renderView.initParamTemplate.height))
                .backgroundColor('#80988787')
                .alignItems(VerticalAlign.Top)
                .focusable(true)
              }

            }
            .width(px2vp(this.renderView.initParamTemplate.width))
            .height(px2vp(this.renderView.initParamTemplate.height))
            .margin({
              left: index === 0 ? px2vp(120) : 0,
              right: index === this.renderView.listData.totalCount() - 1 ? px2vp(120) : 0,
            })
            .onClick(() => {
              let event = new HippyViewEvent("onItemClick")
              let params = new Map<string, string | HippyAny>()
              let dataMap = new Map<string, string>()
              dataMap.set('id', item.id!)
              params.set('position', index)
              params.set('data', dataMap)
              event.send(this.renderView.ctx, this.renderView.tag, params)
              this.renderView.focusStr = item.key;
            })
            .id(item.key)
            .onFocus(() => {
              console.log(TAG_MediaSeries, 'onFocus ListItem', item.key, this.renderView.currentTitleId)
              let event = new HippyViewEvent("onItemFocused")
              let params = new Map<string, number>()
              params.set('position', index)
              event.send(this.renderView.ctx, this.renderView.tag, params)
              this.renderView.focusStr = item.key;
              this.renderView.isSelectedButton = true;
              this.renderView.scroller.scrollToIndex(index, true, ScrollAlign.CENTER)
            })
            .onBlur(() => {
              this.renderView.focusStr = undefined;
            })
          }, (item: string) => item)
        }
        .scrollBar(BarState.On) //临时调试开启 BarState.On
        .listDirection(Axis.Horizontal) // 排列方向
        .height(px2vp(this.renderView.initParamTemplate.height + 5))
        .alignListItem(ListItemAlign.Center)
        .onReachEnd(() => {
          if (this.renderView.initParam.totalCount <= this.renderView.pageNum * this.renderView.initParam.pageSize) {
            return
          }
          let event = new HippyViewEvent("onLoadPageData")
          let params = new Map<string, number>()
          params.set('page', this.renderView.pageNum++)
          params.set('tag', this.renderView.tag)
          event.send(this.renderView.ctx, this.renderView.tag, params)
        })
        .onScrollIndex((_, __, index) => {
          if (!this.renderView.enableGroup) {
            return
          }

          this.renderView.currentTitleId = Math.floor(index / this.renderView.initParam.groupSize)
        })

        //.backgroundColor(Color.Orange)


        if (this.renderView.enableGroup) {

          List({ scroller: this.renderView.navTitleScroller }) {
            ForEach(this.renderView.generatePageData, (item: GeneratePageData, index: number) => {
              ListItem() {
                Column() {
                  Text(item.title)
                    .fontSize(px2vp(this.renderView.initParamGroup.textSize))
                    .textAlign(TextAlign.Center)
                    .fontFamily('HarmonyOS Sans')
                    .focusable(true)
                    .fontColor(this.renderView.focusStr == item.key ?
                    Color.Black :
                      (this.renderView.currentTitleId === index && this.renderView.isSelectedButton) ? Color.White :
                      this.renderView.initParamGroup.textColor.normal)
                    .focusBox({ strokeColor: ColorMetrics.rgba(255, 255, 255, 0) })
                    .backgroundColor(this.renderView.focusStr == item.key ? Color.White : Color.Transparent)
                    .borderRadius({
                      topLeft: px2vp(this.renderView.initParamGroup.focusBackground.cornerRadius?.[0]),
                      topRight: px2vp(this.renderView.initParamGroup.focusBackground.cornerRadius?.[1]),
                      bottomLeft: px2vp(this.renderView.initParamGroup.focusBackground.cornerRadius?.[2]),
                      bottomRight: px2vp(this.renderView.initParamGroup.focusBackground.cornerRadius?.[3]),
                    })
                    .padding({
                      left: px2vp(this.renderView.initParamGroup.focusBackground.padding?.[0]),
                      right: px2vp(this.renderView.initParamGroup.focusBackground.padding?.[0]),
                      top: px2vp(this.renderView.initParamGroup.focusBackground.padding?.[1]),
                      bottom: px2vp(this.renderView.initParamGroup.focusBackground.padding?.[1]),
                    })

                  Text(' ')
                    .width(px2vp(40))
                    .height(px2vp(5))
                    .backgroundColor(Color.White)
                    .borderRadius(6)
                    .visibility((this.renderView.currentTitleId === index && this.renderView.isSelectedButton) ?
                    Visibility.Visible : Visibility.Hidden)
                }
                .height(px2vp(this.renderView.initParamGroup.itemHeight))
              }
              .onClick(() => {
                if (this.renderView.currentTitleId === index) {
                  return
                }
                this.renderView.currentTitleId = index
                let _itv = setInterval(() => {
                  if (this.renderView.listData.totalCount() <= index * this.renderView.initParam.groupSize) {
                    console.log(TAG_MediaSeries, `QTMediaSeriesView:setInterval: check listData for scrollToIndex`)
                    this.renderView.scroller.scrollToIndex(this.renderView.listData.totalCount() - 1)
                  } else {
                    clearInterval(_itv)
                    //console.log(TAG_MediaSeries, `QTMediaSeriesView:setInterval:${this.renderView.listData.totalCount()} - ${index} - ${index*this.renderView.initParam.groupSize}}`);
                    this.renderView.scroller.scrollToIndex(index * this.renderView.initParam.groupSize);
                    this.renderView.currentTitleId = index
                  }
                }, 100)
              })
              .onFocus(() => {
                console.log(TAG_MediaSeries, 'onFocus Text ~~', item.key);
                this.renderView.focusStr = item.key;
                let event = new HippyViewEvent("onGroupItemFocused")
                let params = new Map<string, number>()
                params.set('position', index)
                event.send(this.renderView.ctx, this.renderView.tag, params)
                this.renderView.isSelectedButton = false;
                this.renderView.scroller.scrollToIndex(index, true, ScrollAlign.CENTER)
              })
              .onBlur(() => {
                this.renderView.focusStr = undefined;
              })
              .id(item.key)

            }, (item: GeneratePageData) => JSON.stringify(item.title))
          }
          .height(px2vp(this.renderView.initParamGroup.itemHeight + px2vp(this.renderView.initParamGroup.itemGap) / 2))
          .scrollBar(BarState.Off)
          .listDirection(Axis.Horizontal)
          .padding({
            left: px2vp(this.renderView.initParamGroup.itemGap) / 2,
            right: px2vp(this.renderView.initParamGroup.itemGap) / 2
          })
          .margin({
            left: px2vp(40),
            right: px2vp(40),
            top: px2vp(this.renderView.initParamGroup.itemGap),
            bottom: px2vp(this.renderView.initParamGroup.itemGap),
          })
        }
      }.alignItems(HorizontalAlign.Start)
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
  .backgroundColor($$.cssBackgroundColor)
  .position({ x: $$.cssPositionX, y: $$.cssPositionY })
  .size({ width: $$.cssWidth, height: $$.cssHeight })
  .opacity($$.cssOpacity)
  .clip($$.cssOverflow)
  .visibility(($$ as QTMediaSeriesView).cssVisibility) // must add as, otherwise the compiler has error
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
  //tv basic
  .key($$.name || HIPPY_COMPONENT_KEY_PREFIX + $$.tag)
  .id($$.sid)
  .visibility($$.visibility)
}
