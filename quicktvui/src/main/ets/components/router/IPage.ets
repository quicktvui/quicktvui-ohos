import { FocusManager } from "../FocusManager";

export interface IPage{

  focusManager : FocusManager

  onPausePage() : void ;
  onResumePage(): void;

}