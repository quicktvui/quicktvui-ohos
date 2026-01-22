import { QTView } from "../../QTTypes";
import { ViewUtils } from "../../utils/ViewUtils";
import { QTBaseComponentView } from "../QTBaseComponentView";
import { IPage } from "./IPage";

// PageManager.ets - 堆栈增强版
export class PageManager {
  // 静态变量
  private static pages: Map<string, IPage> = new Map();
  // 新增：页面堆栈，用于记录页面历史顺序 (栈顶在数组末尾)
  private static pageStack: string[] = [];

  private static uiContext : UIContext | null = null;
  // frontPage 可以直接通过堆栈计算得出，但为了性能和兼容旧逻辑保留，作为缓存
  private static frontPage : string | null = null;

  static setUIContext(uiContext : UIContext){
    PageManager.uiContext = uiContext;
  }

  static getUIContext(): UIContext | null{
    return PageManager.uiContext;
  }

  /**
   * 将页面置于前台（入栈或移动到栈顶）
   * @param pageId 页面ID
   */
  static bringToFront(pageId: string) {
    if (!PageManager.pages.has(pageId)) {
      console.warn(`[PageManager] bringToFront: 页面 ${pageId} 未注册`);
      return;
    }

    // 1. 如果堆栈中已经存在该ID，先移除（避免重复，并实现"移动到栈顶"的效果）
    const index = PageManager.pageStack.indexOf(pageId);
    if (index > -1) {
      PageManager.pageStack.splice(index, 1);
    }

    // 2. 推入栈顶
    PageManager.pageStack.push(pageId);

    // 3. 更新当前前台页面标记
    PageManager.frontPage = pageId;

    console.debug(`[PageManager] bringToFront: ${pageId}, 当前堆栈: ${JSON.stringify(PageManager.pageStack)}`);
  }

  /**
   * 页面返回（出栈）
   * @param pageId 当前要退出的页面ID
   * @returns 返回新的栈顶页面ID (即返回后显示的页面)，如果栈空则返回 null
   */
  static routerBack(pageId: string): string | null | undefined {
    const index = PageManager.pageStack.indexOf(pageId);

    if (index === -1) {
      console.warn(`[PageManager] routerBack: 页面 ${pageId} 不在堆栈中`);
      // 如果页面不在堆栈里，可能是异常情况，尝试返回当前的栈顶
      return PageManager.frontPage;
    }

    // 1. 移除指定的页面
    // 注意：通常 routerBack 都是移除栈顶，但为了健壮性，这里支持移除指定ID（即使它不在栈顶）
    PageManager.pageStack.splice(index, 1);

    // 2. 计算新的栈顶
    let newTopPageId: string | null = null;
    if (PageManager.pageStack.length > 0) {
      newTopPageId = PageManager.pageStack[PageManager.pageStack.length - 1];
    }

    // 3. 更新前台标记
    PageManager.frontPage = newTopPageId;

    console.debug(`[PageManager] routerBack: 移除了 ${pageId}, 新栈顶: ${newTopPageId}`);

    return newTopPageId;
  }

  /**
   * 判断是否为前台页面
   */
  static isFrontPage(pageId: string | null | undefined): boolean {
    if (pageId && pageId === PageManager.frontPage) {
      return true;
    }
    return false;
  }

  /**
   * 注册页面
   */
  static registerPage(pageId: string, pageInstance: IPage): void {
    if (PageManager.pages.has(pageId)) {
      console.warn(`[PageManager] 页面ID "${pageId}" 已存在，将被覆盖`);
    }
    PageManager.pages.set(pageId, pageInstance);
    console.log(`[PageManager] 页面注册成功: ${pageId}`);
  }

  /**
   * 注销页面
   * 注：注销时同时也应该清理堆栈，防止内存泄漏或逻辑错误
   */
  static unregisterPage(pageId: string): void {
    // 1. 从 Map 中删除
    if (PageManager.pages.delete(pageId)) {
      console.log(`[PageManager] 页面注销成功: ${pageId}`);
    }

    // 2. 从堆栈中清理（防止已注销的页面卡在堆栈里）
    const stackIndex = PageManager.pageStack.indexOf(pageId);
    if (stackIndex > -1) {
      PageManager.pageStack.splice(stackIndex, 1);

      // 如果注销的是当前前台页面，需要更新 frontPage
      if (PageManager.frontPage === pageId) {
        const newTop = PageManager.pageStack.length > 0
          ? PageManager.pageStack[PageManager.pageStack.length - 1]
          : null;
        PageManager.frontPage = newTop;
      }
    }
  }

  /**
   * 获取页面实例
   */
  static getPage<T extends IPage>(pageId: string): T | null {
    const page = PageManager.pages.get(pageId);
    if (!page) {
      // 降级日志级别，避免频繁查询导致大量 warn
      // console.warn(`[PageManager] 页面不存在: ${pageId}`);
      return null;
    }
    return page as T;
  }

  static getPageHost<T extends IPage>(view : QTView): T | null {
    let pageUid : string | null | undefined = ViewUtils.getViewPageUid(view)
    if(pageUid){
      const page = PageManager.pages.get(pageUid);
      if (!page) {
        console.warn(`[PageManager] getPageByView 页面不存在: ${pageUid}`);
        return null;
      }
      return page as T;
    }else{
      console.warn(`[PageManager] getPageByView uid is null`);
      return null;
    }
  }

  /**
   * 获取栈顶页面 ID
   * @returns 栈顶页面的 ID，如果栈为空则返回 null
   */
  static getTopPageId(): string | null {
    if (PageManager.pageStack.length === 0) {
      return null;
    }
    // 数组的最后一个元素即为栈顶
    return PageManager.pageStack[PageManager.pageStack.length - 1];
  }

  /**
   * 获取栈顶页面实例
   * @returns 栈顶页面的实例对象，如果不存在则返回 null
   */
  static getTopPage<T extends IPage>(): T | null {
    const topId = PageManager.getTopPageId();
    if (!topId) {
      return null;
    }
    return PageManager.getPage<T>(topId);
  }

  /**
   * 检查页面是否存在
   */
  static hasPage(pageId: string): boolean {
    return PageManager.pages.has(pageId);
  }

  /**
   * 获取所有已注册的页面ID
   */
  static getAllPageIds(): string[] {
    return Array.from(PageManager.pages.keys());
  }

  /**
   * 清空所有页面
   */
  static clearAll(): void {
    const count = PageManager.pages.size;
    PageManager.pages.clear();
    PageManager.pageStack = []; // 同时也清空堆栈
    PageManager.frontPage = null;
    console.log(`[PageManager] 已清空所有页面，共清理 ${count} 个页面`);
  }
}