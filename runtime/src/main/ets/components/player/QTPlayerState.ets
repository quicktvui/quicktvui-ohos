export enum QTPlayerState {
  IDLE = 0, //初始化完成
  PREPARING = 1, //正在准备
  PREPARED = 2, //准备完毕
  BUFFER_START = 3, //正在缓冲
  BUFFER_END = 4, //正在缓冲
  BUFFERING_PERCENT = 40, //缓冲进度
  PLAYING = 5, //正在播放
  SEEK_START = 6, //快进开始
  SEEK_COMPLETED = 7, //快进完成
  PAUSED = 8, //暂停
  RESUMED = 9, //继续播放
  BEFORE_STOP = 10, //停止之前
  STOP = 11, //停止
  PLAYBACK_COMPLETED = 12, //播放完毕
  ERROR = 13, //错误
  VIDEO_SIZE_CHANGED = 14, //视频尺寸变化
  PLAYER_VIEW_CHANGED = 15, //播放布局变化

  AD_START = 16, //广告开始
  AD_END = 17, //广告结束
  AD_SKIP = 18, //广告跳过
  AD_PAUSED = 19, //广告暂停


  //鉴权通过，tvbc播放器鉴权
  AUTHORIZED = 20,
  //设置播放倍速成功
  SET_PLAY_RATE_SUCCESS = 21,
  //设置播放倍速报错
  SET_PLAY_RATE_ERROR = 22,

  //广告
  AD_RESUMED = 23, //广告RESUME
  AD_LOADED = 24,
  AD_TIME = 25, //广告倒计时时间

  PLAYER_INITIALIZED = 26, //播放器初始化完毕
  TIMED_TEXT_CHANGED = 27,
  //
  PLAYER_CLICKABLE = 28, //播放器view是否可以点击

  //初始化
  INITIALIZE_SUCCESS = 29, //初始化成功
  INITIALIZE_ERROR = 30, //初始化错误

  RELEASE = 31, //
}
