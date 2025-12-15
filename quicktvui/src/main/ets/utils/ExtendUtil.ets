import {HippyAny,HippyRenderBaseView,EventDispatcher,HREventUtils,NativeRenderContext} from 'hippy'
import { LayoutAttach } from '../components/fastlist/LayoutAttach';
import { QTAttach } from '../components/QTAttach';
import { QTBaseComponentView } from '../components/QTBaseComponentView';
import { QTViewActor } from '../components/QTViewActor';
import { QTViewState, StateView, StateViewConstants } from '../components/StateView';
import { TAG_FASTLIST, TAG_FAST_EVENT, TAG_FOCUS } from '../Constant';
import { QTAny, QTView } from '../QTTypes';
import { CommonUtils } from './CommonUtils';
import { NodeUtils } from './NodeUtils';
import { QTCompatUtil } from './QTCompatUtil';
import { QTLog } from './QTLog';
import { ViewUtils } from './ViewUtils';
export class ExtendUtil{

  static debugView(view:QTView | null) : string{
    if(view  == null ){
      return 'null'
    }
    let className = view.viewType;
    let sid = 'null'
    let name = 'null'
    let attach = QTAttach.findQTAttach(view);
    let uid = ViewUtils.getViewUid(view)
    if(attach){
      if(attach.sid){
        sid = attach.sid;
      }
      if(attach.name){
        name = attach.name;
      }
    }
    let desc = -1;
    return `${className}{ tag:${view.tag},uid:${uid},name: ${name} sid:${sid} [${view.cssPositionX},${view.cssPositionY},${view.cssWidth},${view.cssHeight}] [${view.cssVisibility}] }
    `
  }

  static sendUIEvent(ctx: NativeRenderContext,nodeId:number,eventName:string,params:HippyAny){
    QTLog.i(TAG_FAST_EVENT,`sendUIEvent node${nodeId},eventName:${eventName},params:${CommonUtils.hippyAny2String(params)}`)
    HREventUtils.sendComponentEvent(ctx,nodeId,eventName,params)
  }
  static sendViewEvent(view:QTView,eventName:string,params:HippyAny){
    QTLog.i(TAG_FAST_EVENT,`sendUIEvent view${ExtendUtil.debugView(view)},eventName:${eventName},params:${CommonUtils.hippyAny2String(params)}`)
    HREventUtils.sendComponentEvent(view.ctx,view.tag,eventName,params)
  }

  static findViewActor(view : QTView | null): QTViewActor | undefined {
     return QTCompatUtil.getQTBaseView(view)?.viewActor
  }

  static printTreeView(node: QTView, prefix: string = '', isLast: boolean = true): void {
    // 打印当前节点
    console.log(`${prefix}${isLast ? '└── ' : '├── '}${node.viewType} - ${node.tag}`);

    // 如果有子节点，递归处理
    if (node.children && node.children.length > 0) {
      const childPrefix = prefix + (isLast ? '    ' : '│   ');
      const childCount = node.children.length;

      node.children.forEach((child, index) => {
        // 判断当前子节点是否是最后一个
        const isChildLast = index === childCount - 1;
        ExtendUtil.printTreeView(child, childPrefix, isChildLast);
      });
    }
  }

  // 状态常量定义 - 使用鸿蒙的状态枚举
  static STATE_SET_SELECTED_FOCUS: number[] = [
    QTViewState.STATE_SELECTED,
    QTViewState.STATE_FOCUSED
  ];
  static STATE_SET_SELECTED: number[] = [QTViewState.STATE_SELECTED];
  static STATE_SET_FOCUSED: number[] = [QTViewState.STATE_FOCUSED];

  // 工具函数：检查状态数组是否包含特定属性
  static stateContainsAttribute(stateSpecs: number[], attr: number | number[]): boolean {
    if (!stateSpecs) {
      return false;
    }

    if (Array.isArray(attr)) {
      for (let specAttr of stateSpecs) {
        for (let toState of attr) {
          if (specAttr === toState || -specAttr === toState) {
            return true;
          }
        }
      }
    } else {
      for (let specAttr of stateSpecs) {
        if (specAttr === attr || -specAttr === attr) {
          return true;
        }
      }
    }
    return false;
  }

  // 工具函数：查找相反状态
  static  findOppositeState(showOnState: number[]): number[] {
    let result: number[];
    if (showOnState.length === 2) {
      // [-1，selected] 或 [-1,focused]
      result = new Array(1);
      for (let state of showOnState) {
        if (state !== -1) {
          // 因为只有这俩种可能性，所以简单的变换一下
          // focused->selected
          // selected->focused
          if (state === QTViewState.STATE_FOCUSED) {
            result[0] = QTViewState.STATE_SELECTED;
          } else {
            result[0] = QTViewState.STATE_FOCUSED;
          }
        }
      }
    } else {
      // [-1] 或 [-1，selected,focused]
      result = ExtendUtil.STATE_SET_SELECTED_FOCUS;
    }
    return result;
  }

  // 主函数：处理基于状态的显示逻辑
  static handleShowOnState(view: QTBaseComponentView, states: number[], showOnState: number[]): boolean {
   // QTLog.e(TAG_FOCUS, `handleShowOnState start - states: ${JSON.stringify(states)}, showOnState: ${JSON.stringify(showOnState)}`);

    if (showOnState && showOnState.length > 0) {
      const hasNormalState = ExtendUtil.stateContainsAttribute(showOnState, -1);
      // QTLog.e(TAG_FOCUS, `hasNormalState: ${hasNormalState}`);

      if (hasNormalState) {
        // [normal] 相关逻辑
       const isNormalState = !ExtendUtil.stateContainsAttribute(states, ExtendUtil.findOppositeState(showOnState));
        view.visibility = isNormalState ? Visibility.Visible : Visibility.Hidden;
        // QTLog.e(TAG_FOCUS, `1 handleShowOnState changeVisibility: ${view.visibility} view: ${ExtendUtil.debugView(view)}`);
      } else {
        // [focused,selected] 相关逻辑
        let isShow = false;
        let takeOver = false;

        // QTLog.e(TAG_FOCUS, `showOnState.length: ${showOnState.length}`);

        if (showOnState.length === 1) {
          const containFocusAndSelect = ExtendUtil.stateContainsAttribute(showOnState, ExtendUtil.STATE_SET_SELECTED_FOCUS);
          // QTLog.e(TAG_FOCUS, `containFocusAndSelect: ${containFocusAndSelect}, showOnState[0]: ${showOnState[0]}`);

          if (containFocusAndSelect) {
            if (showOnState[0] === StateViewConstants.STATE_FOCUS_AND_SELECT) {
              isShow = true;
              takeOver = true;
              QTLog.e(TAG_FOCUS, `STATE_FOCUS_AND_SELECT matched`);
            }
          } else {
            // QTLog.e(TAG_FOCUS, `Checking STATE_SELECT_NO_FOCUS and STATE_FOCUS_NO_SELECT`);

            if (showOnState[0] === StateViewConstants.STATE_SELECT_NO_FOCUS) {
              takeOver = true;
              const hasSelected = ExtendUtil.stateContainsAttribute(states, ExtendUtil.STATE_SET_SELECTED);
              const hasFocused = ExtendUtil.stateContainsAttribute(states, ExtendUtil.STATE_SET_FOCUSED);
              // QTLog.e(TAG_FOCUS, `STATE_SELECT_NO_FOCUS - hasSelected: ${hasSelected}, hasFocused: ${hasFocused}`);

              if (hasSelected && !hasFocused) {
                isShow = true;
              }
            }

            if (showOnState[0] === StateViewConstants.STATE_FOCUS_NO_SELECT) {
              takeOver = true;
              const hasFocused = ExtendUtil.stateContainsAttribute(states, ExtendUtil.STATE_SET_FOCUSED);
              const hasSelected = ExtendUtil.stateContainsAttribute(states, ExtendUtil.STATE_SET_SELECTED);
              // QTLog.e(TAG_FOCUS, `STATE_FOCUS_NO_SELECT - hasFocused: ${hasFocused}, hasSelected: ${hasSelected}`);

              if (hasFocused && !hasSelected) {
                isShow = true;
              }
            }
          }
        }

        //QTLog.e(TAG_FOCUS, `takeOver: ${takeOver}, isShow: ${isShow}`);

        if (takeOver) {
          view.visibility = isShow ? Visibility.Visible : Visibility.Hidden;
         // QTLog.e(TAG_FOCUS, `2 handleShowOnState changeVisibility: ${view.visibility} view: ${ExtendUtil.debugView(view)}`);
        } else {
          const contain = ExtendUtil.stateContainsAttribute(states, showOnState);
        //  QTLog.e(TAG_FOCUS, `Final contain check: ${contain}`);
          view.visibility = contain ? Visibility.Visible : Visibility.Hidden;
          //QTLog.e(TAG_FOCUS, `3 handleShowOnState changeVisibility: ${contain} view: ${ExtendUtil.debugView(view)}`);
        }
      }
      return true;
    }

    QTLog.e(TAG_FOCUS, `handleShowOnState return false`);
    return false;
  }


  // 配置状态显示方法
  static configureShowOnState(view: StateView, showOnStateValue : QTAny): void {
    if (showOnStateValue instanceof Array) {
      // 处理数组情况
      ExtendUtil.handleArrayShowOnState(view, showOnStateValue as Array<string>);
    } else if (typeof showOnStateValue === 'string') {
      // 处理字符串情况
      ExtendUtil.handleStringShowOnState(view, showOnStateValue as string);
    }
  }

  // 处理数组类型的showOnState
  static  handleArrayShowOnState(view: StateView, array: Array<string>): void {
    if (!array || array.length === 0) {
      return;
    }

    const customStates: Set<string> = new Set();
    const states: number[] = new Array(array.length);

    for (let i = 0; i < array.length; i++) {
      const stateStr = array[i];
      switch (stateStr) {
        case "selected":
          states[i] = QTViewState.STATE_SELECTED;
          break;
        case "focused":
          states[i] = QTViewState.STATE_FOCUSED;
          break;
        case "normal":
          states[i] = QTViewState.STATE_NORMAL;
          break;
        default:
          customStates.add(stateStr);
          break;
      }
    }

    view.setShowOnState(states);

    if (customStates.size > 0) {
      const customStatesArray: string[] = Array.from(customStates);
      view.setShowOnCustomState(customStatesArray);
    } else {
      view.setShowOnCustomState([]);
    }
  }

  // 处理字符串类型的showOnState
  static handleStringShowOnState(view: StateView, stateStr: string): void {
    let customState: string | null = null;
    const states: number[] = new Array(1);

    switch (stateStr) {
      case "selected":
        states[0] = QTViewState.STATE_SELECTED;
        break;
      case "focused":
        states[0] = QTViewState.STATE_FOCUSED;
        break;
      case "normal":
        states[0] = QTViewState.STATE_NORMAL;
        break;
      case "selected&focused":
      case "focused&selected":
        states[0] = StateViewConstants.STATE_FOCUS_AND_SELECT;
        break;
      case "selected&!focused":
        states[0] = StateViewConstants.STATE_SELECT_NO_FOCUS;
        break;
      case "focused&!selected":
        states[0] = StateViewConstants.STATE_FOCUS_NO_SELECT;
        break;
      default:
        customState = stateStr;
        break;
    }

    view.setShowOnState(states);

    if (customState === null) {
      view.setShowOnCustomState([]);
    } else {
      view.setShowOnCustomState([customState]);
    }
  }

  static findViewByNameByParentId(ctx : NativeRenderContext,id : number,name: string) : QTView | null{
    let view =  NodeUtils.getRenderView(ctx,id)
    if(view){
      return ExtendUtil.findViewByName(view,name)
    }else{
      QTLog.e(TAG_FASTLIST,`findViewByNameByParentId error view is null id:${id},name:${name}`)
      return null;
    }

  }

  static findViewByName(view : QTView | null ,name : string) : QTView | null{
    if(!view){
      return null
    }
    let la = LayoutAttach.obtainLayoutAttach(view)
   // QTLog.d(TAG_FASTLIST,`findViewByName view ${ExtendUtil.debugView(view)}`)
    if(la.name == name){
      return view;
    }
    for(let i = 0; i < view.children.length; i ++){
      let child = view.children[i]
      let result = ExtendUtil.findViewByName(child,name)
      if(result){
        return result;
      }
    }
    return null;
  }





}
