import { IllegalStateException } from '@ohos/zxing';
import {HippyRenderBaseView,HippyMap,HippyAny,NativeRenderContext,HRRect} from 'hippy'
import { HRValueUtils } from '../../HRValueUtils';
import {createRenderViewFromCreator} from '../../polifill/QTViewManager'
import { NodeUtils } from '../../utils/NodeUtils';
import { TemplateCodeParser } from './TemplateCodeParser'
import { QTBaseComponentView } from '../QTBaseComponentView';
import { LayoutAttach } from './LayoutAttach';
import { QTPixelUtil } from '../../utils/QTPixelUtil';
import { QTFastFlexView } from './QTFastFlexView';
import { QTLog } from '../../utils/QTLog';
import { TAG_FASTLIST, TAG_FOCUS, TAG_LAYOUT, TAG_REUSE } from '../../Constant';
import { QTFastItemView } from './QTFastItemView';
import { QTMap, QTView } from '../../QTTypes';
import { ExtendUtil } from '../../utils/ExtendUtil';
import { QTTextView } from '../text/QTTextView';
import { CommonUtils } from '../../utils/CommonUtils';
import { QTFastListView } from './QTFastListView';
import { VirtualViewRegistry } from './VirtualViewRegistry';


export class BuildResult{
  renderView : HippyRenderBaseView | null = null;
  updates : Array<PathUpdate> | null = null;
}

// class Props{
//   pendingProps : Map<string, HippyAny> | null = null;
//   basicProps : Map<string, HippyAny> | null = null;
// }

export class PathUpdate{
  renderView : HippyRenderBaseView;
  props : HippyMap;
  pendingProps : HippyMap;
  // layout: number[] = [-1,-1,-1,-1];
  constructor(renderView: HippyRenderBaseView, props: HippyMap) {
    this.renderView = renderView;
    this.props = props;
    this.pendingProps = new Map()
  }
}

export class PendingPathUpdate{
  renderView : HippyRenderBaseView;
  pendingProps : HippyMap;
  // layout: number[] = [-1,-1,-1,-1];
  constructor(renderView: HippyRenderBaseView, props: HippyMap) {
    this.renderView = renderView;
    this.pendingProps = props;
  }
}

export class TemplateViewManager{
  constructor() {
  }


    static applyPatchUpdate(updates:Array<PathUpdate> | null){
    updates?.map((p)=>{
      p.props.forEach((value,key)=>{
        //更新所有属性
        let handle = false
        switch (key){
          case 'showIf':
            p.renderView.cssVisibility = value ? Visibility.Visible : Visibility.Hidden
            handle = true;
            break;
        }
        if(!handle){
          if(p.renderView instanceof QTTextView){
            QTLog.i(TAG_REUSE,`applyPatchUpdate on bindItem key:${key},value:${value},old Text:${p.renderView.text}`)
          }else{
            QTLog.i(TAG_REUSE,`applyPendingProp on bindItem  key:${key},value:${value},view:${ExtendUtil.debugView(p.renderView)}`)
          }
          p.renderView.setProp(key,value)
        }
      })
    })
  }

  static applyPendingProp(rendView : QTView,pendingProps : QTMap , itemData : QTMap){
    pendingProps.forEach((value,key)=>{
      let dataFromValue = TemplateCodeParser.getValueFromCode(itemData,value as string)
      if(rendView instanceof QTTextView){
        QTLog.i(TAG_REUSE,`applyPendingProp key:${key},dataFromValue:${dataFromValue},old Text:${rendView.text}`)
      }else{
        QTLog.i(TAG_REUSE,`applyPendingProp key:${key},dataFromValue:${dataFromValue},view:${ExtendUtil.debugView(rendView)}`)
      }
      rendView.setProp(key,dataFromValue)
    })
  }



  applyPendingPropsPatchUpdate(updates:Array<PathUpdate> | null){
    updates?.map((p)=>{
      p.props.forEach((value,key)=>{
        // if(key == 'text'){
        //   console.log(TAG_FASTLIST,`updates p :${p.renderView.viewType},prop:${key},value:${value},position:${position}`)
        // }
        //更新所有属性
        let handle = false
        switch (key){
          case 'showIf':
            p.renderView.cssVisibility = value ? Visibility.Visible : Visibility.Hidden
            handle = true;
            break;
        }
        if(!handle){
          p.renderView.setProp(key,value)
        }
      })
    })
  }



   buildRenderView(template:HippyRenderBaseView | null, templateProps:HippyMap,itemData : HippyMap,index:number) : PathUpdate | null{
    if(!template){
      return null;
    }
    let rv = createRenderViewFromCreator(template.ctx,template.viewType)
    if(!rv){
      return null;
    }
    VirtualViewRegistry.getInstance().registerView(rv)
    this.applyInit(rv,template,templateProps,index)
    let style = new Map<String,HippyAny>()
    // toUpdate.forEach((value,key)=>{
    //   console.log(QUICKTVUI_TAG,`gatherToUpdateMap viewType:${rv?.viewType} key:${key},value:${CommonUtils.hippyAny2String(value)}`)
    // })
    // toUpdate?.forEach((value,key)=>{
    //   rv?.setProp(key,value)
    // })
    return this.gatherToUpdateMap(rv,templateProps,itemData,style)
  }

  static applyLayoutTraverse(renderView:HippyRenderBaseView | null){
    if(renderView == null){
      return;
    }
    if(renderView instanceof QTBaseComponentView && !renderView.isVirtual){
      if(!renderView.isVirtual && !(renderView instanceof QTFastItemView)){
        return;
      }
    }
    TemplateViewManager.applyLayout(renderView);
    if(renderView.children){
      renderView.children.map((child)=>{
        TemplateViewManager.applyLayoutTraverse(child)
      })
    }
  }

  static applyLayoutTraverse4AutoSize(renderView:HippyRenderBaseView | null,skipView:HippyRenderBaseView | null){
    if(renderView == null){
      return;
    }
    TemplateViewManager.applyLayout4AutoSize(renderView,skipView);
    if(renderView.children){
      renderView.children.map((child)=>{
        TemplateViewManager.applyLayoutTraverse4AutoSize(child,skipView)
      })
    }
  }

  static applyPositionTraverse(renderView:HippyRenderBaseView | null){
    if(renderView == null){
      return;
    }
    TemplateViewManager.applyPosition(renderView);
    if(renderView.children){
      renderView.children.map((child)=>{
        TemplateViewManager.applyPositionTraverse(child)
      })
    }
  }

  static applyPosition(renderView: HippyRenderBaseView) {
    let attach = LayoutAttach.obtainLayoutAttach(renderView);
    // let layout : HRRect= new HRRect(attach.getLeft(),attach.getTop(),attach.fixedWidth > 0 ? attach.fixedWidth: attach.getWidth(),attach.fixedHeight > 0 ? attach.fixedHeight :  attach.getHeight());
    // // let layout : number[]= [attach.getLeft(),attach.getTop(), attach.fixedWidth > 0 ? attach.fixedWidth: attach.getWidth(),attach.fixedHeight > 0 ? attach.fixedHeight :  attach.getHeight()];
    // QTLog.i(TAG_LAYOUT,`applyLayout:type:${attach.viewType},name:${attach.name},layout:[${layout.x},${layout.y},${layout.width},${layout.height}],this:${ExtendUtil.debugView(renderView)}`)
    // // QTPixelUtil.setRenderViewLayout(renderView,layout)
    // QTPixelUtil.setScaledRenderViewFrame(renderView,layout,null)
    renderView.cssPositionX = attach.getLeft()
    renderView.cssPositionY = attach.getTop()
  }


  static applyLayout(renderView:HippyRenderBaseView){
    let attach = LayoutAttach.obtainLayoutAttach(renderView);
    // let layout : HRRect= new HRRect(attach.getLeft(),attach.getTop(),attach.fixedWidth > 0 ? attach.fixedWidth: attach.getWidth(),attach.fixedHeight > 0 ? attach.fixedHeight :  attach.getHeight());
    // QTPixelUtil.setRenderViewFrameDevSize(renderView,layout,null)
    let layout : number[]= [attach.getLeft(),attach.getTop(), attach.fixedWidth > 0 ? attach.fixedWidth: attach.getWidth(),attach.fixedHeight > 0 ? attach.fixedHeight :  attach.getHeight()];
    QTPixelUtil.setRenderViewLayout(renderView,layout)
    //QTLog.i(TAG_LAYOUT,`applyLayout:type:${attach.viewType},name:${attach.name},layout:[${layout.x},${layout.y},${layout.width},${layout.height}],this:${ExtendUtil.debugView(renderView)}`)
    //由于attach里存放的都是dev尺寸，所以这里要进行缩放

  }

  static applyLayout4AutoSize(renderView:QTView,changedView : QTView | null){
    let attach = LayoutAttach.obtainLayoutAttach(renderView);
    // let layout : HRRect= new HRRect(attach.getLeft(),attach.getTop(),attach.fixedWidth > 0 ? attach.fixedWidth: attach.getWidth(),attach.fixedHeight > 0 ? attach.fixedHeight :  attach.getHeight());
    // QTPixelUtil.setRenderViewFrameDevSize(renderView,layout,null)
    let layout : number[]= [attach.getLeft(),attach.getTop(), attach.fixedWidth > 0 ? attach.fixedWidth: attach.getWidth(),attach.fixedHeight > 0 ? attach.fixedHeight :  attach.getHeight()];
    QTPixelUtil.setRenderViewLayout(renderView,layout)
    //由于attach里存放的都是dev尺寸，所以这里要进行缩放
    // if(renderView instanceof QTTextView){
    //   QTLog.d(TAG_LAYOUT,`applyLayout4AutoSize on Text:${renderView.text},width${layout[2]}`)
    // }

  }

  applyInit(renderView : HippyRenderBaseView,template: HippyRenderBaseView,templateProps:HippyMap,childIndex:number) : HippyRenderBaseView{
    const attach  = LayoutAttach.obtainLayoutAttach(renderView);
    // renderView.attachedInfo = attach;
    if(template instanceof QTTextView){
      QTLog.i(TAG_LAYOUT,`applyInit copy style node template templateProps:${CommonUtils.hippyAny2String(templateProps)}`)
    }

    attach.copyStyleNode(template.ctx.getInstanceId(),template.ctx.getRootId(),template.tag)
    renderView.viewType = template.viewType
    attach.viewType = renderView.viewType;
    renderView.tag = childIndex
    this.applyBasicStyle(renderView,templateProps)
    // console.log(TAG_QUICKTVUI,`applyInit viewType:${template.viewType},size:{${template.cssWidth},${template.cssHeight}} name:${LayoutAttach.obtainLayoutAttach(renderView).name}`)
    if(renderView instanceof QTBaseComponentView){
      renderView.isVirtual = true;
      renderView.templateView = template;
      renderView.onCreateByTemplate(template)
    }
    attach.isVirtual = true;
    // CommonUtils.printObject(templateProps,'applyBasicStyle')
    return renderView
  }


  applyBasicStyle(rendView:HippyRenderBaseView | null,styleMap: HippyMap){
    if(rendView){
      styleMap.forEach((value,key)=>{
        if(!TemplateCodeParser.parsePendingProp(value)){//不处理模板code的情况
          switch (key){
            case 'sid':
              let sid = HRValueUtils.getString(value)
              LayoutAttach.obtainLayoutAttach(rendView).sid = sid
              if(rendView instanceof QTBaseComponentView){
                if(sid){
                  rendView.sid = sid;
                }else{
                  rendView.sid = ''
                }
              }
              break;
            case 'name':
              let name = HRValueUtils.getString(value);
              LayoutAttach.obtainLayoutAttach(rendView).name = name;
              //rendView.setProp(key,value)
              if(rendView instanceof QTBaseComponentView){
                if(name){
                  rendView.name = name;
                }else{
                  rendView.name = ''
                }
              }
              break;
          }
        }
      })
    }
  }



  buildRenderViewTraverse(rootListId:number, ctx:NativeRenderContext | null, template : HippyRenderBaseView | null, templateProps:HippyMap,itemData : HippyMap,parent: HippyRenderBaseView | null,index:number,
    updates:Array<PathUpdate>
  ): HippyRenderBaseView | null{
    if(!ctx){
      return null;
    }
    let patch = this.buildRenderView(template,templateProps,itemData,index)
    if(!patch){
      return null;
    }
    // QTLog.d(TAG_FASTLIST,`buildRenderViewTraverse view :${ExtendUtil.debugView(patch.renderView)}`)
    if(patch.renderView instanceof QTFastFlexView){
      QTLog.d(TAG_FASTLIST,`buildRenderViewTraverse fastFlexView setRootListID:${rootListId}`)
      if(rootListId){
        patch.renderView.setRootListID(rootListId)
      }else{
        QTLog.fatal(TAG_FASTLIST,`buildRenderViewTraverse fastFlexView error rootListID is -1`)
      }
    }
    if(patch.renderView instanceof QTFastListView){
      if(rootListId){
        patch.renderView.mHandleEventNodeId = rootListId
      }
    }
    LayoutAttach.obtainLayoutAttach(patch.renderView).virtualExtra.rootListId = rootListId;
    updates.push(patch)
    if(parent){
      parent.addSubRenderView(patch.renderView,index)
      //添加layout node
      LayoutAttach.obtainLayoutAttach(parent).insertChild(LayoutAttach.obtainLayoutAttach(patch.renderView),index)
    }
    template?.children?.map((child,index)=>{
      let childNode = NodeUtils.getNodeById(ctx,child.tag)
      if(!childNode){
        throw new IllegalStateException(`child node is null tag :${child.tag},viewType:${child.viewType}`)
      }
      this.buildRenderViewTraverse(rootListId,ctx,child,childNode!!.props!!,itemData,patch!!.renderView,index,updates)
    })
    return patch.renderView
  }

  gatherToUpdateMapTraverse(rendView:HippyRenderBaseView , template : HippyRenderBaseView | null,templateProps:HippyMap,itemData : HippyMap,style : Map<String,HippyAny> | null
    ,updates:Array<PathUpdate>,singleton : boolean){
    let u = singleton ? this.gatherToUpdateMap4Singleton(rendView,templateProps,itemData,style) :  this.gatherToUpdateMap(rendView,templateProps,itemData,style)
    if(u){
      updates.push(u)
    }
    template?.children?.map((childTemplate,index)=>{
      let childNode = NodeUtils.getNodeById(rendView.ctx,childTemplate.tag)
      //let childTemplate = template?.children[index]
      let childView = rendView.children[index]
      if(!childView || !childTemplate || !childNode?.props){
        throw new IllegalStateException(`child node is null tag :${childTemplate.tag},viewType:${childTemplate.viewType}`)
      }
      this.gatherToUpdateMapTraverse(childView,childTemplate,childNode.props,itemData,style,updates,singleton)
    })
  }

  gatherToUpdateMap(rendView:HippyRenderBaseView ,templateProps:HippyMap,itemData : HippyMap,style : Map<String,HippyAny> | null) : PathUpdate{
    let toUpdate = new Map<string, HippyAny>()
    let patch = new PathUpdate(rendView,toUpdate)
    templateProps.forEach((value,key)=>{
      if(!(TemplateCodeParser.PENDING_PROP_CREATE_IF === key)){
        if(TemplateCodeParser.isEquationProp(value)){
          let b = TemplateCodeParser.parseBooleanFromPendingProp(key,itemData,value)
          toUpdate.set(key,b)
          patch.pendingProps.set(key,value as string)
        }else{
          let pendingProp = TemplateCodeParser.parsePlaceholderProp(key,templateProps)
          if(pendingProp){
            //LayoutAttach.obtainLayoutAttach(rendView).pendingProps.set(key,pendingProp)
            let dataFromValue = TemplateCodeParser.getValueFromCode(itemData,pendingProp)
            // console.info(QUICKTVUI_TAG,`++put pendingProp key:${key},dataFromValue:${dataFromValue},pendingProp:${pendingProp} ,value:${value},data:${CommonUtils.hippyAny2String(dataFromValue)}`)
            //从${xx}取出dataFromValue数据
            patch.pendingProps.set(key,pendingProp as string)
            if(!this.handleCustomProps(key,dataFromValue,patch,true)){
              toUpdate.set(key,dataFromValue)
            }
          }else{
            // console.log(QUICKTVUI_TAG,`--gatherToUpdateMap discard key:${key},data:${CommonUtils.hippyAny2String(value)}`)
            // toUpdate.set(key,value)
            //原数据没有${xx}，直接按value处理
            if(!this.handleCustomProps(key,value,patch,false)){
              toUpdate.set(key,value)
            }
          }
        }
      }
    })
    return patch
  }

  gatherToUpdateMap4Singleton(rendView:HippyRenderBaseView ,templateProps:HippyMap,itemData : HippyMap,style : Map<String,HippyAny> | null) : PathUpdate{
    let toUpdate = new Map<string, HippyAny>()
    let patch = new PathUpdate(rendView,toUpdate)
    templateProps.forEach((value,key)=>{
      if(!(TemplateCodeParser.PENDING_PROP_CREATE_IF === key)){
        if(TemplateCodeParser.isEquationProp(value)){
          let b = TemplateCodeParser.parseBooleanFromPendingProp(key,itemData,value)
          toUpdate.set(key,b)
        }else{
          let pendingProp = TemplateCodeParser.parsePlaceholderProp(key,templateProps)
          if(pendingProp){
            let dataFromValue = TemplateCodeParser.getValueFromCode(itemData,pendingProp)
            // console.info(QUICKTVUI_TAG,`++put pendingProp key:${key},dataFromValue:${dataFromValue},pendingProp:${pendingProp} ,value:${value},data:${CommonUtils.hippyAny2String(dataFromValue)}`)
            //从${xx}取出dataFromValue数据
            if(!this.handleCustomProps(key,dataFromValue,patch,false)){
              toUpdate.set(key,dataFromValue)
            }
          }else{
            // console.log(QUICKTVUI_TAG,`--gatherToUpdateMap discard key:${key},data:${CommonUtils.hippyAny2String(value)}`)
            // toUpdate.set(key,value)
            //原数据没有${xx}，直接按value处理
            toUpdate.set(key,value)
          }
        }
      }
    })
    return patch
  }

  /**
   *
   * @param key
   * @param value
   * @param p
   * @param needDev2Vp ！！这里重点关注这个值，目前FastList类似${width},这种获取的数据，都需要转换成vp，而原始的例如从template拷贝出来的，都不需要转换，因为在vue层已经转换过，所以这里添加这个参数来区分
   * @returns
   */
  handleCustomProps(key:String,value:HippyAny,p:PathUpdate,needDev2Vp : boolean) : boolean{

    switch (key){
      case 'width':
        let width = QTPixelUtil.dev2VpIfNeed(value,needDev2Vp)
        LayoutAttach.obtainLayoutAttach(p.renderView).setFixedWidth(width)
        return true;
      case 'height':
        let height = QTPixelUtil.dev2VpIfNeed(value,needDev2Vp)
        LayoutAttach.obtainLayoutAttach(p.renderView).setFixedHeight(height)
        return true;
      case 'translation':
        let ts = value as number[]
        let x = QTPixelUtil.dev2VpIfNeed(ts[0],needDev2Vp)
        let y = QTPixelUtil.dev2VpIfNeed(ts[1],needDev2Vp)
        LayoutAttach.obtainLayoutAttach(p.renderView).setPosition(x,y)
        return true;
      case 'style':
      case 'flexStyle':
        let style = HRValueUtils.getMap(value)
        if(style){
          let toStyle = needDev2Vp ? QTPixelUtil.styleDev2Vp(style) : style
          LayoutAttach.obtainLayoutAttach(p.renderView).setStyles(toStyle)
        }
        return true;
      case 'layout':
        let array = value as number[]
        if(array && array.length == 4 && LayoutAttach.obtainLayoutAttach(p.renderView)){
          let x = QTPixelUtil.dev2VpIfNeed(array[0],needDev2Vp)
          let y = QTPixelUtil.dev2VpIfNeed(array[1],needDev2Vp)
          let width = QTPixelUtil.dev2VpIfNeed(array[2],needDev2Vp)
          let height = QTPixelUtil.dev2VpIfNeed(array[3],needDev2Vp)
          LayoutAttach.obtainLayoutAttach(p.renderView).setPosition(x,y)
          LayoutAttach.obtainLayoutAttach(p.renderView).setFixedWidth(width)
          LayoutAttach.obtainLayoutAttach(p.renderView).setFixedHeight(height)
        }
        return true;
      case 'size':
        let size = value as number[]
        let sw = QTPixelUtil.dev2VpIfNeed(size[0],needDev2Vp)
        let sh = QTPixelUtil.dev2VpIfNeed(size[1],needDev2Vp)
        LayoutAttach.obtainLayoutAttach(p.renderView).setFixedWidth(sw)
        LayoutAttach.obtainLayoutAttach(p.renderView).setFixedHeight(sh)
        return true;
      case 'autoWidth':
        LayoutAttach.obtainLayoutAttach(p.renderView).isAutoWidth = true;
        LayoutAttach.obtainLayoutAttach(p.renderView).setFixedWidth(-1)
        return true;
      case 'autoHeight':
        LayoutAttach.obtainLayoutAttach(p.renderView).isAutoHeight = false;
        LayoutAttach.obtainLayoutAttach(p.renderView).setFixedHeight(-1)
        return true;
      case 'eventClick':
        // console.log(TAG_CLICK,`set eventClick view:${ExtendUtil.debugView(p.renderView)}`)
        LayoutAttach.obtainLayoutAttach(p.renderView).virtualExtra.eventClick = true;
        return true;
      case 'eventFocus':
        // console.log(TAG_CLICK,`set eventClick view:${ExtendUtil.debugView(p.renderView)}`)
        LayoutAttach.obtainLayoutAttach(p.renderView).virtualExtra.eventFocus = true;
        return true;
    }
    return false;
  }


}



