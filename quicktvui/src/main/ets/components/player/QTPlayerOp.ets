//播放器操作
export enum QTPlayerOp {
  INIT = "init",
  PLAY = "play",
  START = "start",
  PAUSE = "pause",
  RESUME = "resume",
  SEEK_TO = "seekTo",
  STOP = "stop",
  RESET = "reset",
  RELEASE = "release",
  STOP_FORCE = "stopForce",

  CHANGE_TO_FULL_SCREEN = "changeToFullScreen",
  IS_FULL_SCREEN = "isFullScreen",

  SET_ENABLED = "setEnabled",
  IS_ENABLED = "isEnabled",

  SET_STOPPED = "setStopped",
  IS_STOPPED = "isStopped",

  IS_PLAYING = "isPlaying",
  IS_PAUSED = "isPaused",

  GET_DURATION = "getDuration",
  GET_CURRENT_POSITION = "getCurrentPosition",
  GET_BUFFER_PERCENTAGE = "getBufferPercentage",

  SET_PLAYER_SIZE = "setPlayerSize",
  SET_LAYOUT = "setPlayerLayout",

  SET_PLAYER_DIMENSION = "setPlayerDimension",

  //
  SET_SPEED = "setPlayRate",
  SET_DEFINITION = "setDefinition",
  SET_DECODE = "setDecode",
  SET_ASPECT_RATIO = "setAspectRatio",
  //
  GET_LEFT_VOLUME = "getLeftVolume",
  GET_RIGHT_VOLUME = "getRightVolume",

  SET_LEFT_VOLUME = "setLeftVolume",
  SET_RIGHT_VOLUME = "setRightVolume",

  SET_VOLUME = "setVolume",

}
