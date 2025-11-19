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
import { TAG_FASTLIST, TAG_REUSE } from '../../Constant';
import { QTFastItemView } from './QTFastItemView';
import { QTMap, QTView } from '../../QTTypes';
import { ExtendUtil } from '../../utils/ExtendUtil';
import { QTTextView } from '../text/QTTextView';


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

  static applyLayoutTraverseWithSkip(renderView:HippyRenderBaseView | null,skipView:HippyRenderBaseView | null){
    if(renderView == null){
      return;
    }
    if(skipView != renderView){
      TemplateViewManager.applyLayout(renderView);
    }
    if(renderView.children){
      renderView.children.map((child)=>{
        TemplateViewManager.applyLayoutTraverse(child)
      })
    }
  }



  static applyLayout(renderView:HippyRenderBaseView){
    let attach = LayoutAttach.obtainLayoutAttach(renderView);
    let layout : HRRect= new HRRect(attach.getLeft(),attach.getTop(),attach.fixedWidth > 0 ? attach.fixedWidth: attach.getWidth(),attach.fixedHeight > 0 ? attach.fixedHeight :  attach.getHeight());
    // let layout : HRRect= new HRRect(attach.getLeft(),attach.getTop(), attach.getWidth(),attach.getHeight());
    // console.info(TAG_LAYOUT,`applyLayout:type:${attach.viewType},name:${attach.name},layout:[${layout.x},${layout.y},${layout.width},${layout.height}]`)
    QTPixelUtil.setScaledRenderViewFrame(renderView,layout,null)
  }

  applyInit(renderView : HippyRenderBaseView,template: HippyRenderBaseView,templateProps:HippyMap,childIndex:number) : HippyRenderBaseView{
    const attach  = LayoutAttach.obtainLayoutAttach(renderView);
    // renderView.attachedInfo = attach;
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
              return;
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
              return ;
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
            if(!this.handleCustomProps(key,dataFromValue,patch)){
              toUpdate.set(key,dataFromValue)
            }
          }else{
            // console.log(QUICKTVUI_TAG,`--gatherToUpdateMap discard key:${key},data:${CommonUtils.hippyAny2String(value)}`)
            // toUpdate.set(key,value)
            //原数据没有${xx}，直接按value处理
            if(!this.handleCustomProps(key,value,patch)){
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
            if(!this.handleCustomProps(key,dataFromValue,patch)){
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

  handleCustomProps(key:String,value:HippyAny,p:PathUpdate) : boolean{
    switch (key){
      case 'width':
        // (p.renderView.attachedInfo as StyleAttach).style().setStyles()
        // p.layout[2] = HRValueUtils.getNumber(value);
        LayoutAttach.obtainLayoutAttach(p.renderView).setFixedWidth(QTPixelUtil.getDimensionValue(value))
        return true;
      case 'height':
        //p.layout[3] = HRValueUtils.getNumber(value);
        LayoutAttach.obtainLayoutAttach(p.renderView).setFixedHeight(QTPixelUtil.getDimensionValue(value))
        return true;
      case 'translation':
        let ts = value as number[]
        // if(ts){
        //   p.layout[0] = ts[0]
        //   p.layout[1] = ts[1]
        // }
        LayoutAttach.obtainLayoutAttach(p.renderView).setPosition(QTPixelUtil.vp2Vp(ts[0]),QTPixelUtil.vp2Vp(ts[1]))
        return true;
      case 'style':
      case 'flexStyle':
        // console.log(TAG_LAYOUT,`updateLayoutStyle key:${key},value:${CommonUtils.hippyAny2String(value)},viewType:${p.renderView.viewType}`)
        let style = HRValueUtils.getMap(value)
        // if(style){
        //   style.forEach((value,key)=>{
        //     console.log(TAG_LAYOUT,`handleCustomProps style key:${key},value:${CommonUtils.hippyAny2String(value)}`)
        //   })
        // }
        if(style){
          LayoutAttach.obtainLayoutAttach(p.renderView).setStyles(style)
        }
        return true;
      case 'layout':
        let array = value as number[]
        // if(array){
        //   for(let i = 0; i < 4; i ++){
        //     p.layout[i] = array[i]
        //   }
        // }else{
        //   console.warn(QUICKTVUI_TAG,`setLayout error array:${array},value:${value},viewType:${p.renderView.viewType}`)
        // }
        if(array && array.length == 4 && LayoutAttach.obtainLayoutAttach(p.renderView)){
          LayoutAttach.obtainLayoutAttach(p.renderView).setPosition(QTPixelUtil.vp2Vp(array[0]),QTPixelUtil.vp2Vp(array[1]))
          LayoutAttach.obtainLayoutAttach(p.renderView).setFixedWidth(QTPixelUtil.vp2Vp(array[2]))
          LayoutAttach.obtainLayoutAttach(p.renderView).setFixedHeight(QTPixelUtil.vp2Vp(array[3]))
        }
        return true;
      case 'size':
        let size = value as number[]
        // if(size){
        //   p.layout[2] = size[0]
        //   p.layout[3] = size[1]
        // }else{
        //   console.warn(QUICKTVUI_TAG,`setSize error array:${size},value:${value},viewType:${p.renderView.viewType}`)
        // }
        LayoutAttach.obtainLayoutAttach(p.renderView).setFixedWidth(QTPixelUtil.vp2Vp(size[0]))
        LayoutAttach.obtainLayoutAttach(p.renderView).setFixedHeight(QTPixelUtil.vp2Vp(size[1]))
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



