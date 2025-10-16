export interface  QTNativeLayout {
  constructor();

  GetWidth(): number;
  GetHeight(): number;
  GetLeft(): number;
  GetTop(): number;
  GetRight(): number;
  GetBottom(): number;
  GetStyleWidth(): number;
  GetStyleHeight(): number;

  SetWidth(value: number): void;
  SetHeight(value: number): void;
  SetMaxWidth(value: number): void;
  SetMaxHeight(value: number): void;
  SetScaleFactor(value: number): void;
  SetPosition(edge: Edge, position: number): void;

  HasNewLayout(): boolean;
  IsDirty(): boolean;
  MarkDirty(): void;
  CalculateLayout(width: number, height: number): void;

  InsertChild(child: QTNativeLayout, index: number): void;
  RemoveChild(child: QTNativeLayout): void;

  ResetLayoutCache(): void;
}

export enum Edge {
  EdgeLeft,
  EdgeTop,
  EdgeRight,
  EdgeBottom,
  EdgeStart,
  EdgeEnd
}

export enum Direction {
  Inherit,
  LTR,
  RTL
}

export enum LayoutMeasureMode {
  Undefined,
  Exactly,
  AtMost
}

export enum LayoutEngineType {
  LayoutEngineDefault,
  LayoutEngineTaitank,
  LayoutEngineYoga
}
