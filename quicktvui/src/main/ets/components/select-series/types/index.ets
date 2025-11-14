
export interface ColorState {
  normal: string;
  focused?: string;
  selected?: string;
}

export interface GradientBackground {
  orientation: string;
  cornerRadius: number[];
  color: string[];
  padding?: number[];
}

export interface Mark {
  color: string;
}

export interface CornerBgColor extends GradientBackground {}

export interface Extra {
  imgWidth: number;
  imgHeight: number;
  textColor: ColorState;
  cornerBgColor: CornerBgColor;
}

export interface Template {
  titleSize: number;
  floatTitleSize: number;
  isFree: boolean;
  type: string;
  width: number;
  height: number;
  focusScale: number;
  extra: Extra;
}

export interface Group {
  itemWidth: number;
  itemHeight: number;
  itemGap: number;
  textSize: number;
  textColor: ColorState;
  focusBackground: GradientBackground;
  mark: Mark;
}

export interface InitParam {
  initPosition: number;
  contentWidth: number;
  contentHeight: number;
  itemGap: number;
  enableGroup: boolean;
  groupSize: number;
  groupHeight: number;
  groupTopMargin: number;
  group?: Group;
  template?: Template;
  totalCount: number;
  pageSize: number;
}

export interface VipInfo {
  enable: boolean;
  text: string;
}

export interface vipTitleStyle {
  width: number;
  height: number;
}

export interface MyComponentParams {
  title?: string;
  cover?: string;
  showVip?: boolean;
  floatText?: string;
  vip?: VipInfo; // <-- 这里直接使用你定义的类型
  vipTitleStyle?: vipTitleStyle;
  index2?: string;
};

export interface GeneratePageData {
  list: number[];
  title: string;
};
