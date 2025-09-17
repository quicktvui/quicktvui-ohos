import { Upload } from "./Upload";
import { UploadState } from "./UploadState";

export interface UploadStatus<T> {
  state: UploadState;
  upload: Upload | null;
  data?: T | undefined | null
}
