import {
  HippyRenderBaseView,
  HippyObservedArray,
  NativeRenderContext,
  HippyAny,
  HippyRenderCallback,
  HIPPY_COMPONENT_KEY_PREFIX,
  buildHippyRenderView,
  LogUtils
} from 'hippy'
import { QTBaseComponentView } from '../QTBaseComponentView'

/**
 * 动画
 */
@Observed
export class QTAnimationView extends QTBaseComponentView {
  public animation: QTAnimation | null = null

  constructor(ctx: NativeRenderContext) {
    super(ctx)
  }

  setProp(propKey: string, propValue: HippyAny): boolean {
    return super.setProp(propKey, propValue)
  }

  call(method: string, params: Array<HippyAny>, callback: HippyRenderCallback | null): void {
    if (this.animation && this.animation.call(method, params, callback)) {
      return;
    }
    super.call(method, params, callback)
  }
}

@Component
export struct QTAnimation {
  private readonly TAG = "QTAnimation"
  @ObjectLink renderView: QTAnimationView
  @ObjectLink children: HippyObservedArray<HippyRenderBaseView>
  //------------------------------------------------------
  @State rotateValue: number = 0; // 组件一旋转角度
  //
  @State translateX: number | string = 0; // 组件二偏移量
  @State translateY: number | string = 0; // 组件二偏移量
  @State translateZ: number | string = 0; // 组件二偏移量
  //
  @State opacityValue: number = 1; // 组件二透明度
  //
  @State scaleX: number = 1; //
  @State scaleY: number = 1; //
  @State scaleZ: number = 1; //
  @State centerX: number = -1; //
  @State centerY: number = -1; //
  //------------------------------------------------------

  private animationMap: Map<string, KeyframeAnimate> = new Map();
  private animationSetMap: Map<string, Array<KeyframeAnimate>> = new Map();

  /**
   */
  public call(method: string, params: Array<HippyAny>,
    callback: HippyRenderCallback | null): boolean {
    switch (method) {
      case 'setPivotX': {
        const value: number = params[0] as number;
        this.centerX = value
        break
      }
      case 'setPivotY': {
        const value: number = params[0] as number;
        this.centerY = value
        break
      }
      case 'resetPivot': {
        this.centerX = -1
        this.centerY = -1
        break
      }
      case 'animator': {
        const id: string = params[0] as string;
        const animator = this.convertAnimatorToKeyframes(params)
        this.logInfo('animator', `animator: ${JSON.stringify(animator)}`);
        this.animationMap.set(id, animator);
        break
      }
      case 'resume':
      case 'startDelay':
      case 'start': {
        const id: string = params[0] as string;
        const delay: number | undefined = params.length > 1 ? params[1] as number : undefined;
        const animation = this.animationMap.get(id);
        const animationSet = this.animationSetMap.get(id);
        // 单个动画处理
        if (animation) {
          const clonedAnimation = this.cloneAnimation(animation);
          if (typeof delay === 'number') {
            clonedAnimation.param.delay = delay;
            this.logInfo('start', `Start animation with delay | ID: ${id}, Delay: ${delay}`);
          } else {
            this.logInfo('start', `Start animation | ID: ${id}`);
          }
          this.logInfo('startDelay', `animator: ${JSON.stringify(clonedAnimation)}`);
          this.getUIContext()?.keyframeAnimateTo(clonedAnimation.param, clonedAnimation.keyframes);
          break;
        }
        // 动画集合处理
        if (Array.isArray(animationSet) && animationSet.length > 0) {
          const combinedAnimation: KeyframeAnimate = {
            param: {
              delay,
              iterations: 1, // 可调整为 animationSet[0].param.iterations 等
              onFinish: () => {
                // 所有动画执行完才触发
                animationSet.forEach(anim => anim.param.onFinish?.());
              }
            },
            keyframes: []
          };

          for (const anim of animationSet) {
            for (const state of anim.keyframes) {
              combinedAnimation.keyframes.push({
                duration: state.duration,
                curve: state.curve,
                event: state.event
              });
            }
          }
          this.logInfo('start', `Start animation set | ID: ${id}, Delay: ${delay ?? 0}`);
          this.getUIContext()?.keyframeAnimateTo(combinedAnimation.param,
            combinedAnimation.keyframes);
          break;
        }
        // 都没找到
        this.logWarn('start', `Animation or animation set not found | ID: ${id}`);
        break
      }
      case 'pause': {
        const id: string = params[0] as string;
        LogUtils.w(this.TAG, `Unsupported property: pause`);
        break
      }
      case 'cancel': {
        try {
          const id: string = params[0] as string;
          this.animationMap.delete(id)
          this.logInfo('cancel', `Cancel animation | ID: ${id}`);
        } catch (e) {
        }
        break
      }
      case 'reverse': {
        const id: string = params[0] as string;
        const animation = this.animationMap.get(id);
        if (animation) {
          const clonedAnimation = this.cloneAnimation(animation)
          // 1) 提取原始 durations（只做一次）
          const originalDurations = clonedAnimation.keyframes.map(f => f.duration);
          // 2) 克隆每个 keyframe（避免修改原对象），然后反转数组
          const reversedKeyframes: Array<KeyframeState> = [...clonedAnimation.keyframes]
            .reverse()
          reversedKeyframes.forEach((frame, i) => {
            frame.duration = originalDurations[i];
          });
          this.logInfo('reverse',
            `Reverse animation | ID: ${id} KeyframeAnimate: ${JSON.stringify(reversedKeyframes)}}`);
          this.getUIContext()?.keyframeAnimateTo(clonedAnimation.param, reversedKeyframes);
        } else {
          this.logWarn('reverse', `Animation not found | ID: ${id}`);
        }
        break
      }
      case 'afterDelay': {
        const animatorSetId: string = params[0] as string;
        const animatorId: string = params[1] as string;
        break
      }
      case 'reset': {
        this.logInfo('reset', `Reset animations`);
        this.animationMap.clear();
        this.centerX = -1
        this.centerY = -1
        break
      }
    //----------------------------------------------------------------------------
      case 'animatorSet': {
        const animatorSetId: string = params[0] as string;
        const animatorSet = this.convertAnimatorSetToKeyframes(params)
        const oldSet: Array<KeyframeAnimate> | undefined = this.animationSetMap.get(animatorSetId);
        const newSet: Array<KeyframeAnimate> =
          Array.isArray(animatorSet) ? animatorSet : [animatorSet];

        if (!Array.isArray(oldSet)) {
          this.animationSetMap.set(animatorSetId, newSet);
        } else {
          const merged: Array<KeyframeAnimate> = [...oldSet, ...newSet];
          this.animationSetMap.set(animatorSetId, merged);
        }
        break
      }
      case 'play': {
        const animatorId: string = params[1] as string;
        const animator: KeyframeAnimate | undefined = this.animationMap.get(animatorId)
        if (!animator) {
          break
        }
        const animatorSetId: string = params[0] as string;
        const oldSet: Array<KeyframeAnimate> | undefined = this.animationSetMap.get(animatorSetId);

        if (!Array.isArray(oldSet)) {
          this.animationSetMap.set(animatorSetId, [animator]);
        } else {
          const merged: Array<KeyframeAnimate> = [...oldSet, animator];
          this.animationSetMap.set(animatorSetId, merged);
        }
        break
      }
      case 'with': {
        const animatorSetId: string = params[0] as string;
        const animatorId: string = params[1] as string;
        const animator: KeyframeAnimate | undefined = this.animationMap.get(animatorId);
        if (!animator) {
          break;
        }
        const oldSet: Array<KeyframeAnimate> | undefined = this.animationSetMap.get(animatorSetId);
        const newSet = oldSet ? [...oldSet, animator] : [animator];
        const merged = this.mergeKeyframeAnimates(newSet);
        this.animationSetMap.set(animatorSetId, [merged]);
        break
      }
      case 'before': {
        const animatorId: string = params[1] as string;
        const animator: KeyframeAnimate | undefined = this.animationMap.get(animatorId)
        if (!animator) {
          break
        }
        const animatorSetId: string = params[0] as string;
        const oldSet: Array<KeyframeAnimate> | undefined = this.animationSetMap.get(animatorSetId);

        if (!Array.isArray(oldSet)) {
          this.animationSetMap.set(animatorSetId, [animator]);
        } else {
          const merged: Array<KeyframeAnimate> = [...oldSet, animator];
          this.animationSetMap.set(animatorSetId, merged);
        }
        break
      }
      case 'after': {
        const animatorId: string = params[1] as string;
        const animator: KeyframeAnimate | undefined = this.animationMap.get(animatorId)
        if (!animator) {
          break
        }
        const animatorSetId: string = params[0] as string;
        const oldSet: Array<KeyframeAnimate> | undefined = this.animationSetMap.get(animatorSetId);

        if (!Array.isArray(oldSet)) {
          this.animationSetMap.set(animatorSetId, [animator]);
        } else {
          const merged: Array<KeyframeAnimate> = [animator, ...oldSet];
          this.animationSetMap.set(animatorSetId, merged);
        }
        break
      }
      case 'playSequentially': {
        const animatorSetId: string = params[0] as string;
        const animatorIds: Array<string> = params[1] as Array<string>;
        this.logInfo('playSequentially',
          `animatorSetId: ${animatorSetId} animatorIds: ${JSON.stringify(animatorIds)}`);
        const animators: KeyframeAnimate[] = animatorIds
          .map((id) => this.animationMap.get(id))
          .filter((a) => a !== undefined)
          .map((a) => a as KeyframeAnimate);

        const oldSet: Array<KeyframeAnimate> | undefined = this.animationSetMap.get(animatorSetId);

        if (!Array.isArray(oldSet)) {
          this.animationSetMap.set(animatorSetId, [...animators]);
        } else {
          const merged: Array<KeyframeAnimate> = [...oldSet, ...animators];
          this.animationSetMap.set(animatorSetId, merged);
        }
        this.logInfo('playSequentially',
          `AnimationSet: ${JSON.stringify(this.animationSetMap.get(animatorSetId))}`);
        break
      }
      case 'playTogether': {
        const animatorSetId: string = params[0] as string;
        const animatorIds: Array<string> = params[1] as Array<string>;
        this.logInfo('playTogether',
          `animatorSetId: ${animatorSetId} animatorIds: ${JSON.stringify(animatorIds)}`);

        const animators: KeyframeAnimate[] = animatorIds
          .map(id => this.animationMap.get(id))
          .filter(animator => animator !== undefined)
          .map(animator => animator as KeyframeAnimate);

        if (animators.length === 0) {
          break;
        }
        const mergedAnimate: KeyframeAnimate = this.mergeKeyframeAnimates(animators);
        this.logInfo('playTogether',
          `animatorSetId: ${animatorSetId} animatorIds: ${JSON.stringify(mergedAnimate)}`);
        this.animationSetMap.set(animatorSetId, [mergedAnimate]);
        break
      }
    }
    return false
  }

  aboutToAppear(): void {
    this.renderView.animation = this

    //translate
    this.translateX = this.renderView?.cssTranslate?.x ?? 0
    this.translateY = this.renderView?.cssTranslate?.y ?? 0
    this.translateZ = this.renderView?.cssTranslate?.z ?? 0

    //opacity
    this.opacityValue = this.renderView?.cssOpacity ?? 1

    //scale
    this.scaleX = this.renderView?.cssScale?.x ?? 1
    this.scaleY = this.renderView?.cssScale?.y ?? 1
    this.scaleZ = this.renderView?.cssScale?.z ?? 1
  }

  aboutToDisappear() {
    this.renderView.animation = null
  }

  build(): void {
    Stack() {
      ForEach(this.children, (item: HippyRenderBaseView) => {
        buildHippyRenderView(item, null)
      }, (item: HippyRenderBaseView) => item.tag + '')
      ContentSlot(this.renderView.childSlot)
    }
    .applyRenderViewBaseAttr(this.renderView)
    .opacity(this.opacityValue)
    .translate({
      x: this.translateX,
      y: this.translateY,
      z: this.translateZ
    })
    .rotate({ angle: this.rotateValue })
    .scale({
      x: this.scaleX,
      y: this.scaleY,
      z: this.scaleZ,
      centerX: this.centerX == -1 ? undefined : this.centerX,
      centerY: this.centerY == -1 ? undefined : this.centerY
    })
  }

  private parseCurve(interpolator: QTAnimationInterpolator | null): Curve {
    const type = interpolator?.type || -1;
    switch (type) {
      case QTAnimationInterpolatorType.QT_LINEAR_INTERPOLATOR:
        return Curve.Linear;
      case QTAnimationInterpolatorType.QT_ACCELERATE_DECELERATE_INTERPOLATOR:
        return Curve.EaseInOut;
      case QTAnimationInterpolatorType.QT_ACCELERATE_INTERPOLATOR:
        return Curve.EaseIn;
      case QTAnimationInterpolatorType.QT_DECELERATE_INTERPOLATOR:
        return Curve.EaseOut;
      case QTAnimationInterpolatorType.QT_FAST_OUT_SLOW_IN_INTERPOLATOR:
        return Curve.FastOutSlowIn;
      case QTAnimationInterpolatorType.QT_FAST_OUT_LINEAR_IN_INTERPOLATOR:
        return Curve.FastOutLinearIn;
      case QTAnimationInterpolatorType.QT_OVERSHOOT_INTERPOLATOR:
        return Curve.Sharp;
      case QTAnimationInterpolatorType.QT_ANTICIPATE_INTERPOLATOR:
        return Curve.Rhythm;
      case QTAnimationInterpolatorType.QT_ANTICIPATE_OVERSHOOT_INTERPOLATOR:
        return Curve.Smooth;
      case QTAnimationInterpolatorType.QT_BOUNCE_INTERPOLATOR:
        return Curve.Friction;
    // 这些在 ArkTS 中无明确对应：
      case QTAnimationInterpolatorType.QT_CYCLE_INTERPOLATOR:
      case QTAnimationInterpolatorType.QT_PATH_INTERPOLATOR:
        return Curve.Linear; // 默认或自定义扩展支持
      default:
        return Curve.Linear;
    }
  }

  private parseInterpolator(raw: Array<HippyAny>): QTAnimationInterpolator | null {
    if (!Array.isArray(raw) || raw.length === 0) {
      return null;
    }
    const type = raw[0] as number;
    const params = Array.isArray(raw[1]) ? raw[1] : [];
    return { type, params };
  }

  private cloneAnimation(animation: KeyframeAnimate): KeyframeAnimate {
    const clonedParam: KeyframeAnimateParam = {
      delay: animation.param.delay,
      iterations: animation.param.iterations,
      onFinish: animation.param.onFinish,
    };

    const clonedKeyframes: Array<KeyframeState> = animation.keyframes
      .map((frame: KeyframeState): KeyframeState => {
        return {
          duration: frame.duration,
          curve: frame.curve,
          event: frame.event
        };
      });
    return {
      param: clonedParam,
      keyframes: clonedKeyframes
    };
  }

  private convertAnimatorToKeyframes(params: Array<HippyAny>): KeyframeAnimate {
    const id: string = params[0] as string;
    const valueType: number = params[1] as number;
    const propertyName: string = params[2] as string;
    const values: Array<number> = params[3] as Array<number>;
    const duration: number = params[4] as number;
    const repeatMode: number = params[5] as number;
    const repeatCount: number = params[6] as number;
    const listenAnimator: boolean = params[7] as boolean;
    const listenAnimatorValue: boolean = params[8] as boolean;
    const interpolator: Array<HippyAny> = params[9] as Array<HippyAny>;
    const i = this.parseInterpolator(interpolator)

    const singleDuration = Math.floor(duration / Math.max(1, values.length - 1));
    const curve = this.parseCurve(i);

    const param: KeyframeAnimateParam = {
      iterations: repeatCount > 0 ? repeatCount : 1,
    };
    const keyframes: KeyframeState[] = [];

    for (let i = 0; i < values.length; i++) {
      const value = values[i];
      keyframes.push({
        duration: (i == 0) ? 0 : singleDuration,
        curve: curve,
        event: () => {
          switch (propertyName) {
            case 'rotation':
              this.rotateValue = Number(value);
              break;
            case 'translationX':
              this.translateX = Number(value);
              break;
            case 'translationY':
              this.translateY = Number(value);
              break;
            case 'translationZ':
              this.translateZ = Number(value);
              break;
            case 'scaleX':
              this.scaleX = Number(value);
              break;
            case 'scaleY':
              this.scaleY = Number(value);
              break;
            case 'scaleZ':
              this.scaleZ = Number(value);
              break;
            case 'alpha':
            case 'opacity':
              this.opacityValue = Number(value);
              break;
            default: {
              LogUtils.w(this.TAG, `不支持的属性: ${propertyName}`);
              break;
            }
          }
        }
      });
    }
    return {
      param,
      keyframes
    };
  }

  private convertAnimatorSetToKeyframes(params: Array<HippyAny>): KeyframeAnimate {
    const id: string = params[0] as string;
    const duration: number = params[1] as number;
    const listenAnimator: boolean = params[2] as boolean;

    const param: KeyframeAnimateParam = {
      iterations: 1
    };
    const keyframes: KeyframeState[] = [];

    return {
      param,
      keyframes
    };
  }

  private mergeKeyframeAnimates(animators: KeyframeAnimate[]): KeyframeAnimate {
    const combinedFrames: Array<CombinedFrame> = [];

    for (const animator of animators) {
      const delay = animator.param.delay ?? 0;
      let currentTime = delay;

      for (const frame of animator.keyframes) {
        combinedFrames.push({
          startTime: currentTime,
          duration: frame.duration,
          event: frame.event,
          curve: frame.curve,
        });
        currentTime += frame.duration;
      }
    }

    // 排序：按 startTime 升序排列
    combinedFrames.sort((a, b) => a.startTime - b.startTime);

    // 重新构造统一的 keyframes，使用相对时间片段（duration）
    const mergedKeyframes: KeyframeState[] = [];
    let prevTime = 0;

    for (const frame of combinedFrames) {
      const gap = frame.startTime - prevTime;
      if (gap > 0) {
        // 插入空帧以补足时间间隔，避免动画提前
        mergedKeyframes.push({
          duration: gap,
          event: () => {
          },
        });
      }

      mergedKeyframes.push({
        duration: frame.duration,
        curve: frame.curve,
        event: frame.event,
      });

      prevTime = frame.startTime + frame.duration;
    }

    const mergedAnimate: KeyframeAnimate = {
      param: {
        delay: 0,
        iterations: 1,
      },
      keyframes: mergedKeyframes,
    };

    return mergedAnimate;
  }

  private logInfo(action: string, message: string) {
    LogUtils.i(this.TAG, `[${action}] ${message}`);
  }

  private logWarn(action: string, message: string) {
    LogUtils.w(this.TAG, `[warn][${action}] ${message}`);
  }
}

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


//-------------------------------------------------------------------------------------
export interface QTAnimationInterpolator {
  type: number
  params?: Array<HippyAny>
}

export interface KeyframeAnimate {
  param: KeyframeAnimateParam,
  keyframes: Array<KeyframeState>
}

export enum QTAnimationInterpolatorType {
  QT_ACCELERATE_DECELERATE_INTERPOLATOR = 1,
  QT_ACCELERATE_INTERPOLATOR = 2,
  QT_ANTICIPATE_INTERPOLATOR = 3,
  QT_ANTICIPATE_OVERSHOOT_INTERPOLATOR = 4,
  QT_BOUNCE_INTERPOLATOR = 5,
  QT_CYCLE_INTERPOLATOR = 6,
  QT_DECELERATE_INTERPOLATOR = 7,
  QT_LINEAR_INTERPOLATOR = 8,
  QT_OVERSHOOT_INTERPOLATOR = 9,
  QT_FAST_OUT_LINEAR_IN_INTERPOLATOR = 10,
  QT_FAST_OUT_SLOW_IN_INTERPOLATOR = 11,
  QT_PATH_INTERPOLATOR = 12,
}

interface CombinedFrame {
  startTime: number;
  duration: number;
  event: () => void;
  curve?: string | Curve | ICurve;
}

