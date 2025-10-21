import {HippyMap,HippyAny} from 'hippy'
import { TAG_QUICKTVUI } from '../Constant'
import { QTMap } from '../QTTypes';

interface MapEntry {
  key: string;
  value: HippyAny;
}

let arr: MapEntry[] = []; // ✅ 正确

export  class CommonUtils{


  static hippyMap2String(map : HippyMap | null)  {
    return hippyMapToString(map)
  }

  static hippyAny2String(obj : HippyAny | null) : string{
    if(!obj) {
      return 'null'
    }
    if(obj instanceof Map){
      return CommonUtils.hippyMap2String(obj)
    }else{
      return obj.toString();
    }
  }

  static updateMap(target : QTMap | null | undefined,update: QTMap | null | undefined){
    if(target && update){
      update.forEach((value,key)=>{
        target.set(key,value)
      })
    }
  }

  static  printObject(obj: HippyAny | null, indent: string = ''): void {
    if(!obj){
      console.warn(TAG_QUICKTVUI,`${indent}null`)
      return
    }
    if(obj instanceof Map){
      printMapPretty(obj,indent,false)
    }else{
      console.log(TAG_QUICKTVUI,`${indent}${JSON.stringify(obj)}`)
    }
  }

  static  printMapPretty(
    map: HippyMap,
    prefix: string = '',
    isLast: boolean = true
  ): void {
    printMapPretty(map,prefix,isLast)
  }
}

function mapToString(map : HippyMap | null){
  if(!map){
    console.warn(TAG_QUICKTVUI,'mapToString error  map is null')
    return;
  }

}


function hippyMapToString(map: HippyMap | null, indent: number = 0): string {
  if(!map){
    return 'null'
  }
  let result: string = '';
  const indentStr: string = '  '.repeat(indent);

  const keys: Array<string> = Array.from(map.keys());

  for (let i = 0; i < keys.length; i++) {
    const key: string = keys[i];
    const value: HippyAny = map.get(key);

    if (value instanceof Map) {
      result += `${indentStr}${key}:\n`;
      result += hippyMapToString(value, indent + 1); // 递归子Map
    } else {
      result += `${indentStr}${key}: ${String(value)}\n`;
    }
  }
  return result;
}


function printMapPretty(
  map: HippyMap | null,
  prefix: string = '',
  isLast: boolean = true
): void {
  if(!map){
    console.warn(TAG_QUICKTVUI,'printMapPretty error  map is null')
    return;
  }
  let entries: MapEntry[] = [];
  let iterator = map.entries();
  let current = iterator.next();

  while (!current.done) {
    let entry = current.value;
    let key = entry[0];
    let value = entry[1];
    entries.push({ key: key, value: value });
    current = iterator.next();
  }

  let total = entries.length;

  for (let i = 0; i < total; i++) {
    let entry = entries[i];
    let isLastEntry = i === total - 1;
    let branch = isLastEntry ? '└─ ' : '├─ ';
    let linePrefix = prefix + branch;

    if (entry.value instanceof Map) {
      console.log(TAG_QUICKTVUI,linePrefix + entry.key);
      let nextPrefix = prefix + (isLastEntry ? '   ' : '│  ');
      printMapPretty(entry.value as HippyMap, nextPrefix, true);
    } else {
      console.log(TAG_QUICKTVUI,linePrefix + entry.key + ': ' + String(entry.value));
    }
  }
}
