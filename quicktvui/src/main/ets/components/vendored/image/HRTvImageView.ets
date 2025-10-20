/*
 * Tencent is pleased to support the open source community by making
 * Hippy available.
 *
 * Copyright (C) 2022 THL A29 Limited, a Tencent company.
 * All rights reserved.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *   http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */
import { HippyAny, HRNodeProps, HippyRenderCallback, HippyResource, NativeRenderContext } from 'hippy';
import { HRConvertUtil } from 'hippy/src/main/ets/renderer_native/utils/HRConvertUtil';
import HippyRenderBaseView, { HIPPY_COMPONENT_KEY_PREFIX } from 'hippy/src/main/ets/renderer_native/components/base/HippyRenderBaseView';
import { HippyCustomComponentView } from 'hippy/src/main/ets/renderer_native/components/custom/HippyCustomComponentView'
import { LogUtils } from 'hippy/src/main/ets/support/utils/LogUtils';
import {HRDownloadUtils} from 'hippy/src/main/ets/renderer_native/utils/HRDownloadUtils'
import { HREventUtils } from 'hippy/src/main/ets/renderer_native/utils/HREventUtils';
import { ImageRequestListener } from './TvImageRequestListener';
import { ImageDataSupplier } from './TvImageDataSupplier';
import { HashMap } from '@kit.ArkTS';
import { HRValueUtils } from 'hippy/src/main/ets/renderer_native/utils/HRValueUtils';
import { HippyResourceLoader } from 'hippy/src/main/ets/hippy_framework/HippyResourceLoader';
import { UrlUtils } from 'hippy/src/main/ets/support/utils/UrlUtils';
import { HRPadding, HRRect } from 'hippy/src/main/ets/renderer_native/utils/HRTypes';
import { QTBaseComponentView } from '../../QTBaseComponentView';

interface TvImageLoadEvent {
  width: number
  height: number
  componentWidth: number
  componentHeight: number
  loadingStatus: number
  contentWidth: number
  contentHeight: number
  contentOffsetX: number
  contentOffsetY: number
}

enum TvTintColorBlendMode {
  CLEAR,
  SRC,
  DST,
  SRC_OVER,
  DST_OVER,
  SRC_IN,
  DST_IN,
  SRC_OUT,
  DST_OUT,
  DST_ATOP = 10,
  XOR,
  ADD,
  MULTIPLY,
  SCREEN,
  OVERLAY,
  DARKEN,
  LIGHTEN,
  SRC_ATOP,
}

@Observed
export class HRTvImageView extends QTBaseComponentView {
  private static readonly BASE64_IMAGE_PREFIX = "data:image"
  private static readonly RAW_IMAGE_PREFIX = "hpfile://"
  private static readonly ASSETS_PREFIX = "assets://"
  private static readonly INTERNET_IMAGE_PREFIX = "http"
  private readonly TAG = "HRTvImageView"
  public uiCtx: UIContext | null = null
  private imageLoader: HRDownloadUtils = new HRDownloadUtils
  tempDir:string = getContext().tempDir

  src: string | PixelMap | Resource
  cssSrc: string | Resource | null = null
  cssAlt: string | Resource | null = null
  cssResizeMode: ImageFit = ImageFit.Fill
  imageRepeat: ImageRepeat = ImageRepeat.NoRepeat
  resizable: ResizableOptions | null = null
  cssTintColor: number[] = [0] // RGBA
  cssColorFilter: ColorFilter = [0]
  draggable: boolean = false
  cssTvTintColorBlendMode: TvTintColorBlendMode = TvTintColorBlendMode.SRC_ATOP
  cssPreTvTintColorBlendMode: TvTintColorBlendMode = TvTintColorBlendMode.SRC_ATOP
  onCompleteCallback: ((event?: TvImageLoadEvent) => void) | null = null
  onErrorCallback: ((error: ImageError) => void) | null = null

  // imageSpan props
  spanVerticalAlign: ImageSpanAlignment = ImageSpanAlignment.BOTTOM
  spanObjectFit: ImageFit = ImageFit.Fill

  // TV扩展
  visibility: Visibility = Visibility.Visible
  sid: string = ''
  name: string = ''
  selected: boolean = false
  showonstate: string = 'normal'
  focus: boolean = false
  visible: boolean = false
  border: BorderOptions = {}   //模拟selected选中效果

  constructor(ctx: NativeRenderContext) {
    super(ctx)
    LogUtils.d(this.TAG, "constructor")
    this.initCallbacks()
    this.src = ""
  }

  //selected选中时加蓝色边框，不选中时恢复css初始边框
  private setBorder() {
    if (this.selected === true) {
      this.border.width = 2;
      this.border.color = Color.Blue
    } else {
      this.border.width = this.cssBorder?.width;
      this.border.color = this.cssBorder?.color;
    }
  }

  private showOnState() {
    if (this.showonstate == 'normal') {
      //不做处理
    } else if (this.showonstate == 'selected') {
      //选中显示，未选中隐藏
      if (this.selected === true) {
        this.visibility = Visibility.Visible
      } else {
        this.visibility = Visibility.Hidden
      }
    } else if (this.showonstate == 'focused') {
      //聚焦显示，失焦隐藏
      if (this.focus === true) {
        this.visibility = Visibility.Visible
      } else {
        this.visibility = Visibility.Hidden
      }
    }
  }

  private setResizeMode(pvalue: string) {
    LogUtils.d(this.TAG, "setResizeMode")
    switch (pvalue) {
      case 'contain':
        this.cssResizeMode = ImageFit.Contain
        break;
      case 'cover':
        this.cssResizeMode = ImageFit.Cover
        break;
      case 'center':
        this.cssResizeMode = ImageFit.ScaleDown
        break;
      case 'origin':
        this.cssResizeMode = ImageFit.None
        break;
      case 'repeat':
        this.cssResizeMode = ImageFit.ScaleDown
        this.imageRepeat = ImageRepeat.XY
        break;
      case 'fitXY':
        this.cssResizeMode = ImageFit.Fill
        break;
      default:
        this.cssResizeMode = ImageFit.Fill
        break;
    }
  }

  private setTvTintColorBlendMode(propValue: HippyAny){
    LogUtils.d(this.TAG,"setTvTintColorBlendMode")
    this.cssPreTvTintColorBlendMode = this.cssTvTintColorBlendMode
    let blendMode = HRValueUtils.getNumber(propValue)
    switch (blendMode){
      case 0:
        this.cssTvTintColorBlendMode = TvTintColorBlendMode.CLEAR
        break;
      case 1:
        this.cssTvTintColorBlendMode = TvTintColorBlendMode.SRC
        break;
      case 2:
        this.cssTvTintColorBlendMode = TvTintColorBlendMode.DST
        break;
      case 3:
        this.cssTvTintColorBlendMode = TvTintColorBlendMode.SRC_OVER
        break;
      case 4:
        this.cssTvTintColorBlendMode = TvTintColorBlendMode.DST_OVER
        break;
      case 5:
        this.cssTvTintColorBlendMode = TvTintColorBlendMode.SRC_IN
        break;
      case 6:
        this.cssTvTintColorBlendMode = TvTintColorBlendMode.DST_IN
        break;
      case 7:
        this.cssTvTintColorBlendMode = TvTintColorBlendMode.SRC_OUT
        break;
      case 8:
        this.cssTvTintColorBlendMode = TvTintColorBlendMode.DST_OUT
        break;
      case 10:
        this.cssTvTintColorBlendMode = TvTintColorBlendMode.DST_ATOP
        break;
      case 11:
        this.cssTvTintColorBlendMode = TvTintColorBlendMode.XOR
        break;
      case 12:
        this.cssTvTintColorBlendMode = TvTintColorBlendMode.ADD
        break;
      case 13:
        this.cssTvTintColorBlendMode = TvTintColorBlendMode.MULTIPLY
        break;
      case 14:
        this.cssTvTintColorBlendMode = TvTintColorBlendMode.SCREEN
        break;
      case 15:
        this.cssTvTintColorBlendMode = TvTintColorBlendMode.OVERLAY
        break;
      case 16:
        this.cssTvTintColorBlendMode = TvTintColorBlendMode.DARKEN
        break;
      case 17:
        this.cssTvTintColorBlendMode = TvTintColorBlendMode.LIGHTEN
        break
      case 9:
      default:
        this.cssTvTintColorBlendMode = TvTintColorBlendMode.SRC_ATOP
        break;
    }
  }

  private setColorFilterMatrix(){
    LogUtils.d(this.TAG,"setColorFilterMatrix")
    if (this.cssTintColor.length != 1) {
      let matrixColor = [0] //RGBA
      matrixColor[0]= Number((this.cssTintColor[0]/0xff).toFixed(2))
      matrixColor[1]= Number((this.cssTintColor[1]/0xff).toFixed(2))
      matrixColor[2]= Number((this.cssTintColor[2]/0xff).toFixed(2))
      matrixColor[3]= Number((this.cssTintColor[3]/0xff).toFixed(2))
      switch (this.cssTvTintColorBlendMode){
        case TvTintColorBlendMode.CLEAR:
          this.cssColorFilter = [
            0,  0,  0,  0,  0,
            0,  0,  0,  0,  0,
            0,  0,  0,  0,  0,
            0,  0,  0,  0,  0]
          break
        case TvTintColorBlendMode.SRC:
          this.cssColorFilter = [
            0,  0,  0,  0,  matrixColor[0],
            0,  0,  0,  0,  matrixColor[1],
            0,  0,  0,  0,  matrixColor[2],
            0,  0,  0,  0,  matrixColor[3]]
          break
        case TvTintColorBlendMode.DST:
          this.cssColorFilter = [
            1,  0,  0,  0,  0,
            0,  1,  0,  0,  0,
            0,  0,  1,  0,  0,
            0,  0,  0,  1,  0]
          break
        case TvTintColorBlendMode.SRC_OVER:
          break
        case TvTintColorBlendMode.DST_OVER:
          break
        case TvTintColorBlendMode.SRC_IN:
          break
        case TvTintColorBlendMode.DST_IN:
          break
        case TvTintColorBlendMode.SRC_OUT:
          break
        case TvTintColorBlendMode.DST_OUT:
          break
        case TvTintColorBlendMode.DST_ATOP:
          break
        case TvTintColorBlendMode.XOR:
          break
        case TvTintColorBlendMode.MULTIPLY:
          break
        case TvTintColorBlendMode.SCREEN:
          break
        case TvTintColorBlendMode.ADD:
          break
        case TvTintColorBlendMode.OVERLAY:
          break
        case TvTintColorBlendMode.DARKEN:
          break
        case TvTintColorBlendMode.LIGHTEN:
          break
        case TvTintColorBlendMode.SRC_ATOP:
          this.cssColorFilter = [
            1-matrixColor[3], 0, 0, 0, matrixColor[0]*matrixColor[3],
            0, 1-matrixColor[3], 0, 0, matrixColor[1]*matrixColor[3],
            0, 0, 1-matrixColor[3], 0, matrixColor[2]*matrixColor[3],
            0, 0, 0, 1, 0]
          break
        default:
          break
      }
    }
  }

  setProp(propKey: string, propValue: HippyAny | HippyRenderCallback): boolean {
    LogUtils.d(this.TAG, `${ propKey }: ${ JSON.stringify(propValue) }`)
    switch (propKey) {
      case 'visible':
        this.visible = HRValueUtils.getBoolean(propValue as HippyAny, false);
        switch (this.visible) {
          case true: {
            this.visibility = Visibility.Visible;
            break;
          }
          case false: {
            this.visibility = Visibility.Hidden;
            break;
          }
        }
        return true;
      case 'selected':
        this.selected = HRValueUtils.getBoolean(propValue as HippyAny, false);
        // this.setBorder();
        return true;
      case 'showOnState':
        this.showonstate = HRValueUtils.getString(propValue as HippyAny);
        this.showOnState();
        return true;
      case 'name':
        this.name = HRValueUtils.getString(propValue as HippyAny);
        return true;
      case HRNodeProps.WIDTH:
        if (this.isImageSpan()) {
          this.cssWidth = HRValueUtils.getNumber(propValue as HippyAny);
        }
        return true;
      case HRNodeProps.HEIGHT:
        if (this.isImageSpan()) {
          this.cssHeight = HRValueUtils.getNumber(propValue as HippyAny);
        }
        return true;
      case HRNodeProps.VERTICAL_ALIGN:
        if(this.isImageSpan()) {
          let t = HRValueUtils.getString(propValue as HippyAny);
          switch (t) {
            case "top":
              this.spanVerticalAlign = ImageSpanAlignment.TOP;
              break;
            case "middle":
              this.spanVerticalAlign = ImageSpanAlignment.CENTER;
              break;
            case "bottom":
              this.spanVerticalAlign = ImageSpanAlignment.BOTTOM;
              break;
            case "baseline":
              this.spanVerticalAlign = ImageSpanAlignment.BASELINE;
              break;
          }
        }
        return true;
      case 'src':
        {
          this.cssSrc = HRValueUtils.getString(propValue as HippyAny)
          this.fetchImage()
        }
        return true
      case 'resizeMode':
        {
          let pvalue = HRValueUtils.getString(propValue as HippyAny)
          this.setResizeMode(pvalue)
        }
        return true
      case 'defaultSource':
        {
          let cssAlt = HRValueUtils.getString(propValue as HippyAny)
          this.cssAlt = this.convertToLocalPathIfNeeded(cssAlt)
        }
        return true
      case 'tintColor'://ARGB
        {
          let intColor = HRValueUtils.getNumber(propValue as HippyAny)
          this.cssTintColor[0] = (intColor >> 16) & 0xff   //red
          this.cssTintColor[1] = (intColor >> 8) & 0xff    //green
          this.cssTintColor[2] = intColor & 0xff           //blue
          this.cssTintColor[3] = (intColor >> 24) & 0xff   //alpha
          this.setColorFilterMatrix()
        }
        return true
      case 'TvTintColorBlendMode':
        let blendMode = HRValueUtils.getNumber(propValue as HippyAny)
        this.setTvTintColorBlendMode(blendMode)
        if (this.cssTvTintColorBlendMode != this.cssPreTvTintColorBlendMode) {
          this.setColorFilterMatrix()
        }
        return true
      case 'capInsets':
        let map = HRValueUtils.getMap(propValue as HippyAny)
        if (map) {
          let left = Math.round(HRValueUtils.getNumber(map.get("left")))
          let top = Math.round(HRValueUtils.getNumber(map.get("top")))
          let right = Math.round(HRValueUtils.getNumber(map.get("right")))
          let bottom = Math.round(HRValueUtils.getNumber(map.get("bottom")))
          this.resizable = { slice: { top: top, right: right, bottom: bottom, left: left }}
        } else {
          this.resizable = null
        }
        return true
      case 'draggable':
        let draggable = HRValueUtils.getBoolean(propValue as HippyAny, false)
        this.draggable = draggable;
        return true

      case HRNodeProps.VISIBILITY:
        {
          let visibility = propValue as string
          switch (visibility) {
            case 'visible': {
              this.visibility = Visibility.Visible
              break
            }
            case 'invisible': {
              this.visibility = Visibility.Hidden
              break
            }
            case 'gone': {
              this.visibility = Visibility.None
              break
            }
          }
        }
        return true

      case 'sid':
        {
          this.sid = propValue as string
        }
        return true

      default:
        break
    }
    return super.setProp(propKey, propValue as HippyAny)
  }

  isImageSpan(): boolean {
    if(this.parentView && this.parentView.viewType == "Text") {
      return true;
    }
    return false;
  }

  protected updateRenderViewFrame(frame: HRRect, padding: HRPadding | null): void {
    if(this.isImageSpan()) {
      if(frame.x != 0 || frame.y != 0) { // c 测得span的位置
        this.cssPositionX = frame.x
        this.cssPositionY = frame.y
      }
      return;
    }
    super.updateRenderViewFrame(frame, padding)
  }

  private initCallbacks() {
    if (!this.onCompleteCallback) {
      this.onCompleteCallback = (event) => {
        if (event?.loadingStatus !== 1) {
          return
        }
        // send onLoad event
        HREventUtils.sendComponentEvent(this.ctx, this.tag, HREventUtils.EVENT_IMAGE_ON_LOAD, null)
        let params = new Map<string, HippyAny>()
        params.set("success", 1)
        let imageSize = new Map<string, number>()
        imageSize.set("width", event?.width)
        imageSize.set("height", event?.height)
        params.set("image", imageSize)
        // send onLoadEnd event
        HREventUtils.sendComponentEvent(this.ctx, this.tag, HREventUtils.EVENT_IMAGE_LOAD_END, params as HippyAny)
      }
    }
    if (!this.onErrorCallback) {
      this.onErrorCallback = (error: ImageError) => {
        LogUtils.d(this.TAG, `onErrorCallback, w: ${error.componentWidth}, h: ${error.componentHeight}, msg: ${error.message}`)
        // send onError event
        HREventUtils.sendComponentEvent(this.ctx, this.tag, HREventUtils.EVENT_IMAGE_LOAD_ERROR, null)
        let params = new Map<string, number>()
        params.set("success", 0)
        // send onLoadEnd event
        HREventUtils.sendComponentEvent(this.ctx, this.tag, HREventUtils.EVENT_IMAGE_LOAD_END, params)
      }
    }
  }

  fetchImage() {
    LogUtils.d(this.TAG, `fetchImage enter.`)
    if (!this.cssSrc || typeof this.cssSrc !== 'string') {
      return
    }
    if (this.cssSrc.startsWith(HRTvImageView.BASE64_IMAGE_PREFIX)) {
      this.src = this.cssSrc
      return
    } else if (this.cssSrc.startsWith(HRTvImageView.RAW_IMAGE_PREFIX)) {
      this.src = this.convertToLocalPath(this.cssSrc)
      this.src = $rawfile(this.src)
      return
    } else if (UrlUtils.isWebUrl(this.cssSrc)) {
      LogUtils.d(this.TAG, `fetchImage. isWebUrl cssSrc: ${JSON.stringify(this.cssSrc)}, currentSrc: ${JSON.stringify(this.src)}`)
      this.src = this.cssSrc
      return
    }

    // for asset:/xxx
    let src = this.cssSrc
    let listener: ImageRequestListener = {
      onRequestStart: (imageData: ImageDataSupplier) => {},
      onRequestSuccess: (imageData: PixelMap) => {
        this.src = imageData
      },
      onRequestFail: () => {
        // this.src = src
      },
      onRequestProgress: (total: number, loaded: number) => {}
    }
    let imageLoader = this.ctx.getNativeRender()!.getImageLoader()!
    imageLoader.fetchImageAsync(src, listener, new HashMap<string, HippyAny>(), this.cssWidth, this.cssHeight)
  }

  getImage() {
    LogUtils.d(this.TAG,"getImage")
    if (typeof this.cssSrc == 'string') {
      if (this.cssSrc.startsWith(HRTvImageView.BASE64_IMAGE_PREFIX)) {
        return this.cssSrc
      } else if (this.cssSrc.startsWith(HRTvImageView.RAW_IMAGE_PREFIX)) {
        this.cssSrc = this.convertToLocalPath(this.cssSrc)
        LogUtils.d(this.TAG, "getImage: cssSrc= " + this.cssSrc)
        return $rawfile(this.cssSrc)
      }
    }
    return this.cssSrc
  }

  convertToLocalPath(uri: string): string {
    // hpfile://./assets/file_banner02.jpg
    if (uri != null && uri.startsWith("hpfile://")) {
      let relativePath = uri.replace("hpfile://./", "");
      let bundlePath = this.ctx.getNativeRender().getBundlePath()
      bundlePath = bundlePath.replace("asset:/", "")
      return bundlePath.substring(0, bundlePath.lastIndexOf("/") + 1) + relativePath
    }
    return uri
  }

  call(method: string, params: Array<HippyAny>, callback: HippyRenderCallback | null): void {
    LogUtils.d(this.TAG, "call. method: " + JSON.stringify(method) + ", params: " + JSON.stringify(params))
    this.uiCtx?.runScopedTask(() => {
      switch (method) {
        case "setSrc":
          {
            LogUtils.d(this.TAG, `call. setSrc enter.`)
            this.cssSrc = params[0] as string
            this.fetchImage()
          }
          break;

        default:
          break;
      }
      switch (method) {
        case "setFocus":
          {
            this.focus = params[0] as boolean;
            const id = params[1] as string;
            LogUtils.d(this.TAG, "setFocus："+this.focus);
            if (this.focus) {
              focusControl.requestFocus(this.name);
              LogUtils.d(this.TAG, "requestFocus："+focusControl.requestFocus(this.name));
            } else {
              this.uiCtx?.getFocusController().clearFocus()
            }
            this.showOnState();
          }
          break;
        default:
          break;
      }
    })
  }
}

@Component
export struct HRTvImage {
  @ObjectLink renderView: HRTvImageView
  private readonly TAG = "HRTvImage"

  aboutToAppear(): void {
    LogUtils.d(this.TAG, "aboutToAppear enter")
    this.renderView.uiCtx = this.getUIContext()
  }

  build() {
    Image(this.renderView.src)
      .applyRenderViewBaseAttr(this.renderView)
      .alt(this.renderView.cssAlt)
      .objectFit(this.renderView.cssResizeMode)
      .objectRepeat(this.renderView.imageRepeat)
      .colorFilter(this.renderView.cssColorFilter)
      .resizable(this.renderView.resizable)
      .draggable(this.renderView.draggable)
      .onComplete(this.renderView.onCompleteCallback)
      .onError(this.renderView.onErrorCallback)
      .visibility(this.renderView.visibility)
      .id(this.renderView.sid)
      .key(this.renderView.name)
      // .border(this.renderView.border)
      .onFocus(()=>{
        LogUtils.d(this.TAG, "onFocus，name:"+this.renderView.name);
      })
      .onBlur(()=>{
        LogUtils.d(this.TAG, "onBlur，name:"+this.renderView.name);
      })
  }
}

// base props for all components
@Extend(Image)
function applyRenderViewBaseAttr($$: HippyRenderBaseView) {
  .key(HIPPY_COMPONENT_KEY_PREFIX + $$.tag)
  .backgroundColor($$.cssBackgroundColor)
  .position({x: $$.cssPositionX, y: $$.cssPositionY})
  .size({width:$$.cssWidth, height: $$.cssHeight})
  .opacity($$.cssOpacity)
  .clip($$.cssOverflow)
  .visibility(($$ as HippyRenderBaseView).cssVisibility) // must add as, otherwise the compiler has error
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
