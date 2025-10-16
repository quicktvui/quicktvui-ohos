import {buildHippyRenderView,HippyRenderBaseView,HippyMap} from 'hippy'
import { QTAny, QTMap, QTView } from '../../QTTypes';
import { QTPlaceholderView } from './QTPlaceholderView';

export class ItemTemplate  {
  templateView: QTView;
  viewType:number;
  props:QTMap;

  constructor(templateView: QTView, viewType: number, props: QTMap) {
    this.templateView = templateView;
    this.viewType = viewType;
    this.props = props;
  }
}

@Observed
export class ItemView{
  // template: QTView | undefined = undefined;
  template:ItemTemplate | undefined = undefined
  position: number;
  id : String | null = null;
  raw:QTMap | null;
  renderView : QTView | null = null;
  constructor(position: number, raw : QTMap | null) {
    this.position = position
    this.raw = raw
  }

  getItemId():string | null{
    let id : QTAny | null = null
    if(this.raw){
      id = this.raw.get('id')
      if(id){
        return id as string
      }
      id = this.raw.get('_id')
      if(id){
        return id as string
      }
      id = this.raw.get('sid')
      if(id){
        return id as string
      }
    }
    return null
  }
}



// @Builder
// export function createView4Template(template : ItemTemplate) : QTView{
//   return buildRenderViewByTemplate(template,)
// }
//
// @Builder
// export function renderView(template : ItemTemplate,data:HippyMap){
//   Stack(){
//     buildHippyRenderView()
//   }
// }

// @Component
// export struct Item{
//   @ObjectLink itemData : ItemView;
//
//   constructor(itemData : ItemView) {
//     super()
//     this.itemData = itemData;
//   }
//
//   build() {
//     Text(`位置:${this.itemData.position}`)
//     .width('100%')
//     .height('100%')
//   }
//
// }



@Builder
export function  renderItem(item : ItemView){
  if(item.template && item.raw){
    buildHippyRenderView(
      item.renderView ?? new QTPlaceholderView(item.template.templateView.ctx),null
    )
  }else{
    Text(`未实现:${item.position},viewName:${item.template?.viewType}`)
      .width('100%')
      .height(100)
  }

}

export function getItemType(map : QTMap | null) : number | null{
  return getAsNumber(map,'type')
}

// 从 Map 中安全提取并转换值的函数
function getAsNumber(map: QTMap | null, key: string): number | null {
  if (map === undefined || map === null) {
    return null;
  }
  const value = map.get(key);

  if (value === undefined || value === null) {
    return null;
  }

  // 如果是 number 类型直接返回
  if (typeof value === 'number') {
    return value;
  }

  // 如果是 string 类型尝试转换为 number
  if (typeof value === 'string') {
    const num = Number(value);
    return isNaN(num) ? null : num;
  }
  // 其他类型返回 null
  return null;
}
