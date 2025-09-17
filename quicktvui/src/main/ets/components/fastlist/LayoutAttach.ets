import { QTAttach } from '../QTAttach';
import {HippyRenderBaseView,HippyAny} from 'hippy'
import {QTNativeLayout} from 'libquicktvui.so'
import { HRValueUtils } from '../../HRValueUtils';
import { VirtualExtra } from './VirtualExtra';
import { QTView } from '../../QTTypes';

// constexpr static const char * PADDING_LEFT = "paddingLeft";
// constexpr static const char * PADDING_RIGHT = "paddingRight";
// constexpr static const char * PADDING_TOP = "paddingTop";
// constexpr static const char * PADDING_BOTTOM = "paddingBottom";

export class LayoutAttach extends QTAttach{
  private styleNode : QTNativeLayout | null = null;
  private scale:number = 0.75
  isAutoWidth : boolean = false;
  isAutoHeight : boolean = false;
  fixedWidth:number = -1;
  fixedHeight: number = -1;
  // fixedX : number = -1;
  // fixedY : number = -1;

  //others
  virtualExtra : VirtualExtra = new VirtualExtra();

  private style() : QTNativeLayout{
    if(!this.styleNode){
      this.styleNode = new QTNativeLayout();
    }
    return this.styleNode as QTNativeLayout;
  }

  copyStyleNode(instanceId: number, rootId: number, nodeId: number,){
    this.style().CopyStyleNode(instanceId,rootId,nodeId)
  }
  setStyles(style: Map<string, HippyAny> | null) {
    // console.error(TAG_LAYOUT, `LayoutAttach setStyle:${CommonUtils.hippyMap2String(style)},name:${this.name},viewType:${this.viewType}`)
    // 将 Map 转换为普通对象的正确方式
    style?.forEach((value,key)=>{
      switch (key){
        case 'width':
          this.fixedWidth = HRValueUtils.getNumber(value);
          break;
        case 'height':
          this.fixedHeight = HRValueUtils.getNumber(value);
          break;
      }
    })
    let styleObj: Record<string, HippyAny> = {};
    if (style) {
      style.forEach((value: HippyAny, key: string) => {
        // 使用正确的方式设置对象属性
        (styleObj as Record<string, HippyAny>)[key] = value;
      });
    }
    this.style().SetLayoutStyles(styleObj)  // 传递普通对象而不是 Map
  }

  setFixedWidth(value:number){
    this.fixedWidth = value;
    this.setWidth(value)
  }

  setFixedHeight(value:number){
    this.fixedHeight = value;
    this.setHeight(value);
  }

  setWidth(value : number){
    this.style().SetWidth(value )
    // console.debug(TAG_LAYOUT,`LayoutAttach setWidth:${value}`)
  }
  setHeight(value : number){
    this.style().SetHeight(value)
    // console.debug(TAG_LAYOUT,`LayoutAttach setHeight:${value}`)
  }

  // setPosition(number e){
  //   this.style().SetPosition()
  // }

  calculateLayout(parentWidth: number,parentHeight: number){
    this.style().CalculateLayout(parentWidth,parentHeight)
  }

  insertChild(attach:LayoutAttach,index: number){
    this.style().InsertChild(attach.style(),index)
  }

  removeChild(attach:LayoutAttach){
    this.style().RemoveChild(attach.style())
  }

  getWidth() : number{
    return this.style().GetWidth();
  }

  getHeight(): number{
    return this.style().GetHeight();
  }

  getStyleWidth() : number{
    return this.style().GetStyleWidth();
  }

  getStyleHeight(): number{
    return this.style().GetStyleHeight();
  }

  getPaddingLeft():number{
    return this.style().GetPadding(0);
  }
  getPaddingRight():number{
    return this.style().GetPadding(2);
  }
  getPaddingTop():number{
    return this.style().GetPadding(1);
  }
  getPaddingBottom():number{
    return this.style().GetPadding(3);
  }

  setPadding(top:number,left:number,right:number,bottom:number){
    let style: Map<string, HippyAny> = new Map()
    style.set('paddingLeft',left)
    style.set('paddingTop',top)
    style.set('paddingRight',right)
    style.set('paddingBottom',bottom)
    // console.info(TAG_LAYOUT,`setPadding:${CommonUtils.hippyMap2String(style)}`)
    this.setStyles(style)
  }


  getMarginLeft():number{
    return this.style().GetMargin(0);
  }
  getMarginRight():number{
    return this.style().GetMargin(2);
  }
  getMarginTop():number{
    return this.style().GetMargin(1);
  }
  getMarginBottom():number{
    return this.style().GetMargin(3);
  }

  getLeft() : number{
    return this.style().GetLeft();
  }
  getTop() : number{
    return this.style().GetTop();
  }
  getRight() : number{
    return this.style().GetRight();
  }
  getBottom() : number{
    return this.style().GetBottom();
  }
  setPosition(x: number,y : number){
    this.style().SetPosition(0,x)
    this.style().SetPosition(1,y)
  }

  public static obtainLayoutAttach(renderView:QTView) : LayoutAttach{
    if(renderView.attachedInfo instanceof LayoutAttach){
      return renderView.attachedInfo as LayoutAttach
    }
    renderView.attachedInfo = new LayoutAttach();
    return renderView.attachedInfo as LayoutAttach
  }

  public static findLayoutAttach(renderView:QTView) : LayoutAttach | null{
    if(renderView.attachedInfo instanceof LayoutAttach){
      return renderView.attachedInfo as LayoutAttach
    }
    return null;
  }



}
