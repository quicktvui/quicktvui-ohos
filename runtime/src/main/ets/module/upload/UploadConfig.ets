export interface UploadConfig {
  title?: string;
  description?: string;
  mode?: number;
  overwrite?: boolean;
  method?: string;
  headers?: object;
  metered?: boolean;
  roaming?: boolean;
  retry?: boolean;
  redirect?: boolean;
  proxy?: string;
  index?: number;
  begins?: number;
  ends?: number;
  gauge?: boolean;
  precise?: boolean;
  token?: string;
  priority?: number;

  //
  uploadCacheDir: string,
  progressThrottleInterval: number
}

