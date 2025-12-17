import { QTBaseComponentView } from "../components/QTBaseComponentView";
import { PageManager } from "../components/router/PageManager";
import { TVView } from "../components/TVView";
import { TAG_FOCUS } from "../Constant";
import { QTView } from "../QTTypes";
import { ExtendUtil } from "./ExtendUtil";
import { QTLog } from "./QTLog";

// Rect类实现
class Rect {
  left: number = 0;
  top: number = 0;
  right: number = 0;
  bottom: number = 0;

  constructor(left?: number, top?: number, right?: number, bottom?: number) {
    if (left !== undefined) this.left = left;
    if (top !== undefined) this.top = top;
    if (right !== undefined) this.right = right;
    if (bottom !== undefined) this.bottom = bottom;
  }

  get width(): number {
    return this.right - this.left;
  }

  get height(): number {
    return this.bottom - this.top;
  }

  set(left: number, top: number, right: number, bottom: number): Rect {
    this.left = left;
    this.top = top;
    this.right = right;
    this.bottom = bottom;
    return this;
  }

  setFrom(other: Rect): Rect {
    this.left = other.left;
    this.top = other.top;
    this.right = other.right;
    this.bottom = other.bottom;
    return this;
  }

  offset(dx: number, dy: number): Rect {
    this.left += dx;
    this.top += dy;
    this.right += dx;
    this.bottom += dy;
    return this;
  }

  offsetTo(newLeft: number, newTop: number): Rect {
    const width = this.width;
    const height = this.height;
    this.left = newLeft;
    this.top = newTop;
    this.right = newLeft + width;
    this.bottom = newTop + height;
    return this;
  }

  contains(other: Rect): boolean {
    return (
      this.left <= other.left &&
        this.top <= other.top &&
        this.right >= other.right &&
        this.bottom >= other.bottom
    );
  }

  intersects(other: Rect): boolean {
    return (
      this.left < other.right &&
        other.left < this.right &&
        this.top < other.bottom &&
        other.top < this.bottom
    );
  }

  isEmpty(): boolean {
    return this.left >= this.right || this.top >= this.bottom;
  }

  centerX(): number {
    return (this.left + this.right) * 0.5;
  }

  centerY(): number {
    return (this.top + this.bottom) * 0.5;
  }

  exactCenterX(): number {
    return (this.left + this.right) / 2;
  }

  exactCenterY(): number {
    return (this.top + this.bottom) / 2;
  }

  equals(other: Rect): boolean {
    return (
      this.left === other.left &&
        this.top === other.top &&
        this.right === other.right &&
        this.bottom === other.bottom
    );
  }

  toString(): string {
    return `Rect(${this.left}, ${this.top}, ${this.right}, ${this.bottom})`;
  }

  // Android兼容方法
  setEmpty(): void {
    this.left = this.top = this.right = this.bottom = 0;
  }

  intersect(other: Rect): boolean {
    const left = Math.max(this.left, other.left);
    const top = Math.max(this.top, other.top);
    const right = Math.min(this.right, other.right);
    const bottom = Math.min(this.bottom, other.bottom);

    if (left < right && top < bottom) {
      this.left = left;
      this.top = top;
      this.right = right;
      this.bottom = bottom;
      return true;
    }

    this.setEmpty();
    return false;
  }

  union(other: Rect): void {
    if (other.isEmpty()) return;

    if (this.isEmpty()) {
      this.setFrom(other);
      return;
    }

    this.left = Math.min(this.left, other.left);
    this.top = Math.min(this.top, other.top);
    this.right = Math.max(this.right, other.right);
    this.bottom = Math.max(this.bottom, other.bottom);
  }

  inset(dx: number, dy: number): void {
    this.left += dx;
    this.top += dy;
    this.right -= dx;
    this.bottom -= dy;
  }
}

export class FocusFinder {
  static DIRECTION_LEFT = 1;
  static DIRECTION_RIGHT = 2;
  static DIRECTION_UP = 3;
  static DIRECTION_DOWN = 4;

  // 临时Rect对象，避免频繁创建
  private static mFocusedRect = new Rect();
  private static mOtherRect = new Rect();
  private static mBestCandidateRect = new Rect();
  private static mTempRect = new Rect(); // 新增的临时Rect

  static findNextFocus(focusedView: TVView | null, root: QTView, direction: number): TVView | null {
    const views: TVView[] = [];
    FocusFinder.addAllFocusable(views, root, direction);

    QTLog.i(TAG_FOCUS, `findNextFocus search views length: ${views.length} root : ${ExtendUtil.debugView(root)}`);
    // QTLog.i(TAG_FOCUS, `findNextFocus current focused: ${focusedView ? ExtendUtil.debugView(focusedView) : 'null'}`);

    if (views.length === 0) {
      QTLog.i(TAG_FOCUS, `findNextFocus no focusable views found`);
      return null;
    }

    views.map((v)=>{
      QTLog.d(TAG_FOCUS,`findNextFocus to search :${v.uid},type:${v.viewType}`)
    })

    // 如果有当前焦点视图，找到下一个焦点
    if (focusedView) {
      // 获取焦点视图的矩形
      const focusedRect = FocusFinder.getViewRectInRoot(focusedView, root);

      // 如果当前焦点视图的矩形无效，按没有焦点处理
      if (!focusedRect) {
        QTLog.w(TAG_FOCUS, `Current focused view has invalid rect, treat as no focus`);
        return FocusFinder.findFirstFocusableByDirection(views, root, direction);
      }

      QTLog.i(TAG_FOCUS, `findNextFocus current focused rect: ${focusedRect.toString()}`);

      // 找到最佳候选视图
      const bestCandidate = FocusFinder.findBestCandidate(views, root, focusedView, focusedRect, direction);
      // QTLog.i(TAG_FOCUS, `findNextFocus best candidate: ${bestCandidate ? ExtendUtil.debugView(bestCandidate) : 'null'}`);

      return bestCandidate;
    } else {
      // 如果没有当前焦点，根据方向找到最合适的初始焦点
      QTLog.i(TAG_FOCUS, `findNextFocus no current focus, finding initial focus`);
      return FocusFinder.findInitialFocus( views, root, direction);
    }
  }

  // 新增方法：找到初始焦点
  private static findInitialFocus(views: TVView[], root: QTView, direction: number): TVView | null {
    // 首先尝试找屏幕左上角附近的可获取焦点视图
    // const screenWidth = root.cssWidth;
    // const screenHeight = root.cssHeight;

    let bestView: TVView | null = null;
    let bestDistance = Number.MAX_VALUE;

    for (let i = 0; i < views.length; i++) {
      const view = views[i];
      const viewRect = FocusFinder.getViewRectInRoot(view, root);

      if (!viewRect) {
        continue;
      }

      // 计算到屏幕左上角的距离
      const distance = Math.sqrt(
        Math.pow(viewRect.left, 2) +
        Math.pow(viewRect.top, 2)
      );

      if (bestView === null || distance < bestDistance) {
        bestView = view;
        bestDistance = distance;
      }
    }

    return bestView;
  }

  // 新增方法：根据方向找到位置最靠前/靠上的可获取焦点视图
  private static findFirstFocusableByDirection(views: TVView[], root: QTView, direction: number): TVView | null {
    if (views.length === 0) {
      return null;
    }

    QTLog.i(TAG_FOCUS, `findFirstFocusableByDirection direction: ${direction}, views: ${views.length}`);

    let bestView: TVView | null = null;
    let bestScore = Number.MAX_VALUE;

    for (let i = 0; i < views.length; i++) {
      const view = views[i];
      const viewRect = FocusFinder.getViewRectInRoot(view, root);

      // 跳过无效矩形
      if (!viewRect) {
        continue;
      }

      let score = 0;

      // 根据方向计算得分，得分越小越好
      switch (direction) {
        case FocusFinder.DIRECTION_DOWN:
          // 对于向下，优先选择top最小的（最靠上），其次left最小的（最靠左）
          score = viewRect.top * 1000 + viewRect.left;
          // QTLog.d(TAG_FOCUS, `findFirstFocusableByDirection DOWN candidate: ${ExtendUtil.debugView(view)}, top: ${viewRect.top}, left: ${viewRect.left}, score: ${score}`);
          break;

        case FocusFinder.DIRECTION_UP:
          // 对于向上，优先选择bottom最大的（最靠下），其次left最小的
          score = (10000 - viewRect.bottom) * 1000 + viewRect.left;
          // QTLog.d(TAG_FOCUS, `findFirstFocusableByDirection UP candidate: ${ExtendUtil.debugView(view)}, bottom: ${viewRect.bottom}, left: ${viewRect.left}, score: ${score}`);
          break;

        case FocusFinder.DIRECTION_RIGHT:
          // 对于向右，优先选择left最小的（最靠左），其次top最小的
          score = viewRect.left * 1000 + viewRect.top;
          // QTLog.d(TAG_FOCUS, `findFirstFocusableByDirection RIGHT candidate: ${ExtendUtil.debugView(view)}, left: ${viewRect.left}, top: ${viewRect.top}, score: ${score}`);
          break;

        case FocusFinder.DIRECTION_LEFT:
          // 对于向左，优先选择right最大的（最靠右），其次top最小的
          score = (10000 - viewRect.right) * 1000 + viewRect.top;
          // QTLog.d(TAG_FOCUS, `findFirstFocusableByDirection LEFT candidate: ${ExtendUtil.debugView(view)}, right: ${viewRect.right}, top: ${viewRect.top}, score: ${score}`);
          break;
      }

      // 选择得分最小的视图
      if (bestView === null || score < bestScore) {
        bestView = view;
        bestScore = score;
        // QTLog.d(TAG_FOCUS, `findFirstFocusableByDirection new best: ${ExtendUtil.debugView(view)}, score: ${score}`);
      }
    }

    // QTLog.i(TAG_FOCUS, `findFirstFocusableByDirection final best: ${bestView ? ExtendUtil.debugView(bestView) : 'null'}, score: ${bestScore}`);
    return bestView;
  }

  // 辅助方法：判断哪个主轴值更好
  private static isBetterPrimaryAxisValue(direction: number, value1: number, value2: number): boolean {
    switch (direction) {
      case FocusFinder.DIRECTION_DOWN:
        // 对于向下，更小的top值更好（更靠上）
        return value1 < value2;
      case FocusFinder.DIRECTION_UP:
        // 对于向上，更大的bottom值更好（更靠下）
        return value1 > value2;
      case FocusFinder.DIRECTION_RIGHT:
        // 对于向右，更小的left值更好（更靠左）
        return value1 < value2;
      case FocusFinder.DIRECTION_LEFT:
        // 对于向左，更大的right值更好（更靠右）
        return value1 > value2;
      default:
        return false;
    }
  }

  static addAllFocusable(views: TVView[], target: QTView, direction: number) {
    // 检查当前视图是否可获取焦点
    if(target instanceof QTBaseComponentView){
      target.addFocusables(views,direction)
    }
    else if (target.cssFocusable === true) {
      //views.push(target);
      QTLog.e(TAG_FOCUS,`addAllFocusable sip view :${ExtendUtil.debugView(target)}`)
    }
    if (target.children && target.children.length > 0) {
      target.children.forEach((child: QTView) => {
        FocusFinder.addAllFocusable(views, child, direction);
      });
    }
  }

  private static getViewRectInRoot(view: TVView, root: QTView): Rect | null {
    try {
      let uid = view.uid
      // 检查uid是否有效
      if (!uid) {
        return null;
      }

      let uiContext = PageManager.getUIContext();
      if(!uiContext){
        QTLog.e(TAG_FOCUS,`FocusFinder error uiContext is null`)
        return null;
      }

      let c = uiContext.getComponentUtils().getRectangleById(uid);

      // 检查c是否有效
      if (!c) {
        QTLog.w(TAG_FOCUS, `getViewRectInRoot getRectangleById returned null for uid: ${uid}`);
        return null;
      }

      // 检查视图的宽度和高度是否为0（或接近0）
      if (!c.size || c.size.width <= 0.1 || c.size.height <= 0.1) {
        QTLog.w(TAG_FOCUS, `getViewRectInRoot view has zero/small size, skip: ${view.uid} type:${view.viewType} size:${c.size?.width}x${c.size?.height}`);
        return null;
      }

      // 检查windowOffset是否有效
      if (!c.windowOffset) {
        QTLog.w(TAG_FOCUS, `getViewRectInRoot no windowOffset for uid: ${uid}`);
        return null;
      }

      const rect = new Rect();
      rect.left = c.windowOffset.x;
      rect.top = c.windowOffset.y;
      rect.right = rect.left + c.size.width;
      rect.bottom = rect.top + c.size.height;
      QTLog.d(TAG_FOCUS, `getViewRectInRoot reutrn view: ${view.uid} type:${view.viewType} size:${c.size?.width}x${c.size?.height} ,left: ${rect.left},top : ${rect.top}`);
      return rect;
    } catch (e) {
      QTLog.e(TAG_FOCUS, `getViewRectInRoot error: ${e}`);
      return null;
    }
  }


  private static findBestCandidate(
    focusables: TVView[],
    root: QTView,
    focused: TVView,
    focusedRect: Rect,
    direction: number
  ): TVView | null {
    let bestCandidate: TVView | null = null;
    FocusFinder.mBestCandidateRect.setFrom(focusedRect);

    QTLog.i(TAG_FOCUS, `findBestCandidate start, focusedRect: ${focusedRect.toString()}, direction: ${direction}, candidates: ${focusables.length}`);

    // 初始化最佳候选矩形为不可能的位置（在相反方向）
    switch (direction) {
      case FocusFinder.DIRECTION_DOWN:
        // 对于向下，初始化为当前焦点上方很远的位置
        FocusFinder.mBestCandidateRect.offset(0, -(focusedRect.height + 1000));
        break;
      case FocusFinder.DIRECTION_UP:
        // 对于向上，初始化为当前焦点下方很远的位置
        FocusFinder.mBestCandidateRect.offset(0, focusedRect.height + 1000);
        break;
      case FocusFinder.DIRECTION_RIGHT:
        // 对于向右，初始化为当前焦点左侧很远的位置
        FocusFinder.mBestCandidateRect.offset(-(focusedRect.width + 1000), 0);
        break;
      case FocusFinder.DIRECTION_LEFT:
        // 对于向左，初始化为当前焦点右侧很远的位置
        FocusFinder.mBestCandidateRect.offset(focusedRect.width + 1000, 0);
        break;
    }

    QTLog.i(TAG_FOCUS, `findBestCandidate initial bestRect: ${FocusFinder.mBestCandidateRect.toString()}`);

    for (let i = 0; i < focusables.length; i++) {
      const candidate = focusables[i];

      // 跳过当前焦点视图和根视图
      if (candidate === focused || (( candidate instanceof  QTBaseComponentView) && candidate === root)) {
        continue;
      }

      // 获取候选视图的矩形（可能返回null）
      const candidateRect = FocusFinder.getViewRectInRoot( candidate, root);
      if (!candidateRect) {
        continue;
      }


      // 检查是否更好的候选者
      if (FocusFinder.isBetterCandidate(direction, focusedRect, candidateRect, FocusFinder.mBestCandidateRect)) {
        FocusFinder.mBestCandidateRect.setFrom(candidateRect);
        bestCandidate = candidate;
      }
    }

    return bestCandidate;
  }

  private static isBetterCandidate(
    direction: number,
    source: Rect,
    candidate: Rect,
    currentBest: Rect
  ): boolean {
    // 检查候选矩形是否在方向上是合法的候选者
    if (!FocusFinder.isCandidate(source, candidate, direction)) {
      return false;
    }

    // 如果当前最佳不是候选者，那么候选者更好
    if (!FocusFinder.isCandidate(source, currentBest, direction)) {
      return true;
    }

    // 检查射线是否击败当前最佳
    if (FocusFinder.beamBeats(direction, source, candidate, currentBest)) {
      return true;
    }

    // 如果当前最佳的射线击败候选者，那么候选者不好
    if (FocusFinder.beamBeats(direction, source, currentBest, candidate)) {
      return false;
    }

    // 计算加权距离并比较
    const candidateDistance = FocusFinder.getWeightedDistanceFor(
      FocusFinder.majorAxisDistance(direction, source, candidate),
      FocusFinder.minorAxisDistance(direction, source, candidate)
    );

    const currentBestDistance = FocusFinder.getWeightedDistanceFor(
      FocusFinder.majorAxisDistance(direction, source, currentBest),
      FocusFinder.minorAxisDistance(direction, source, currentBest)
    );

    return candidateDistance < currentBestDistance;
  }

  private static isCandidate(source: Rect, dest: Rect, direction: number): boolean {
    switch (direction) {
      case FocusFinder.DIRECTION_LEFT:
        return (source.right > dest.right || source.left >= dest.right) && source.left > dest.left;
      case FocusFinder.DIRECTION_RIGHT:
        return (source.left < dest.left || source.right <= dest.left) && source.right < dest.right;
      case FocusFinder.DIRECTION_UP:
        return (source.bottom > dest.bottom || source.top >= dest.bottom) && source.top > dest.top;
      case FocusFinder.DIRECTION_DOWN:
        return (source.top < dest.top || source.bottom <= dest.top) && source.bottom < dest.bottom;
      default:
        return false;
    }
  }

  private static beamBeats(direction: number, source: Rect, rect1: Rect, rect2: Rect): boolean {
    const rect1InBeam = FocusFinder.beamsOverlap(direction, source, rect1);
    const rect2InBeam = FocusFinder.beamsOverlap(direction, source, rect2);

    // 如果rect2也在射线上，或者rect1不在射线上，rect1不赢
    if (rect2InBeam || !rect1InBeam) {
      return false;
    }

    // rect1在射线上，rect2不在
    // 如果rect2不在方向上，rect1赢
    if (!FocusFinder.isToDirectionOf(direction, source, rect2)) {
      return true;
    }

    // 对于水平方向，在射线上总是赢
    if (direction === FocusFinder.DIRECTION_LEFT || direction === FocusFinder.DIRECTION_RIGHT) {
      return true;
    }

    // 对于垂直方向，只有当rect1比rect2更近时才赢
    return (
      FocusFinder.majorAxisDistance(direction, source, rect1) <
      FocusFinder.majorAxisDistanceToFarEdge(direction, source, rect2)
    );
  }

  private static beamsOverlap(direction: number, rect1: Rect, rect2: Rect): boolean {
    switch (direction) {
      case FocusFinder.DIRECTION_LEFT:
      case FocusFinder.DIRECTION_RIGHT:
        return rect2.bottom > rect1.top && rect2.top < rect1.bottom;
      case FocusFinder.DIRECTION_UP:
      case FocusFinder.DIRECTION_DOWN:
        return rect2.right > rect1.left && rect2.left < rect1.right;
      default:
        return false;
    }
  }

  private static isToDirectionOf(direction: number, src: Rect, dest: Rect): boolean {
    switch (direction) {
      case FocusFinder.DIRECTION_LEFT:
        return src.left >= dest.right;
      case FocusFinder.DIRECTION_RIGHT:
        return src.right <= dest.left;
      case FocusFinder.DIRECTION_UP:
        return src.top >= dest.bottom;
      case FocusFinder.DIRECTION_DOWN:
        return src.bottom <= dest.top;
      default:
        return false;
    }
  }

  private static majorAxisDistance(direction: number, source: Rect, dest: Rect): number {
    return Math.max(0, FocusFinder.majorAxisDistanceRaw(direction, source, dest));
  }

  private static majorAxisDistanceRaw(direction: number, source: Rect, dest: Rect): number {
    switch (direction) {
      case FocusFinder.DIRECTION_LEFT:
        return source.left - dest.right;
      case FocusFinder.DIRECTION_RIGHT:
        return dest.left - source.right;
      case FocusFinder.DIRECTION_UP:
        return source.top - dest.bottom;
      case FocusFinder.DIRECTION_DOWN:
        return dest.top - source.bottom;
      default:
        return 0;
    }
  }

  private static majorAxisDistanceToFarEdge(direction: number, source: Rect, dest: Rect): number {
    return Math.max(1, FocusFinder.majorAxisDistanceToFarEdgeRaw(direction, source, dest));
  }

  private static majorAxisDistanceToFarEdgeRaw(direction: number, source: Rect, dest: Rect): number {
    switch (direction) {
      case FocusFinder.DIRECTION_LEFT:
        return source.left - dest.left;
      case FocusFinder.DIRECTION_RIGHT:
        return dest.right - source.right;
      case FocusFinder.DIRECTION_UP:
        return source.top - dest.top;
      case FocusFinder.DIRECTION_DOWN:
        return dest.bottom - source.bottom;
      default:
        return 0;
    }
  }

  private static minorAxisDistance(direction: number, source: Rect, dest: Rect): number {
    switch (direction) {
      case FocusFinder.DIRECTION_LEFT:
      case FocusFinder.DIRECTION_RIGHT:
        // 中心垂直距离
        return Math.abs(
          (source.top + source.height / 2) - (dest.top + dest.height / 2)
        );
      case FocusFinder.DIRECTION_UP:
      case FocusFinder.DIRECTION_DOWN:
        // 中心水平距离
        return Math.abs(
          (source.left + source.width / 2) - (dest.left + dest.width / 2)
        );
      default:
        return 0;
    }
  }

  private static getWeightedDistanceFor(majorAxisDistance: number, minorAxisDistance: number): number {
    // 权重因子（来自Android源码）
    return 13 * majorAxisDistance * majorAxisDistance + minorAxisDistance * minorAxisDistance;
  }

  // 工具方法：查找第一个可获取焦点的视图
  static findFirstFocusable(root: QTView): TVView | null {
    const views: TVView[] = [];
    FocusFinder.addAllFocusable(views, root, FocusFinder.DIRECTION_RIGHT);
    return views.length > 0 ? views[0] : null;
  }

  // 工具方法：查找指定方向上的第一个可获取焦点的视图
  static findFirstFocusableInDirection(root: QTView, direction: number): TVView | null {
    const views: TVView[] = [];
    FocusFinder.addAllFocusable(views, root, direction);

    if (views.length === 0) {
      return null;
    }

    // 根据方向选择
    switch (direction) {
      case FocusFinder.DIRECTION_RIGHT:
      case FocusFinder.DIRECTION_DOWN:
        return views[0];
      case FocusFinder.DIRECTION_LEFT:
      case FocusFinder.DIRECTION_UP:
        return views[views.length - 1];
      default:
        return null;
    }
  }
}