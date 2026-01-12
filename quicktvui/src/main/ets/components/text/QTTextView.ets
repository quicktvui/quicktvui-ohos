
import {HippyRenderBaseView,HippyObservedArray,HRRect,HRPadding,NativeRenderContext,HippyAny,HippyRenderCallback,HIPPY_COMPONENT_KEY_PREFIX,HippyArray} from 'hippy'
import { HRValueUtils } from '../../HRValueUtils';
import QTRenderBaseView from '../QTRenderBaseView';
import { ViewUtils } from '../../utils/ViewUtils';
import MeasureText from '@ohos.measure';
import { LayoutAttach } from '../fastlist/LayoutAttach';
import { QTPixelUtil } from '../../utils/QTPixelUtil';
import { QTView } from '../../QTTypes';
import { QTBaseComponentView } from '../QTBaseComponentView';
import { TAG_FASTLIST, TAG_LAYOUT, TAG_REUSE } from '../../Constant';
import { QTLog } from '../../utils/QTLog';
import { ExtendUtil } from '../../utils/ExtendUtil';
import { QTViewState } from '../StateView';
import { MeasureUtils } from '@ohos.arkui.UIContext';


@Observed
export class QTTextView extends QTRenderBaseView{

  maxLines: number = 10000000
  lines: number = 1
  text: string = ""
  fontColor: ResourceColor | null = null
  userFontColor: ResourceColor | null = null
  fontSize: number = 16
  lineHeight: number | null = null
  // fontStyle: FontStyle = FontStyle.Normal
  // fontWeight: number | FontWeight | string = FontWeight.Normal
  // fontFamily: string | null = null

  letterSpacing: number = 0
  textAlign: TextAlign = TextAlign.Start
  verticalAlign :Alignment = Alignment.TopStart
  ellipsisMode: EllipsisMode = EllipsisMode.END
  textOverflow: TextOverflow = TextOverflow.Clip
  focusColor: ResourceColor | null = null
  selectColor: ResourceColor | null = null
  duplicateParentState: boolean = true

  constructor(ctx: NativeRenderContext) {
    super(ctx)
  }

  drawableStateChanged(currentState: number[]): void {
    super.handleShowOnState(currentState)
    if(ExtendUtil.stateContainsAttribute(currentState,QTViewState.STATE_FOCUSED)){
      this.fontColor = this.focusColor;
    } else if(ExtendUtil.stateContainsAttribute(currentState,QTViewState.STATE_SELECTED)){
      this.fontColor = this.selectColor;
    }else{
      this.fontColor = this.userFontColor;
    }
  }


  setProp(propKey: string, propValue: HippyAny): boolean {
    switch (propKey){
      case "lineSpacing":

        return true;
      case "textHtml":

        return true;
      case "typeface":

        return true;
      // case 'showOnState':
      //   this.showonstate = HRValueUtils.getString(propValue as HippyAny) || (HRValueUtils.getArray(propValue as HippyArray)||[]).join('|');
      //   this.showOnState();
      //   return true;
      case "textSpan":

        return true;
      case "fontFamily":

        return true;
      case "gravityNumber":

        return true;
      case "gravity":
      case "textAlign":
        // this. = HRValueUtils.getNumber(propValue)
        //this.textAlign = ViewUtils.getTextGravity(HRValueUtils.getString(propValue))
        ViewUtils.configGravity(HRValueUtils.getString(propValue),this)
        return true;
      case "fontSize":
      case "textSize":
        this.fontSize = HRValueUtils.getNumber(propValue);
        if(Number.isNaN(this.fontSize)){
          this.fontSize = 20;
        }
        QTLog.i(TAG_LAYOUT,`setTextFontSize:${this.fontSize},text:${this.text},this:${ExtendUtil.debugView(this)}`)
        return true;
      case "paddingRect":
        let padding = propValue as HippyArray
        this.qtPadding = { top: HRValueUtils.getNumber(padding[1]), right: HRValueUtils.getNumber(padding[2]), bottom: HRValueUtils.getNumber(padding[3]), left: HRValueUtils.getNumber(padding[0]) }
        QTPixelUtil.devPadding2Vp(this.qtPadding)
        return true;
      case "textAlignment":

        return true;
      case "textSpan":

        return true;
      case "ellipsizeMode":
        this.ellipsisMode = HRValueUtils.getNumber(propValue)
        this.textOverflow = TextOverflow.Ellipsis;
        return true;
      case "lines":
        this.maxLines = HRValueUtils.getNumber(propValue)
        return true;
      case "maxLines":
        this.maxLines = HRValueUtils.getNumber(propValue)
        return true;
      case "textColor":
      case "color":
        let colorVal = HRValueUtils.getNumber(propValue).toString(16).toLowerCase();
        this.fontColor = '#' + colorVal
        this.userFontColor = this.fontColor
        return true;
      case "focusColor":
        let focusColor = HRValueUtils.getNumber(propValue).toString(16).toLowerCase();
        this.focusColor = '#' + focusColor
        this.drawableStateChanged(this.currentStates)
        return true;
      case "selectColor":
        let selectColor = HRValueUtils.getNumber(propValue).toString(16).toLowerCase();
        this.selectColor = '#' + selectColor
        this.drawableStateChanged(this.currentStates)
        return true;
      case "lineHeight":
        this.lineHeight = QTPixelUtil.dev2Vp(QTPixelUtil.getDimensionValue(propValue))
        return true;
      case "fallbackLineSpacing":

        return true;
      case "includeFontPadding":

        return true;
      case "boldOnFocus":

        return true;
      case "gradientBackground":

        return true;
      // case "select":
      //
      //   return true;
      case "text":
        QTLog.d(TAG_LAYOUT,`setText old:${this.text},new :${HRValueUtils.getString(propValue)}`)
        this.text = HRValueUtils.getString(propValue)
        return true;
    }
    return super.setProp(propKey, propValue)
  }

  call(method: string, propValue: Array<HippyAny>, callback: HippyRenderCallback | null): void {

    if(callback){
      switch (method){
        case 'getText':
          callback(this.text)
          break;
      }
    }else{
      switch (method){
        case 'setText':
          this.text = HRValueUtils.getString(propValue)
          break;
        case 'setTextSize':
          this.fontSize = QTPixelUtil.dev2Vp(HRValueUtils.getNumber(propValue))
          break;
        case 'setTextColor':
          this.fontColor = HRValueUtils.getString(propValue)
          break;
        case 'textSpan':

          break;
      }
    }

  }


}

@Component
export struct  QTText {
  @ObjectLink renderView: QTTextView
  @ObjectLink children: HippyObservedArray<QTView>
  // @Consume('autoSize') autoSize?: number[]

  // @State textSize: SizeOptions = MeasureText.measureTextSize({
  //   textContent: this.renderView.text,
  //   fontSize: this.renderView.fontSize,
  // })

  @State uiContext: UIContext = this.getUIContext();
  @State uiContextMeasure: MeasureUtils = this.uiContext.getMeasureUtils();
  @State textSize: SizeOptions = this.uiContextMeasure.measureTextSize({
    textContent: this.renderView.text,
    fontSize: this.renderView.fontSize
  });


  build(): void {
    Text(this.renderView.text)
      .applyRenderViewBaseAttr(this.renderView)
      .width(this.renderView.cssWidth > 0 ? this.renderView.cssWidth : this.textSize.width)
      .height(this.renderView.cssHeight > 0 ? this.renderView.cssHeight :  this.textSize.height)
      .padding(this.renderView.qtPadding)
      .onAreaChange((oldValue: Area, newValue: Area) => {
        QTLog.d(TAG_LAYOUT,`0 textView notifyChildSizeChanged text:${this.renderView.text},oldWidth:${oldValue.width},new Value:${newValue.width} textSize Width:${this.textSize.width}`)
        if(newValue.width != oldValue.width || newValue.height != oldValue.height){
          if(this.renderView.parentView instanceof QTBaseComponentView){
            let newWidth = 0
            let newHeight= 0;
            if(LayoutAttach.obtainLayoutAttach(this.renderView).isAutoWidth || LayoutAttach.obtainLayoutAttach(this.renderView).isAutoHeight) {
              newWidth = QTPixelUtil.vp2Vp(Number(newValue.width))
              LayoutAttach.obtainLayoutAttach(this.renderView).setFixedWidth(newWidth)
              // this.renderView.cssWidth = Number(newValue.width)
              newHeight = QTPixelUtil.vp2Vp(Number(newValue.height))
              LayoutAttach.obtainLayoutAttach(this.renderView).setFixedHeight(newHeight)
              // this.renderView.cssHeight = Number(newValue.height)
              // QTPixelUtil.setRenderViewLayout(this.renderView,[0,])
              QTLog.d(TAG_LAYOUT,`textView notifyChildSizeChanged text:${this.renderView.text},oldWidth:${oldValue.width},new Value:${newValue.width}`)
              this.renderView.parentView.notifyChildSizeChanged(this.renderView, this.renderView, newWidth, newHeight)
            }
          }else{
            QTLog.d(TAG_LAYOUT,`parent is not QTRenderBaseView notifyChildSizeChanged text:${this.renderView.text},oldWidth:${oldValue.width},new Value:${newValue.width}`)
          }
        }
      })
      .applyRenderViewBaseAttr(this.renderView)
      .fontSize(this.renderView.fontSize)
      .fontColor(this.renderView.fontColor)
      .lineHeight(this.renderView.lineHeight)
      .maxLines(this.renderView.maxLines)
      .textAlign(this.renderView.textAlign)
      .textOverflow({ overflow: this.renderView.textOverflow })
      .ellipsisMode(this.renderView.ellipsisMode)
      .align(this.renderView.verticalAlign)
  }

  aboutToAppear(): void {
  }
}

@Extend(Text)
function applyRenderViewBaseAttr($$: QTBaseComponentView) {
  .key(HIPPY_COMPONENT_KEY_PREFIX + $$.tag)
  .backgroundColor($$.cssBackgroundColor)
  .position({x: $$.cssPositionX, y: $$.cssPositionY})
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
  .key($$.name)
  .id($$.sid)
  .visibility($$.visibility)
}

