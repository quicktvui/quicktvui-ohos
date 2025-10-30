import {HippyMap} from 'hippy'
import { FastListUtils } from '../components/fastlist/FastListUtils';
import { LayoutAttach } from '../components/fastlist/LayoutAttach';
import { QTBaseComponentView } from '../components/QTBaseComponentView';
import { TAG_CLICK, TAG_QUICKTVUI } from '../Constant';
import { QTView } from '../QTTypes';
import { ExtendUtil } from './ExtendUtil';
import { QTLog } from './QTLog';
import { ArkTSUtils } from '@kit.ArkTS';
import { MeasureUtils, UIUtils } from '@kit.ArkUI';

export class ViewUtils{
  static getTextGravity(gs : string) : TextAlign{
    switch (gs){
      case  'center':
        return TextAlign.Center;
      case 'top':
      case 'bottom':
      case 'centerHorizontal':
      case 'centerVertical':
        return TextAlign.JUSTIFY
      case 'end':
        return TextAlign.End;
      default :
        return TextAlign.Start
    }
  }

  static handleClickEvent(event:ClickEvent,clickView:QTView){
    let handle = false;
    if(clickView instanceof QTBaseComponentView){
      if(clickView.isVirtual){
        FastListUtils.handleItemClick(clickView)
        handle = true;
      }
    }
    if(!handle){
      QTLog.d(TAG_CLICK,`handleClickEvent view:${ExtendUtil.debugView(clickView)},eventClick:${clickView.eventClick}`)
      // HRGestureDispatcher.handleClickEvent(this.ctx, this.tag, HRNodeProps.ON_CLICK)
      // if(clickView.eventClick){
      //   clickView.eventClick.
      // }
    }else{
      QTLog.fatal(TAG_CLICK,`handleClickEvent no handle view:${ExtendUtil.debugView(clickView)}`)
    }
  }

  static getGradientDirection(ori:number){
    let direction = GradientDirection.Bottom
    switch (ori){
      case 1:
        direction = GradientDirection.LeftBottom
        break;
      case 2:
        direction = GradientDirection.Left
        break;
      case 3:
        direction = GradientDirection.LeftTop
        break;
      case 4:
        direction = GradientDirection.Top
        break;
      case 5:
        direction = GradientDirection.RightTop
        break;
      case 6:
        direction = GradientDirection.Right
        break;
      case 7:
        direction = GradientDirection.RightBottom
        break;
        default :
          QTLog.fatal(TAG_QUICKTVUI,`getGradientDirection no map direction:${ori}`)
          break;
    }
    return direction
  }

  static colorStringToNumber(colorStr: string): number {
    if (!colorStr || typeof colorStr !== 'string') {
      return 0;
    }

    // 移除开头的 # 号
    let hex = colorStr.replace(/^#/, '');

    // 处理缩写格式 #abc -> #aabbcc, #abcd -> #aabbccdd
    if (hex.length === 3 || hex.length === 4) {
      hex = hex.split('').map(char => char + char).join('');
    }

    // 验证十六进制格式
    if (!/^[0-9A-Fa-f]{6,8}$/.test(hex)) {
      console.error(`Invalid color format: ${colorStr}`);
      return 0;
    }

    // 转换为数字
    return parseInt(hex, 16);
  }

}
