import BuildProfile from 'BuildProfile'
import { BundleSourceType, Config } from './Config'

export const BuildConfig: Config = {
  //
  appId: BuildProfile.APP_ID,
  appEntry: BuildProfile.APP_ENTRY,
  appDebug: BuildProfile.APP_DEBUG,
  //
  apiHost: BuildProfile.API_HOST,
  apiVersion: BuildProfile.API_VERSION,
  //
  bundleSource: BuildProfile.BUNDLE_SOURCE as BundleSourceType,
  bundleUri: BuildProfile.BUNDLE_URI,
  //
  params: BuildProfile.PARAMS ? JSON.parse(BuildProfile.PARAMS) : undefined,
}