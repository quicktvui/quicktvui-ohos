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
import deviceInfo  from '@ohos.deviceInfo';
import {HippyAny,buildHippyRenderView,NativeRenderContext,HippyRenderBaseView,HippyObservedArray,HIPPY_COMPONENT_KEY_PREFIX} from 'hippy'
import { QTView } from '../../QTTypes';
import { FastListUtils } from '../fastlist/FastListUtils';
import { LayoutAttach } from '../fastlist/LayoutAttach';
import { HRTvDivView} from '../vendored/view/HRTvDivView';


const HippyGestureTag = 'HippyGestureTag'

@Observed
class MyStackModifier implements AttributeModifier<StackAttribute> {
  public color: string
  constructor(color:string) {
    this.color = color
  }
  applyNormalAttribute(instance: StackAttribute): void {
    if(this.color){
      instance.backgroundColor(`${this.color}`);
    }
  }
}
const modifier: MyStackModifier = new MyStackModifier("");


@Observed
class MyStackModifierVisible implements AttributeModifier<StackAttribute> {
  public isVisible: string

  constructor(isVisible: string) {
    this.isVisible = isVisible
  }
  applyNormalAttribute(instance: StackAttribute): void {
    if (this.isVisible == "visibile") {
      console.log("HRTvDivView","visible")
      instance.visibility(Visibility.Visible)
    } else if (this.isVisible == "invisible") {
      instance.visibility(Visibility.Hidden)
      console.log("HRTvDivView","invisible")
    } else {
      instance.visibility(Visibility.None)
      console.log("HRTvDivView","none")
    }
  }
}
const visibleModifier: MyStackModifierVisible = new MyStackModifierVisible("invisible");

@Observed
export class QTDivView extends HRTvDivView {
  constructor(ctx: NativeRenderContext) {
    super(ctx)
  }

  setProp(propKey: string, propValue: HippyAny): boolean {
    return super.setProp(propKey, propValue)
  }

  notifyChildSizeChanged(child:QTView,changedView:QTView,width: number, height: number){

    super.notifyChildSizeChanged(child,changedView,width,height)
  }
}

@Component
export struct QTDiv {
  @ObjectLink renderView: QTDivView
  @ObjectLink children: HippyObservedArray<QTView>
  @Consume('autoSize') @Watch('onAutoSizeChange') autoSize? : number[]

  private readonly TAG = "QTDiv"
  @State colorModifier: MyStackModifier = modifier
  @State visibilityModifier: MyStackModifierVisible = visibleModifier

  // 监听autoSize变化的回调函数
  onAutoSizeChange(newValue: number[], oldValue: number[]) {


  }



  shouldAddGesture() {
    return deviceInfo.sdkApiVersion >= 11 && (
      this.renderView.eventLongPress != null ||
        this.renderView.eventPressIn != null ||
        this.renderView.eventPressOut != null ||
        this.renderView.eventTouchUp != null ||
        this.renderView.eventTouchDown != null ||
        this.renderView.eventTouchMove != null ||
        this.renderView.eventTouchCancel != null ||
      this.renderView.flagInterceptPullUp
    )
  }

  isEventClick(){
    return this.renderView.isVirtual && LayoutAttach.obtainLayoutAttach(this.renderView).virtualExtra.eventClick
  }

  aboutToAppear() {
    if (this.renderView.eventAttachedToWindow) {
      this.renderView.eventAttachedToWindow()
    }
  }

  aboutToDisappear() {
    if (this.renderView.eventDetachedFromWindow) {
      this.renderView.eventDetachedFromWindow()
    }
  }

  build() {
    if(this.shouldAddGesture()){
      if(this.isEventClick()){
        Stack() {
          ForEach(this.children, (item: QTView) => {
            buildHippyRenderView(item, null)
          }, (item: QTView) => item.tag + '')
        }
        .applyRenderViewBaseAttr(this.renderView)
        .applyGestures(this.renderView)
        //注:当使用了自定义获焦requestFocus时候，不走系统默认焦点逻辑，不会触发focusBox焦点框，如需使用可以根据获焦状态来自定义border样式实现
        //custom
        .attributeModifier(this.colorModifier)
        .onClick((event=>{
          FastListUtils.handleItemClick(this.renderView)
        }))
      }else{
        Stack() {
          ForEach(this.children, (item: QTView) => {
            buildHippyRenderView(item, null)
          }, (item: QTView) => item.tag + '')
        }
        .applyRenderViewBaseAttr(this.renderView)
        .applyGestures(this.renderView)
        //注:当使用了自定义获焦requestFocus时候，不走系统默认焦点逻辑，不会触发focusBox焦点框，如需使用可以根据获焦状态来自定义border样式实现
        .attributeModifier(this.colorModifier)
      }
    }else {
      if(this.isEventClick()){
        //from super
        Stack() {
          ForEach(this.children, (item: QTView) => {
            buildHippyRenderView(item, null)
          }, (item: QTView) => item.tag + '')
        }
        .applyRenderViewBaseAttr(this.renderView)
        .attributeModifier(this.colorModifier)
        .onClick((event=>{
          FastListUtils.handleItemClick(this.renderView)
        }))
      }else{
        Stack() {
          ForEach(this.children, (item: QTView) => {
            buildHippyRenderView(item, null)
          }, (item: QTView) => item.tag + '')
        }
        .applyRenderViewBaseAttr(this.renderView)
        .attributeModifier(this.colorModifier)
      }
    }
  }
}

// base props for all components
@Extend(Stack)
function applyRenderViewBaseAttr($$: QTDivView) {
  // .key(HIPPY_COMPONENT_KEY_PREFIX + $$.tag)
  .backgroundColor($$.cssBackgroundColor)
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
  .focusable($$.focusable)
  .border($$.focus ? $$.setBorder() : $$.border)
  .key($$.name)
  .scale($$.focus ? { x: $$.focusScale, y: $$.focusScale } : {})
  .clip($$.clipChildren)
  .id($$.sid)
  .visibility($$.visibility)
  .focusScopeId($$.sid, $$.focusMemory) // TODO 目前web端未验证出实际效果
  .onFocus(() => {
    $$.focus = true
    $$.handleFocus($$.focus)
  })
  .onBlur(() => {
    $$.focus = false
    $$.handleBlur($$.focus)
  })
}

@Extend(Stack)
function applyGestures($$: QTView) {
  .onGestureJudgeBegin((gestureInfo: GestureInfo, event: BaseGestureEvent): GestureJudgeResult => {
    if (gestureInfo.tag != HippyGestureTag) {
      // let other gestures continue
      return GestureJudgeResult.CONTINUE
    }
    return (gestureInfo.type == GestureControl.GestureType.LONG_PRESS_GESTURE &&
      ($$.eventLongPress != null) || $$.eventPressIn != null || $$.eventPressOut != null) ?
    GestureJudgeResult.CONTINUE : GestureJudgeResult.REJECT
  })
  .parallelGesture(GestureGroup(GestureMode.Parallel,
    LongPressGesture({ repeat: false })
      .tag(HippyGestureTag)
      .onAction((event?: GestureEvent) => {
        if (event && $$.eventPressIn) {
          $$.eventPressIn(event)
        }
      })
      .onActionEnd((event?: GestureEvent) => {
        if (event && $$.eventPressOut) {
          $$.eventPressOut(event)
        }
        if (event && $$.eventLongPress) {
          $$.eventLongPress(event)
        }
      })
      .onActionCancel(() => {
        if ($$.eventPressOut) {
          $$.eventPressOut(null)
        }
      }),
  ))
  .onTouch((event: TouchEvent) => {
    if ($$.flagInterceptPullUp) {
      $$.handleInterceptPullUp(event)
    }
    switch (event.type) {
      case TouchType.Down: {
        if ($$.eventTouchDown) {
          $$.eventTouchDown(event)
        }
      }
        break
      case TouchType.Up: {
        if ($$.eventTouchUp) {
          $$.eventTouchUp(event)
        }
      }
        break
      case TouchType.Move: {
        if ($$.eventTouchMove) {
          $$.eventTouchMove(event)
        }
      }
        break
      case TouchType.Cancel: {
        if ($$.eventTouchCancel) {
          $$.eventTouchCancel(event)
        }
      }
        break
    }
  })
}
