
import {HippyObservedArray,NativeRenderContext,HippyAny,HippyRenderCallback,HippyArray,HippyMap,HippyEndBatchCallback} from 'hippy'
import { TAG_FASTLIST } from '../../Constant';
import { HRValueUtils } from '../../HRValueUtils';

import { ExtendUtil } from '../../utils/ExtendUtil';
import { QTView } from "../../QTTypes"

import QTRenderBaseView from '../QTRenderBaseView';

interface VipInfo {
  enable: boolean;
  text: string;
}

interface vipTitleStyle {
  width: number; height: number;
}

interface MyComponentParams {
  title: string;
  cover: string;
  showVip: boolean;
  floatText: string;
  vip: VipInfo; // <-- 这里直接使用你定义的类型
  vipTitleStyle: vipTitleStyle;
  index2: string;
};


@Observed
export class QTMediaSeriesView extends QTRenderBaseView{

  public virtualChildren: HippyObservedArray<QTView> = new HippyObservedArray()
  isHorizontal : boolean = false;
  spanCount : string | null= null;
  initialPosition : number = 0;
  listSpace: number = 0;
  scroller: ListScroller = new ListScroller();
  scrollOffset: number =  0
  autofocusPosition: number = -1;

  isNativeCreate = false;

  contentTemplate : QTView | null = null;

  listData: Array<MyComponentParams|number> = [];

  // private customTemplate: QTView | null = null;

  private endBatchCallback: HippyEndBatchCallback | null = null

  constructor(ctx: NativeRenderContext) {
    super(ctx)
  }

  /*
   *
   * let pageSize: number = 10;
    let totalCount: number = 100;
   * */
  getLRDataByPage (page:number, pageSize:number, totalSize:number) {
    let result: Array<MyComponentParams> = [];
    let isLast = Math.floor(totalSize / pageSize) <= page;
    let size = isLast ? totalSize - page * pageSize : pageSize;
    for (let i = 0; i < size; i++) {
      let index = page * pageSize + i + 1;
      let index2 = index > 9 ? '' + index : '0' + index;
      result.push({
        // 选集标题
        title: i % 2 === 0 ? `第${page * pageSize + i + 1}集内容`:`第${page * pageSize + i + 1}集内容集内容集内容集内容集内容集内容集内容集内容集内容集内容集内容集内容集内容`,
        // 图文图片
        // cover: 'https://i.328888.xyz/2023/01/04/W49yq.md.jpeg',
        cover: 'https://www.huikez.com/uploads/allimg/2009/1-200921144Ub07.jpg',
        // flagText: needFlag ? `flag${page * pageSize + i}` : '',
        // flagText: (i !== 0 || page !== 0) ? i % 2 === 0 ? 'VIP' : '付费' : '',
        showVip: (i !== 0 || page !== 0) ? i % 2 === 0 ? true : true : false,
        // floatText: `float${page * pageSize + i}`,
        floatText: i % 2 === 0 ? '05:30' : '10:06',
        vip: {
          enable: true,
          text: 'VIP',
        },
        vipTitleStyle:{width:150,height:100},
        index2
      })
    }
    return result;
  }


  exeScroll(){
    this.scroller.scrollToIndex(this.initialPosition)
  }

  getTemplate() : HippyObservedArray<QTView>{
    return this.templateView ? this.templateView.children : this.children
  }

  setCustomTemplate(customTemplate: QTView | null){
    this.templateView = customTemplate;
  }

  onUIAboutToDisappear(){
    if(this.endBatchCallback){
      this.ctx.getNativeRender().removeEndBatchCallback(this.ctx.getRootId(),this.endBatchCallback)
    }
  }

  onPageTemplateReady(template:QTView){
    console.log(TAG_FASTLIST,`onPageTemplateReady:${ExtendUtil.debugView(template)}`)
    this.contentTemplate = template;
    // this.tabsData.forEach((value)=>{
    //   value.contentView?.setcus
    // })
  }


  setProp(propKey: string, propValue: HippyAny): boolean {
    console.log(TAG_FASTLIST,`FastList:propKey:${propKey},value:${propValue}`)
    // if(propKey === 'attributes'){
    //   CommonUtils.printObject(propValue,'FastList setAttributes')
    // }
    switch (propKey){
      case "initParam":
        let initParam  = HRValueUtils.getMap(propValue);

        let __initParam = `{
          "initPosition": 0,
          "contentWidth": 1740,
          "contentHeight": 160,
          "itemGap": 36,
          "enableGroup": true,
          "groupSize": 20,
          "groupHeight": 46,
          "groupTopMargin": 24,
          "group": {
            "itemWidth": 85,
            "itemHeight": 46,
            "itemGap": 50,
            "textSize": 30,
            "textColor": {
              "normal": "#80FFFFFF",
              "focused": "#603314",
              "selected": "#FFD97C"
            },
            "focusBackground": {
              "orientation": "LEFT_RIGHT",
              "cornerRadius": [
                40,
                40,
                40,
                40
              ],
              "color": [
                "#FFE398",
                "#EEB364"
              ],
              "padding": [
                34,
                6
              ]
            },
            "mark": {
              "color": "#FFD97C"
            }
          },
          "template": {
            "titleSize": 28,
            "floatTitleSize": 20,
            "isFree": false,
            "type": "leftRight",
            "width": 560,
            "height": 160,
            "focusScale": 1.1,
            "extra": {
              "imgWidth": 268,
              "imgHeight": 160,
              "textColor": {
                "normal": "#80FFFFFF",
                "focused": "#FFD97C",
                "selected": "#FFD97C"
              },
              "cornerBgColor": {
                "orientation": "LEFT_RIGHT",
                "cornerRadius": [
                  4,
                  4,
                  4,
                  4
                ],
                "color": [
                  "#B67827",
                  "#DBAF5C"
                ]
              }
            }
          },
          "totalCount": 100,
          "pageSize": 10
        }`;


        let key = initParam!.keys();
        console.log(TAG_FASTLIST,`FastList:propKey:initParam keykeykeykeykeykeykeykeykeykey:${Array.from(key)}`)

        this.listData = [0, 11, 2, 3, 4, 5, 6, 7, 8, 9]
        return true;

      default:
        return true;
    }
  }

  aboutToUpdate(): void {
  }

  isGridLayout() : boolean{
    return this.spanCount != null && this.spanCount != undefined
  }

  call(method: string, params: Array<HippyAny>, callback: HippyRenderCallback | null): void {
    console.log(TAG_FASTLIST,`QTFastListView call function : ${method},params:${params}`)
      switch (method){

        case "keyName":
          console.error(TAG_FASTLIST,`QTFastListView : 未实现的function : ${method}`)
          return;
      }

      switch (method){


        case 'scrollToTop':
          this.initialPosition = 0;
          this.exeScroll()
          break;

      }
  }

}



