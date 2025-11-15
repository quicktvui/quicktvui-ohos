
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
  key?: string;
  title?: string;
  cover?: string;
  showVip?: boolean;
  floatText?: string;
  vip?: VipInfo; // <-- 这里直接使用你定义的类型
  vipTitleStyle?: vipTitleStyle;
  index2?: string;
};

export interface GeneratePageData {
  key: string;
  list: number[];
  title: string;
};

export class MyDataSource implements IDataSource {
  private dataArray: MyComponentParams[] = [];
  private listeners: DataChangeListener[] = [];

  constructor(data: MyComponentParams[]) {
    this.dataArray = data;
  }

  totalCount(): number {
    return this.dataArray.length;
  }

  getData(index: number): MyComponentParams {
    return this.dataArray[index];
  }

  registerDataChangeListener(listener: DataChangeListener): void {
    if (this.listeners.indexOf(listener) < 0) {
      this.listeners.push(listener);
    }
  }

  unregisterDataChangeListener(listener: DataChangeListener): void {
    const pos = this.listeners.indexOf(listener);
    if (pos >= 0) {
      this.listeners.splice(pos, 1);
    }
  }

  // 数据更新方法
  addData(item: MyComponentParams): void {
    this.dataArray.push(item);
    this.notifyDataChange();
  }

  removeData(index: number): void {
    if (index >= 0 && index < this.dataArray.length) {
      this.dataArray.splice(index, 1);
      this.notifyDataChange();
    }
  }

  updateData(index: number, item: MyComponentParams): void {
    if (index >= 0 && index < this.dataArray.length) {
      this.dataArray[index] = item;
      this.notifyDataChange();
    }
  }

  private notifyDataChange(): void {
    this.listeners.forEach(listener => {
      listener.onDataReloaded();
    });
  }
}
