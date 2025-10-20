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
import deviceInfo from '@ohos.deviceInfo';
import {HippyMap, HippyValue, HippyAny, HRNodeProps, HippyRenderCallback, buildHippyRenderView, NativeRenderContext } from 'hippy';
import { LogUtils } from 'hippy/src/main/ets/support/utils/LogUtils';
import { HRValueUtils } from 'hippy/src/main/ets/renderer_native/utils/HRValueUtils';
import HippyRenderBaseView, {
  HippyObservedArray,
  HIPPY_COMPONENT_KEY_PREFIX
} from 'hippy/src/main/ets/renderer_native/components/base/HippyRenderBaseView';
import { HippyCustomComponentView } from 'hippy/src/main/ets/renderer_native/components/custom/HippyCustomComponentView'
import { ColorMetrics, FrameNode, LengthMetrics, NodeController, typeNode } from '@kit.ArkUI';
import { QTBaseComponentView } from '../../QTBaseComponentView';

const HippyGestureTag = 'HippyGestureTag'

@Observed
class MyStackModifier implements AttributeModifier<StackAttribute> {
  public color: string
  constructor(color:string) {
    this.color = color
  }
  applyNormalAttribute(instance: StackAttribute): void {
    instance.backgroundColor(`${this.color}`);
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
export class HRTvDivView extends QTBaseComponentView {
  private readonly TAG = "HRTvDivView"
  public uiCtx: UIContext | null = null
  // TV扩展
  name: string = ''
  focusable: boolean = false//是否可获焦
  focus: boolean = false //当前是否处于聚焦状态
  enableFocusBorder: boolean = false//是否显示focusBox
  focusBoxStyle: FocusBoxStyle = {}//focusBox样式
  focusScale: number = 1.1//聚焦时候放大倍数
  sid: string = ''
  clipChildren: boolean = false
  duplicateParentState: boolean = true
  visibility: Visibility = Visibility.Visible
  showonstate: string = 'normal'
  border: BorderOptions = {}   //模拟selected选中效果
  selected: boolean = false
  visible: boolean = false
  nextFocus: Optional<FocusMovement> = {}
  focusMemory: boolean = false
  focusAbility : string = ""

  constructor(ctx: NativeRenderContext) {
    super(ctx)
    LogUtils.d(this.TAG, "constructor")
  }

  //selected选中时加蓝色边框，不选中时恢复css初始边框
  private setSelectedBorder() {
    if (this.selected === true) {
      this.border.width = 2;
      this.border.color = Color.Blue
    } else {
      this.border.width = this.cssBorder?.width;
      this.border.color = this.cssBorder?.color;
    }
  }

  private showOnState() {
    if (this.showonstate == 'normal') {
      //不做处理
    } else if (this.showonstate == 'selected') {
      //选中显示，未选中隐藏
      if (this.selected === true) {
        this.visibility = Visibility.Visible
      } else {
        this.visibility = Visibility.Hidden
      }
    } else if (this.showonstate == 'focused') {
      //聚焦显示，失焦隐藏
      if (this.focus === true) {
        this.visibility = Visibility.Visible
      } else {
        this.visibility = Visibility.Hidden
      }
    }
  }
  // 暂时把focusable、selected赋初值，具体逻辑待定
  private setDuplicate() {
    if(this.duplicateParentState = false) {
      this.focusable = false;
      this.selected = false;
    } else {

    }
  }

  private findFocusable(children: Array<HippyRenderBaseView>):boolean {
    const stack = [...children];
    while (stack.length > 0) {
      const child = stack.pop();
      if ((child as HRTvDivView).focusable && (child as HRTvDivView).visibility ===  Visibility.Visible) {
        return true;
      }
      if ((child as HRTvDivView).children?.length > 0) {
        stack.push(...(child as HRTvDivView).children);
      }
    }
    return false;
  }


  setProp(propKey: string, propValue: HippyAny): boolean {
    LogUtils.d(this.TAG, `${propKey}: ${JSON.stringify(propValue)}`)
    switch (propKey) {
      case 'visible':
        this.visible = HRValueUtils.getBoolean(propValue as HippyAny, false);
        this.visibility = this.visible ? Visibility.Visible : Visibility.Hidden;
        return true;
      case 'name':
        this.name = HRValueUtils.getString(propValue as HippyAny);
        return true;
      case 'focusable':
        {
          this.focusable = HRValueUtils.getBoolean(propValue as HippyAny, false)
        }
        return true
      case 'enableFocusBorder':
        {
          this.enableFocusBorder = HRValueUtils.getBoolean(propValue as HippyAny, false)
          this.setFocusBoxStyle();//预设focusBox样式
        }
        return true
      case 'focusScale':
        {
          this.focusScale = HRValueUtils.getNumber(propValue as HippyAny)
        }
        return true
      case 'selected':
        this.selected = HRValueUtils.getBoolean(propValue as HippyAny, false);
        this.setSelectedBorder();
        return true;
      case 'showOnState':
        this.showonstate = HRValueUtils.getString(propValue as HippyAny);
        this.showOnState();
        return true;
      case 'sid':
        {
          this.sid = propValue as string
        }
        return true
      case 'clipChildren':
        {
          this.clipChildren = HRValueUtils.getBoolean(propValue as HippyAny, false);
        }
        return true
      case 'duplicateParentState':
        {
          this.duplicateParentState = HRValueUtils.getBoolean(propValue as HippyAny, false);
          this.setDuplicate();
        }
        return true
      case HRNodeProps.VISIBILITY:
        let visibility = propValue as string;
        switch (visibility) {
          case 'visible': {
            this.visibility = Visibility.Visible;
            break;
          }
          case 'invisible': {
            this.visibility = Visibility.Hidden;
            break;
          }
          case 'gone': {
            this.visibility = Visibility.None;
            break;
          }
        }
        return true;
      case 'nextFocusId':
        this.setNextFocus(propValue);
        return true;
      case HRNodeProps.NEXT_FOCUS_UP_ID:
        this.nextFocus!.up = HRValueUtils.getString(propValue as HippyAny);
        return true;
      case HRNodeProps.NEXT_FOCUS_RIGHT_ID:
        this.nextFocus!.right = HRValueUtils.getString(propValue as HippyAny);
        return true;
      case HRNodeProps.NEXT_FOCUS_DOWN_ID:
        this.nextFocus!.down = HRValueUtils.getString(propValue as HippyAny);
        return true;
      case HRNodeProps.NEXT_FOCUS_LEFT_ID:
        this.nextFocus!.left = HRValueUtils.getString(propValue as HippyAny);
        return true;
      case 'nextFocusName':
        this.setNextFocus(propValue);
        return true;
      case 'nextFocusUpName':
        this.nextFocus!.up = HRValueUtils.getString(propValue as HippyAny);
        return true;
      case 'nextFocusRightName':
        this.nextFocus!.right = HRValueUtils.getString(propValue as HippyAny);
        return true;
      case 'nextFocusDownName':
        this.nextFocus!.down = HRValueUtils.getString(propValue as HippyAny);
        return true;
      case 'nextFocusLeftName':
        this.nextFocus!.left = HRValueUtils.getString(propValue as HippyAny);
        return true;
      case 'focusMemory':
        this.focusMemory = HRValueUtils.getBoolean(propValue as HippyAny, false);
        return true;
      default:
        break
    }
    return super.setProp(propKey, propValue)
  }

  call(method: string, params: Array<HippyAny>, callback: HippyRenderCallback | null): void {
    LogUtils.d(this.TAG, "call. method: " + JSON.stringify(method) + ", params: " + JSON.stringify(params))
    switch (method) {
        case "setFocus":
          {
            const focus = params[0] as boolean;
            const id = params[1] as string;
            if (focus) {
              focusControl.requestFocus(this.name);
              LogUtils.d(this.TAG, "requestFocus:"+focusControl.requestFocus(this.name));
            } else {
              this.uiCtx?.getFocusController().clearFocus()
            }
            this.showOnState();
          }
          break;
      case "hasFocus":
        let hasFocusRes = new Map<string, HippyValue>() as HippyMap;
        hasFocusRes.set("value", (this.focusable || this.findFocusable(this.children) ));
        callback && callback(hasFocusRes)
        break;
      case "isFocused":
        let isFocusedRes = new Map<string, HippyValue>() as HippyMap;
        isFocusedRes.set("value", this.focus);
        callback && callback(isFocusedRes)
        break;
      case "requestFocus":
        {
          const id = params[0] as string;
          focusControl.requestFocus(id);
          LogUtils.d(this.TAG, "requestFocus："+focusControl.requestFocus(id));
        }
        break;
      case "clearFocus":
        this.uiCtx?.getFocusController().clearFocus();
        break;
      case "focus":
        {
          const isFocused = params[0] as boolean;
          this.handleFocus(isFocused);
          LogUtils.d(this.TAG, "receive focus：" + isFocused);
        }
        break;
      case "blur":
        {
          const isFocused = params[0] as boolean;
          this.handleBlur(isFocused);
          LogUtils.d(this.TAG, "receive blur：" + isFocused);
        }
        break;
      case "requestFocusDirectly":
        {
          const direction = params[0] as string;
          focusControl.requestFocus(direction.toString());
          console.log(this.TAG, "requestFocusDirectly：" + direction);
        }
        break;
      case "setBackGroundColor":
      {
        const focusAbility = params[0] as string;
        const name = params[1] as string;
        this.focusAbility = focusAbility
        console.log(this.TAG, "receive setBackGroundColor：" + this.focusAbility + " name:" + name);
        modifier.color = focusAbility;
        break;
      }
      case "setVisibility":
        {
          const Visibility = params[0] as string;
          console.log(this.TAG, "receive setVisibilityVisible：" + Visibility);
          visibleModifier.isVisible = Visibility;
          break;
        }
      default:
    }
  }

  setFocusBoxStyle() {
    //处理enableFocusBorder为true时候的默认样式，如果复杂则不能单纯使用focusBox来实现了，需要结合其他属性来混和实现
    // 注意：后续需处理与css样式的冲突以及优先级
    if (this.enableFocusBorder) {
      this.focusBoxStyle = {
        margin: LengthMetrics.px(0),
        strokeColor: ColorMetrics.rgba(255, 0, 0),
        strokeWidth: LengthMetrics.px(3)
      }
    } else {
      this.focusBoxStyle = {
        strokeWidth: LengthMetrics.px(0)
      }
    }
  }

  handleFocus(isFocused: boolean){
    LogUtils.d(this.TAG, "Get Focus Method：" + isFocused);
  }

  handleBlur(isFocused: boolean){
    LogUtils.d(this.TAG, "Get Blur Method：" + isFocused);
  }

  setBorder(): BorderOptions{
    return {
      width: 2,
      color: Color.Blue
    }
  }

  private setNextFocus(propValue: HippyAny) {
    const m = HRValueUtils.getMap(propValue);
    if (m) {
      const left = HRValueUtils.getString((m as Map<string, HippyAny>).get('left') as string);
      const right = HRValueUtils.getString((m as Map<string, HippyAny>).get('right') as string);
      const up = HRValueUtils.getString((m as Map<string, HippyAny>).get('up') as string);
      const down = HRValueUtils.getString((m as Map<string, HippyAny>).get('down') as string);
      left && (this.nextFocus!.left = left);
      right && (this.nextFocus!.right = right);
      up && (this.nextFocus!.up = up);
      down && (this.nextFocus!.down = down);
    }
  }
}

@Component
export struct HRTvDiv {
  @ObjectLink renderView: HRTvDivView
  @ObjectLink children: HippyObservedArray<HippyRenderBaseView>
  private readonly TAG = "HRTvDiv"
  @State colorModifier: MyStackModifier = modifier
  @State visibilityModifier: MyStackModifierVisible = visibleModifier

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

  aboutToAppear() {
    LogUtils.d(this.TAG, "aboutToAppear enter")
    this.renderView.uiCtx = this.getUIContext()
    if (this.renderView.eventAttachedToWindow) {
      this.renderView.eventAttachedToWindow()
    }
  }

  aboutToDisappear() {
    LogUtils.d(this.TAG, "aboutToDisappear enter")
    if (this.renderView.eventDetachedFromWindow) {
      this.renderView.eventDetachedFromWindow()
    }
  }

  build() {
    if(this.shouldAddGesture()){
      Stack(){
        Column(){
          Text("visibile测试1")
        }
        .height(100)
        .aspectRatio(1)
        .backgroundColor(Color.Orange)
      }
      .attributeModifier(this.visibilityModifier)
      .zIndex(1)

      Stack() {
        ForEach(this.children, (item: HippyRenderBaseView) => {
          buildHippyRenderView(item, null)
        }, (item: HippyRenderBaseView) => item.tag + '')
      }
      .applyRenderViewBaseAttr(this.renderView)
      .applyGestures(this.renderView)
      //注:当使用了自定义获焦requestFocus时候，不走系统默认焦点逻辑，不会触发focusBox焦点框，如需使用可以根据获焦状态来自定义border样式实现
      .focusBox(this.renderView.focusBoxStyle)
      .focusable(this.renderView.focusable)
      .border(this.renderView.focus ? this.renderView.setBorder() : this.renderView.border)
      .key(this.renderView.name)
      .scale(this.renderView.focus ? { x: this.renderView.focusScale, y: this.renderView.focusScale } : {})
      .clip(this.renderView.clipChildren)
      .id(this.renderView.sid)
      .visibility(this.renderView.visibility)
      // .nextFocus(this.renderView.nextFocus) // TODO 当前测试设备不支持 nextFocus，需要先注释
      .focusScopeId(this.renderView.sid, this.renderView.focusMemory) // TODO 目前web端未验证出实际效果
      .onFocus(() => {
        this.renderView.focus = true
        LogUtils.d(this.TAG, "onFocus，name:" + this.renderView.name);
        this.renderView.handleFocus(this.renderView.focus)
      })
      .onBlur(() => {
        this.renderView.focus = false
        LogUtils.d(this.TAG, "onFocus，name:" + this.renderView.name);
        this.renderView.handleBlur(this.renderView.focus)
      })
      .attributeModifier(this.colorModifier)
    } else {
      Stack() {
        ForEach(this.children, (item: HippyRenderBaseView) => {
          buildHippyRenderView(item, null)
        }, (item: HippyRenderBaseView) => item.tag + '')
      }
      .applyRenderViewBaseAttr(this.renderView)
      .focusBox(this.renderView.focusBoxStyle)
      .focusable(this.renderView.focusable)
      .border(this.renderView.focus ? this.renderView.setBorder() : this.renderView.border)
      .key(this.renderView.name)
      .scale(this.renderView.focus ? { x: this.renderView.focusScale, y: this.renderView.focusScale } : {})
      .clip(this.renderView.clipChildren)
      .id(this.renderView.sid)
      .visibility(this.renderView.visibility)
      // .nextFocus(this.renderView.nextFocus) // TODO 当前测试设备不支持 nextFocus，需要先注释
      .focusScopeId(this.renderView.sid, this.renderView.focusMemory) // TODO 目前web端未验证出实际效果
      .onFocus(() => {
        this.renderView.focus = true
        LogUtils.d(this.TAG, "onFocus，nam1e:" + this.renderView.name);
        this.renderView.handleFocus(this.renderView.focus)
      })
      .onBlur(() => {
        this.renderView.focus = false
        this.renderView.handleBlur(this.renderView.focus)
      })
      .attributeModifier(this.colorModifier)
    }
  }
}

// base props for all components
@Extend(Stack)
function applyRenderViewBaseAttr($$: HippyRenderBaseView) {
  .key(HIPPY_COMPONENT_KEY_PREFIX + $$.tag)
  .backgroundColor($$.cssBackgroundColor)
  .position({ x: $$.cssPositionX, y: $$.cssPositionY })
  .size({ width: $$.cssWidth, height: $$.cssHeight })
  .opacity($$.cssOpacity)
  .clip($$.cssOverflow)
  .visibility(($$ as HippyRenderBaseView).cssVisibility) // must add as, otherwise the compiler has error
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

@Extend(Stack)
function applyGestures($$: HippyRenderBaseView) {
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
