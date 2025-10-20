import {HippyRenderBaseView,NativeRenderContext,hippyRenderViewCreatorRegisterMap,HRRenderViewCreator,HippyMap} from 'hippy'

let myHippyRenderViewCreatorRegisterMap :Map<string, HRRenderViewCreator> | null
let myCustomRenderViewCreatorRegisterMap :Map<string, HRRenderViewCreator> | null

export function createRenderViewFromCreator(ctx:NativeRenderContext | null, viewName: string): HippyRenderBaseView | null {
  if(!ctx){
    return null
  }
  if(!myHippyRenderViewCreatorRegisterMap){
    myHippyRenderViewCreatorRegisterMap = hippyRenderViewCreatorRegisterMap();
    //这里将div替换成自己的div
    // myHippyRenderViewCreatorRegisterMap.set("View", (ctx): HippyRenderBaseView => new QTDivView(ctx))
  }

  if(!myCustomRenderViewCreatorRegisterMap){
    myCustomRenderViewCreatorRegisterMap = ctx.getCustomRenderViewCreatorMap();
  }
  let creator = myCustomRenderViewCreatorRegisterMap?.get(viewName) ?? myHippyRenderViewCreatorRegisterMap.get(viewName);
  if(creator){
    return creator(ctx)
  }
  return null
}



// private createRenderView(tag: number, viewName: string): void {
//   LogUtils.i('quicktvui',`createRenderView crate tag:${tag},viewName:${viewName}`)
// let existRenderView = this.viewRegistry.get(tag)
// if (existRenderView) {
//   return
// }
// let renderView = this.createRenderViewFromCreator(viewName)
// if (renderView) {
//   renderView.tag = tag
//   renderView.viewType = viewName
//   this.viewRegistry.set(tag, renderView)
// } else {
//   LogUtils.d(this.TAG, "createRenderView: failed:  " + viewName)
// }
// }


