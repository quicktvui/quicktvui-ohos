import { QTBaseComponentView } from "../components/QTBaseComponentView";
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
  static DIRECTION_LEFT = 0;
  static DIRECTION_RIGHT = 1;
  static DIRECTION_UP = 2;
  static DIRECTION_DOWN = 3;

  // 临时Rect对象，避免频繁创建
  private static mFocusedRect = new Rect();
  private static mOtherRect = new Rect();
  private static mBestCandidateRect = new Rect();
  private static mTempRect = new Rect(); // 新增的临时Rect

  static findNextFocus(focusedView: QTView | null, root: QTView, direction: number): QTView | null {
    const views: QTView[] = [];
    FocusFinder.addAllFocusable(views, root, direction);
    QTLog.i(TAG_FOCUS,`findNextFocus search views length : ${views.length}`)
    views.map((v)=>{
      QTLog.d(TAG_FOCUS,`findNextFocus  view to search view:${ExtendUtil.debugView(v)}`)
    })
    // 如果有当前焦点视图，找到下一个焦点
    if (focusedView) {
      // 获取焦点视图的矩形
      const focusedRect = FocusFinder.getViewRectInRoot(focusedView, root);
      // 找到最佳候选视图
      return FocusFinder.findBestCandidate(views, root, focusedView, focusedRect, direction);
    } else {
      // 如果没有当前焦点，根据方向返回第一个或最后一个可获取焦点的视图
      // switch (direction) {
      //   case FocusFinder.DIRECTION_RIGHT:
      //   case FocusFinder.DIRECTION_DOWN:
      //     return views[0];
      //   case FocusFinder.DIRECTION_LEFT:
      //   case FocusFinder.DIRECTION_UP:
      //     return views[views.length - 1];
      //   default:
      //     return null;
      // }
      return FocusFinder.findFirstFocusableByDirection(views, root, direction);
    }
  }

  // 新增方法：根据方向找到位置最靠前/靠上的可获取焦点视图
  private static findFirstFocusableByDirection(views: QTView[], root: QTView, direction: number): QTView | null {
    if (views.length === 0) {
      return null;
    }

    // 获取根视图的中心点作为参考点
    const rootCenterX = root.cssWidth / 2;
    const rootCenterY = root.cssHeight / 2;

    let bestView: QTView | null = null;
    let bestDistance = Number.MAX_VALUE;
    let bestPrimaryAxisValue = 0;

    for (let i = 0; i < views.length; i++) {
      const view = views[i];
      const viewRect = FocusFinder.getViewRectInRoot(view, root);

      let candidateDistance = 0;
      let primaryAxisValue = 0;
      let isValidCandidate = true;

      switch (direction) {
        case FocusFinder.DIRECTION_DOWN:
          // 对于向下，找top值最小（最靠上）的视图
          primaryAxisValue = viewRect.top;
          // 视图必须在参考点下方
          if (viewRect.top < rootCenterY) {
            isValidCandidate = false;
            break;
          }
          // 计算与参考点的距离（使用加权距离）
          candidateDistance = FocusFinder.getWeightedDistanceFor(
            Math.abs(viewRect.top - rootCenterY),
            Math.abs(viewRect.centerX() - rootCenterX)
          );
          break;

        case FocusFinder.DIRECTION_UP:
          // 对于向上，找bottom值最大（最靠下）的视图
          primaryAxisValue = viewRect.bottom;
          // 视图必须在参考点上方
          if (viewRect.bottom > rootCenterY) {
            isValidCandidate = false;
            break;
          }
          // 计算与参考点的距离（使用加权距离）
          candidateDistance = FocusFinder.getWeightedDistanceFor(
            Math.abs(viewRect.bottom - rootCenterY),
            Math.abs(viewRect.centerX() - rootCenterX)
          );
          break;

        case FocusFinder.DIRECTION_RIGHT:
          // 对于向右，找left值最小（最靠左）的视图
          primaryAxisValue = viewRect.left;
          // 视图必须在参考点右侧
          if (viewRect.left < rootCenterX) {
            isValidCandidate = false;
            break;
          }
          // 计算与参考点的距离（使用加权距离）
          candidateDistance = FocusFinder.getWeightedDistanceFor(
            Math.abs(viewRect.left - rootCenterX),
            Math.abs(viewRect.centerY() - rootCenterY)
          );
          break;

        case FocusFinder.DIRECTION_LEFT:
          // 对于向左，找right值最大（最靠右）的视图
          primaryAxisValue = viewRect.right;
          // 视图必须在参考点左侧
          if (viewRect.right > rootCenterX) {
            isValidCandidate = false;
            break;
          }
          // 计算与参考点的距离（使用加权距离）
          candidateDistance = FocusFinder.getWeightedDistanceFor(
            Math.abs(viewRect.right - rootCenterX),
            Math.abs(viewRect.centerY() - rootCenterY)
          );
          break;
      }

      if (!isValidCandidate) {
        continue;
      }

      // 选择最佳视图：优先选择在方向上最靠近参考点的，如果距离相同选择主轴值更优的
      if (bestView === null ||
        candidateDistance < bestDistance ||
        (candidateDistance === bestDistance && FocusFinder.isBetterPrimaryAxisValue(direction, primaryAxisValue, bestPrimaryAxisValue))) {
        bestView = view;
        bestDistance = candidateDistance;
        bestPrimaryAxisValue = primaryAxisValue;
      }
    }


    // 如果没有找到符合方向条件的视图，返回最近的一个
    if (bestView === null && views.length > 0) {
      // 简单返回第一个视图
      return views[0];
    }

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

  static addAllFocusable(views: QTView[], target: QTView, direction: number) {
    // 检查当前视图是否可获取焦点
    if(target instanceof QTBaseComponentView){
      target.addFocusables(views,direction)
    }else if (target.cssFocusable === true) {
      views.push(target);
    }
    if (target.children && target.children.length > 0) {
      target.children.forEach((child: QTView) => {
        FocusFinder.addAllFocusable(views, child, direction);
      });
    }
  }

  private static getViewRectInRoot(view: QTView, root: QTView): Rect {
    const rect = new Rect();
    rect.left = view.cssPositionX;
    rect.top = view.cssPositionY;
    rect.right = rect.left + view.cssWidth;
    rect.bottom = rect.top + view.cssHeight;

    // 转换坐标到根视图坐标系
    return FocusFinder.offsetRectToRootCoords(view, root, rect);
  }

  private static offsetRectToRootCoords(view: QTView, root: QTView, rect: Rect): Rect {
    const result = new Rect();
    result.setFrom(rect);

    // 从当前视图向上遍历到根视图，累加所有父视图的偏移
    let current: QTView | null = view;
    let parent: QTView | null = view.parentView;

    while (parent && current !== root) {
      result.left += parent.cssPositionX;
      result.top += parent.cssPositionY;
      result.right += parent.cssPositionX;
      result.bottom += parent.cssPositionY;

      current = parent;
      parent = parent.parentView;
    }

    return result;
  }

  private static findBestCandidate(
    focusables: QTView[],
    root: QTView,
    focused: QTView,
    focusedRect: Rect,
    direction: number
  ): QTView | null {
    let bestCandidate: QTView | null = null;
    FocusFinder.mBestCandidateRect.setFrom(focusedRect);

    // 初始化最佳候选矩形为不可能的位置（在相反方向）
    switch (direction) {
      case FocusFinder.DIRECTION_LEFT:
        FocusFinder.mBestCandidateRect.offset(focusedRect.width + 1, 0);
        break;
      case FocusFinder.DIRECTION_RIGHT:
        FocusFinder.mBestCandidateRect.offset(-(focusedRect.width + 1), 0);
        break;
      case FocusFinder.DIRECTION_UP:
        FocusFinder.mBestCandidateRect.offset(0, focusedRect.height + 1);
        break;
      case FocusFinder.DIRECTION_DOWN:
        FocusFinder.mBestCandidateRect.offset(0, -(focusedRect.height + 1));
        break;
    }

    for (let i = 0; i < focusables.length; i++) {
      const candidate = focusables[i];

      // 跳过当前焦点视图和根视图
      if (candidate === focused || candidate === root) {
        continue;
      }

      // 获取候选视图的矩形
      FocusFinder.mOtherRect = FocusFinder.getViewRectInRoot(candidate, root);

      // 检查是否更好的候选者
      if (FocusFinder.isBetterCandidate(direction, focusedRect, FocusFinder.mOtherRect, FocusFinder.mBestCandidateRect)) {
        FocusFinder.mBestCandidateRect.setFrom(FocusFinder.mOtherRect);
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
  static findFirstFocusable(root: QTView): QTView | null {
    const views: QTView[] = [];
    FocusFinder.addAllFocusable(views, root, FocusFinder.DIRECTION_RIGHT);
    return views.length > 0 ? views[0] : null;
  }

  // 工具方法：查找指定方向上的第一个可获取焦点的视图
  static findFirstFocusableInDirection(root: QTView, direction: number): QTView | null {
    const views: QTView[] = [];
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