import {
  HippyObservedArray,
  NativeRenderContext,
  HippyAny,
  HIPPY_COMPONENT_KEY_PREFIX,
  HippyRenderCallback,
  buildHippyRenderView,
} from 'hippy'
import { TAG_FASTLIST, TAG_FAST_EVENT, TAG_LAYOUT, TAG_QUICKTVUI, TAG_REUSE } from '../../Constant';
import { QTPendingListView, QTView } from '../../QTTypes';
import { QTPixelUtil } from '../../utils/QTPixelUtil';
import { QTDivView } from '../div/QTDivView';
import QTRenderBaseView from '../QTRenderBaseView';
import { ItemView } from './ItemView';
import { LayoutAttach } from './LayoutAttach';
import { applyLayoutTraverse, applyLayoutTraverseWithSkip } from './TemplateViewManager';


@Observed
export class ItemStoreView extends QTRenderBaseView{

  constructor(ctx: NativeRenderContext) {
    super(ctx)
  }

}

@Component
export struct ItemStore {
  @ObjectLink renderView: ItemStoreView
  @ObjectLink children: HippyObservedArray<QTView>

  build(): void {
    Stack() {
      ForEach(this.children, (item: QTView) => {
        buildHippyRenderView(item, null)
      }, (item: QTView,index:number) => item.tag + ''+index)
    }
    .applyRenderViewBaseAttr(this.renderView)
    .backgroundColor(Color.Pink)
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
