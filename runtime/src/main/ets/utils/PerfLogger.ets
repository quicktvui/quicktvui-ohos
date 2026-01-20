// src/main/ets/utils/PerfLogger.ets

/**
 * 简易性能打点工具
 * 用法：
 * 1. PerfLogger.start('AppLaunch');
 * 2. PerfLogger.mark('AppLaunch', 'AbilityCreated');
 * 3. PerfLogger.end('AppLaunch');
 */
export class PerfLogger {
  private static times: Map<string, number> = new Map();
  // 记录上一次打点的时间，用于计算“步骤间”的耗时
  private static lastStepTimes: Map<string, number> = new Map();

  /**
   * 开始计时
   * @param tag 任务标签，如 "PageJump", "AppLaunch"
   */
  static start(tag: string) {
    const now = Date.now();
    PerfLogger.times.set(tag, now);
    PerfLogger.lastStepTimes.set(tag, now);
    // 使用 [PERF] 前缀，方便在控制台过滤
    console.warn(`[PERF] [START] 🏁 ${tag} at ${now}`);
  }

  /**
   * 中间打点：记录距离上一步过去了多久，以及距离开始过去了多久
   * @param tag 任务标签
   * @param stepName 步骤名称，如 "loadBundle", "renderUI"
   */
  static mark(tag: string, stepName: string) {
    const now = Date.now();
    const startTime = PerfLogger.times.get(tag);
    const lastTime = PerfLogger.lastStepTimes.get(tag);

    if (startTime && lastTime) {
      const stepCost = now - lastTime;
      const totalCost = now - startTime;
      console.info(`[PERF] [STEP] ⏱️ ${tag} -> ${stepName}: +${stepCost}ms (Total: ${totalCost}ms)`);

      // 更新上一步的时间
      PerfLogger.lastStepTimes.set(tag, now);
    } else {
      console.warn(`[PERF] [WARN] Tag ${tag} has not started yet.`);
    }
  }

  /**
   * 结束计时
   * @param tag 任务标签
   */
  static end(tag: string) {
    const now = Date.now();
    const startTime = PerfLogger.times.get(tag);

    if (startTime) {
      const totalCost = now - startTime;
      console.error(`[PERF] [END] 🛑 ${tag} Finished. Total Cost: ${totalCost}ms`);

      // 清理内存
      PerfLogger.times.delete(tag);
      PerfLogger.lastStepTimes.delete(tag);
    }
  }
}