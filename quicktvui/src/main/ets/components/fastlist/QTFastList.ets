import { QTFastListView } from "./QTFastListView"
import {HippyObservedArray,HRDiv,HIPPY_COMPONENT_KEY_PREFIX,HippyRenderBaseView,buildHippyRenderView,HippyMap,HippyEndBatchCallback} from 'hippy'
import { TAG_FASTLIST, TAG_LAYOUT, TAG_REUSE } from "../../Constant";
import { FastListDataSource } from "./FastListDataSource";
import { NodeUtils } from "../../utils/NodeUtils";
import { QTView } from "../../QTTypes";
import { QTItemRoot, QTItemRootView } from "./QTItemRootView";
import { LayoutAttach } from "./LayoutAttach";
import { QTLog } from "../../utils/QTLog";

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
    if (item instanceof QTItemRootView && item.itemView){
      return item.itemView.getItemForEachKey();
    } else{
      return 'view-' + index
    }
    /*if(item instanceof QTItemRootView){
      let id = LayoutAttach.obtainLayoutAttach(item).sid
      if(id){
        QTLog.d(TAG_REUSE,`keyGenerate id from sid:${id}`)
        return id +'-'+ item.updateTimes
      }
      if(item.itemView){
        id =  item.itemView.getItemId()
        if(id){
          QTLog.d(TAG_REUSE,`keyGenerate id by item:${id}`)
          return LayoutAttach.obtainLayoutAttach(item).virtualExtra.itemType + ''+ id + '-'+item.updateTimes;
        }else{
          // QTLog.d(TAG_REUSE,`keyGenerate id with fi-:${index}-${item.updateTimes}`)
        }
        return `fi-:${index}-${item.updateTimes}`
      }
    }else{
      // QTLog.d(TAG_REUSE,`keyGenerate use fallback -:${index}`)
    }
    return 'view-'+index*/
  }


  build(): void {
    if(this.renderView.spanCount){
      if(this.renderView.isHorizontal){
        Stack() {
          Grid(this.renderView.scroller){
            LazyForEach(this.renderView.dataSource,(item : QTItemRootView,index : number)=>{
              GridItem() {
                QTItemRoot({
                  renderView:item as QTItemRootView,
                  children: item.children,
                }).reuseId(item.getReuseId())
              }
              .margin(item.decoration)
            }, this.keyGenerate)
          }
          .scrollBar(BarState.Off)
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
            LazyForEach(this.renderView.dataSource,(item : QTItemRootView,index : number)=>{
              GridItem() {
                QTItemRoot({
                  renderView:item as QTItemRootView,
                  children: item.children,
                }).reuseId(item.getReuseId())
              }
              .margin(item.decoration)
            }, this.keyGenerate)
          }

          .alignItems(GridItemAlignment.STRETCH)
          .columnsTemplate(this.renderView.spanCount)
          //.direction(this.renderView.isHorizontal ? Axis.Horizontal : Axis.Vertical)
          .width('100%')
          .height('100%')
          .scrollBar(BarState.Off)
          // ContentSlot(this.renderView.childSlot)
        }
        .applyRenderViewBaseAttr(this.renderView)
      }
    }else{
      Stack() {
        List({ space: this.renderView.listSpace, initialIndex: this.renderView.initialPosition, scroller: this.renderView.scroller }){
          LazyForEach(this.renderView.dataSource,(item : QTItemRootView,index : number)=>{
            ListItem() {
              QTItemRoot({
                renderView:item as QTItemRootView,
                children: item.children,
              })
                .reuseId(item.getReuseId())
            }
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
        .scrollBar(BarState.Off)
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
  //tv basic
  .key($$.name)
  .id($$.sid)
  .visibility($$.visibility)
}
