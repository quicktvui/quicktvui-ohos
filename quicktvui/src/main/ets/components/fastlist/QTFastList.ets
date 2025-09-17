import { QTFastListView } from "./QTFastListView"
import {HippyObservedArray,HRDiv,HIPPY_COMPONENT_KEY_PREFIX,HippyRenderBaseView,buildHippyRenderView,HippyMap,HippyEndBatchCallback} from 'hippy'
import { TAG_LAYOUT, TAG_QUICKTVUI } from "../../Constant";
import { FastListDataSource } from "./FastListDataSource";
import { NodeUtils } from "../../utils/NodeUtils";
import { QTView } from "../../QTTypes";
import { QTFastItem, QTFastItemView } from "./QTFastItemView";

@Component
export struct  QTFastList {
  @ObjectLink renderView: QTFastListView
  @ObjectLink children: HippyObservedArray<QTView>

  test : boolean = false
  dataSource: FastListDataSource | null = null;
  @State bgColor : Color = Color.Yellow
  private endBatchCallback: HippyEndBatchCallback | null = null

  // 监听autoSize变化的回调函数
  onAutoSizeChange(newValue: number[], oldValue: number[]) {
    console.error(TAG_LAYOUT,'onAutoSizeChange notifyReload')
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
    this.notifyReload()
  }



  build(): void {
    if(this.renderView.spanCount){
      if(this.renderView.isHorizontal){
        Stack() {
          Grid(){
            LazyForEach(this.dataSource,(item : QTFastItemView,index : number)=>{
              GridItem() {
                QTFastItem({
                  renderView:item as QTFastItemView,
                  children: item.children,
                })
              }
            })
          }
          .alignItems(GridItemAlignment.STRETCH)
          .rowsTemplate(this.renderView.spanCount)
          //.direction(this.renderView.isHorizontal ? Axis.Horizontal : Axis.Vertical)
          .width('100%')
          .height('100%')
          // ContentSlot(this.renderView.childSlot)
        }
        .applyRenderViewBaseAttr(this.renderView)
        .backgroundColor(this.bgColor)
      }else{
        Stack() {
          Grid(){
            LazyForEach(this.dataSource,(item : QTFastItemView,index : number)=>{
              GridItem() {
                QTFastItem({
                  renderView:item as QTFastItemView,
                  children: item.children,
                })
              }
            })
          }
          .alignItems(GridItemAlignment.STRETCH)
          .columnsTemplate(this.renderView.spanCount)
          //.direction(this.renderView.isHorizontal ? Axis.Horizontal : Axis.Vertical)
          .width('100%')
          .height('100%')
          // ContentSlot(this.renderView.childSlot)
        }
        .applyRenderViewBaseAttr(this.renderView)
        .backgroundColor(this.bgColor)
      }
    }else{
      Stack() {
        List(){
          LazyForEach(this.dataSource,(item : QTFastItemView,index : number)=>{
            ListItem() {
              QTFastItem({
                renderView:item as QTFastItemView,
                children: item.children,
              })
            }
            .width(item?.cssWidth)
            .height(item?.cssHeight)
          })
        }
        .listDirection(this.renderView.isHorizontal ? Axis.Horizontal : Axis.Vertical)
        .width('100%')
        .height('100%')
        // ContentSlot(this.renderView.childSlot)
      }
      .applyRenderViewBaseAttr(this.renderView)
      .backgroundColor(this.bgColor)
    }

  }

  public notifyReload(){
    this.dataSource?.notifyReload()
  }

  public handleOnChildrenUpdated() {
    // this.bgColor = Color.Pink
    console.log(TAG_QUICKTVUI,`QTFastList: handleOnChildrenUpdated children:${this.children.length}`)
    NodeUtils.printViewTreePretty(this.renderView,'',false)
    if(this.renderView.isVirtual){
      console.error(TAG_QUICKTVUI,`handleOnChildrenUpdated registerTemplate for virtual FastList`)
      this.renderView.templateView?.children.map((c,index)=>{
        this.dataSource?.registerTemplate(this.renderView,c,index,true)
      })
    }else{
      this.children.map((c,index)=>{
        // console.log(QUICKTVUI_TAG,`template: viewType：`+c.viewType+",node:"+NodeUtils.getNodeById(this.renderView.ctx,c.tag))
        this.dataSource?.registerTemplate(this.renderView,c,index,this.renderView.isVirtual)
      })
    }
  }



  aboutToAppear(): void {
    console.log(TAG_QUICKTVUI,`FastList aboutToAppear childrenCount:${this.children.length}`)
    this.renderView.uiCtx = this.getUIContext()
    this.dataSource = new FastListDataSource(this.renderView.ctx,this.renderView.virtualChildren)
    this.dataSource.rootListId = this.renderView.tag
    this.renderView.ui  = this

    this.handleOnChildrenUpdated()
    this.endBatchCallback = () =>{
      this.handleOnChildrenUpdated()
    }
    this.renderView.ctx.getNativeRender().addEndBatchCallback(this.renderView.ctx.getRootId(),this.endBatchCallback)
    if (this.renderView.eventAttachedToWindow) {
      this.renderView.eventAttachedToWindow()
    }
  }

  aboutToDisappear() {
    if (this.renderView.eventDetachedFromWindow) {
      this.renderView.eventDetachedFromWindow()
    }
    this.renderView.clearListener()
    if(this.endBatchCallback){
      this.renderView.ctx.getNativeRender().removeEndBatchCallback(this.renderView.ctx.getRootId(),this.endBatchCallback)
    }
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
