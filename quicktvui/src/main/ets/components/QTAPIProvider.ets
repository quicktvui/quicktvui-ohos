import { HippyAPIProvider } from 'hippy';

import {
  HippyJSModuleCreator
} from 'hippy/src/main/ets/hippy_framework/modules/HippyModuleManagerImpl';
import {
  HippyNativeModuleCreator
} from 'hippy/src/main/ets/hippy_framework/modules/HippyModuleManagerImpl';

import HippyRenderBaseView
  from 'hippy/src/main/ets/renderer_native/components/base/HippyRenderBaseView';
import {
  HRRenderViewCreator
} from 'hippy/src/main/ets/renderer_native/components/HippyRenderRegisterMap';

import { QTDivView } from './div/QTDivView';
import { QTFastListView } from './fastlist/QTFastListView';
import { QTFastFlexView } from './fastlist/QTFastFlexView';
import { QTFastItemView } from './fastlist/QTFastItemView';
import { TAG_QUICKTVUI } from '../Constant';
import { QTTextView } from './text/QTTextView';
import { QTFallback, QTFallbackView } from './compat/QTFallbackView';
import { QTLoadingView } from './loading/QTLoadingView';
import { QTEventView } from './event/QTEventView';
import { QTProgressView } from './progress/QTProgressView';
import { QTQRCodeView } from './qrcode/QTQRCodeView';
import { QTWebView } from './web/QTWebView';
import { QTSliderView } from './slider/QTSliderView';
import { QTAnimationView } from './animation/QTAnimationView';
import { QTItemFrameView } from './item/QTItemFrameView';
import { QTLottieView } from './lottie/QTLottieView';

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
    registerMap.set("QTView", (ctx): HippyRenderBaseView => new QTDivView(ctx))
    registerMap.set("FastListView", (ctx): HippyRenderBaseView => new QTFastListView(ctx))
    registerMap.set("FastFlexView", (ctx): HippyRenderBaseView => new QTFastFlexView(ctx))
    registerMap.set("FastItemView", (ctx): HippyRenderBaseView => new QTFastItemView(ctx))

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
    return registerMap
  }

  getCustomMeasureRenderViews(): Array<string> | null {
    return ["ExampleViewB"]
  }

  getCustomMappingRenderViewMap(): Map<string, string> | null {
    return null
  }
}
