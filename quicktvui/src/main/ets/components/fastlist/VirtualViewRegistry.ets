// 文件：VirtualViewRegistry.ets（最终版）
import { QTView } from "../../QTTypes";
import { QTLog } from "../../utils/QTLog";
import { LayoutAttach } from "./LayoutAttach";

interface VirtualViewInfo {
  id: string;          // virtual_1, virtual_2...
  number: number;      // 纯数字：1, 2, 3...
  view: QTView;
  uid?: string;        // 设置给LayoutAttach的UID，格式：virtual_1
}

export class VirtualViewRegistry {
  private static instance: VirtualViewRegistry | null = null;
  private viewMap: Map<string, VirtualViewInfo> = new Map();

  // UID索引：通过UID快速查找View
  private uidToIdMap: Map<string, string> = new Map();

  // 数字分组索引：按数字范围快速筛选
  private numberGroupIndex: Map<number, Set<string>> = new Map();
  private readonly GROUP_SIZE = 100;

  TAG : string = 'DebugVirtualView'

  // 核心：纯数字自增计数器
  private idCounter: number = 1;

  private constructor() {
    QTLog.d(this.TAG,'[VirtualViewRegistry] 初始化');
  }

  public static getInstance(): VirtualViewRegistry {
    if (!VirtualViewRegistry.instance) {
      VirtualViewRegistry.instance = new VirtualViewRegistry();
    }
    return VirtualViewRegistry.instance;
  }

  /**
   * 核心方法：注册虚拟View
   * 流程：
   * 1. 获取下一个自增数字（纯数字）
   * 2. 生成 virtual_X 格式的ID
   * 3. 将同样的 virtual_X 设置给LayoutAttach.uid
   */
  public registerView(view: QTView): string {
    if (!view) {
      throw new Error('无法为null或undefined的view注册ID');
    }

    // 1. 获取下一个自增数字（纯数字）
    const currentNumber = this.idCounter++;

    // 2. 生成ID（virtual_ + 数字）
    const virtualId = `virtual_${currentNumber}`;

    // 3. 【关键】将同样的ID设置给LayoutAttach.uid
    let uidAssigned = false;

    try {
      const layoutAttach = LayoutAttach.obtainLayoutAttach(view);
      if (layoutAttach) {
        // 将 virtual_X 直接赋值给uid
        layoutAttach.uid = virtualId; // virtual_1, virtual_2...
        uidAssigned = true;
        // QTLog.d(this.TAG,`[VirtualViewRegistry] 为View设置UID: ${virtualId}`);
      } else {
        QTLog.w(this.TAG,`[VirtualViewRegistry] 无法获取LayoutAttach，UID未设置`);
      }
    } catch (e) {
      QTLog.w(this.TAG,`[VirtualViewRegistry] 设置UID异常:${e}`);
    }

    // 4. 创建View信息
    const viewInfo: VirtualViewInfo = {
      id: virtualId,
      number: currentNumber,
      view: view,
      uid: uidAssigned ? virtualId : undefined
    };

    // 5. 存储和建立索引
    this.storeAndIndexView(virtualId, currentNumber, viewInfo);

    QTLog.d(this.TAG,`[VirtualViewRegistry] 注册虚拟View: ${virtualId}`);
    return virtualId;
  }

  /**
   * 存储View并建立所有索引
   */
  private storeAndIndexView(id: string, number: number, info: VirtualViewInfo): void {
    // 主存储
    this.viewMap.set(id, info);

    // UID索引（如果UID设置成功）
    if (info.uid) {
      this.uidToIdMap.set(info.uid, id);
    }

    // 数字分组索引
    const groupKey = Math.floor(number / this.GROUP_SIZE);
    if (!this.numberGroupIndex.has(groupKey)) {
      this.numberGroupIndex.set(groupKey, new Set());
    }
    this.numberGroupIndex.get(groupKey)!.add(id);
  }

  // ================= 查找方法 =================

  /**
   * 通过ID查找View（主要方法）
   */
  public getViewById(id: string): QTView | null {
    return this.viewMap.get(id)?.view || null;
  }

  /**
   * 通过UID查找View（UID就是virtual_X格式）
   */
  public getViewByUid(uid: string): QTView | null {
    const id = this.uidToIdMap.get(uid);
    return id ? this.getViewById(id) : null;
  }

  /**
   * 获取所有虚拟View
   */
  public getAllViews(): QTView[] {
    return Array.from(this.viewMap.values()).map(info => info.view);
  }

  /**
   * 按数字范围查找View（高性能）
   */
  public getViewsInNumberRange(startNum: number, endNum: number): QTView[] {
    if (startNum > endNum) return [];

    const views: QTView[] = [];
    const startGroup = Math.floor(startNum / this.GROUP_SIZE);
    const endGroup = Math.floor(endNum / this.GROUP_SIZE);

    for (let group = startGroup; group <= endGroup; group++) {
      const idSet = this.numberGroupIndex.get(group);
      if (idSet) {
        for (const id of idSet) {
          const info = this.viewMap.get(id);
          if (info && info.number >= startNum && info.number <= endNum) {
            views.push(info.view);
          }
        }
      }
    }

    return views;
  }

  // ================= 工具方法 =================

  /**
   * 解析ID，获取纯数字部分
   */
  public static parseId(id: string): number | null {
    const PREFIX = 'virtual_';
    if (!id.startsWith(PREFIX)) return null;

    const numStr = id.substring(PREFIX.length);
    const num = parseInt(numStr, 10);
    return isNaN(num) ? null : num;
  }

  /**
   * 获取View的完整信息
   */
  public getViewInfo(id: string): VirtualViewInfo | null {
    return this.viewMap.get(id) || null;
  }

  /**
   * 获取下一个将生成的数字
   */
  public getNextIdNumber(): number {
    return this.idCounter;
  }

  /**
   * 获取已注册的View数量
   */
  public getTotalCount(): number {
    return this.viewMap.size;
  }

  /**
   * 移除View并清理索引
   */
  public removeView(id: string): boolean {
    const info = this.viewMap.get(id);
    if (!info) return false;

    // 1. 从UID索引清理
    if (info.uid) {
      this.uidToIdMap.delete(info.uid);
    }

    // 2. 从数字分组索引清理
    const groupKey = Math.floor(info.number / this.GROUP_SIZE);
    this.numberGroupIndex.get(groupKey)?.delete(id);

    // 3. 从主存储清理
    this.viewMap.delete(id);

    QTLog.d(this.TAG,`[VirtualViewRegistry] 移除虚拟View: ${id}`);
    return true;
  }

  /**
   * 通过UID移除View
   */
  public removeViewByUid(uid: string): boolean {
    const id = this.uidToIdMap.get(uid);
    return id ? this.removeView(id) : false;
  }

  /**
   * 清空所有
   */
  public clearAll(): void {
    this.viewMap.clear();
    this.uidToIdMap.clear();
    this.numberGroupIndex.clear();
    this.idCounter = 1;
    QTLog.d(this.TAG,'[VirtualViewRegistry] 已清空所有虚拟View');
  }
}