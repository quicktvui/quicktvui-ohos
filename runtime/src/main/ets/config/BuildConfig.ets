import BuildProfile from 'BuildProfile'
import { Config } from './Config'

export const BuildConfig: Config = {
  //
  appId: BuildProfile.APP_ID,
  appEntry: BuildProfile.APP_ENTRY,
  appDebug: BuildProfile.APP_DEBUG,
  //
  bundleUri: BuildProfile.BUNDLE_URI,
  //
  params: BuildProfile.PARAMS ? JSON.parse(BuildProfile.PARAMS) : undefined,
}