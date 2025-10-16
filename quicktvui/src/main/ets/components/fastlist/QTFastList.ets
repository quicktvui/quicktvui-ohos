import { QTFastListView } from "./QTFastListView"
import {HippyObservedArray,HRDiv,HIPPY_COMPONENT_KEY_PREFIX,HippyRenderBaseView,buildHippyRenderView,HippyMap,HippyEndBatchCallback} from 'hippy'
import { TAG_FASTLIST, TAG_LAYOUT } from "../../Constant";
import { FastListDataSource } from "./FastListDataSource";
import { NodeUtils } from "../../utils/NodeUtils";
import { QTView } from "../../QTTypes";
import { QTFastItem, QTFastItemView } from "./QTFastItemView";
import { LayoutAttach } from "./LayoutAttach";

@Component
export struct  QTFastList {
  @ObjectLink renderView: QTFastListView
  @ObjectLink children: HippyObservedArray<QTView>


  test : boolean = false





  // 监听autoSize变化的回调函数
  onAutoSizeChange(newValue: number[], oldValue: number[]) {
    console.error(TAG_FASTLIST,'onAutoSizeChange notifyReload')
    // let la = LayoutAttach.obtainLayoutAttach(this.renderView)
    // if(la.isAutoWidth){
    //   console.info(TAG_LAYOUT,`AutoWidth changed from ${oldValue} to [${newValue[0]},${newValue[1]}]`)
    //   la.setWidth(newValue[0])
    //   this.renderView.cssWidth = newValue[0]
    // }
    // if(la.isAutoHeight){
    //   la.setWidth(newValue[1])
    //   this.renderView.cssHeight = newValue[1]
    // }
    this.renderView.notifyReload()
  }



  keyGenerate(item : QTView,index : number) : string{
    if(item instanceof QTFastItemView){
      let id = LayoutAttach.obtainLayoutAttach(item).sid
      if(id){
        // console.debug(TAG_FASTLIST,`keyGenerate id from sid:${id}`)
        return id +'-'+ item.updateTimes
      }
      if(item.itemView){
        id =  item.itemView.getItemId()
        if(id){
          // console.debug(TAG_FASTLIST,`keyGenerate id by item:${id}`)
          return LayoutAttach.obtainLayoutAttach(item).virtualExtra.itemType + ''+ id + '-'+item.updateTimes;
        }
        return `fi-:${index}-${item.updateTimes}`
      }
    }
    return 'view-'+index
  }


  build(): void {
    if(this.renderView.spanCount){
      if(this.renderView.isHorizontal){
        Stack() {
          Grid(this.renderView.scroller){
            LazyForEach(this.renderView.dataSource,(item : QTFastItemView,index : number)=>{
              GridItem() {
                QTFastItem({
                  renderView:item as QTFastItemView,
                  children: item.children,
                }).reuseId(item.getReuseId())
              }
            }, this.keyGenerate)
          }
          .alignItems(GridItemAlignment.STRETCH)
          .rowsTemplate(this.renderView.spanCount)
          //.direction(this.renderView.isHorizontal ? Axis.Horizontal : Axis.Vertical)
          .width('100%')
          .height('100%')
          // ContentSlot(this.renderView.childSlot)
        }
        .applyRenderViewBaseAttr(this.renderView)
      }else{
        Stack() {
          Grid(this.renderView.scroller){
            LazyForEach(this.renderView.dataSource,(item : QTFastItemView,index : number)=>{
              GridItem() {
                QTFastItem({
                  renderView:item as QTFastItemView,
                  children: item.children,
                }).reuseId(item.getReuseId())
              }
            }, this.keyGenerate)
          }
          .alignItems(GridItemAlignment.STRETCH)
          .columnsTemplate(this.renderView.spanCount)
          //.direction(this.renderView.isHorizontal ? Axis.Horizontal : Axis.Vertical)
          .width('100%')
          .height('100%')
          // ContentSlot(this.renderView.childSlot)
        }
        .applyRenderViewBaseAttr(this.renderView)
      }
    }else{
      Stack() {
        List({ space: this.renderView.listSpace, initialIndex: this.renderView.initialPosition, scroller: this.renderView.scroller }){
          LazyForEach(this.renderView.dataSource,(item : QTFastItemView,index : number)=>{
            ListItem() {
              QTFastItem({
                renderView:item as QTFastItemView,
                children: item.children,
              }).reuseId(item.getReuseId())
            }
            .width(item?.cssWidth)
            .height(item?.cssHeight)
            .margin(item.decoration)
          }, this.keyGenerate)
        }
        .listDirection(this.renderView.isHorizontal ? Axis.Horizontal : Axis.Vertical)
        .width('100%')
        .height('100%')
        .onAttach(()=>{
          console.error(TAG_FASTLIST,`List on Aattch!!`)
          // this.renderView.scroller.scrollToIndex(5)
        })
        .onScrollVisibleContentChange(()=>{
          this.renderView.dataSource?.makeBindEventDirty()
        })
        // ContentSlot(this.renderView.childSlot)
      }
      .applyRenderViewBaseAttr(this.renderView)
    }

  }







  aboutToAppear(): void {
    this.renderView.onUIAboutToAppear(this)

  }

  aboutToDisappear() {
    if (this.renderView.eventDetachedFromWindow) {
      this.renderView.eventDetachedFromWindow()
    }
    this.renderView.clearListener()
    this.renderView.onUIAboutToDisappear()
  }

}



@Extend(Stack)
function applyRenderViewBaseAttr($$: QTFastListView) {
  .key(HIPPY_COMPONENT_KEY_PREFIX + $$.tag)
  .backgroundColor($$.cssBackgroundColor)
  .position({x: $$.cssPositionX, y: $$.cssPositionY})
  .size({width:$$.cssWidth, height: $$.cssHeight})
  .opacity($$.cssOpacity)
  .clip($$.cssOverflow)
  .visibility(($$ as QTFastListView).cssVisibility) // must add as, otherwise the compiler has error
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
}
