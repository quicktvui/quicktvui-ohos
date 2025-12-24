import { Config } from "./Config";

export const DefaultConfig: Config = {
  appId: 'debug',
  appEntry: 'Application',
  appDebug: false,
  // api
  apiHost: '',
  apiVersion: '',
  //
  bundleSource: 'LOCAL', //枚举：LOCAL | REMOTE
  bundleUri: 'assets:///vue',
  //
  params: undefined
}