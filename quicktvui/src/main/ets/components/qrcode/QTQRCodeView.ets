import {
  HippyRenderBaseView,
  HippyObservedArray,
  NativeRenderContext,
  HippyAny,
  HIPPY_COMPONENT_KEY_PREFIX,
  LogUtils
} from 'hippy'

import { BarcodeFormat, } from '@ohos/zxing';
import QRCode from './QRCode'

import { QTBaseComponentView } from '../QTBaseComponentView';
import { image } from '@kit.ImageKit';
import { BusinessError } from '@kit.BasicServicesKit';

@Observed
export class QTQRCodeView extends QTBaseComponentView {
  private readonly TAG = "QTQRCodeView";
  private qrcode = new QRCode()
  public pixelMap: image.PixelMap | null = null
  public qrcodeWidth: number = 0
  public qrcodeHeight: number = 0

  constructor(ctx: NativeRenderContext) {
    super(ctx)
  }

  setProp(propKey: string, propValue: HippyAny): boolean {
    if (propKey === 'width') {
      this.qrcodeWidth = propValue as number
    } else if (propKey === 'height') {
      this.qrcodeHeight = propValue as number
    } else if (propKey === 'content') {
      this.qrcode.encode(propValue as string, {
        width: Math.floor(this.qrcodeWidth),
        height: Math.floor(this.qrcodeHeight),
        format: BarcodeFormat.QR_CODE
      }).then((pixelMap) => {
        this.pixelMap = pixelMap
      }, (error: BusinessError) => {
        this.pixelMap = null
        LogUtils.e(this.TAG, "qrcode encode error: " + JSON.stringify(error))
      })
      return true;
    }
    return super.setProp(propKey, propValue)
  }
}

@Component
export struct QTQRCode {
  @ObjectLink renderView: QTQRCodeView
  @ObjectLink children: HippyObservedArray<HippyRenderBaseView>

  build() {
    Image(this.renderView.pixelMap)
      .applyRenderViewBaseAttr(this.renderView)
  }
}

@Extend(Image)
function applyRenderViewBaseAttr($$: HippyRenderBaseView) {
  .key(HIPPY_COMPONENT_KEY_PREFIX + $$.tag)
  .backgroundColor($$.cssBackgroundColor)
  .position({ x: $$.cssPositionX, y: $$.cssPositionY })
  .size({
    width: $$.cssWidth,
    height: $$.cssHeight
  })
  .opacity($$.cssOpacity)
  .clip($$.cssOverflow)
  .visibility(($$ as HippyRenderBaseView).cssVisibility)
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
