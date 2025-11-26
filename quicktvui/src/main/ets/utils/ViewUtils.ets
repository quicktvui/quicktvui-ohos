import { FastListUtils } from '../components/fastlist/FastListUtils';
import { QTBaseComponentView } from '../components/QTBaseComponentView';
import { TAG_CLICK, TAG_FASTLIST, TAG_LAYOUT, TAG_QUICKTVUI } from '../Constant';
import { QTView } from '../QTTypes';
import { ExtendUtil } from './ExtendUtil';
import { QTLog } from './QTLog';

import { QTItemRootView } from '../components/fastlist/QTItemRootView';
import { QTTextView } from '../components/text/QTTextView';

export class ViewUtils{
  static getTextGravity(gs : string) : TextAlign{
    //gs:  left|centerVertical
    //gs:  top|centerHorizontal

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

  static configGravity(gs : string,tx : QTTextView){

    if(gs == 'center'){
      tx.textAlign = TextAlign.Center
      tx.verticalAlign = Alignment.Center
    }else{
      let hAlign : TextAlign | null = null;
      let vAlign : Alignment | null  = null;
      if(gs.indexOf('|') > -1){
        //包括
        let aligns = gs.split('|'); // aligns[0]控制水平方向位置: left|start|right  aligns[0]控制垂直方向位置 top|center|bottom
        if(aligns[0] == "center"){
          aligns.reverse()//兼容 gravity="center|start"
        }
        hAlign = ViewUtils.getTextHorizontalGravity(aligns[0]);
        vAlign = ViewUtils.getTextVerticalGravity(aligns[1]);
        /*aligns.map((align,index)=>{
          if(align == 'center'){
            // hAlign = TextAlign.Center
            // vAlign = Alignment.Center
            let otherIndex = 1 - index
            let otherAlignString = aligns[otherIndex]

            // if(otherAlign == 'start'){
            //   hAlign = TextAlign.Start
            // }else if(otherAlign == 'end'){
            //   hAlign = TextAlign.End
            // }
            let hOtherAlign = ViewUtils.getTextHorizontalGravity(otherAlignString)
            if(hOtherAlign){
              //水平方向，center纵向生效
              hAlign = hOtherAlign
              vAlign = Alignment.Center
            }
            let vOtherAlign = ViewUtils.getTextVerticalGravity(otherAlignString)
            if(vOtherAlign){
              //纵向方法，center横向生效
              hAlign = TextAlign.Center
              vAlign = vOtherAlign
            }
          }else{
            if(!hAlign){
              hAlign = ViewUtils.getTextHorizontalGravity(align)
            }
            if(!vAlign){
              vAlign = ViewUtils.getTextVerticalGravity(align)
            }
          }
        })*/

      }else{
        if(!hAlign){
          hAlign = ViewUtils.getTextHorizontalGravity(gs)
        }
        if(!vAlign){
          vAlign = ViewUtils.getTextVerticalGravity(gs)
        }
      }
      if(hAlign){
        tx.textAlign = hAlign
      }
      if(vAlign){
        tx.verticalAlign = vAlign
      }
      QTLog.i('DebugTextView',`configGravity gs:${gs} hAlign:${hAlign},vAlign:${vAlign},text:${tx.text}`)


    }


  }


  static getTextVerticalGravity(gs : string) : Alignment | null{
    //gs:  left|centerVertical
    //gs:  top|centerHorizontal

    switch (gs){
      case  'center':
      case  'centerVertical':
        return Alignment.Center;
      case 'top':
        return Alignment.TopStart
      case 'bottom':
        return Alignment.BottomEnd
    }
    return null;
  }

  static getTextHorizontalGravity(gs : string) : TextAlign | null{
    //gs:  left|centerVertical
    //gs:  top|centerHorizontal

    switch (gs){
      case 'start':
      case 'left':
        return TextAlign.Start;
      case 'right':
        return TextAlign.End
      case 'centerHorizontal':
        return TextAlign.Center;
    }
    return null;
  }


  static handleClickEvent(event:ClickEvent,clickView:QTView){
    let handle = false;
    if(clickView.parentView instanceof QTItemRootView){
      QTLog.i(TAG_CLICK,`handleClickEvent clickView handle by parent QTItemRootView`)
      FastListUtils.handleItemClick(clickView.parentView)
      return;
    }
    if(clickView instanceof QTBaseComponentView){
      if(clickView.isVirtual){
        FastListUtils.handleItemClick(clickView)
        handle = true;
      }else{
        QTLog.w(TAG_CLICK,`handleClickEvent no handle view ! is Virtual :${ExtendUtil.debugView(clickView)}`)
      }
    }else{
      QTLog.w(TAG_CLICK,`handleClickEvent !clickView instanceof QTBaseComponentView:${ExtendUtil.debugView(clickView)}`)
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
