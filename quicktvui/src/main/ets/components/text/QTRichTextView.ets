/*
 * Tencent is pleased to support the open source community by making
 * Hippy available.
 *
 * Copyright (C) 2022 THL A29 Limited, a Tencent company.
 * All rights reserved.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *   http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */
import QTRenderBaseView from "../QTRenderBaseView"
import {HRNodeProps,NativeRenderContext,HippyAny,HRRect,HRPadding,HippyRenderBaseView,HIPPY_COMPONENT_KEY_PREFIX} from 'hippy'
import { HRValueUtils } from "../../HRValueUtils"
import { HRTvImageView } from "../vendored/image/HRTvImageView"
import { ExtendUtil } from "../../utils/ExtendUtil"
import { QTViewState } from "../StateView"

@Observed
export class QTRichTextView extends QTRenderBaseView {
  private readonly TAG = "HRRichTextView"
  cssPadding: Padding = { top: 0, right: 0, bottom: 0, left: 0 }
  maxLines: number = 10000000
  text: string = ""
  fontColor: ResourceColor | null = null
  fontSize: number = HRNodeProps.FONT_SIZE_SP
  lineHeight: number | null = null
  shadowColor: number = 0
  shadowRadius: number = 0
  shadowOffX: number = 0
  shadowOffY: number = 0
  sid: string = ''
  name: string = ''
  visible: boolean = false
  visibility: Visibility = Visibility.Visible
  textColor: string = ''
  focusColor: string = ''
  selectColor: string = ''
  selected: boolean = false
  fontStyle: FontStyle = FontStyle.Normal
  fontWeight: number | FontWeight | string = FontWeight.Normal
  fontFamily: string | null = null
  decorationType: TextDecorationType = TextDecorationType.None
  decorationColor: number = 0
  decorationStyle: TextDecorationStyle = TextDecorationStyle.SOLID
  letterSpacing: number = 0
  textAlign: TextAlign = TextAlign.Start
  wordBreak: WordBreak = WordBreak.BREAK_WORD
  ellipsisMode: EllipsisMode = EllipsisMode.END
  textOverflow: TextOverflow = TextOverflow.Clip
  direction: Direction = Direction.Ltr

  userFontColor: ResourceColor | null = null

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
    switch(propKey) {
      case 'sid':
        this.sid = propValue as string
        return true
      case 'name':
        this.name = HRValueUtils.getString(propValue as HippyAny);
        return true;
      case "textColor":
      case HRNodeProps.COLOR:
        let colorVal = HRValueUtils.getNumber(propValue).toString(16).toLowerCase();
        this.fontColor = '#' + colorVal
        this.userFontColor = this.fontColor
        return true;
      // case 'focusColor':
      //   this.focusColor = HRValueUtils.getString(propValue as HippyAny);
      //   return true;
      // case 'selectColor':
      //   this.selectColor = HRValueUtils.getString(propValue as HippyAny);
      //   return true;
      // case 'selected':
      //   this.selected = HRValueUtils.getBoolean(propValue as HippyAny, false);
      //   return true;
      case 'visible':
        this.visible = HRValueUtils.getBoolean(propValue as HippyAny, false);
        this.visibility = Visibility[this.visible ? 'Visible' : 'Hidden'];
        return true;
      case HRNodeProps.VISIBILITY:
        {
          let visibility = propValue as string
          switch (visibility) {
            case 'visible': {
              this.visibility = Visibility.Visible
              break;
            }
            case 'invisible': {
              this.visibility = Visibility.Hidden
              break;
            }
            case 'none': {
              this.visibility = Visibility.None
              break;
            }
          }
        }
        return true
      case "text":
        this.text = HRValueUtils.getString(propValue);
        return true
      // case HRNodeProps.COLOR:
      //   this.fontColor = HRValueUtils.getNumber(propValue);
      //   return true
      case "enableScale": // Android有，iOS无
        return true;
      case HRNodeProps.FONT_FAMILY:
        this.fontFamily = HRValueUtils.getString(propValue);
        return true;
      case HRNodeProps.FONT_SIZE:
        this.fontSize = HRValueUtils.getNumber(propValue);
        return true
      case HRNodeProps.FONT_STYLE: {
        let t = HRValueUtils.getString(propValue);
        if (t == 'italic') {
          this.fontStyle = FontStyle.Italic;
        } else {
          this.fontStyle = FontStyle.Normal;
        }
      }
        return true;
      case HRNodeProps.FONT_WEIGHT: {
        let t = HRValueUtils.getString(propValue);
        if (t == "normal") {
          this.fontWeight = FontWeight.Normal;
        } else if (t == "bold") {
          this.fontWeight = FontWeight.Bold;
        } else {
          let n = parseInt(t);
          if (isNaN(n)) {
            this.fontWeight = FontWeight.Normal;
          } else {
            this.fontWeight = Math.min(Math.max(1, n), 1000);
          }
        }
      }
        return true;
      case HRNodeProps.LETTER_SPACING:
        this.letterSpacing = HRValueUtils.getNumber(propValue);
        return true;
      case HRNodeProps.LINE_HEIGHT:
        this.lineHeight = HRValueUtils.getNumber(propValue);
        return true
      case HRNodeProps.LINE_SPACING_EXTRA: // Android有，iOS无
        return true;
      case HRNodeProps.LINE_SPACING_MULTIPLIER: // TODO:
        return true;
      case HRNodeProps.NUMBER_OF_LINES:
        this.maxLines = HRValueUtils.getNumber(propValue);
        if (this.maxLines <= 0) {
          this.maxLines = 10000000
        }
        return true
      case HRNodeProps.TEXT_ALIGN: {
        let t = HRValueUtils.getString(propValue);
        if (t == "justify") {
          this.textAlign = TextAlign.JUSTIFY;
        } else if (t == "right") {
          this.textAlign = TextAlign.End;
        } else if (t == "center") {
          this.textAlign = TextAlign.Center;
        } else {
          this.textAlign = TextAlign.Start;
        }
      }
        return true;
      case HRNodeProps.TEXT_DECORATION_LINE: { // 安卓可以同时显示下划线和删除线
        let t = HRValueUtils.getString(propValue);
        this.decorationType = TextDecorationType.None;
        t.split(" ").forEach(s => {
          if (s == 'underline') {
            this.decorationType = TextDecorationType.Underline;
          } else if (s == 'line-through') {
            this.decorationType = TextDecorationType.LineThrough;
          }
        });
      }
        return true;
      case HRNodeProps.TEXT_SHADOW_COLOR:
        this.shadowColor = HRValueUtils.getNumber(propValue);
        return true;
      case HRNodeProps.TEXT_SHADOW_OFFSET:
        let m = HRValueUtils.getMap(propValue);
        if (m) {
          this.shadowOffX = HRValueUtils.getNumber(m.get('width'));
          this.shadowOffY = HRValueUtils.getNumber(m.get('height'));
        }
        return true;
      case HRNodeProps.TEXT_SHADOW_RADIUS:
        this.shadowRadius = HRValueUtils.getNumber2(propValue, 1.0);
        return true;
      case HRNodeProps.TEXT_DECORATION_COLOR: // 下划线/删除线的颜色
        this.decorationColor = HRValueUtils.getNumber(propValue);
        return true;
      case HRNodeProps.ELLIPSIZE_MODE: {
        let t = HRValueUtils.getString(propValue);
        if (t == "clip") {
          this.textOverflow = TextOverflow.Clip;
        } else {
          this.textOverflow = TextOverflow.Ellipsis;
          switch (t) {
            case "head":
              this.ellipsisMode = EllipsisMode.START;
              break;
            case "middle":
              this.ellipsisMode = EllipsisMode.CENTER;
              break;
            case "tail":
              this.ellipsisMode = EllipsisMode.END;
              break;
          }
        }
      }
        return true;
      case HRNodeProps.TEXT_DECORATION_STYLE:
        let t = HRValueUtils.getString(propValue);
        if (t == "double") {
          this.decorationStyle = TextDecorationStyle.DOUBLE;
        } else if (t == "dotted") {
          this.decorationStyle = TextDecorationStyle.DOTTED;
        } else if (t == "dashed") {
          this.decorationStyle = TextDecorationStyle.DASHED;
        } else {
          this.decorationStyle = TextDecorationStyle.SOLID;
        }
        return true;
      case HRNodeProps.BREAK_STRATEGY: { // 文本断行策略，不完全匹配
        let t = HRValueUtils.getString(propValue);
        if (t == "high_quality") {
          this.wordBreak = WordBreak.BREAK_ALL;
        } else if (t == "balanced") {
          this.wordBreak = WordBreak.BREAK_WORD;
        } else {
          this.wordBreak = WordBreak.BREAK_WORD; // 如果使用WordBreak.NORMAL，超过行宽的连续字符不会换行(被裁剪)
        }
      }
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
    }
    return super.setProp(propKey, propValue)
  }

  protected updateRenderViewFrame(frame: HRRect, padding: HRPadding | null): void {
    super.updateRenderViewFrame(frame, padding)
    if (padding) {
      this.cssPadding = { top: padding.paddingTop, right: padding.paddingRight, bottom: padding.paddingBottom, left: padding.paddingLeft }
    }
  }
}

@Component
export struct QTHRRichText {
  @ObjectLink renderView: QTRichTextView

  @Builder
  TextSpan(txt: QTRichTextView) {
    Span(txt.text)
      .applyRenderViewBaseAttr_TextSpan(txt)
      .fontColor(txt.fontColor)
      .fontSize(txt.fontSize)
      .lineHeight(txt.lineHeight)
      .textShadow({
        radius: txt.shadowRadius,
        color: txt.shadowColor,
        offsetX: txt.shadowOffX,
        offsetY: txt.shadowOffY
      })
      .fontStyle(txt.fontStyle)
      .fontWeight(txt.fontWeight)
      .fontFamily(txt.fontFamily)
      .decoration({
        type: txt.decorationType,
        color: txt.decorationColor,
        style: txt.decorationStyle
      })
      .letterSpacing(txt.letterSpacing)
      .textBackgroundStyle({color: txt.cssBackgroundColor}) // backgroundColor无效，换成这个
      .direction(txt.direction)
  }

  @Builder
  ImageSpan(img: HRTvImageView) {
    ImageSpan(img.getImage())
      .applyRenderViewBaseAttr_ImageSpan(img)
      // .verticalAlign(img.spanVerticalAlign)
      .objectFit(img.spanObjectFit)
      .textBackgroundStyle({color: img.cssBackgroundColor})
  }

  fontColorBeforeFocus = "";

  build() {
    Text(this.renderView.text) {
      if (this.renderView.children.length > 0) {
        ForEach(this.renderView.children, (item: HippyRenderBaseView) => {
          if (item.viewType == "Text") {
            this.TextSpan(item as QTRichTextView)
          }
          if (item.viewType == "Image") {
            this.ImageSpan(item as HRTvImageView)
          }
        }, (item: HippyRenderBaseView) => item.tag + '')
      }
    }
    .applyRenderViewBaseAttr(this.renderView)
    .fontColor(this.renderView.textColor || this.renderView.fontColor)
    .fontSize(this.renderView.fontSize)
    .lineHeight(this.renderView.lineHeight) // ArkUI设置了这个文本不能垂直居中，解决方法：module.json5里metadata里配置half_leading
    .textOverflow({ overflow: this.renderView.textOverflow })
    .ellipsisMode(this.renderView.ellipsisMode)
    .maxLines(this.renderView.maxLines)
    .id(this.renderView.sid)
    .key(this.renderView.name)
    .textShadow({
      radius: this.renderView.shadowRadius,
      color: this.renderView.shadowColor,
      offsetX: this.renderView.shadowOffX,
      offsetY: this.renderView.shadowOffY
    })
    .fontStyle(this.renderView.fontStyle)
    .fontWeight(this.renderView.fontWeight)
    .fontFamily(this.renderView.fontFamily)
    .decoration({
      type: this.renderView.decorationType,
      color: this.renderView.decorationColor,
      style: this.renderView.decorationStyle
    })
    .letterSpacing(this.renderView.letterSpacing)
    .textAlign(this.renderView.textAlign)
    .wordBreak(this.renderView.wordBreak)
    .padding(this.renderView.cssPadding)
    .direction(this.renderView.direction)
    .visibility(this.renderView.visibility)
    .onFocus(() => {
      this.fontColorBeforeFocus = this.renderView.textColor;
      this.renderView.textColor = this.renderView.focusColor
    })
    .onBlur(() => {
      this.renderView.textColor = this.fontColorBeforeFocus
    })
  }
}

// base props for all components
@Extend(Text)
function applyRenderViewBaseAttr($$: QTRichTextView) {
  .key(HIPPY_COMPONENT_KEY_PREFIX + $$.tag)
  .backgroundColor($$.cssBackgroundColor)
  .position({x: $$.cssPositionX, y: $$.cssPositionY})
  .size({width:$$.cssWidth, height: $$.cssHeight})
  .opacity($$.cssOpacity)
  .clip($$.cssOverflow)
  .visibility(($$ as QTRichTextView).cssVisibility) // must add as, otherwise the compiler has error
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
  .id($$.uid)
  .scale($$.cssScale)
  .translate($$.cssTranslate)
  .hitTestBehavior($$.hitTestBehavior)
  .onClick($$.eventClick)
}

@Extend(Span)
function applyRenderViewBaseAttr_TextSpan($$: HippyRenderBaseView) {
  .key(HIPPY_COMPONENT_KEY_PREFIX + $$.tag)
  .onClick($$.eventClick)
}

@Extend(ImageSpan)
function applyRenderViewBaseAttr_ImageSpan($$: HRTvImageView) {
  .key(HIPPY_COMPONENT_KEY_PREFIX + $$.tag)
  .backgroundColor($$.cssBackgroundColor)
  .position({x: $$.cssPositionX, y: $$.cssPositionY}) // 使用 c 测得的绝对位置
  .size({width:$$.cssWidth, height: $$.cssHeight})
  .opacity($$.cssOpacity)
  .clip($$.cssOverflow)
  .visibility(($$ as HRTvImageView).cssVisibility) // must add as, otherwise the compiler has error
  .zIndex($$.cssZIndex)
  .accessibilityText($$.cssAccessibilityLabel)
  .focusable($$.cssFocusable)
  .border($$.cssBorder)
  .shadow($$.cssShadow)
  .id($$.uid)
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
