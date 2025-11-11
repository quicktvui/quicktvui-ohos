import {
  HippyObservedArray,
  NativeRenderContext,
  HippyAny,
  HippyRenderCallback,
  HippyArray,
  HippyMap,
  HippyEndBatchCallback
} from 'hippy'
import { TAG_FASTLIST } from '../../Constant';
import { HRValueUtils } from '../../HRValueUtils';

import { ExtendUtil } from '../../utils/ExtendUtil';
import { QTView } from "../../QTTypes"

import QTRenderBaseView from '../QTRenderBaseView';
import { HashMap } from '@kit.ArkTS';

import { InitParam ,MyComponentParams } from './types/index';

@Observed
export class QTMediaSeriesView extends QTRenderBaseView {
  public virtualChildren: HippyObservedArray<QTView> = new HippyObservedArray()
  isHorizontal: boolean = false;
  spanCount: string | null = null;
  initialPosition: number = 0;
  listSpace: number = 0;
  scroller: ListScroller = new ListScroller();
  scrollOffset: number = 0
  autofocusPosition: number = -1;
  isNativeCreate = false;
  contentTemplate: QTView | null = null;
  listData: Array<MyComponentParams | number | string> = [];
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
  getLRDataByPage(page: number, pageSize: number, totalSize: number) {
    let result: Array<MyComponentParams> = [];
    let isLast = Math.floor(totalSize / pageSize) <= page;
    let size = isLast ? totalSize - page * pageSize : pageSize;
    for (let i = 0; i < size; i++) {
      let index = page * pageSize + i + 1;
      let index2 = index > 9 ? '' + index : '0' + index;
      result.push({
        // 选集标题
        title: i % 2 === 0 ? `第${page * pageSize + i + 1}集内容` :
          `第${page * pageSize + i + 1}集内容集内容集内容集内容集内容集内容集内容集内容集内容集内容集内容集内容集内容`,
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
        vipTitleStyle: { width: 150, height: 100 },
        index2
      })
    }
    return result;
  }


  exeScroll() {
    this.scroller.scrollToIndex(this.initialPosition)
  }

  getTemplate(): HippyObservedArray<QTView> {
    return this.templateView ? this.templateView.children : this.children
  }

  setCustomTemplate(customTemplate: QTView | null) {
    this.templateView = customTemplate;
  }

  onUIAboutToDisappear() {
    if (this.endBatchCallback) {
      this.ctx.getNativeRender().removeEndBatchCallback(this.ctx.getRootId(), this.endBatchCallback)
    }
  }

  onPageTemplateReady(template: QTView) {
    console.log(TAG_FASTLIST, `onPageTemplateReady:${ExtendUtil.debugView(template)}`)
    this.contentTemplate = template;
    // this.tabsData.forEach((value)=>{
    //   value.contentView?.setcus
    // })
  }


  setProp(propKey: string, propValue: HippyAny): boolean {
    console.log(TAG_FASTLIST, `setProp ============ QTFastListView :propKey:${propKey},value:${propValue}`)
    // if(propKey === 'attributes'){
    //   CommonUtils.printObject(propValue,'FastList setAttributes')
    // }
    switch (propKey) {
      case "initParam":
        // 图文模式
        let initParam = HRValueUtils.getMap(propValue);

        //测试数据：
        let __initParam:InitParam = {
          "initPosition": 0,
          "contentWidth": 1740,
          "contentHeight": 160,
          "itemGap": 36,

          "enableGroup": true,  //是否开启快速分组
          "groupSize": 20, // 快速分组对应的集数
          "groupHeight": 46,
          "groupTopMargin": 24,

          // 控制快速分组的UI
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
        };


        console.log(TAG_FASTLIST, `QTFastListView ${Array.from(initParam)}`)
        let template = initParam?.get('template');
        let type = (template as HippyMap).get('type');
        /*
         * type == ’leftRight‘ : 图文
         *
         * */
        console.log(TAG_FASTLIST, `QTFastListView template.type :${type}`)

        //this.listData = [0, 11, 2, 3, 4, 5, 6, 7, 8, 9]
        return true;
      case "groupParam":
        //  是否设置快速分组
        let groupParam = HRValueUtils.getMap(propValue);
        let groupSize = groupParam?.get('groupSize');
        console.log(TAG_FASTLIST, `QTFastListView :groupSize is:${groupSize}`)
      case "commonParam":
        //


      default:
        return true;
    }
  }

  aboutToUpdate(): void {
  }

  isGridLayout(): boolean {
    return this.spanCount != null && this.spanCount != undefined
  }

  call(method: string, params: Array<HippyAny>, callback: HippyRenderCallback | null): void {
    console.log(TAG_FASTLIST, `QTFastListView call function : ${method},params:${params}`)
    switch (method) {

      case "setPageData":
        let getArray = HRValueUtils.getArray(params as HippyArray)
        let page = getArray![0];
        let data = getArray![1] as Map<string, HippyAny>; //数据格式参考 getLRDataByPage 函数返回值

        console.log(TAG_FASTLIST, `QTFastListView:page:${method},value:${page}`)

        let _listData = this.listData.slice();
        data.forEach((value: HippyAny, keyA: string) => {
          console.log(TAG_FASTLIST, `QTFastListView:page,key:${keyA}`);

          (value as HippyMap).forEach((eachValue: HippyAny, keyB: string) => {
            console.log(TAG_FASTLIST, `QTFastListView:page,key:${keyA}-${keyB}`, eachValue);
          })

          _listData.push({
            title: HRValueUtils.getStringValue('title', value as HippyMap, null)!
            //.....
          });

        });
        this.listData = _listData;

        break;

      case "keyName":
        console.error(TAG_FASTLIST, `QTFastListView : 未实现的function : ${method}`)
        return;
    }

    switch (method) {


      case 'scrollToTop':
        this.initialPosition = 0;
        this.exeScroll()
        break;

    }
  }
}



