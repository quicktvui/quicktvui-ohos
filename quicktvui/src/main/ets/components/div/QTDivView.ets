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
import {HippyAny,buildHippyRenderView,NativeRenderContext,HippyRenderCallback,HippyObservedArray,HIPPY_COMPONENT_KEY_PREFIX} from 'hippy'
import { TAG_FOCUS, TAG_QUICKTVUI } from '../../Constant';
import { HRValueUtils } from '../../HRValueUtils';
import { QTAny, QTView } from '../../QTTypes';
import { ExtendUtil } from '../../utils/ExtendUtil';
import { QTLog } from '../../utils/QTLog';
import { ViewUtils } from '../../utils/ViewUtils';
import { FastListUtils } from '../fastlist/FastListUtils';
import { LayoutAttach } from '../fastlist/LayoutAttach';
import { QTBaseComponentView } from '../QTBaseComponentView';
import { HRTvDivView } from '../vendored/view/HRTvDivView';


const HippyGestureTag = 'HippyGestureTag'

// @Observed
// class MyStackModifier implements AttributeModifier<StackAttribute> {
//   public color: string
//   constructor(color:string) {
//     this.color = color
//   }
//   applyNormalAttribute(instance: StackAttribute): void {
//     if(this.color){
//       instance.backgroundColor(`${this.color}`);
//     }
//   }
// }
// const modifier: MyStackModifier = new MyStackModifier("");


@Observed
class MyStackModifierVisible implements AttributeModifier<StackAttribute> {
  public isVisible: string

  constructor(isVisible: string) {
    this.isVisible = isVisible
  }
  applyNormalAttribute(instance: StackAttribute): void {
    if (this.isVisible == "visibile") {
      QTLog.d("HRTvDivView","visible")
      instance.visibility(Visibility.Visible)
    } else if (this.isVisible == "invisible") {
      instance.visibility(Visibility.Hidden)
      QTLog.d("HRTvDivView","invisible")
    } else {
      instance.visibility(Visibility.None)
      QTLog.d("HRTvDivView","none")
    }
  }
}
const visibleModifier: MyStackModifierVisible = new MyStackModifierVisible("invisible");

@Observed
export class QTDivView extends HRTvDivView {

  mUserSetFocusBackgroundColor : ResourceColor = Color.White;
  mUserSetSelectBackgroundColor : ResourceColor = Color.Transparent;
  mUserSetBackgroundColor : ResourceColor = Color.Transparent;
  stateBackgroundColor : ResourceColor  = Color.Transparent;


  constructor(ctx: NativeRenderContext) {
    super(ctx)
  }

  drawableStateChanged(){
    super.drawableStateChanged()
    let focused = this.isFocused()
    if(!focused){
      if(this.parentView instanceof QTBaseComponentView){
        focused = this.duplicateParentState && this.parentView.isFocused();
        // QTLog.d(TAG_FOCUS,`drawableStateChanged focused:${focused} duplicateParentState :${this.duplicateParentState},this;${ExtendUtil.debugView(this)}`)
      }
    }
    let selected = this.isSelected()
    if(!selected){
      if(this.parentView instanceof QTBaseComponentView){
        selected = this.duplicateParentState && this.parentView.isSelected();
        // QTLog.d(TAG_FOCUS,`drawableStateChanged selected:${selected} duplicateParentState :${this.duplicateParentState} ,this;${ExtendUtil.debugView(this)}`)
      }
    }
    if(focused){
      this.stateBackgroundColor = this.mUserSetFocusBackgroundColor;
      // QTLog.e(TAG_FOCUS,`drawableStateChanged -------> to focused state bg:${this.mUserSetFocusBackgroundColor} this:${ExtendUtil.debugView(this)}`)
    }else if(selected){
      // QTLog.w(TAG_FOCUS,`drawableStateChanged -------> to selected state bg:${this.mUserSetSelectBackgroundColor} this:${ExtendUtil.debugView(this)}`)
      this.stateBackgroundColor = this.mUserSetSelectBackgroundColor;
    }else{
      // QTLog.i(TAG_FOCUS,`drawableStateChanged -------> to normal state bg:${this.mUserSetBackgroundColor} this:${ExtendUtil.debugView(this)}`)
      this.stateBackgroundColor = this.mUserSetBackgroundColor;
    }
    this.children.map((child)=>{
      if(child instanceof QTBaseComponentView){
        child.drawableStateChanged()
      }
    })
  }


  addFocusables(views: QTView[], direction: number): boolean {
    if(!super.addFocusables(views,direction)){
      //证明自身是不可获焦的
      if (this.children && this.children.length > 0) {
        this.children.forEach((child: QTView) => {
          if(child instanceof QTBaseComponentView){
            child.addFocusables(views,direction)
          }else if (child.cssFocusable === true) {
            views.push(child);
          }
        });
      }
    }
    return true;
  }

  requestFocus(){
    QTLog.e(TAG_FOCUS,`requestFocus focusable:${this.cssFocusable} ,this :`+ExtendUtil.debugView(this))
    focusControl.requestFocus(ViewUtils.getViewUid(this));
  }

  setProp(propKey: string, propValue: HippyAny): boolean {
    switch (propKey){
      case 'gradientBackground':
        let map = HRValueUtils.getMap(propValue)
        if(map){
          let type = map.get('type')
          if(type && type != 0){
            QTLog.fatal(TAG_QUICKTVUI,'set gradientBackground error ohos only support LINEAR_GRADIENT(0) ,type:'+type)
            return true;
          }
          let shape = map.get('shape')
          if(shape){
            QTLog.w(TAG_QUICKTVUI,'set gradientBackground , ohos cant set shape')
          }
          let orientation = map.get('orientation')
          let direction = GradientDirection.Bottom
          if(typeof orientation == 'number'){
            direction = ViewUtils.getGradientDirection(orientation)
          }
          let colorStringArray = map.get("colors")
          let colorArray : [ResourceColor, number][] = []
          if(colorStringArray instanceof Array){
            let count = colorStringArray.length
            for(let i = 0; i < colorStringArray.length; i ++){
              let colorStr = colorStringArray[i] as string
              let color = ViewUtils.colorStringToNumber(colorStr)
              if(!color){
                color = Color.Transparent;
              }
              colorArray[i] = [color,1/count * i]
            }
          }
          this.cssLinearGradient = {
            direction : direction,
            colors:colorArray
          }
        }else{
          this.cssLinearGradient = null
        }

        return true;
        case 'focusBackgroundColor':
          // QTLog.w(TAG_FOCUS,`mUserSetFocusBackgroundColor :${this.mUserSetFocusBackgroundColor}`)
          this.mUserSetFocusBackgroundColor = HRValueUtils.getNumber(propValue)
          if(!this.mUserSetFocusBackgroundColor){
            this.mUserSetFocusBackgroundColor = Color.Transparent
          }
          this.drawableStateChanged()
          return true;
        case 'selectBackgroundColor':
          this.mUserSetSelectBackgroundColor = HRValueUtils.getNumber(propValue)
          if(!this.mUserSetSelectBackgroundColor){
            this.mUserSetSelectBackgroundColor = Color.Transparent
          }
          // QTLog.i(TAG_FOCUS,`mUserSetSelectBackgroundColor :${this.mUserSetSelectBackgroundColor}`)
          this.drawableStateChanged()
          return true;
        case 'backgroundColor':
          this.mUserSetBackgroundColor = HRValueUtils.getNumber(propValue)
          if(!this.mUserSetBackgroundColor){
            this.mUserSetBackgroundColor = Color.Transparent
          }
          this.cssBackgroundColor = this.mUserSetBackgroundColor
          QTLog.i(TAG_FOCUS,`backgroundColor :${this.mUserSetBackgroundColor}`)
          this.drawableStateChanged()
        break;
        case 'autofocus':
          this.autofocus = HRValueUtils.getBoolean(propValue,true)
          QTLog.w(TAG_FOCUS,`set AutofocusPosition:${this.autofocus},this:${ExtendUtil.debugView(this)}`)
          break;
      // case 'showOnState':
      //   super.setProp(propKey, propValue)
      //   QTLog.w(TAG_FOCUS,`div setShowOnState :${propValue},this:${ExtendUtil.debugView(this)}`)
      //   this.handleShowOnState();
      //   return true;
    }
    return super.setProp(propKey, propValue)
  }

  call(method: string, params: Array<HippyAny>, callback: HippyRenderCallback | null): void {
    switch (method){
      case 'requestFocus':
        this.requestFocus()
        return;
    }
    super.call(method,params,callback)
  }

  notifyChildSizeChanged(child:QTView,changedView:QTView,width: number, height: number){

    super.notifyChildSizeChanged(child,changedView,width,height)
  }

  handleFocus(isFocused: boolean): void {
    QTLog.i(TAG_FOCUS,`+++handle Focus this:${ExtendUtil.debugView(this)} isFocused:${isFocused},focusable:${this.cssFocusable}`)
    if(this.parentView instanceof QTBaseComponentView){
      if(this.cssFocusable){
        this.parentView.notifyChildRequestFocus(this,this)
      }
    }
    if(this.cssFocusable){
      this.onFocusChanged(true)
    }
    super.handleFocus(isFocused)
  }

  /**
   * 可获焦view，isFocused状态改变
   * @param isFocused
   */
  onFocusChanged(isFocused:boolean){
    if(!this.isVirtual){
      let map = new Map<string,QTAny>()
      map.set('isFocused',isFocused)
      let sid = LayoutAttach.obtainLayoutAttach(this).sid
      map.set('sid',sid)
      ExtendUtil.sendViewEvent(this,'onFocus',map)
    }
    if(isFocused && this.isEventFocus()){
      FastListUtils.handleItemFocus(this)
    }
  }



  handleBlur(isFocused: boolean): void {
    QTLog.i(TAG_FOCUS,`---handle blur this:${ExtendUtil.debugView(this)}`)
    if(this.cssFocusable){
      this.onFocusChanged(false)
    }
    super.handleBlur(isFocused)
  }
}

@Component
export struct QTDiv {
  @ObjectLink renderView: QTDivView
  @ObjectLink children: HippyObservedArray<QTView>
  @Consume('autoSize') @Watch('onAutoSizeChange') autoSize? : number[]

  private readonly TAG = "QTDiv"
  // @State colorModifier: MyStackModifier = modifier
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

  // isEventClick(){
  //   return this.renderView.isVirtual && LayoutAttach.obtainLayoutAttach(this.renderView).virtualExtra.eventClick
  // }

  aboutToAppear() {
    //QTLog.i(TAG_FOCUS,`div about to Appear virtual${this.renderView.isVirtual}, uid:${ViewUtils.getViewUid(this.renderView)}`)
    if (this.renderView.eventAttachedToWindow) {
      this.renderView.eventAttachedToWindow()
    }
    setInterval(()=>{
      QTLog.i(TAG_FOCUS,`+++handle Focus this:${ExtendUtil.debugView(this.renderView)} `)
    },5000)
  }

  aboutToDisappear() {
    if (this.renderView.eventDetachedFromWindow) {
      this.renderView.eventDetachedFromWindow()
    }
  }

  build() {
    if(this.shouldAddGesture() || this.renderView.isEventClick()){
        Stack() {
          ForEach(this.children, (item: QTView) => {
            buildHippyRenderView(item, null)
          }, (item: QTView) => item.tag + '')
        }
        .applyRenderViewBaseAttr(this.renderView)
        .applyGestures(this.renderView)
        //注:当使用了自定义获焦requestFocus时候，不走系统默认焦点逻辑，不会触发focusBox焦点框，如需使用可以根据获焦状态来自定义border样式实现
        //custom
        // .attributeModifier(this.colorModifier)
        // .attributeModifier(this.visibilityModifier)
        .alignContent(Alignment.Center)
        .align(Alignment.Center)
        .onFocus(() => {
          this.renderView.focus = true
          this.renderView.handleFocus(this.renderView.focus)
        })
        .onBlur(() => {
          this.renderView.focus = false
          this.renderView.handleBlur(this.renderView.focus)
        })
        .onClick((event=>{
          ViewUtils.handleClickEvent(event,this.renderView)
        }))
    }else {
        Stack() {
          ForEach(this.children, (item: QTView) => {
            buildHippyRenderView(item, null)
          }, (item: QTView) => item.tag + '')
        }
        .applyRenderViewBaseAttr(this.renderView)
        // .attributeModifier(this.visibilityModifier)
        // .attributeModifier(this.colorModifier)
        .alignContent(Alignment.Center)
        .align(Alignment.Center)
    }
  }
}

// base props for all components
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
  // .focusable($$.cssFocusable)
  //.tabStop($$.cssFocusable)  设置了tabStop的容器节点获焦后 按OK键 不会触发OnClick，而是跳到容器内部寻找可获焦节点
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
