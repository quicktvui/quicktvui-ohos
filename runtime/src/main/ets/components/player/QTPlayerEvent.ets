export enum QTPlayerEvent {
  ON_PLAYER_STATUS_CHANGED = "onPlayerStatusChanged",
  ON_PLAYER_PROGRESS_CHANGED = "onPlayerProgressChanged",
  //
  ON_PLAYER_ERROR = "onPlayerError",
  //
  ON_PLAYER_INFO = "onPlayerInfo",

  //播放速率
  ON_PLAYER_RATE_LIST_CHANGED = "onAllPlayRateChanged",
  ON_PLAYER_RATE_CHANGED = "onPlayRateChanged",

  //清晰度
  ON_PLAYER_DEFINITION_LIST_CHANGED = "onAllDefinitionChanged",
  ON_PLAYER_DEFINITION_CHANGED = "onDefinitionChanged",

  //画面比例
  ON_PLAYER_ASPECT_RATIO_LIST_CHANGED = "onAllAspectRatioChanged",
  ON_PLAYER_ASPECT_RATIO_CHANGED = "onAspectRatioChanged",

  //解码
  ON_PLAYER_DECODE_LIST_CHANGED = "onAllDecodeChanged",
  ON_PLAYER_DECODE_CHANGED = "onDecodeChanged",

  //大小屏变化
  ON_PLAYER_ENTER_FULL_SCREEN = "onEnterFullScreen",
  ON_PLAYER_EXIT_FULL_SCREEN = "onExitFullScreen",

  //音量
  ON_PLAYER_VOLUME_CHANGED = "onPlayerVolumeChanged",
  //
  ON_ANDROID_INVOKE_VUE = "onAndroidInvokeVue",


  //---------------------------------音频相关-------------------------------------------
  //
  ON_AUDIO_PLAYER_SERVICE_BIND = "onESAudioPlayerServiceBind",
  ON_AUDIO_PLAYER_STATUS_CHANGED = "onESAudioPlayerStatusChanged",
  ON_AUDIO_PLAYER_ERROR = "onESAudioPlayerError",
  ON_AUDIO_PLAYER_INFO = "onESAudioPlayerInfo",
  ON_AUDIO_PLAYER_RATE_CHANGED = "onESAudioPlayRateChanged",
  ON_AUDIO_PLAYER_INIT = "onESAudioPlayerInit",
}
