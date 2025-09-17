import { UploadMessage } from "./UploadMessage";
import { UploadProgress } from "./UploadProgress";
import { UploadStatus } from "./UploadStatus";


export type UploadStatusListener = (uploadStatus: UploadStatus<UploadMessage>) => void

export type UploadProgressListener = (progressStatus: UploadStatus<UploadProgress>) => void
