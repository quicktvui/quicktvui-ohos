import { Config } from "./Config";

export const DefaultConfig: Config = {
  appId: 'debug',
  appEntry: 'Application',
  appDebug: false,
  //
  bundleSource: 'REMOTE', //枚举：LOCAL | REMOTE
  bundleUri: 'https://api.extscreen.com/extscreenapi/api/extend_screen/v2/hili/client/tvinfo', //assets:///vue',
  //
  params: undefined
}