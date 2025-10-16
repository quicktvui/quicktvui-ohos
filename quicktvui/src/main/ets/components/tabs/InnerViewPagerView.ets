
import {HippyRenderBaseView,HippyObservedArray,HRDiv,NativeRenderContext,HippyAny,HippyRenderCallback,HIPPY_COMPONENT_KEY_PREFIX,buildHippyRenderView} from 'hippy'
import { QTFastListView, QTTabsView } from '../../../../../Index';
import { TAG_QUICKTVUI, TAG_TABS } from '../../Constant';
import { QTView } from '../../QTTypes';
import { CommonUtils } from '../../utils/CommonUtils';
import { ExtendUtil } from '../../utils/ExtendUtil';
import QTRenderBaseView from '../QTRenderBaseView';


@Observed
export class InnerViewPagerView extends QTRenderBaseView{

  static VIEW_NAME = "RecyclerViewPager"
  templateListView: QTFastListView | null = null;

  constructor(ctx: NativeRenderContext) {
    console.warn(TAG_TABS,'create InnerViewPagerView')
    super(ctx)
  }

  setProp(propKey: string, propValue: HippyAny): boolean {
    console.log(TAG_TABS,`viewpager:setProp propKey:${propKey},propValue:${CommonUtils.hippyAny2String(propValue)}`)
    switch (propKey) {
      case "direction":
        return true;
      case "disableTransform":
        return true;
      case "slidingEnable":
        return true;
      case "initTranslation":
        return true;
      case "rightTranslation":
        return true;
      case "leftTranslation":
        return true;
      case "duration":
        return true;
      case "interpolatorType":
        return true;
      case "useTouchClickMode":
        return true;
      case "focusSearchEnabled":
        return true;
      case "useAdvancedFocusSearch":
        return true;
      case "listenFocusSearchOnFail":
        return true;
      case "enableTransform":
        return true;
      case "offscreenPageLimit":
        return true;
      case "slidingMode":
        return true;

      default :
        break;
    }

    return super.setProp(propKey, propValue)
  }

  addSubRenderView(subView: HippyRenderBaseView, index: number): void {
    super.addSubRenderView(subView,index)
    if(subView instanceof QTFastListView){
      this.templateListView = subView;
      if(this.parentView instanceof QTTabsView){
        this.parentView.onPageTemplateReady(subView)
      }
    }
    console.debug(TAG_TABS,`waterfall template ${ExtendUtil.debugView(subView)}`)

  }

  call(method: string, params: Array<HippyAny>, callback: HippyRenderCallback | null): void {
    console.log(TAG_TABS,`viewpager:call function:${method},params:${CommonUtils.hippyAny2String(params)}`)
    switch (method){
      case 'setPageData':
        break;
      case 'setPage':
        break;
      case 'setIndex':
        break;
      case 'next':
        break;
      case 'prev':
        break;
      case 'translationLeft':
        break;
      case 'translationRight':
        break;
      case 'setPageWithoutAnimation':
        break;
    }
  }

}

@Component
export struct  InnerViewPager {
  @ObjectLink renderView: InnerViewPagerView
  @ObjectLink children: HippyObservedArray<QTView>

  build(): void {
    // Stack() {
    //   ForEach(this.children, (item: QTView) => {
    //     buildHippyRenderView(item, null)
    //   }, (item: QTView) => item.tag + '')
    // }
    // .applyRenderViewBaseAttr(this.renderView)
    // .backgroundColor(Color.Blue)
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

