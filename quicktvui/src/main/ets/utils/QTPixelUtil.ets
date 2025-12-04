import {PixelUtil,HRRect,HippyRenderBaseView,HRPadding,HippyAny,HippyMap} from 'hippy'
import { TAG_LAYOUT, TAG_QUICKTVUI } from '../Constant';
import {display} from '@kit.ArkUI'
import { HRValueUtils } from '../HRValueUtils';
import { QTAny, QTMap } from '../QTTypes';
import { QTLog } from './QTLog';


export class QTPixelUtil{
  public static DEV_WIDTH = 1920.0;
  public static native_scale_enabled = true;

  public static dev2Vp(value: number) : number{
    let screenWidthDP = PixelUtil.px2dp(display.getDefaultDisplaySync().width)
    let scalePx = 2560 / QTPixelUtil.DEV_WIDTH
    // console.log(TAG_QUICKTVUI,`dp2px getDensityScale :${PixelUtil.getDensityScale()},getDensity:${PixelUtil.getDensity()},scalePx:${scalePx},screenWidthDP:${screenWidthDP}`)
    //Fixme 这里暂未实现适配
    // screenWidthDP :1280  display.getDefaultDisplaySync().width is 1920
    return (value * (screenWidthDP/QTPixelUtil.DEV_WIDTH));
  }

  public static dev2VpIfNeed(value: QTAny,need : boolean) : number{
    let dValue = QTPixelUtil.getDimensionValue(value)
    if(need){
      return QTPixelUtil.dev2Vp(dValue)
    }else{
      return dValue;
    }
  }

  public static vp2Vp(value: number): number{
    return value
  }

  public static vp2Dev(value:number) : number{
    let screenWidthDP = PixelUtil.px2dp(display.getDefaultDisplaySync().width)
    let scalePx =  QTPixelUtil.DEV_WIDTH / screenWidthDP
    return scalePx * value
  }

  public static vp2DevIfNeed(value:number){
    if(QTPixelUtil.native_scale_enabled){
      return value
    }else{
      return QTPixelUtil.vp2Dev(value)
    }
  }

  public static styleDev2Vp(style : QTMap) : Map<string, HippyAny>{
    let toStyle = new Map<string,QTAny>()
    style?.forEach((value,key)=>{
      switch (key){
        case 'width':
        case 'height':
        case 'top':
        case 'left':
        case 'right':
        case 'bottom':
        case 'marginLeft':
        case 'marginTop':
        case 'marginRight':
        case 'marginBottom':
        case 'paddingLeft':
        case 'paddingRight':
        case 'paddingTop':
        case 'paddingBottom':
        case 'x':
        case 'y':
        case 'fontSize':
          if (typeof value == 'number' || typeof value == 'string') {
            toStyle.set(key,QTPixelUtil.dev2Vp(QTPixelUtil.getDimensionValue(value)))
          }else{
            QTLog.e(TAG_LAYOUT,`styleDev2Vp error value not valid:${key},value:${value}`)
          }
          break;
        case 'style':
          let map = HRValueUtils.getMap(value)
          if(map){
            toStyle.set(key,QTPixelUtil.styleDev2Vp(map) as QTAny)
          }
          break;
          default:
            QTLog.w(TAG_LAYOUT,`styleDev2Vp skip key:${key}`)
            toStyle.set(key,value)
            break;
      }
    });
    return toStyle;
  }


  public static devRect2Vp(rect : HRRect){
    return new HRRect(QTPixelUtil.dev2Vp(rect.x),QTPixelUtil.dev2Vp(rect.y),QTPixelUtil.dev2Vp(rect.width),QTPixelUtil.dev2Vp(rect.height))
  }

  public static getScreenDevWidth(){
    return PixelUtil.px2dp(display.getDefaultDisplaySync().width)
  }

  public static getScreenDevHeight(){
    return PixelUtil.px2dp(display.getDefaultDisplaySync().height)
  }

  public static devPadding2Vp(padding: Padding){
    padding.left = QTPixelUtil.dev2Vp(padding.left ? padding.left as number : 0)
    padding.top = QTPixelUtil.dev2Vp(padding.top ? padding.top as number : 0)
    padding.right = QTPixelUtil.dev2Vp(padding.right ? padding.right as number : 0)
    padding.bottom = QTPixelUtil.dev2Vp(padding.bottom ? padding.bottom as number : 0)
  }

  public static setRenderViewFrameDevSize(view : HippyRenderBaseView | null, rect : HRRect | null, padding : HRPadding | null){
    if(view && rect){
      view.setRenderViewFrame(QTPixelUtil.devRect2Vp(rect),padding)
    }
  }

  public static setScaledRenderViewSize(view : HippyRenderBaseView | null, size : number[] ){
    if(view){
      view.setRenderViewFrame(QTPixelUtil.devRect2Vp(new HRRect(view.cssPositionX,view.cssPositionY,size[0],size[1])),null)
    }
  }

  public static setScaledRenderViewLayout(view : HippyRenderBaseView | null, layout : number[] ){
    if(view){
      view.setRenderViewFrame(QTPixelUtil.devRect2Vp(new HRRect(layout[0],layout[1],layout[2],layout[3])),null)
    }
  }


  public static setRenderViewLayout(view : HippyRenderBaseView | null, layout : number[] ){
    if(view){
      view.setRenderViewFrame(new HRRect(layout[0],layout[1],layout[2],layout[3]),null)
    }
  }

  public static setScaledRenderPadding(view : HippyRenderBaseView | null, padding : number[] ){
    if(view){
      view.setRenderViewFrame(new HRRect(view.cssPositionX,view.cssPositionY,view.cssWidth,view.cssHeight),new HRPadding(padding[0],padding[1],padding[2],padding[3]))
    }
  }

  public static getDimensionValue(value : HippyAny) : number{
    // return QTPixelUtil.dev2Vp(HRValueUtils.getNumber(value))
    return HRValueUtils.getNumber(value)
  }

  public static dev2VpStyle(style : HippyMap) : HippyMap{
    let result = new Map<string,HippyAny>()
    style.forEach((value,key)=>{
      switch (key){
      }
    })
    return result
  }
}
