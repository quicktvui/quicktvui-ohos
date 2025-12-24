import { Config } from "./Config";

export const DefaultConfig: Config = {
  appId: '',
  appEntry: 'Application',
  appDebug: false,
  // api
  apiHost: '', //TODO
  apiVersion: '',
  //
  bundleSource: 'REMOTE', //枚举：LOCAL | REMOTE
  bundleUri: '',
  //
  params: undefined
}