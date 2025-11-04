import { LoadStatus } from "./LoadStatus"
import { BusinessError } from "@kit.BasicServicesKit"

export interface LoadResult {
  status: LoadStatus
  exception: BusinessError<string>
}