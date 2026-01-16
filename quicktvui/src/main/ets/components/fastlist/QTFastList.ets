import { QTFastListView } from "./QTFastListView"
import {HippyObservedArray,HRDiv,HIPPY_COMPONENT_KEY_PREFIX,HippyRenderBaseView,buildHippyRenderView,HippyMap,HippyEndBatchCallback} from 'hippy'
import { TAG_FASTLIST, TAG_LAYOUT, TAG_REUSE } from "../../Constant";
import { FastListDataSource } from "./FastListDataSource";
import { NodeUtils } from "../../utils/NodeUtils";
import { QTView } from "../../QTTypes";
import { QTItemRoot, QTItemRootView } from "./QTItemRootView";
import { LayoutAttach } from "./LayoutAttach";
import { QTLog } from "../../utils/QTLog";
import { ExtendUtil } from "../../utils/ExtendUtil";

@Component
export struct  QTFastList {
  @ObjectLink renderView: QTFastListView
  @ObjectLink children: HippyObservedArray<QTView>




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
    let key : string | null = ''

    if (item instanceof QTItemRootView && item.itemView){
      if(item.uid){
        return item.uid
      }
      key =  item.itemView.getItemForEachKey();
      if(!key){
        key = item.itemView.getItemId();
      }
      if(!key){
        key = item.uid;
      }
    } else{
      key =  'view-' + index
    }
    if(!key){
      QTLog.e(TAG_FASTLIST,`keyGenerate fail item:${ExtendUtil.debugView(this.renderView)},index:${index}`)
    }else{
      QTLog.d(TAG_FASTLIST,`keyGenerate key:${key} item ${ExtendUtil.debugView(item)},index:${index}`)
    }
    return key ?? '';
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
          .clip(this.renderView.clipChildren)
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
          .clip(this.renderView.clipChildren)
          .alignItems(GridItemAlignment.STRETCH)
          .columnsTemplate(this.renderView.spanCount)
          //.direction(this.renderView.isHorizontal ? Axis.Horizontal : Axis.Vertical)
          .width('100%')
          .height('100%')
          .scrollBar(BarState.Off)
          .onDidScroll((scrollOffset: number, scrollState: ScrollState) => {
            this.renderView.onDidScroll(scrollOffset,scrollState)
          })
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
            .onFocus(()=>{
              this.renderView.scroller.scrollToIndex(index,true,ScrollAlign.CENTER)
            })
            .margin(item.decoration)
          }, this.keyGenerate)
        }
        .listDirection(this.renderView.isHorizontal ? Axis.Horizontal : Axis.Vertical)
        .width('100%')
        .height('100%')
        .clip(this.renderView.clipChildren)
        .onAttach(()=>{
          console.error(TAG_FASTLIST,`List on Aattch!!`)
          // this.renderView.scroller.scrollToIndex(5)
        })
        .onDidScroll((scrollOffset: number, scrollState: ScrollState) => {
          this.renderView.onDidScroll(scrollOffset,scrollState)
        })
        .onScrollVisibleContentChange(()=>{
          this.renderView.dataSource?.makeBindEventDirty()
        })
        .scrollBar(BarState.Off)
        // .onScrollStart(()=>{
        //   this.renderView.onScrollStart()
        // })
        // .onScrollStop(()=>{
        //   this.renderView.onScrollStop()
        // })
        // .onScrollIndex((start,end,center)=>{
        //   this.renderView.onScrollIndex(start,end,center)
        // })
        .onDidScroll((scrollOffset: number, scrollState: ScrollState) => {
          this.renderView.onDidScroll(scrollOffset,scrollState)
        })
        // ContentSlot(this.renderView.childSlot)
      }
      .applyRenderViewBaseAttr(this.renderView)
    }

  }


  aboutToReuse(params: Record<string, Object>): void {
    QTLog.w(TAG_REUSE, `FastList +++ aboutToReuse this:${this.renderView.uid}`)
    this.renderView.isRecycled = false;
  }

  aboutToRecycle(): void {
    this.renderView.isRecycled = true;
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
  // .key(HIPPY_COMPONENT_KEY_PREFIX + $$.tag)
  .backgroundColor($$.cssBackgroundColor)
  .position({x: $$.cssPositionX, y: $$.cssPositionY})
  .size({width:$$.cssWidth, height: $$.cssHeight})
  .opacity($$.cssOpacity)
  .clip($$.clipChildren)
  .visibility(($$ as QTFastListView).cssVisibility) // must add as, otherwise the compiler has error
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
  .key($$.uid? $$.uid : `real_${$$.tag}`)
  .id($$.uid? $$.uid : `real_${$$.tag}`)
  .visibility($$.visibility)
}
