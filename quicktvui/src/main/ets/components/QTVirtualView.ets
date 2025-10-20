import { QTView } from "../QTTypes";

export interface QTVirtualView{
  aboutToUpdate() : void;
  onCreateByTemplate(templateView : QTView) : void;
}