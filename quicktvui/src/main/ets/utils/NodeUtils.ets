

import {NativeRenderContext,HippyRenderBaseView} from 'hippy'
import { QTBaseComponentView } from '../components/QTBaseComponentView';
import { TAG_QUICKTVUI } from '../Constant';

export class NodeUtils{
  static getNodeById(ctx : NativeRenderContext,tag : number){
    return ctx.getNativeRender().getRenderManager().getVirtualNodeManager(ctx.getRootId())?.getVirtualNode(tag)
  }

  static getRenderView(ctx : NativeRenderContext,tag : number){
    return ctx.getNativeRender().getRenderManager().getViewManager(ctx.getRootId())?.getRenderView(tag)
  }


  static printViewTreePretty(
  node: HippyRenderBaseView,
  prefix: string = '',
  isLast: boolean = true
): void {
  const children = node.children ?? [];

  const branch = isLast ? '└─ ' : '├─ ';
  const linePrefix = prefix + branch;
  let templateTag = -1;
  if(node instanceof QTBaseComponentView && node.templateView){
    templateTag = node.templateView.tag
  }

  console.log(TAG_QUICKTVUI,`${linePrefix}${node.viewType}: ${node.tag} ,template:${templateTag} (${children.length} children)`);

  const nextPrefix = prefix + (isLast ? '   ' : '│  ');
  children.forEach((child, index) =>
  NodeUtils.printViewTreePretty(child, nextPrefix, index === children.length - 1)
  );
}


}

// interface HippyRenderBaseView {
//   tag: number;
//   viewType: string;
//   children?: HippyRenderBaseView[];
//   [key: string]: any;
// }






