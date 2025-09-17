import {HippyRenderBaseView,HippyMap,HippyAny,HippyValue,HippyArray} from 'hippy'
import { QTFastFlexView } from './components/fastlist/QTFastFlexView'
import { QTFastListView } from './components/fastlist/QTFastListView'

export type QTView = HippyRenderBaseView
export type QTMap = HippyMap |  Map<string, HippyAny>
export type QTAny = HippyAny
export type QTValue = HippyValue
export type QTPendingListView = QTFastListView | QTFastFlexView
export type QTArray = HippyArray
