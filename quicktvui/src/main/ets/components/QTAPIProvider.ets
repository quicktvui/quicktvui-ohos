import { HippyAPIProvider } from 'hippy';

import {
  HippyJSModuleCreator,
  HippyNativeModuleCreator,
  HippyRenderBaseView,
  HRRenderViewCreator
} from 'hippy';

import { QTDiv, QTDivView } from './div/QTDivView';
import { QTFastListView } from './fastlist/QTFastListView';
import { QTFastFlex, QTFastFlexView } from './fastlist/QTFastFlexView';
import { QTFastItem, QTFastItemView } from './fastlist/QTFastItemView';
import { TAG_QUICKTVUI } from '../Constant';
import { QTText, QTTextView } from './text/QTTextView';
import { QTFallback, QTFallbackView } from './compat/QTFallbackView';
import { QTLoading, QTLoadingView } from './loading/QTLoadingView';
import { QTEvent, QTEventView } from './event/QTEventView';
import { QTProgress, QTProgressView } from './progress/QTProgressView';
import { QTQRCode, QTQRCodeView } from './qrcode/QTQRCodeView';
import { QTWeb, QTWebView } from './web/QTWebView';
import { QTSlider, QTSliderView } from './slider/QTSliderView';
import { QTAnimation, QTAnimationView } from './animation/QTAnimationView';
import { QTItemFrame, QTItemFrameView } from './item/QTItemFrameView';
import { QTLottie, QTLottieView } from './lottie/QTLottieView';
import { HRTvImage, HRTvImageView } from './image/HRTvImageView';
import { HRTvDiv, HRTvDivView } from './view/HRTvDivView';
import { HRTvListView } from './list/HRTvListView';
import { HRTvListItem, HRTvListItemView } from './list/HRTvListItemView';
import { HRTvViewPager, HRTvViewPagerView } from './pager/HRTvViewPager';
import { HRTvViewPagerItem, HRTvViewPagerItemView } from './pager/HRTvViewPagerItem';
import { QTFastList } from './fastlist/QTFastList';
import { QTVideoPlayer, QTVideoPlayerView } from './video/QTVideoPlayerView';
import { QTPageRouter, QTPageRouterView } from './router/QTPageRouterView';
import { QTPage, QTPageView } from './router/QTPageView';
import { HRTvList } from './list/HRTvList';
import { QTTabs, QTTabsView } from './tabs/QTTabsView';
import { InnerViewPager, InnerViewPagerView } from './tabs/InnerViewPagerView';

export class QTAPIProvider extends HippyAPIProvider {
  getCustomNativeModuleCreatorMap(): Map<string, HippyNativeModuleCreator> | null {
    let registerMap: Map<string, HippyNativeModuleCreator> = new Map()
    // registerMap.set(ExampleNativeModule.NAME, (ctx): HippyNativeModuleBase => new ExampleNativeModule(ctx))
    // registerMap.set(ExampleNativeTurboModule.NAME, (ctx): HippyNativeModuleBase => new ExampleNativeTurboModule(ctx))
    return registerMap;
  }

  getCustomJavaScriptModuleCreatorMap(): Map<string, HippyJSModuleCreator> | null {
    return null
  }

  getCustomRenderViewCreatorMap(): Map<string, HRRenderViewCreator> | null {
    let registerMap: Map<string, HRRenderViewCreator> = new Map()

    registerMap.set("QTVideoPlayerView", (ctx): HippyRenderBaseView => new QTVideoPlayerView(ctx))
    registerMap.set("ESPageRouterView", (ctx): HippyRenderBaseView => new QTPageRouterView(ctx))
    registerMap.set("ESPageRootView", (ctx): HippyRenderBaseView => new QTPageView(ctx))

    registerMap.set("QTView", (ctx): HippyRenderBaseView => new QTDivView(ctx))
    registerMap.set("FastListView", (ctx): HippyRenderBaseView => new QTFastListView(ctx))
    registerMap.set("FastFlexView", (ctx): HippyRenderBaseView => new QTFastFlexView(ctx))
    registerMap.set("FastItemView", (ctx): HippyRenderBaseView => new QTFastItemView(ctx))
    registerMap.set("TabsView", (ctx): HippyRenderBaseView => new QTTabsView(ctx))
    registerMap.set("RecyclerViewPager", (ctx): HippyRenderBaseView => new InnerViewPagerView(ctx))
    //测试
    registerMap.set("LoadingViewComponent", (ctx): HippyRenderBaseView => new QTLoadingView(ctx))
    registerMap.set("QrCodeComponent", (ctx): HippyRenderBaseView => new QTQRCodeView(ctx))
    registerMap.set("ESWebViewComponent", (ctx): HippyRenderBaseView => new QTWebView(ctx))
    registerMap.set("TVProgressBarViewComponent", (ctx): HippyRenderBaseView => new QTProgressView(ctx))
    registerMap.set("EsEventComponent", (ctx): HippyRenderBaseView => new QTEventView(ctx))
    registerMap.set("QTSliderView", (ctx): HippyRenderBaseView => new QTSliderView(ctx))
    registerMap.set("AnimationViewComponent", (ctx): HippyRenderBaseView => new QTAnimationView(ctx))

    registerMap.set("TextView", (ctx): HippyRenderBaseView => new QTTextView(ctx))
    registerMap.set("ItemFrameComponent", (ctx): HippyRenderBaseView => new QTItemFrameView(ctx))
    registerMap.set("ESLottieViewComponent", (ctx): HippyRenderBaseView => new QTLottieView(ctx))


    //fallback
    registerMap.set("ItemFrameComponent", (ctx): HippyRenderBaseView => new QTFallbackView(ctx))
    registerMap.set("RippleViewComponent", (ctx): HippyRenderBaseView => new QTFallbackView(ctx))
    // registerMap.set("ExampleViewB", (ctx): HippyRenderBaseView => new ExampleViewB(ctx))
    // registerMap.set("MyScrollView", (ctx): HippyRenderBaseView => new MyScrollView(ctx))
    // registerMap.set("MyTopView", (ctx): HippyRenderBaseView => new MyTopView(ctx))
    // registerMap.set("MyTabBarView", (ctx): HippyRenderBaseView => new MyTabBarView(ctx))
    // registerMap.set("MyBottomView", (ctx): HippyRenderBaseView => new MyBottomView(ctx))

    //鸿蒙开发者
    registerMap.set("TvImage", (ctx): HippyRenderBaseView => new HRTvImageView(ctx))
    registerMap.set("TvView", (ctx): HippyRenderBaseView => new HRTvDivView(ctx))
    registerMap.set("TvListView", (ctx): HippyRenderBaseView => new HRTvListView(ctx))
    registerMap.set("TvListViewItem", (ctx): HippyRenderBaseView => new HRTvListItemView(ctx))
    registerMap.set("TvViewPager", (ctx): HippyRenderBaseView => new HRTvViewPagerView(ctx))
    registerMap.set("TvViewPagerItem", (ctx): HippyRenderBaseView => new HRTvViewPagerItemView(ctx))
    //
    return registerMap
  }

  getCustomMeasureRenderViews(): Array<string> | null {
    return ["ExampleViewB"]
  }

  getCustomMappingRenderViewMap(): Map<string, string> | null {
    return null
  }
}


@Builder
export function buildCustomRenderView($$: HippyRenderBaseView) {
  if ($$ instanceof QTLoadingView) {
    QTLoading({
      renderView: $$ as QTLoadingView,
      children: $$.children,
    })
  } else if ($$ instanceof QTEventView) {
    QTEvent({
      renderView: $$ as QTEventView,
      children: $$.children,
    })
  } else if ($$ instanceof QTProgressView) {
    QTProgress({
      renderView: $$ as QTProgressView,
      children: $$.children,
    })
  } else if ($$ instanceof QTQRCodeView) {
    QTQRCode({
      renderView: $$ as QTQRCodeView,
      children: $$.children,
    })
  } else if ($$ instanceof QTWebView) {
    QTWeb({
      renderView: $$ as QTWebView,
      children: $$.children,
    })
  } else if ($$ instanceof QTVideoPlayerView) {
    QTVideoPlayer({
      renderView: $$ as QTVideoPlayerView,
      children: $$.children,
    })
  } else if ($$ instanceof QTSliderView) {
    QTSlider({
      renderView: $$ as QTSliderView,
      children: $$.children,
    })
  } else if ($$ instanceof QTFastListView) {
    QTFastList({
      renderView: $$ as QTFastListView,
      children: $$.children,
    })
  } else if ($$ instanceof QTTextView) {
    QTText({
      renderView: $$ as QTTextView,
      children: $$.children,
    })
  } else if ($$ instanceof QTFastItemView) {
    QTFastItem({
      renderView: $$ as QTFastItemView,
      children: $$.children,
    })
  } else if ($$ instanceof QTDivView) {
    QTDiv({
      renderView: $$ as QTTextView,
      children: $$.children,
    })
  } else if ($$ instanceof QTPageRouterView) {
    QTPageRouter({
      renderView: $$ as QTPageRouterView,
      children: $$.children,
    })
  } else if ($$ instanceof QTAnimationView) {
    QTAnimation({
      renderView: $$ as QTAnimationView,
      children: $$.children,
    })
  } else if ($$ instanceof QTItemFrameView) {
    QTItemFrame({
      renderView: $$ as QTItemFrameView,
      children: $$.children,
    })
  } else if ($$ instanceof QTLottieView) {
    QTLottie({
      renderView: $$ as QTLottieView,
      children: $$.children,
    })
  }
  //页面
  else if ($$ instanceof QTPageView) {
    QTPage({
      renderView: $$ as QTPageView,
      children: $$.children,
    })
  } else if ($$ instanceof QTFastFlexView) {
    QTFastFlex({
      renderView: $$ as QTFastFlexView,
      children: $$.children,
    })
  }
  //-------------------------------------------------------------------
  else if ($$ instanceof HRTvImageView) {
    HRTvImage({ renderView: $$ as HRTvImageView })
  } else if ($$ instanceof HRTvDivView) {
    HRTvDiv({ renderView: $$ as HRTvDivView, children: $$.children })
  } else if ($$ instanceof HRTvListView) {
    HRTvList({
      renderView: $$ as HRTvListView,
      children: $$.children,
    })
  } else if ($$ instanceof HRTvListItemView) {
    HRTvListItem({
      renderView: $$ as HRTvListItemView,
      children: $$.children,
    }).reuseId($$.type)
  } else if ($$ instanceof HRTvViewPagerView) {
    HRTvViewPager({
      renderView: $$ as HRTvViewPagerView,
      children: $$.children,
    })
  } else if ($$ instanceof HRTvViewPagerItemView) {
    HRTvViewPagerItem({
      renderView: $$ as HRTvViewPagerItemView,
      children: $$.children,
    })
  } else if ($$ instanceof QTTabsView) {
    QTTabs({
      renderView: $$ as QTTabsView,
      children: $$.children,
    })
  } else if ($$ instanceof InnerViewPagerView) {
    InnerViewPager({
      renderView: $$ as InnerViewPagerView,
      children: $$.children,
    })
  }

  else {
    QTFallback({
      renderView: $$ as QTFallbackView,
      children: $$.children,
    })
  }
}