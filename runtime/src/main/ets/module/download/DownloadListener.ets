import { DownloadMessage } from "./DownloadMessage";
import { DownloadProgress } from "./DownloadProgress";
import { DownloadStatus } from "./DownloadStatus";


export type DownloadStatusListener = (downloadStatus: DownloadStatus<DownloadMessage>) => void

export type DownloadProgressListener = (progressStatus: DownloadStatus<DownloadProgress>) => void
