import { QTBaseComponentView } from "../components/QTBaseComponentView";
import { QTBaseView, QTView } from "../QTTypes";

export class QTCompatUtil{

  static getQTBaseView(view : QTView | null) : QTBaseView | null {
    if(view instanceof QTBaseComponentView){
      return view;
    }

    return null;
  }
}