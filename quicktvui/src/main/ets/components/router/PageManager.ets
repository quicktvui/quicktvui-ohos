import { IPage } from "./IPage";

// PageManager.ets - 修复版
export class PageManager {
  // 静态变量
  private static pages: Map<string, IPage> = new Map();
  private static currentPageId: string | null = null;
  private static uiContext : UIContext | null = null;

  static setUIContext(uiContext : UIContext){
    PageManager.uiContext = uiContext;
  }

  static getUIContext(): UIContext | null{
    return PageManager.uiContext;
  }

  /**
   * 注册页面
   */
  static registerPage(pageId: string, pageInstance: IPage): void {
    if (PageManager.pages.has(pageId)) { // 使用类名
      console.warn(`[PageManager] 页面ID "${pageId}" 已存在，将被覆盖`);
    }
    PageManager.pages.set(pageId, pageInstance); // 使用类名
    PageManager.currentPageId = pageId; // 使用类名
    console.log(`[PageManager] 页面注册成功: ${pageId}`);
  }

  /**
   * 注销页面
   */
  static unregisterPage(pageId: string): void {
    if (PageManager.pages.delete(pageId)) { // 使用类名
      console.log(`[PageManager] 页面注销成功: ${pageId}`);

      if (PageManager.currentPageId === pageId) { // 使用类名
        PageManager.currentPageId = null; // 使用类名
      }
    }
  }

  /**
   * 获取页面实例
   */
  static getPage<T extends IPage>(pageId: string): T | null {
    const page = PageManager.pages.get(pageId); // 使用类名
    if (!page) {
      console.warn(`[PageManager] 页面不存在: ${pageId}`);
      return null;
    }
    return page as T;
  }

  // /**
  //  * 获取当前活跃页面
  //  */
  // static getCurrentPage<T extends  QTPage>(): T | null {
  //   if (!PageManager.currentPageId) { // 使用类名
  //     return null;
  //   }
  //   return PageManager.getPage<T>(PageManager.currentPageId);
  // }
  //
  // /**
  //  * 获取当前活跃页面ID
  //  */
  // static getCurrentPageId(): string | null {
  //   return PageManager.currentPageId; // 使用类名
  // }
  //
  // /**
  //  * 设置当前活跃页面
  //  */
  // static setCurrentPage(pageId: string): void {
  //   if (PageManager.pages.has(pageId)) { // 使用类名
  //     PageManager.currentPageId = pageId; // 使用类名
  //   } else {
  //     console.warn(`[PageManager] 无法设置不存在的页面为当前页面: ${pageId}`);
  //   }
  // }

  /**
   * 检查页面是否存在
   */
  static hasPage(pageId: string): boolean {
    return PageManager.pages.has(pageId); // 使用类名
  }

  /**
   * 获取所有已注册的页面ID
   */
  static getAllPageIds(): string[] {
    return Array.from(PageManager.pages.keys()); // 使用类名
  }

  /**
   * 清空所有页面
   */
  static clearAll(): void {
    const count = PageManager.pages.size; // 使用类名
    PageManager.pages.clear(); // 使用类名
    PageManager.currentPageId = null; // 使用类名
    console.log(`[PageManager] 已清空所有页面，共清理 ${count} 个页面`);
  }
}