import {
  HippyObservedArray,
  NativeRenderContext,
  HIPPY_COMPONENT_KEY_PREFIX,
} from 'hippy'
import { QTPendingListView, QTView } from '../../QTTypes';
import QTRenderBaseView from '../QTRenderBaseView';


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
    // Stack() {
    //   ForEach(this.children, (item: QTView) => {
    //     buildHippyRenderView(item, null)
    //   }, (item: QTView,index:number) => item.tag + ''+index)
    // }
    // .applyRenderViewBaseAttr(this.renderView)
    // .backgroundColor(Color.Pink)
  }

  aboutToAppear(): void {

  }


}

@Extend(Stack)
function applyRenderViewBaseAttr($$: QTView) {
  .key(HIPPY_COMPONENT_KEY_PREFIX + $$.tag)
  .backgroundColor(Color.Orange)
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
}
