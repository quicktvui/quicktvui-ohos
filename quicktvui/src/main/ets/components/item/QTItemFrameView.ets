import {
  HippyRenderBaseView,
  HippyObservedArray,
  NativeRenderContext,
  HippyAny,
  buildHippyRenderView,
} from 'hippy'
import { QTBaseComponentView, QTDivView } from '../../../../../Index';

@Observed
export class QTItemFrameView extends QTDivView {
  enableFocusBorder: boolean = false;
  // duplicateParentState:boolean = true;
  constructor(ctx: NativeRenderContext) {
    super(ctx)
    this.cssFocusable = true;
  }

  setProp(propKey: string, propValue: HippyAny): boolean {
    return super.setProp(propKey, propValue)
  }
}

@Component
export struct QTItemFrame {
  @ObjectLink renderView: QTItemFrameView
  @ObjectLink children: HippyObservedArray<HippyRenderBaseView>

  aboutToAppear() {
    this.renderView.isAttached = true;
    if(this.children[0] instanceof QTBaseComponentView){
      this.children[0].cssFocusable =  false;
      this.children[0].duplicateParentState = true;
    }

  }

  aboutToDisappear() {
    this.renderView.isAttached = false;
  }

  build() {
    Stack() {
      ForEach(this.children, (item: HippyRenderBaseView) => {
        buildHippyRenderView(item, null)
      }, (item: HippyRenderBaseView) => item.tag + '')
    }
    .applyRenderViewBaseAttr(this.renderView)
  }
}

@Extend(Stack)
function applyRenderViewBaseAttr($$: QTDivView) {
  // .key(HIPPY_COMPONENT_KEY_PREFIX + $$.tag)
  .backgroundColor($$.stateBackgroundColor)
  .position({x: $$.cssPositionX, y: $$.cssPositionY})
  .size({width:$$.cssWidth, height: $$.cssHeight})
  .opacity($$.cssOpacity)
  .clip($$.cssOverflow)
  .zIndex($$.cssZIndex)
  .accessibilityText($$.cssAccessibilityLabel)
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
  //edit by tv
  //basic
  .key($$.name)
  .scale($$.focus ? { x: $$.focusScale, y: $$.focusScale } : {})
  .clip($$.clipChildren)
  .id($$.uid? $$.uid : `real_${$$.tag}`)
  .visibility($$.visibility)
  //div
  .focusable($$.children[0].cssFocusable)
  .tabStop($$.children[0].cssFocusable)
  .border($$.focus ? $$.setBorder() : $$.border)
  .focusScopeId($$.sid, $$.focusMemory) // TODO 目前web端未验证出实际效果
  .borderRadius({
    topLeft: $$.borderTopLeftRadius,
    topRight: $$.borderTopRightRadius,
    bottomLeft: $$.borderBottomLeftRadius,
    bottomRight: $$.borderBottomRightRadius,
  })
  // .onFocus(() => {
  //   $$.focus = true
  //   $$.handleFocus($$.focus)
  // })
  // .onBlur(() => {
  //   $$.focus = false
  //   $$.handleBlur($$.focus)
  // })
}
