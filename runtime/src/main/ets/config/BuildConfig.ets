// config/BuildConfig.ts
import BuildProfile from 'BuildProfile'

export interface IBuildConfig {
  entryPage: string
  enableLog: boolean
  packageName: string
  parameters: string
}

export const BuildConfig: IBuildConfig = {
  entryPage: BuildProfile.ENTRY_PAGE ?? 'Application',
  enableLog: BuildProfile.ENABLE_LOG ?? false,
  packageName: BuildProfile.PRODUCT_NAME,
  parameters: BuildProfile.PARAMETERS
}