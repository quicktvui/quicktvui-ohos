export interface IDefaultConfig {
  entryPage: string
  enableLog: boolean
  packageName: string
  parameters: string
}

export const DefaultConfig: IDefaultConfig = {
  entryPage: 'Application',
  enableLog: false,
  packageName: '',
  parameters: ''
}