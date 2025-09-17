
import {HippyRenderBaseView,HippyObservedArray,HRRect,HRPadding,NativeRenderContext,HippyAny,HippyRenderCallback,HIPPY_COMPONENT_KEY_PREFIX,HippyArray} from 'hippy'
import { HRValueUtils } from '../../HRValueUtils';
import QTRenderBaseView from '../QTRenderBaseView';
import { ViewUtils } from '../../utils/ViewUtils';
import MeasureText from '@ohos.measure';
import { LayoutAttach } from '../fastlist/LayoutAttach';
import { QTPixelUtil } from '../../utils/QTPixelUtil';
import { QTView } from '../../QTTypes';


@Observed
export class QTTextView extends QTRenderBaseView{

  maxLines: number = 10000000
  lines: number = 1
  text: string = ""
  fontColor: ResourceColor | null = null
  fontSize: Dimension = 20
  lineHeight: number | null = null
  // fontStyle: FontStyle = FontStyle.Normal
  // fontWeight: number | FontWeight | string = FontWeight.Normal
  // fontFamily: string | null = null

  letterSpacing: number = 0
  textAlign: TextAlign = TextAlign.Start
  ellipsisMode: EllipsisMode = EllipsisMode.END


  constructor(ctx: NativeRenderContext) {
    super(ctx)
  }

  setProp(propKey: string, propValue: HippyAny): boolean {
    switch (propKey){
      case "lineSpacing":

        return true;
      case "textHtml":

        return true;
      case "typeface":

        return true;
      case "textSpan":

        return true;
      case "fontFamily":

        return true;
      case "gravityNumber":

        return true;
      case "gravity":
      case "textAlign":
        // this. = HRValueUtils.getNumber(propValue)
        this.textAlign = ViewUtils.getTextGravity(HRValueUtils.getString(propValue))
        return true;
      case "fontSize":
        this.fontSize = HRValueUtils.getNumber(propValue)
        return true;
      case "paddingRect":
        let padding = propValue as HippyArray
        this.qtPadding = { top: HRValueUtils.getNumber(padding[1]), right: HRValueUtils.getNumber(padding[2]), bottom: HRValueUtils.getNumber(padding[3]), left: HRValueUtils.getNumber(padding[0]) }
        return true;
      case "textAlignment":

        return true;
      case "textSpan":

        return true;
      case "ellipsizeMode":
        this.ellipsisMode = HRValueUtils.getNumber(propValue)
        return true;
      case "lines":
        this.maxLines = HRValueUtils.getNumber(propValue)
        return true;
      case "maxLines":
        this.maxLines = HRValueUtils.getNumber(propValue)
        return true;
      case "textColor":
      case "color":
        this.fontColor = HRValueUtils.getNumber(propValue)
        return true;
      case "lineHeight":
        this.lineHeight = HRValueUtils.getNumber(propValue)
        return true;
      case "fallbackLineSpacing":

        return true;
      case "includeFontPadding":

        return true;
      case "boldOnFocus":

        return true;
      case "gradientBackground":

        return true;
      case "select":

        return true;
      case "text":
        this.text = HRValueUtils.getString(propValue)
        // console.log(QUICKTVUI_TAG,`setText:${this.text}`)
        return true;
    }
    return super.setProp(propKey, propValue)
  }

  call(method: string, propValue: Array<HippyAny>, callback: HippyRenderCallback | null): void {

    if(callback){
      switch (method){
        case 'getText':

          break;
      }
    }else{
      switch (method){
        case 'setText':
          this.text = HRValueUtils.getString(propValue)
          break;
        case 'setTextSize':
          this.fontSize = HRValueUtils.getNumber(propValue)
          break;
        case 'setTextColor':
          this.fontColor = HRValueUtils.getString(propValue)
          break;
        case 'textSpan':

          break;
      }
    }

  }

  setRenderViewFrame(frame: HRRect, padding: HRPadding | null): void {
    // console.error(TAG_QUICKTVUI,`QTText setRenderViewFrame width:${frame.width},height:${frame.height}`)
    super.setRenderViewFrame(frame,padding)
  }

}

@Component
export struct  QTText {
  @ObjectLink renderView: QTTextView
  @ObjectLink children: HippyObservedArray<QTView>
  @Consume('autoSize') autoSize?: number[]

  @State textSize: SizeOptions = MeasureText.measureTextSize({
    textContent: this.renderView.text,
    fontSize: this.renderView.fontSize,
  })


  build(): void {
    Text(this.renderView.text)
      .width(this.renderView.cssWidth > 0 ? this.renderView.cssWidth : this.textSize.width)
      .height(this.renderView.cssHeight > 0 ? this.renderView.cssHeight :  this.textSize.height)
      .padding(this.renderView.qtPadding)
      .onAreaChange((oldValue: Area, newValue: Area) => {
        if( newValue.width != oldValue.width || newValue.height != oldValue.height){
          if(this.renderView.parentView instanceof QTRenderBaseView){
            if(LayoutAttach.obtainLayoutAttach(this.renderView).isAutoWidth || LayoutAttach.obtainLayoutAttach(this.renderView).isAutoHeight){
              if(LayoutAttach.obtainLayoutAttach(this.renderView).isAutoWidth){
                 LayoutAttach.obtainLayoutAttach(this.renderView).setWidth(Number(newValue.width))
              }else{
                LayoutAttach.obtainLayoutAttach(this.renderView).setHeight(Number(newValue.height))
              }
              this.renderView.parentView.notifyChildSizeChanged(this.renderView,this.renderView,Number(newValue.width),Number(newValue.height))
            }
          }
        }
      })
      .applyRenderViewBaseAttr(this.renderView)
      .fontSize(this.renderView.fontSize)
      .fontColor(this.renderView.fontColor)
      .lineHeight(this.renderView.lineHeight)
      .maxLines(this.renderView.maxLines)
      .textAlign(this.renderView.textAlign)
  }

  aboutToAppear(): void {
  }
}

@Extend(Text)
function applyRenderViewBaseAttr($$: QTView) {
  .key(HIPPY_COMPONENT_KEY_PREFIX + $$.tag)
  .backgroundColor($$.cssBackgroundColor)
  .position({x: $$.cssPositionX, y: $$.cssPositionY})
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

