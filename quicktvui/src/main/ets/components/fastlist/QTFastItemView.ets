import {
  HippyObservedArray,
  NativeRenderContext,
  HippyAny,
  HIPPY_COMPONENT_KEY_PREFIX,
  HippyRenderCallback,
  buildHippyRenderView,
} from 'hippy'
import { QTPendingListView, QTView } from '../../QTTypes';
import { QTPixelUtil } from '../../utils/QTPixelUtil';
import QTRenderBaseView from '../QTRenderBaseView';
import { ItemView } from './ItemView';
import { LayoutAttach } from './LayoutAttach';
import { applyLayoutTraverse } from './TemplateViewManager';


@Observed
export class QTFastItemView extends QTRenderBaseView{

  itemView:ItemView |  null = null;
  parentList : QTPendingListView | null = null;

  constructor(ctx: NativeRenderContext) {
    super(ctx)
  }

  init(parent : QTPendingListView,item:ItemView): QTFastItemView{
    this.parentList = parent;
    this.itemView = item
    return this;
  }


  notifyChildSizeChanged(child: QTView, changedView: QTView, width: number, height: number): void {
    // console.info(TAG_LAYOUT,`notifyChildSizeChanged on FastItem,isVirtual${this.isVirtual} changeViewType:${changedView.viewType},width:${width},height:${height},child width:${LayoutAttach.obtainLayoutAttach(child).fixedWidth}`)
    //主里直接阻断向上，只处理一层
    //super.notifyChildSizeChanged
    this.layoutItem(child)
    //this.layoutItem(child.)
  }

  layoutItem(childView:QTView ){
    if(this.parentView){
      LayoutAttach.obtainLayoutAttach(this).calculateLayout(this.parentView.cssWidth,this.parentView.cssHeight)
    }else{
      //fixme 暂时写死
      LayoutAttach.obtainLayoutAttach(this).calculateLayout(1920,1080)
    }
    applyLayoutTraverse(this)
    LayoutAttach.obtainLayoutAttach(this).setFixedWidth(LayoutAttach.obtainLayoutAttach(childView).getWidth())
    LayoutAttach.obtainLayoutAttach(this).setFixedHeight(LayoutAttach.obtainLayoutAttach(childView).getHeight())
    // console.warn(TAG_LAYOUT,`set FastItem size:[${childView.cssWidth},height:${childView.cssHeight}]`)
    QTPixelUtil.setScaledRenderViewLayout(this,[0,0,childView.cssWidth,childView.cssHeight]);
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
@Reusable
@Component
export struct QTFastItem {
  @ObjectLink renderView: QTFastItemView
  @ObjectLink children: HippyObservedArray<QTView>

  build(): void {
    Stack() {
      ForEach(this.children, (item: QTView) => {
        buildHippyRenderView(item, null)
      }, (item: QTView) => item.tag + '')
    }
    .applyRenderViewBaseAttr(this.renderView)
  }

  aboutToAppear(): void {

  }
}

@Extend(Stack)
function applyRenderViewBaseAttr($$: QTView) {
  .key(HIPPY_COMPONENT_KEY_PREFIX + $$.tag)
  .backgroundColor($$.cssBackgroundColor)
  .position({x: $$.cssPositionX, y: $$.cssPositionY})
  .size({width:$$.cssWidth, height: $$.cssHeight})
  .opacity($$.cssOpacity)
  .clip($$.cssOverflow)
  .visibility(($$ as QTView).cssVisibility) // must add as, otherwise the compiler has error
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
