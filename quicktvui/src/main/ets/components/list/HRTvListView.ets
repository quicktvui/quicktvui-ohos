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
import { HippyMap, HippyValue, HippyAny, HippyRenderCallback } from 'hippy/src/main/ets/support/common/HippyTypes';
import { NativeRenderContext ,HRNodeProps} from 'hippy';
import HippyRenderBaseView from 'hippy/src/main/ets/renderer_native/components/base/HippyRenderBaseView';
import { LogUtils } from 'hippy/src/main/ets/support/utils/LogUtils';
import { HRValueUtils } from 'hippy/src/main/ets/renderer_native/utils/HRValueUtils';

@Observed
export class HRTvListView extends HippyRenderBaseView {
  private readonly TAG = "HRTvListView"
  public scrollForward: number = NestedScrollMode.SELF_FIRST
  public scrollBackward: number = NestedScrollMode.SELF_FIRST
  public scroller: ListScroller = new ListScroller()
  public uiCtx: UIContext | null = null
  listDirection: Axis = Axis.Vertical;
  scrollEnabled: boolean = true;
  initialOffset: number = 0;
  edgeEffect: EdgeEffect = EdgeEffect.Spring;
  cachedCount: number = 4;
  scrollEventThrottle: number = 30;
  preloadItemNumber: number = 0;
  exposureEventEnabled: Boolean = false;
  rowShouldSticky: boolean = false

  scrollBeginDragEventEnable: boolean = false
  scrollEndDragEventEnable: boolean = false
  momentumScrollBeginEventEnable: boolean = false
  momentumScrollEndEventEnable: boolean = false
  onScrollEventEnable: boolean = false

  hasPullHeader: boolean = false
  pullHeaderHeight: number = 0
  name: string = ''
  sid: string = ''
  focusable:boolean = true
  nextFocus: Optional<FocusMovement> = {}
  clipChildren: boolean = false
  enableSelectOnFocus: boolean = false
  autofocusPosition: number = 1
  opacity: number = -1
  visibility: Visibility = Visibility.Visible
  backgroundColor: string = ""
  tabStop: boolean = false;

  constructor(ctx: NativeRenderContext) {
    super(ctx)
  }

private findFocusable(children: Array<HippyRenderBaseView>):boolean {
    const stack = [...children];
    while (stack.length > 0) {
        const child = stack.pop();
        if ((child as HRTvListView).focusable) {
            return true;
        }
        if ((child as HRTvListView).children?.length > 0) {
            stack.push(...(child as HRTvListView).children);
        }
    }
    return false;
}

  setProp(propKey: string, propValue: HippyAny | HippyRenderCallback): boolean {
    LogUtils.d(this.TAG, "setProp: propKey " + propKey + ", value: " + propValue)
    switch (propKey) {
      case 'name':
        this.name = HRValueUtils.getString(propValue as HippyAny);
        return true;
      case 'sid':
        this.sid = HRValueUtils.getString(propValue as HippyAny);
        return true;
      case 'focusable':
        this.focusable =HRValueUtils.getBoolean(propValue as HippyAny, true);
        return true;
      case 'clipChildren':
        this.clipChildren = HRValueUtils.getBoolean(propValue as HippyAny, false);
        return true
      case 'autofocusPosition':
        this.autofocusPosition = HRValueUtils.getNumber(propValue as HippyAny);
        return true
      case 'nestedScrollTopPriority':
        {
          let value = HRValueUtils.getString(propValue as HippyAny)
          if (value === 'parent') {
            this.scrollForward = NestedScrollMode.PARENT_FIRST
            //this.scrollBackward = NestedScrollMode.PARENT_FIRST
          } else if (value === 'self') {
            this.scrollForward = NestedScrollMode.SELF_FIRST
            //this.scrollBackward = NestedScrollMode.SELF_FIRST
          }
        }
        return true
      case "horizontal":
        this.listDirection = HRValueUtils.getBoolean(propValue as HippyAny, false) == true ? Axis.Horizontal : Axis.Vertical;
        return true
      case "scrollEnabled":
        this.scrollEnabled = HRValueUtils.getBoolean(propValue as HippyAny, true);
        return true
      case "initialContentOffset":
        this.initialOffset = HRValueUtils.getNumber(propValue as HippyAny);
        return true
      case "itemViewCacheSize":
        this.cachedCount = HRValueUtils.getNumber(propValue as HippyAny);
        return true
      case "scrollEventThrottle":
        this.scrollEventThrottle = HRValueUtils.getNumber2(propValue as HippyAny, 30);
        return true
      case "preloadItemNumber":
        this.preloadItemNumber = HRValueUtils.getNumber(propValue as HippyAny);
        return true
      case "exposureEventEnabled":
        this.exposureEventEnabled = HRValueUtils.getBoolean(propValue as HippyAny, false);
        return true
      case 'rowShouldSticky':
        this.rowShouldSticky = HRValueUtils.getBoolean(propValue as HippyAny, false);
        return true
      case 'bounces':
        let b = HRValueUtils.getBoolean(propValue as HippyAny, true);
        this.edgeEffect = b ? EdgeEffect.Spring : EdgeEffect.None;
        return true
      case 'scrollbegindrag':
        this.scrollBeginDragEventEnable = HRValueUtils.getBoolean(propValue as HippyAny, false)
        return true
      case 'scrollenddrag':
        this.scrollEndDragEventEnable = HRValueUtils.getBoolean(propValue as HippyAny, false)
        return true
      case 'momentumscrollbegin':
        this.momentumScrollBeginEventEnable = HRValueUtils.getBoolean(propValue as HippyAny, false)
        return true
      case 'momentumscrollend':
        this.momentumScrollEndEventEnable = HRValueUtils.getBoolean(propValue as HippyAny, false)
        return true
      case 'scroll':
        this.onScrollEventEnable = HRValueUtils.getBoolean(propValue as HippyAny, false)
        return true
      case 'nextFocusIds':
        this.setNextFocus(propValue as HippyAny);
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
      case 'enableSelectOnFocus':
        this.enableSelectOnFocus = HRValueUtils.getBoolean(propValue as HippyAny, false);
        return true;
      case "opacity":
        {
          this.opacity = HRValueUtils.getNumber(propValue as HippyAny);
          console.log(this.TAG,"设置透明度:"+this.opacity)
        }
        return true;
      case "Visibility":
        {
          let visibility = HRValueUtils.getString(propValue as HippyAny);
          if(visibility == 'visible'){
            this.visibility = Visibility.Visible
          }
          else if(visibility == 'invisible'){
            this.visibility = Visibility.Hidden
          }
          else if(visibility == 'gone'){
            this.visibility = Visibility.None
          }
          console.log(this.TAG,"设置可见:"+this.visibility)
        }
        return true;
      case "backGroundColor":
        {
          this.backgroundColor = HRValueUtils.getString(propValue as HippyAny);
          console.log(this.TAG,"设置背景颜色:"+this.backgroundColor)
        }
        return true;

      case "tabStop":
        {
          this.tabStop = HRValueUtils.getBoolean(propValue as HippyAny, false);
          console.log(this.TAG,"设置焦点阻塞:"+this.tabStop)
        }
        return true;
      default:
        break;
    }

    return super.setProp(propKey, propValue as HippyAny)
  }

  call(method: string, params: Array<HippyAny>, callback: HippyRenderCallback | null): void {
    this.uiCtx?.runScopedTask(() => {
    LogUtils.d(this.TAG, "call: method " + method + ", params: " + params)
    switch (method) {
      case "scrollToIndex":
        {
          let xIndex = HRValueUtils.getNumber(params[0])
          let yIndex = HRValueUtils.getNumber(params[1])
          let animated = HRValueUtils.getBoolean(params[2], false)
          let index = this.listDirection == Axis.Vertical ? yIndex : xIndex
          this.scroller.scrollToIndex(this.hasPullHeader ? index + 1 : index, animated)
        }
        break;
      case "scrollToContentOffset":
        {
          let xOffset = HRValueUtils.getNumber(params[0])
          let yOffset = HRValueUtils.getNumber(params[1])
          let animated = HRValueUtils.getBoolean(params[2], false)
          if (this.listDirection == Axis.Vertical) {
            yOffset += this.pullHeaderHeight
          } else {
            xOffset += this.pullHeaderHeight
          }
          this.scroller.scrollTo({
            xOffset: xOffset,
            yOffset: yOffset,
            animation: animated
          })
        }
        break;
      case "scrollToTop":
        {
          this.scroller.scrollToIndex(this.hasPullHeader ? 1 : 0)
        }
        break
      case "hasFocus":
          let hasFocusRes = new Map<string, HippyValue>() as HippyMap;
          hasFocusRes.set("value", (this.focusable || this.findFocusable(this.children) ));
          callback && callback(hasFocusRes)
          break;
      case "requestFocus":
          focusControl.requestFocus(this.name);
          break;
      case "clearFocus":
          this.uiCtx?.getFocusController().clearFocus();
          break;
      default:
        break;
      }
    })
  }
   setNextFocus(propValue: HippyAny) {
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
