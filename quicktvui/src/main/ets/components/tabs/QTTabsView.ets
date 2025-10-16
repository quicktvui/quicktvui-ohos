import System from '@ohos/zxing/src/main/ets/core/util/System';
import {HippyRenderBaseView,HippyObservedArray,HRDiv,NativeRenderContext,HippyAny,HippyRenderCallback,HIPPY_COMPONENT_KEY_PREFIX,buildHippyRenderView} from 'hippy'
import { InnerViewPagerView, QTFastList,QTFastListView } from '../../../../../Index';
import { TAG_FASTLIST, TAG_TABS } from '../../Constant';
import { HRValueUtils } from '../../HRValueUtils';
import { QTAny, QTArray, QTMap, QTView } from '../../QTTypes';
import { CommonUtils } from '../../utils/CommonUtils';
import { ExtendUtil } from '../../utils/ExtendUtil';
import { QTPixelUtil } from '../../utils/QTPixelUtil';
import QTRenderBaseView from '../QTRenderBaseView';
import { TabsDataSource } from './TabsDataSource';
import { WaterfallListView } from './WaterfallListView';


@Observed
export class QTTabsView extends QTRenderBaseView{

  viewpager: InnerViewPagerView | null = null;
  tabList: QTFastListView | null = null;
  controller: TabsController = new TabsController();
  currentIndex: number = 0;
  selectedIndex: number = 0;

  defaultPosition = 0; //默认选中tab
  defaultFocusPosition = -1; //默认选中tab
  tabPendingFocus = -1;

  barPosition: BarPosition = BarPosition.Start;

  dataSource : TabsDataSource;

  contentTemplate : QTView | null = null;

  static STRATEGY_ONE_SHOT = 1
  static STRATEGY_ALWAYS = 2
  static STRATEGY_OVER_TIME = 3
  static PRELOAD_STRATEGY_BOTH_SIDE = 1
  static PRELOAD_STRATEGY_SINGLE = 2
  static TAB_POSITION_TOP = 1
  static TAB_POSITION_LEFT = 2
  static TAB_POSITION_RIGHT = 3
  static TAB_POSITION_BOTTOM = 4

  loadDataStrategy  = QTTabsView.STRATEGY_ONE_SHOT
  preloadStrategy = QTTabsView.PRELOAD_STRATEGY_BOTH_SIDE
  tabPosition =  QTTabsView.TAB_POSITION_TOP

  outOfDateTime = 5 * 60 * 1000
  outOfDateTimeLocalCache = 1000 * 60 * 60 * 24 * 1

  hideOnSingleTab =  false
  singleTabMode = false
  autoHandleBackKey = true
  autoReFocusOnSingleTab = true
  autoBackToDefault = true
  useClickMode = false
  autoScrollToTop = true
  blockFocusDirections = []
  defaultIndex = 0
  preloadItemNumber = 1
  requestAutofocusOnPageChange = false
  switchDuration = 200

  pageSwitchDelay = 100
  resumeTaskDelay = 500
  resumePlayerTaskDelay = 500
  firstResumeTaskDelay = 1000
  speedPerPixel = -1
  offscreenPageLimit = 1
  disableScrollAnimation = false;
  preferSaveMemory = true;
  alphaTransform = false;
  syncNavListSID = ''
  changePageOnFocusFail = false
  enableDrawerAnimation = false;
  autoChangePageByNative = true;

  public tabsData: HippyObservedArray<TabPageData> = new HippyObservedArray()

  constructor(ctx: NativeRenderContext) {
    console.warn(TAG_TABS,'create QTTabsView')
    super(ctx)
    this.dataSource = new TabsDataSource(ctx,this.tabsData)
  }

  setProp(propKey: string, propValue: HippyAny): boolean {
    console.log(TAG_TABS,`tabs:setProp propKey:${propKey},propValue:${CommonUtils.hippyAny2String(propValue)}`)
    switch (propKey) {
      case "tabs":
        return true;
      case "hideOnSingleTab":
        return true;
      case "speedPerPixel":
        this.speedPerPixel = propValue as number
        return true;
      case "switchDuration":
        this.switchDuration = propValue as number
        return true;
      case "preloadItemNumber":
        this.preloadItemNumber = propValue as number
        return true;
      case "autoHandleBackKey":
        this.autoHandleBackKey = propValue as boolean
        return true;
      case "autoScrollToTop":
        this.autoScrollToTop = propValue as boolean
        return true;
      case "dataStrategy":
        switch(propValue as string){
          case 'oneShot':
            this.loadDataStrategy = QTTabsView.STRATEGY_ONE_SHOT
            break;
          case 'always':
            this.loadDataStrategy = QTTabsView.STRATEGY_ALWAYS
            break;
          case 'overTime':
            this.loadDataStrategy = QTTabsView.STRATEGY_OVER_TIME
            break;
        }
        return true;
      case "preloadStrategy":
        if(propValue == 'single'){
          this.preloadStrategy = QTTabsView.PRELOAD_STRATEGY_SINGLE
        }else{
          this.preloadStrategy = QTTabsView.PRELOAD_STRATEGY_BOTH_SIDE
        }
        return true;
      case "tabPosition":
        // switch(propValue){
        //   case 'top':
        // }
        return true;
      case "outOfDateTime":
        this.outOfDateTime = propValue as number
        return true;
      case "blockFocusDirections":
        return true;
      case "autoHandleBackKey":
        this.autoHandleBackKey = propValue as boolean
        return true;
      case "useClickMode":
        this.useClickMode = propValue as boolean
        return true;
      case "disableScrollAnimation":
        this.disableScrollAnimation = propValue as boolean
        return true;
      case "autoChangePageByNative":
        this.autoChangePageByNative = propValue as boolean
        return true;
      case "pageSwitchDelay":
        this.pageSwitchDelay = propValue as number
        return true;
      case "firstResumeTaskDelay":
        this.firstResumeTaskDelay = propValue as number
        return true;
      case "checkAutofocusOnPageChange":
        return true;
      case "firstResumeTaskDelay":
        this.firstResumeTaskDelay = propValue as number
        return true;
      case "changePageOnFocusFail":
        return true;
      case "enableDrawerAnimation":
        return true;
      case "preferSaveMemory":
        return true;
      case "offscreenPageLimit":
        return true;
      case "autoBackToDefault":
        return true;
      case "listenScrollEvent":
        return true;
      case "alphaTransform":
        return true;

      default :
        break;
    }
    switch (propKey){
      case 'useDiff':
      case "singleTabMode":
      case "autoReFocusOnSingleTab":
      case "suspension":
      case "useSuspensionBg":
      case "isHideList":
      case "suspensionHideOffset":
      case "useSuspensionBg":
      case "customNavListSID":
      case "resumeTaskDelay":
      case "resumePlayerTaskDelay":
      case "outOfDateTimeLocalCache":
      case "localCacheKey":
        console.warn(TAG_TABS,`tabs组件，不处理的属性:${propKey}`)
        return true;
    }
    return super.setProp(propKey, propValue)
  }

  onPageTemplateReady(template:QTView){
    console.log(TAG_TABS,`onPageTemplateReady:${template}`)
    this.contentTemplate = template;
    // this.tabsData.forEach((value)=>{
    //   value.contentView?.setcus
    // })
  }

  addSubRenderView(subView: HippyRenderBaseView, index: number): void {
    super.addSubRenderView(subView,index)
    if(subView instanceof QTFastListView){
      this.tabList = subView;
    }
    if(subView instanceof InnerViewPagerView){
      this.viewpager = subView;
    }
    if(this.tabList && this.viewpager){
      console.warn(TAG_TABS,`tabs content ready!`)
    }
    if(this.tabList && this.viewpager){

    }
  }

  updateTabsData(tabList : QTArray){
    this.tabsData = []
    tabList.forEach((item: QTAny,index:number)=>{
        let p :TabPageData = new TabPageData()
      if(item instanceof Map){
        if(item.has('text')){
          p.title = item.get('text') as string
        }
        if(item.has('title')){
          p.title = item.get('title') as string
        }
      }else{
        p.title = `请设定text:${index}`
      }
      p.pageIndex = index
      let wl = new WaterfallListView(this.ctx)
      wl.pageIndex = index
      wl.isVirtual = true
      if(this.viewpager?.templateListView){
        wl.templateView = this.viewpager?.templateListView as QTView
      }
      p.contentView = wl
      QTPixelUtil.setRenderViewLayout(p.contentView,[0,0,this.cssWidth,this.cssHeight])
      // console.log(TAG_TABS,`updateTabsData this width:${this.cssWidth},height:${this.cssHeight}`)
      if(item){
        p.tabItem = item as QTMap
      }
      this.tabsData.push(p)
    })

    this.tryLoadPageData(this.defaultPosition)
    console.log(TAG_TABS,`updateTabsData tabList:${tabList?.length},tabsData length:${this.tabsData.length}`)
    this.dataSource.notifyReload()
  }


  viewAboutToAppear(){
    //console.error(TAG_TABS,`viewAboutToAppear`)
  }

  onTabsContentWillChangeCallback(currentIndex: number,comingIndex: number) : boolean{
    console.log(TAG_TABS,`onTabsContentWillChangeCallback currentIndex  :${currentIndex},comingIndex:${comingIndex}`)
    this.tryLoadPageData(comingIndex)
    return true;
  }

  tryLoadPageData(pageIndex: number){
    let pd = this.getTabData(pageIndex)
    if(pd){
      if(this.isNeedLoad(pd)){
        this.notifyLoadPage(pageIndex)
      }else{
        if(pd.dataState == 1){
          pd.updateDirty = true;
        }
      }
    }
  }

  isNeedLoad(tabData:TabPageData){
    let b = false;
    if(this.loadDataStrategy == QTTabsView.STRATEGY_ALWAYS){
      b = tabData.dataState != 0
    }else if(this.loadDataStrategy == QTTabsView.STRATEGY_ONE_SHOT){
      b = tabData.dataState == -1;
    }else if(this.loadDataStrategy == QTTabsView.STRATEGY_OVER_TIME){
      if(tabData.dataState == -1){
        b = true;
      }else{
        let now = System.currentTimeMillis();
        let outOfDate = tabData.loadTime == -1 || ((now-tabData.loadTime)) > this.outOfDateTime;
        b = outOfDate
      }
    }
    return b;
  }

  getTabItem(index: number): QTMap | null{
    if(this.tabsData && this.tabsData[index]){
      return this.tabsData[index].tabItem as QTMap
    }
		return null;
	}

  getTabData(index:number):TabPageData | null{
    return this.tabsData[index]
  }

  notifyLoadPage(page:number){
    let map = new Map<string,QTAny>()
    let item = this.getTabItem(page)
    if(item){
      if(item.has('content')){
          let pageData = item.get('content')
        if(pageData instanceof Map){
          map.set('itemCount',pageData.size)
        }else{
          map.set('itemCount',0)
        }
      }else{
        map.set('itemCount',0)
      }
    }else{
      console.error(TAG_TABS,`notifyLoadPage error item is null`)
      return;
    }
    map.set('pageIndex',page)
    map.set('data',item)
    map.set('useDiff',false)
    console.log(TAG_TABS,`---send onLoadPageData pageIndex:${page}, map:${CommonUtils.hippyMap2String(map)}`)
    ExtendUtil.sendUIEvent(this.ctx,this.tag,'onLoadPageData',map)
  }

  setPageData(pageIndex: number,params:QTMap,dataArray : QTArray){
    console.log(TAG_TABS,`setPageData :${pageIndex},dataArray:${dataArray?.length},params:${CommonUtils.hippyMap2String(params)}`)
      this.updateDataOnly(pageIndex,params,dataArray)
      let pd = this.getTabData(pageIndex)
      if(pd?.contentView){
        if(!this.contentTemplate){
          console.error(TAG_TABS,`setPageData error contentTemplate is null`)
          return;
        }
        pd.contentView.nativeSetupIfNeed(this.contentTemplate.tag,this.contentTemplate)
        pd.contentView.updateSections(dataArray,pd.contentParams)
      }
  }

  updateDataOnly(pageIndex: number,params:QTMap,data : QTAny){
    let pd = this.getTabData(pageIndex)
    if(pd){
      pd.contentParams = params
      pd.contentData = data
      pd.updateDirty = true
      if(data){
        pd.dataState = 1
      }else{
        pd.dataState = -1
      }
    }

  }
  call(method: string, params: Array<HippyAny>, callback: HippyRenderCallback | null): void {
    console.log(TAG_TABS,`tabs:call function:${method},params:${CommonUtils.hippyAny2String(params)}`)
    switch (method){
      case 'setTabsData':
        let initParam : QTMap = params[0] as QTMap
        let tabData : QTArray = params[1] as QTArray
        this.defaultPosition = HRValueUtils.getNumberValue('defaultIndex',initParam,0)
        this.defaultFocusPosition = HRValueUtils.getNumberValue('focusIndex',initParam,-1)
        this.tabPendingFocus = this.defaultFocusPosition
        this.updateTabsData(tabData)
        break;
      case 'requestTabFocus':
        break;
      case 'setCurrentPage':
        break;
      case 'addPageData':
        break;
      case 'removePageData':
        break;
      case 'insertPageData':
        break;
      case 'updateChildNode':
        break;
      case 'getChildNodeState':
        break;
      case 'getRootNodeState':
        break;
      case 'updateRootNode':
        break;
      case 'dispatchUIFunctionOnChildNode':
        break;
      case 'updateItemMatched':
        break;
      case 'setPageData':
        let pageIndex = params[0] as number
        let p = params[1] as QTMap
        let data = params[2] as QTArray
        this.setPageData(pageIndex,p,data)
        break;
      case 'requestNodeFocus':
        break;
      case 'requestPageFocus':
        break;
      case 'updatePageData':
        break;
      case 'reloadAll':
        break;
      case 'reloadPage':
        break;
      case 'setFirstFocusTarget':
        break;
      case 'contentScrollToFocus':
        break;
      case 'performBackKeyPressed':
        break;
      case 'invokeContentFunction':
        break;
      case 'performBackKeyPressed':
        break;
      case 'destroy':
        break;
      case 'getCurrentPage':
        break;
      case 'translationLeft':
        break;
      case 'translationRight':
        break;
      case 'cancelAll':
        break;
      case 'searchReplaceItem':
        break;
      case 'markToReloadPage':
        break;

    }
  }

}

@Builder
function buildPage(item: TabPageData, index: number){
  if(item.contentView){
    QTFastList({
      renderView : item.contentView,
      children : item.contentView.children
    })
    .width('100%')
    .height('100%')
  }else{
    Text(`page:${index}`)
      .width('100%')
      .height('100%')
      .backgroundColor(Color.Green)
  }

}

@Component
export struct  QTTabs {
  @ObjectLink renderView: QTTabsView
  @ObjectLink children: HippyObservedArray<QTView>

  build(): void {
    Tabs({barPosition: this.renderView.barPosition,index: this.renderView.currentIndex,controller: this.renderView.controller}){
      ForEach(this.renderView.tabsData, (item: TabPageData, index: number) => {
        TabContent() {
          buildPage(item,index)
        }
        .tabBar(`${item.title}`)
      },(item:TabPageData,index:number)=>{
        return ''+index
      })
    }
    .barPosition(BarPosition.Start)
    .onContentWillChange((currentIndex:number,comingIndex:number)=>{
      return this.renderView.onTabsContentWillChangeCallback(currentIndex,comingIndex)
    })
    .backgroundColor(Color.Black)

  }

  aboutToAppear(): void {
    this.renderView.viewAboutToAppear()
  }
}

@Extend(Tabs)
function applyRenderViewBaseAttr($$: QTView) {
  .key(HIPPY_COMPONENT_KEY_PREFIX + $$.tag)
  .backgroundColor($$.cssBackgroundColor)
  .position({x: $$.cssPositionX, y: $$.cssPositionY})
  .size({width:$$.cssWidth, height: $$.cssHeight})
  .opacity($$.cssOpacity)
  .clip($$.cssOverflow)
  .visibility(($$ as QTView).cssVisibility) // must add as, otherwise the compiler has error
  .zIndex($$.cssZIndex)
  .accessibilityText($$.cssAccessibilityLabel)
  .focusable($$.cssFocusable)
  .border($$.cssBorder)
  .shadow($$.cssShadow)
  .linearGradient($$.cssLinearGradient)
  .backgroundImage($$.cssBackgroundImage)
  .backgroundImageSize($$.cssBackgroundImageSize)
  .backgroundImagePosition($$.cssBackgroundImagePosition)
  .transform($$.cssMatrix)
  .rotate($$.cssRotate)
  .scale($$.cssScale)
  .translate($$.cssTranslate)
  .hitTestBehavior($$.hitTestBehavior)
  .onClick($$.eventClick)
}

@Observed
export class TabPageData{
  // template: QTView | undefined = undefined;
  title: string | null  = null;
  tabItem : QTMap | null = null;
  contentParams : QTMap | null = null;
  contentData : QTAny | null = null;
  pageIndex: number = -1;
  pendingFocusPosition : number = -1;
  updateDirty = true;
  disableScrollOnFirstScreen = false;
  dataState = -1;
  loadTime = -1;
  contentView: WaterfallListView | null = null;



}
