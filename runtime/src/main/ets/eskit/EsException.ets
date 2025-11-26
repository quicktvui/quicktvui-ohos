import { int } from "@ohos/zxing/src/main/ets/customTypings"


export class EsException extends Error {
  code:int = 0
  constructor(code:int, message: string) {
    super()
    this.message = message
    this.code = code
  }
}