import {HippyMap} from 'hippy'
import { LayoutAttach } from '../components/fastlist/LayoutAttach';

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

}
