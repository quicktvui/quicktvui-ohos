import { Download } from "./Download";
import { DownloadState } from "./DownloadState";

export interface DownloadStatus<T> {
  state: DownloadState;
  download: Download | null;
  data?: T | undefined | null
}
