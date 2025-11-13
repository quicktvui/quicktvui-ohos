import {
  HippyObservedArray,
  NativeRenderContext,
  HippyAny,
  HippyRenderCallback,
  HippyArray,
  HippyMap,
  HippyEndBatchCallback
} from 'hippy'
import { TAG_FASTLIST, TAG_MediaSeries } from '../../Constant';
import { HRValueUtils } from '../../HRValueUtils';

import { ExtendUtil } from '../../utils/ExtendUtil';
import { QTView } from "../../QTTypes"

import QTRenderBaseView from '../QTRenderBaseView';
import { HashMap } from '@kit.ArkTS';

import { Group, InitParam, MyComponentParams, Template } from './types/index';

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
  initParamTemplate: Template | HippyAny = {
    titleSize: 0,
    floatTitleSize: 0,
    isFree: false,
    type: '',
    width: 0,
    height: 0,
    focusScale: 0,
    extra: {
      imgWidth: 0,
      imgHeight: 0,
      textColor: {
        normal: '',
        focused: '',
        selected: '',
      },
      cornerBgColor: {
        orientation: '',
        cornerRadius: [],
        color: [],
        padding: [],
      }
    }
  }
  initParamGroup: Group = {
    itemWidth: 0,
    itemHeight: 0,
    itemGap: 0,
    textSize: 0,
    textColor: {
      normal: '',
      focused: '',
      selected: '',
    },
    focusBackground: {
      orientation: '',
      cornerRadius: [],
      color: [],
      padding: [],
    },
    mark: {
      color: ''
    }
  }
  initParam: InitParam = {
    initPosition: 0,
    contentWidth: 0,
    contentHeight: 0,
    itemGap: 0,
    enableGroup: false,
    groupSize: 0,
    groupHeight: 0,
    groupTopMargin: 0,
    totalCount: 0,
    pageSize: 0,
  };
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
    console.log(TAG_MediaSeries, `onPageTemplateReady:${ExtendUtil.debugView(template)}`)
    this.contentTemplate = template;
    // this.tabsData.forEach((value)=>{
    //   value.contentView?.setcus
    // })
  }


  setProp(propKey: string, propValue: HippyAny): boolean {
    console.log(TAG_MediaSeries, `setProp ============ QTMediaSeriesView :propKey:${propKey},value:${propValue}`)
    // if(propKey === 'attributes'){
    //   CommonUtils.printObject(propValue,'FastList setAttributes')
    // }
    switch (propKey) {
      case "initParam":
        // 图文模式
        let initParam = HRValueUtils.getMap(propValue);
        //测试数据：
        let __initParam: InitParam = {
          "initPosition": 0,
          "contentWidth": 1740,
          "contentHeight": 160,
          "itemGap": 36,

          "enableGroup": true, //是否开启快速分组
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
        console.log(TAG_MediaSeries, `QTMediaSeriesView ${Array.from(initParam)}`)
        //是否开启快速分组
        let enableGroup = initParam?.get('enableGroup');
        /*
         * type == ’leftRight‘ : 图文
         *
         * */
        this.initParam = {
          initPosition: initParam?.get('initPosition') as number,
          contentWidth: initParam?.get('contentWidth') as number,
          contentHeight: initParam?.get('contentHeight') as number,
          itemGap: initParam?.get('itemGap') as number,
          enableGroup: initParam?.get('enableGroup') as boolean,
          groupSize: initParam?.get('groupSize') as number,
          groupHeight: initParam?.get('groupHeight') as number,
          groupTopMargin: initParam?.get('groupTopMargin') as number,
          totalCount: initParam?.get('totalCount') as number,
          pageSize: initParam?.get('pageSize') as number,
        };
        let template = initParam?.get('template');
        let type = (template as HippyMap).get('type');
        let extra = (template as HippyMap).get('extra');
        let textColor = (extra as HippyMap).get('textColor');
        let cornerBgColor = (extra as HippyMap).get('cornerBgColor');
        this.initParamTemplate = {
          titleSize: (template as HippyMap).get('titleSize') as number,
          floatTitleSize: (template as HippyMap).get('floatTitleSize') as number,
          isFree: (template as HippyMap).get('isFree') as boolean,
          type: (template as HippyMap).get('type') as string,
          width: (template as HippyMap).get('width') as number,
          height: (template as HippyMap).get('height') as number,
          focusScale: (template as HippyMap).get('focusScale') as number,
          extra: {
            imgWidth: (extra as HippyMap).get('imgWidth') as number,
            imgHeight: (extra as HippyMap).get('imgHeight') as number,
            textColor: {
              normal: (textColor as HippyMap).get('normal') as string,
              focused: (textColor as HippyMap).get('focused') as string,
              selected: (textColor as HippyMap).get('selected') as string,
            },
            cornerBgColor: {
              orientation: (cornerBgColor as HippyMap).get('orientation') as string,
              cornerRadius: (cornerBgColor as HippyMap).get('cornerRadius') as number[],
              color: (cornerBgColor as HippyMap).get('color') as string[],
              padding: (cornerBgColor as HippyMap).get('padding') as number[],
            }
          }
        }
        let group = initParam?.get('group');
        let groupTextColor = (group as HippyMap).get('textColor');
        let focusBackground = (group as HippyMap).get('focusBackground');
        let mark = (group as HippyMap).get('mark');
        this.initParamGroup = {
          itemWidth: 0,
          itemHeight: 0,
          itemGap: 0,
          textSize:0,
          textColor: {
            normal: (groupTextColor as HippyMap).get('normal') as string,
            focused: (groupTextColor as HippyMap).get('focused') as string,
            selected: (groupTextColor as HippyMap).get('selected') as string,
          },
          focusBackground: {
            orientation: (focusBackground as HippyMap).get('orientation') as string,
            cornerRadius: (focusBackground as HippyMap).get('cornerRadius') as number[],
            color: (focusBackground as HippyMap).get('color') as string[],
            padding: (focusBackground as HippyMap).get('padding') as number[],
          },
          mark: {
            color: (mark as HippyMap).get('color') as string,
          }
        }
        console.log(TAG_FASTLIST, `QTFastListView template.type :${JSON.stringify(this.initParam)}`)
        console.log(TAG_FASTLIST, `QTFastListView initParamTemplate :${JSON.stringify(this.initParamTemplate)}`)
        console.log(TAG_FASTLIST, `QTFastListView initParamGroup :${JSON.stringify(this.initParamGroup)}`)
        console.log(TAG_FASTLIST, `QTFastListView extra :${JSON.stringify(extra)}`)
        console.log(TAG_MediaSeries, `QTMediaSeriesView template.type :${type} ,${typeof enableGroup},${enableGroup}`)
        //this.listData = [0, 11, 2, 3, 4, 5, 6, 7, 8, 9]
        return true;
      case "groupParam":
        //  是否设置快速分组
        let groupParam = HRValueUtils.getMap(propValue);
        let groupSize = groupParam?.get('groupSize');
        console.log(TAG_MediaSeries, `QTMediaSeriesView :groupSize is:${groupSize}`)
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
    console.log(TAG_MediaSeries, `QTMediaSeriesView call function : ${method},params:${params}`)
    switch (method) {
      //加载数据
      case "setPageData":
        let getArray = HRValueUtils.getArray(params as HippyArray)
        let page = getArray![0];
        let data = getArray![1] as Map<string, HippyAny>; //数据格式参考 getLRDataByPage 函数返回值

        console.log(TAG_MediaSeries, `QTMediaSeriesView:page:${method},value:${page}`)

        let _listData = this.listData.slice();
        data.forEach((value: HippyAny, keyA: string) => {
          console.log(TAG_MediaSeries, `QTMediaSeriesView:page,key:${keyA}`);

          (value as HippyMap).forEach((eachValue: HippyAny, keyB: string) => {
            console.log(TAG_MediaSeries, `QTMediaSeriesView:page,key:${keyA}-${keyB}`, eachValue);
          })

          _listData.push({
            title: HRValueUtils.getStringValue('title', value as HippyMap, null)!,
            cover: HRValueUtils.getStringValue('cover', value as HippyMap, null)!,
            floatText: HRValueUtils.getStringValue('floatText', value as HippyMap, null)!,
            showVip: HRValueUtils.getBooleanValue('showVip', value as HippyMap, false)!,
            vip: {
              enable: HRValueUtils.getMap('vip')?.get('enable') as boolean,
              text: HRValueUtils.getMap('vip')?.get('text') as string,
            },
            vipTitleStyle: {
              width: HRValueUtils.getMap('vipTitleStyle')?.get('width') as number,
              height: HRValueUtils.getMap('vipTitleStyle')?.get('height') as number,
            },
            index2: HRValueUtils.getStringValue('index2', value as HippyMap, null)!,
          });

        });
        this.listData = _listData;

        break;

      //设置选中的item
      case "setSelectChildPosition":
        let childPos = HRValueUtils.getNumber2(params[0], 0)
        console.log(TAG_MediaSeries, `setSelectChildPosition : childPos is : ${childPos} `)
        break;

      //滚动到指定位置
      case "scrollToPosition":
        let scrollPos = HRValueUtils.getNumber2(params[0], 0)
        console.log(TAG_MediaSeries, `scrollToPosition : scrollPos is : ${scrollPos}`)
        break;

      //滚动到指定位置 可添加偏移量
      case "scrollToPositionWithOffset":
        let scrollPosIdx = HRValueUtils.getNumber2(params[0], 0)
        let scrollPosOffset = HRValueUtils.getNumber2(params[1], 0)
        console.log(TAG_MediaSeries,
          `scrollToPositionWithOffset : scrollPosIdx is : ${scrollPosIdx}, scrollPosOffset is :${scrollPosOffset}`)
        break;

      //设置选中的item
      case "requestChildFocus":
        let focusPos = HRValueUtils.getNumber2(params[0], 0)
        console.log(TAG_MediaSeries, `requestChildFocus : focusPos is : ${focusPos}`)
        break;
    }

  }
}



