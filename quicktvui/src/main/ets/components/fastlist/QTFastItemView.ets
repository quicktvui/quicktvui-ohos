import {
  HippyObservedArray,
  NativeRenderContext,
  HippyAny,
  HIPPY_COMPONENT_KEY_PREFIX,
  HippyRenderCallback,
  buildHippyRenderView,
} from 'hippy'
import { TAG_FOCUS } from '../../Constant';
import { QTView } from '../../QTTypes';
import { ExtendUtil } from '../../utils/ExtendUtil';
import { QTLog } from '../../utils/QTLog';
import { QTBaseComponentView } from '../QTBaseComponentView';
import QTRenderBaseView from '../QTRenderBaseView';
import { TVView } from '../TVView';
import { FastListUtils } from './FastListUtils';
import { LayoutAttach } from './LayoutAttach';


@Observed
export class QTFastItemView extends QTRenderBaseView{


  constructor(ctx: NativeRenderContext) {
    super(ctx)
  }

  onAboutToReuse(){
    
  }

  getContentWidth(){
    return this.children[0].cssWidth
  }

  getContentHeight(){
    return this.children[0].cssHeight
  }

  addFocusables(views: TVView[], direction: number): boolean {
    if(!super.addFocusables(views,direction)){
      //证明自身是不可获焦的
      if (this.children && this.children.length > 0) {
        this.children.forEach((child: QTView) => {
          if(child instanceof QTBaseComponentView){
            child.addFocusables(views,direction)
          }else if (child.cssFocusable === true) {
            QTLog.e(TAG_FOCUS,`addFocusables skip focusable view : ${ExtendUtil.debugView(child)}`)
          }
        });
      }
    }
    return true;
  }


  setProp(propKey: string, propValue: HippyAny): boolean {
    switch (propKey) {
      case "focusScrollTarget":

        return true;
      case "firstFocusChild":

        return true;
      case "list":

        return true;
      case "sharedItemStore":

        return true;

    }
    return super.setProp(propKey, propValue)
  }

  call(method: string, params: Array<HippyAny>, callback: HippyRenderCallback | null): void {

    if (callback) {
      switch (method) {
        case 'dispatchItemFunctionWithPromise':

          break;
      }
    } else {
      switch (method) {
        case 'updateInstance':

          break;
        case 'updateItem':

          break;
        case 'batch':

          break;
        case 'updateItemProps':

          break;
        case 'dispatchItemFunction':

          break;
      }
    }

  }
}


// @Reusable
@Component
export struct QTFastItem {
  @ObjectLink renderView: QTFastItemView
  @ObjectLink children: HippyObservedArray<QTView>

  build(): void {
    if(this.renderView.isEventClick()){
      Stack() {
        ForEach(this.children, (item: QTView) => {
          buildHippyRenderView(item, null)
        }, (item: QTView,index:number) => item.tag + ''+index)
      }
      .applyRenderViewBaseAttr(this.renderView)
      .position({x:0,y:0})
      .width(this.children[0].cssWidth)
      .height(this.children[0].cssHeight)
      .onClick((event=>{
        FastListUtils.handleItemClick(this.renderView)
      }))
    }else{
      Stack() {
        ForEach(this.children, (item: QTView) => {
          buildHippyRenderView(item, null)
        }, (item: QTView,index:number) => item.tag + ''+index)
      }
      .applyRenderViewBaseAttr(this.renderView)
      .position({x:0,y:0})
      .width(this.children[0].cssWidth)
      .height(this.children[0].cssHeight)
    }
  }

  aboutToAppear(): void {
    if(this.children[0]){
      if(this.renderView.cssWidth < 1){
        this.renderView.cssWidth = this.children[0].cssWidth
        LayoutAttach.obtainLayoutAttach(this.renderView).fixedWidth = this.children[0].cssWidth
      }
      if(this.renderView.cssHeight< 1){
        this.renderView.cssHeight = this.children[0].cssHeight
        LayoutAttach.obtainLayoutAttach(this.renderView).fixedHeight = this.children[0].cssHeight
      }
    }

  }

  aboutToRecycle(): void {
  }

  aboutToReuse(params: Record<string, Object>): void {
    this.renderView.onAboutToReuse()
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
  .visibility(($$ as QTView).cssVisibility) // must add as, otherwise the compiler has error
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
  .key($$.name)
  .id($$.sid)
  .visibility($$.visibility)
}
