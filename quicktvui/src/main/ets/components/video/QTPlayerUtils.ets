import { media } from "@kit.MediaKit";
import { QTPlayerAspectRatio } from "../player/QTPlayerEnums";

export function getAvPlayerSpeed(speed: string): media.PlaybackSpeed {
  let sp = media.PlaybackSpeed.SPEED_FORWARD_1_00_X;
  switch (speed) {
    case '0.5':
      sp = media.PlaybackSpeed.SPEED_FORWARD_0_50_X;
      break;
    case '0.75':
      sp = media.PlaybackSpeed.SPEED_FORWARD_0_75_X;
      break;
    case '1':
      sp = media.PlaybackSpeed.SPEED_FORWARD_1_00_X;
      break;
    case '1.2':
    case '1.25':
      sp = media.PlaybackSpeed.SPEED_FORWARD_1_25_X;
      break;
    case '1.5':
      sp = media.PlaybackSpeed.SPEED_FORWARD_1_50_X;
      break;
    case '1.75':
      sp = media.PlaybackSpeed.SPEED_FORWARD_1_75_X;
      break;
    case '2.0':
      sp = media.PlaybackSpeed.SPEED_FORWARD_2_00_X;
      break;
    case '2.5':
      sp = media.PlaybackSpeed.SPEED_FORWARD_3_00_X;
      break;
  }
  return sp;
}

export function getAspectRatioSize(ratio: number, videoSize: PlayerViewSize, viewSize: PlayerViewSize): PlayerViewSize {
  let surfaceW: number = 0, surfaceH: number = 0,
    videoWidth: number = videoSize.width, videoHeight = videoSize.height,
    viewWidth: number = viewSize.width, viewHeight = viewSize.height;

  if (ratio == QTPlayerAspectRatio.AR_ASPECT_MATCH_PARENT) {
    surfaceW = viewWidth;
    surfaceH = viewHeight;
  } else {
    let viewPer = viewWidth / viewHeight, displayPer: number;
    switch (ratio) {
      case QTPlayerAspectRatio.AR_16_9_FIT_PARENT:
        displayPer = 16 / 9;
        break;
      case QTPlayerAspectRatio.AR_4_3_FIT_PARENT:
        displayPer = 4 / 3;
        break;
      case QTPlayerAspectRatio.AR_ASPECT_FIT_PARENT:
      case QTPlayerAspectRatio.AR_ASPECT_FILL_PARENT:
      case QTPlayerAspectRatio.AR_ASPECT_WRAP_CONTENT:
      default :
        displayPer = videoWidth / videoHeight;
        break;
    }
    const wider = displayPer > viewPer;
    switch (ratio) {
      case QTPlayerAspectRatio.AR_ASPECT_FIT_PARENT: // 长边全屏短边居中(等比) AR_ASPECT_FIT_PARENT
      case QTPlayerAspectRatio.AR_16_9_FIT_PARENT: // 16:9
      case QTPlayerAspectRatio.AR_4_3_FIT_PARENT: // 4:3
        if (wider) {
          surfaceW = viewWidth;
          surfaceH = surfaceW / displayPer;
        } else {
          surfaceH = viewHeight;
          surfaceW = surfaceH * displayPer;
        }
        break;
      case QTPlayerAspectRatio.AR_ASPECT_FILL_PARENT: // 长边居中裁剪，短边全屏(等比) AR_ASPECT_FILL_PARENT
        if (wider) {
          surfaceH = viewHeight;
          surfaceW = surfaceH * displayPer;
        } else {
          surfaceW = viewWidth;
          surfaceH = surfaceW / displayPer;
        }
        break;
      case QTPlayerAspectRatio.AR_ASPECT_WRAP_CONTENT: // 展示不超过父view(等比) AR_ASPECT_WRAP_CONTENT
        if (wider) {
          surfaceW = Math.min(viewWidth, videoWidth);
          surfaceH = surfaceW / displayPer;
        } else {
          surfaceH = Math.min(viewHeight, videoHeight);
          surfaceW = surfaceH * displayPer;
        }
        break;
    }
  }

  return {width: surfaceW, height: surfaceH}
}

export interface PlayerViewSize {
  width: number
  height: number
}
