export enum QTAVPlayerState {
  IDLE = 0,
  INITIALIZED = 1,
  PREPARED = 2,
  PLAYING = 3,
  PAUSED = 4,
  COMPLETED = 5,
  STOPPED = 6,
  ERROR = 7,
  RELEASED = 8
}

export enum QTPlayerAspectRatio {
  AR_ASPECT_FIT_PARENT = 0,
  AR_ASPECT_FILL_PARENT = 1,
  AR_ASPECT_WRAP_CONTENT = 2,
  AR_ASPECT_MATCH_PARENT = 3,
  AR_16_9_FIT_PARENT = 4,
  AR_4_3_FIT_PARENT = 5
}

export enum QTPlayerRenderView {
  NONE = 0,
  SURFACE = 1,
  TEXTURE = 2,
  SURFACE_FORCE = 3,
  TEXTURE_FORCE = 4
}
