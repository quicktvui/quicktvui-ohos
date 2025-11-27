import { EsData } from "./EsData"
import { HippyEngine } from "hippy"
import { LoadResult } from "./LoadResult"
import { LoadStatus } from "./LoadStatus"

export class AppContext {
  private _abilityContext: Context
  private _data: EsData | null = null
  private _engine: HippyEngine | null = null
  private _loadResult: LoadResult

  constructor(context: Context) {
    this._abilityContext = context
    this._loadResult = {
      status: LoadStatus.IDLE
    } as LoadResult
  }

  set engine(value: HippyEngine) {
    this._engine = value
  }

  get engine(): HippyEngine {
    return this._engine!
  }

  set data(value: EsData) {
    this._data = value
  }

  get data(): EsData {
    return this._data!
  }

  get abilityContext(): Context | null {
    return this._abilityContext!
  }

  set loadResult(value: LoadResult) {
    this._loadResult = value
  }

  get loadResult(): LoadResult {
    return this._loadResult
  }
}