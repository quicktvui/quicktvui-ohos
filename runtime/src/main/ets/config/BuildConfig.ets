import BuildProfile from 'BuildProfile'
import { Config } from './Config'

export const BuildConfig: Config = {
  //
  appId: BuildProfile.APP_ID,
  appName: BuildProfile.APP_NAME,
  appIcon: BuildProfile.APP_ICON,
  appVersion: BuildProfile.APP_VERSION,
  appEntry: BuildProfile.APP_ENTRY,
  appDebug: BuildProfile.APP_DEBUG,
  appBundleUri: BuildProfile.APP_BUNDLE_URI,
  appParams: BuildProfile.APP_PARAMS ? JSON.parse(BuildProfile.APP_PARAMS) : undefined,
}