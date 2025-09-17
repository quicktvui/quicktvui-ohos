export interface Upload {
  id: number
  filePath: string
  fileAbsolutePath?: string
  fileName: string
  fileType: string
  uploadPath: string
  //
  fileLength?: number
  uploadLength?: number
}
