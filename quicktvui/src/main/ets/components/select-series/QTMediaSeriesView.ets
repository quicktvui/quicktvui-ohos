import {
  HippyObservedArray,
  NativeRenderContext,
  HippyAny,
  HippyRenderCallback,
  HIPPY_COMPONENT_KEY_PREFIX,
  HippyArray,
  HippyMap,
  HippyEndBatchCallback
} from 'hippy'
import { TAG_MediaSeries } from '../../Constant';
import { HRValueUtils } from '../../HRValueUtils';

import { ExtendUtil } from '../../utils/ExtendUtil';
import { QTView } from "../../QTTypes"

import QTRenderBaseView from '../QTRenderBaseView';
import { HashMap } from '@kit.ArkTS';

import { LengthMetrics } from "@kit.ArkUI";

import { Group, InitParam, MyComponentParams, GeneratePageData, Template, MyDataSource } from './types/index';

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
  listData: MyDataSource = new MyDataSource([]);
  generatePageData: GeneratePageData[] = [];
  currentTitleId: number = 0;
  navTitleScroller: Scroller = new Scroller();
  focusStr: string | undefined = undefined;
  isSelectedButton: boolean = true;
  pageNum: number = 0;
  initParamTemplate: Template = {
    titleSize: 28,
    floatTitleSize: 20,
    isFree: false,
    type: 'leftRight',
    width: 560,
    height: 160,
    focusScale: 1.1,
    extra: {
      imgWidth: 268,
      imgHeight: 160,
      textColor: {
        normal: '#80FFFFFF',
        focused: '#FFD97C',
        selected: '#FFD97C',
      },
      cornerBgColor: {
        orientation: 'LEFT_RIGHT',
        cornerRadius: [4, 4, 4, 4],
        color: ["#B67827", "#DBAF5C"],
      }
    }
  }
  initParamGroup: Group = {
    itemWidth: 105,
    itemHeight: 46,
    itemGap: 50,
    textSize: 30,
    textColor: {
      normal: '#80FFFFFF',
      focused: '#603314',
      selected: '#FFD97C',
    },
    focusBackground: {
      orientation: 'LEFT_RIGHT',
      cornerRadius: [40, 40, 40, 40],
      color: ["#FFE398", "#EEB364"],
      padding: [34, 6],
    },
    mark: {
      color: '#FFD97C'
    }
  }
  enableGroup: boolean = true;
  initParam: InitParam = {
    initPosition: 0,
    contentWidth: 1740,
    contentHeight: 160,
    itemGap: 36,
    groupSize: 20,
    groupHeight: 46,
    groupTopMargin: 24,
    totalCount: 0,
    pageSize: 10,
  };
  // private customTemplate: QTView | null = null;

  private endBatchCallback: HippyEndBatchCallback | null = null

  constructor(ctx: NativeRenderContext) {
    super(ctx)
  }

  /*
   * let pageSize: number = 10;
   * let totalCount: number = 100;
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

  /*
   * let groupSize: number = 20;
   * let totalCount: number = 100;
   * */
  generatePageRanges(totalCount: number, groupSize: number): GeneratePageData[] {
    const result: GeneratePageData[] = [];
    const totalPages = Math.ceil(totalCount / groupSize);
    for (let page = 0; page < totalPages; page++) {
      const start = page * groupSize + 1;
      const end = Math.min((page + 1) * groupSize, totalCount);
      // 格式化标题，将1-9格式化为01-09
      const formatNumber = (num: number): string => {
        return num < 10 ? `0${num}` : `${num}`;
      };
      result.push({
        key: this.getRandomString(),
        title: start!==end ?`${formatNumber(start)}-${formatNumber(end)}` : `${formatNumber(start)}`,
      });
    }
    console.log(TAG_MediaSeries, `generatePageRanges is :${JSON.stringify(result)}`)
    return result;
  }

  getRandomString() {
    let date = new Date().getTime().toString();
    let data = Math.floor(Math.random() * 9000) + 1000;
    return `${date}${data}`;
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
    switch (propKey) {
      case "initParam": {
        // type == ’leftRight‘ : 图文模式
        let initParam = HRValueUtils.getMap(propValue);
        console.log(TAG_MediaSeries, `QTMediaSeriesView ${Array.from(initParam)}`)
        this.initParam = {
          initPosition: initParam?.get('initPosition') as number || 0,
          contentWidth: initParam?.get('contentWidth') as number || 1740,
          contentHeight: initParam?.get('contentHeight') as number || 160,
          itemGap: initParam?.get('itemGap') as number || 36,
          groupSize: initParam?.get('groupSize') as number || 20,
          groupHeight: initParam?.get('groupHeight') as number || 46,
          groupTopMargin: initParam?.get('groupTopMargin') as number || 24,
          totalCount: initParam?.get('totalCount') as number || 0,
          pageSize: initParam?.get('pageSize') as number || 10,
        };
        this.enableGroup = initParam?.get('enableGroup') as boolean || true;
        let template = initParam?.get('template');
        let extra = (template as HippyMap).get('extra');
        let textColor = (extra as HippyMap).get('textColor');
        let cornerBgColor = (extra as HippyMap).get('cornerBgColor');
        let extraCornerRadius = (cornerBgColor as HippyMap).get('cornerRadius') as number[];
        this.initParamTemplate = {
          titleSize: (template as HippyMap).get('titleSize') as number || 28,
          floatTitleSize: (template as HippyMap).get('floatTitleSize') as number || 20,
          isFree: (template as HippyMap).get('isFree') as boolean || false,
          type: (template as HippyMap).get('type') as string || 'leftRight',
          width: (template as HippyMap).get('width') as number || 560,
          height: (template as HippyMap).get('height') as number || 160,
          focusScale: (template as HippyMap).get('focusScale') as number || 1.1,
          extra: {
            imgWidth: (extra as HippyMap).get('imgWidth') as number || 268,
            imgHeight: (extra as HippyMap).get('imgHeight') as number || 160,
            textColor: {
              normal: (textColor as HippyMap).get('normal') as string || '#803e3838',
              focused: (textColor as HippyMap).get('focused') as string || '#FFD97C',
              selected: (textColor as HippyMap).get('selected') as string || '#FFD97C',
            },
            cornerBgColor: {
              orientation: (cornerBgColor as HippyMap).get('orientation') as string | 'LEFT_RIGHT',
              cornerRadius: [extraCornerRadius[0] || 4, extraCornerRadius[1] || 4, extraCornerRadius[2] || 4,
                extraCornerRadius[3] || 4],
              color: (cornerBgColor as HippyMap).get('color') as string[] | ["#B67827", "#DBAF5C"],
            }
          }
        }
        let group = initParam?.get('group');
        let groupTextColor = (group as HippyMap).get('textColor');
        let focusBackground = (group as HippyMap).get('focusBackground');
        let mark = (group as HippyMap).get('mark');
        let focusBackgroundPadding = (focusBackground as HippyMap).get('padding') as number[];
        let focusBackgroundCornerRadius = (focusBackground as HippyMap).get('cornerRadius') as number[];
        this.initParamGroup = {
          itemWidth: (group as HippyMap).get('itemWidth') as number || 105,
          itemHeight: (group as HippyMap).get('itemHeight') as number || 46,
          itemGap: (group as HippyMap).get('itemGap') as number || 50,
          textSize: (group as HippyMap).get('textSize') as number || 30,
          textColor: {
            normal: (groupTextColor as HippyMap).get('normal') as string || '#80FFFFFF',
            focused: (groupTextColor as HippyMap).get('focused') as string || '#603314',
            selected: (groupTextColor as HippyMap).get('selected') as string || '#FFD97C',
          },
          focusBackground: {
            orientation: (focusBackground as HippyMap).get('orientation') as string || 'LEFT_RIGHT',
            cornerRadius: [focusBackgroundCornerRadius[0] || 40, focusBackgroundCornerRadius[1] || 40,
              focusBackgroundCornerRadius[2] || 40, focusBackgroundCornerRadius[3] || 40],
            color: (focusBackground as HippyMap).get('color') as string[] || ['#FFE398', '#EEB364'],
            padding: [focusBackgroundPadding[0] || 34, focusBackgroundPadding[1] || 6],
          },
          mark: {
            color: (mark as HippyMap).get('color') as string | '#FFD97C',
          }
        }
        // 是否开启快速分组
        if (this.enableGroup) {
          this.generatePageData = this.generatePageRanges(this.initParam.totalCount, this.initParam.groupSize);
        }
        console.log(TAG_MediaSeries, ` this.enableGroup :${this.enableGroup}`)
        console.log(TAG_MediaSeries, ` template.type :${JSON.stringify(this.initParam)}`)
        console.log(TAG_MediaSeries, ` initParamTemplate :${JSON.stringify(this.initParamTemplate)}`)
        console.log(TAG_MediaSeries, ` initParamGroup :${JSON.stringify(this.initParamGroup)}`)
        console.log(TAG_MediaSeries, ` extra :${JSON.stringify(extra)}`)
        console.log(TAG_MediaSeries, ` generatePageData :${JSON.stringify(this.generatePageData)}`)
        return true;
      }
      case "groupParam": {
        // 选集类型为非图文模式('leftrigth') 例如：'custom'
        let groupParam = HRValueUtils.getMap(propValue);
        let groupTextColor = (groupParam as HippyMap).get('textColor');
        let focusBackground = (groupParam as HippyMap).get('focusBackground');
        let mark = (groupParam as HippyMap).get('mark');
        let focusBackgroundPadding = (focusBackground as HippyMap).get('padding') as number[];
        let focusBackgroundCornerRadius = (focusBackground as HippyMap).get('cornerRadius') as number[];
        this.initParamGroup = {
          itemWidth: (groupParam as HippyMap).get('itemWidth') as number || 105,
          itemHeight: (groupParam as HippyMap).get('itemHeight') as number || 46,
          itemGap: (groupParam as HippyMap).get('itemGap') as number || 50,
          textSize: (groupParam as HippyMap).get('textSize') as number || 30,
          textColor: {
            normal: (groupTextColor as HippyMap).get('normal') as string || '#80FFFFFF',
            focused: (groupTextColor as HippyMap).get('focused') as string || '#603314',
            selected: (groupTextColor as HippyMap).get('selected') as string || '#FFD97C',
          },
          focusBackground: {
            orientation: (focusBackground as HippyMap).get('orientation') as string || 'LEFT_RIGHT',
            cornerRadius: [focusBackgroundCornerRadius[0] || 40, focusBackgroundCornerRadius[1] || 40,
              focusBackgroundCornerRadius[2] || 40, focusBackgroundCornerRadius[3] || 40],
            color: (focusBackground as HippyMap).get('color') as string[] || ['#FFE398', '#EEB364'],
            padding: [focusBackgroundPadding[0] || 34, focusBackgroundPadding[1] || 6],
          },
          mark: {
            color: (mark as HippyMap).get('color') as string || '#FFD97C',
          }
        }
        console.log(TAG_MediaSeries, ` groupParam :${JSON.stringify(this.initParamGroup)}`)
        return true;
      }
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
        //this.listData.removeAllData();

        console.log(TAG_MediaSeries, `QTMediaSeriesView:page:${method},value:${page}`)

        data.forEach((value: HippyAny, keyA: string) => {
          console.log(TAG_MediaSeries, `QTMediaSeriesView:page,key:${keyA}`);

          (value as HippyMap).forEach((eachValue: HippyAny, keyB: string) => {
            console.log(TAG_MediaSeries, `QTMediaSeriesView:page,key:${keyA}-${keyB}`, eachValue);
          })

          this.listData.addData({
            key: this.getRandomString(),
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
            id: HRValueUtils.getStringValue('id', value as HippyMap, null)!,
          });
        })
        console.log(TAG_MediaSeries, `QTMediaSeriesView listData :${JSON.stringify(this.listData)}`)
        break;

      // 自定义模式下的 数据总数
      case "setInitData":
        let totalCount = HRValueUtils.getNumber2(params[0], 0)
        let pageSize = HRValueUtils.getNumber2(params[1], 0)
        this.initParam.totalCount = totalCount;
        this.initParam.pageSize = this.initParam.groupSize = pageSize;
        this.enableGroup = true
        this.generatePageData = this.generatePageRanges(totalCount, pageSize);
        break;

      //设置选中的item
      case "setSelectChildPosition":
        let childPos = HRValueUtils.getNumber2(params[0], 0)
        console.log(TAG_MediaSeries, `setSelectChildPosition : childPos is : ${childPos} `)
        break;

      //滚动到指定位置
      case "scrollToPosition":
        let scrollPos = HRValueUtils.getNumber2(params[0], 0)
        this.scroller.scrollToIndex(scrollPos);
        console.log(TAG_MediaSeries, `scrollToPosition : scrollPos is : ${scrollPos}`)
        break;

      //滚动到指定位置 可添加偏移量
      case "scrollToPositionWithOffset":
        let scrollPosIdx = HRValueUtils.getNumber2(params[0], 0)
        let scrollPosOffset = HRValueUtils.getNumber2(params[1], 0)
        this.scroller.scrollToIndex(scrollPosIdx, false, ScrollAlign.START,
          { extraOffset: LengthMetrics.vp(scrollPosOffset) });

        console.log(TAG_MediaSeries,
          `scrollToPositionWithOffset : scrollPosIdx is : ${scrollPosIdx}, scrollPosOffset is :${scrollPosOffset}`)
        break;

      //设置选中的item
      case "requestChildFocus":
        let focusPos = HRValueUtils.getNumber2(params[0], 0)
        focusControl.requestFocus(HIPPY_COMPONENT_KEY_PREFIX + this.tag + '_LIST_' + focusPos)
        console.log(TAG_MediaSeries,
          `requestChildFocus : focusPos is : ${HIPPY_COMPONENT_KEY_PREFIX + this.tag + '_LIST_' + focusPos}`)
        break;
    }

  }
}



