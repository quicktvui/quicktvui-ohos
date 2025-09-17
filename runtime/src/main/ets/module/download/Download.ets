export interface Download {
  id: number
  fileUrl: string
  fileMD5: string
  fileName: string
  fileType: string
  //
  fileLength?: number
  downloadLength?: number
  downloadPath?: string
}
