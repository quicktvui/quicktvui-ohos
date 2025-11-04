
 export interface ISplashView {
  /**
   * 初始化，传入参数
   * @param data 可序列化数据
   */
  onInit(data: object): void;

  /**
   * 页面渲染成功
   */
  onEsRenderSuccess(): void;

  /**
   * 页面渲染失败
   * @param exception 异常对象
   */
  onEsRenderFailed(exception: object): void;

  /**
   * 页面临时挂起，暂时不要自动关闭
   * @param msg 挂起消息
   */
  suspend(msg: string): void;

  /**
   * 页面挂起结束，可以关闭页面
   */
  unSuspend(): void;
}