export interface StateView {
  // 设置基于系统状态的显示条件
  setShowOnState(showOnState: number[]): void;

  // 设置基于自定义状态的显示条件
  setShowOnCustomState(showOnState: string[]): void;

  // 设置自定义状态
  setCustomState(state: string, on: boolean): void;
}

// 状态常量
export class StateViewConstants {
  static readonly STATE_FOCUS_AND_SELECT: number = 100;
  static readonly STATE_FOCUS_NO_SELECT: number = StateViewConstants.STATE_FOCUS_AND_SELECT + 1;
  static readonly STATE_SELECT_NO_FOCUS: number = StateViewConstants.STATE_FOCUS_AND_SELECT + 2;
}

export class QTViewState{
  static readonly STATE_SELECTED = 1002;
  static readonly STATE_FOCUSED = 1001;
  static readonly STATE_NORMAL = 1000;
}