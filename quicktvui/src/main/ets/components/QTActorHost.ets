import { QTView } from "../QTTypes"
import { QTViewActor } from "./QTViewActor"
export interface QTActorHost{
  readonly viewActor : QTViewActor
  notifyChildSizeChanged(child:QTView,changedView:QTView,width: number, height: number) : void
}