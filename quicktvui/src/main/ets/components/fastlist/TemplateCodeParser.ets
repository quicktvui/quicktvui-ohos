// TemplateCodeParser.ets
import {HippyAny,HippyMap} from 'hippy'
export class TemplateCodeParser {
  static TAG: string = "TemplateCodeParser";

  static readonly PENDING_PROP_TRANSLATION: string = "translation";
  static readonly PENDING_PROP_SIZE: string = "size";
  static readonly PENDING_PROP_LAYOUT: string = "layout";
  static readonly PENDING_PROP_FLEX_STYLE: string = "flexStyle";
  static readonly PLACEHOLDER_STYLE: string = "placeholderStyle";
  static readonly ITEM_SID: string = "itemSID";

  /** @deprecated */
  static readonly PENDING_PROP_EVENT_CLICK: string = "eventClick";
  /** @deprecated */
  static readonly PENDING_PROP_EVENT_FOCUS: string = "eventFocus";

  static readonly PENDING_PROP_SHOW_IF: string = "showIf";
  static readonly PENDING_PROP_CREATE_IF: string = "createIf";

  static readonly PENDING_PROPS_EVENT: Array<string> = [
    TemplateCodeParser.PENDING_PROP_EVENT_CLICK,
    TemplateCodeParser.PENDING_PROP_EVENT_FOCUS
  ];

  /**
   * 解析形如 ${xxx} 的 pendingProp
   */
  static parsePendingProp(obj: HippyAny): string | null {
    if (typeof obj === 'string') {
      let value: string = obj.trim();
      if (value.length > 3 && value.startsWith("${")) {
        return value.substring(2, value.length - 1);
      }
    }
    return null;
  }

  /**
   * 判断是否是等式表达式，例如 ${type=1}
   */
  static isEquationProp(obj: HippyAny): boolean {
    return typeof obj === 'string' && obj.startsWith("${") && obj.indexOf("=") > 0;
  }

  /**
   * 解析形如 ${key==value} 的表达式并从 dataMap 中验证是否相等
   */
  static parseBooleanFromPendingProp(prop: string, dataMap: HippyMap, code: HippyAny): boolean {
    if (typeof code === 'string') {
      let value: string = code.trim();
      if (value.length > 3 && value.startsWith("${")) {
        let expression: string = value.substring(2, value.length - 1);
        let eqArray: Array<string> = expression.split("==");
        if (eqArray.length != 2) {
          console.warn(`${TemplateCodeParser.TAG}: invalid expression: ${expression}`);
          return false;
        }

        let key: string = eqArray[0];
        let valueAfter: string = eqArray[1];
        let dataFromMap = TemplateCodeParser.getValueFromCode(dataMap, key);

        if (dataFromMap === null || dataFromMap === undefined) {
          console.info(`${TemplateCodeParser.TAG}: parseBoolean return false on key=${key}, valueAfter=${valueAfter}`);
          return false;
        }

        console.info(`${TemplateCodeParser.TAG}: parseBoolean key=${key}, valueAfter=${valueAfter}, dataFromMap=${dataFromMap}`);
        return String(dataFromMap) === valueAfter;
      }
    }
    return false;
  }

  /**
   * 从对象中提取值，支持 key 为 "a.b.c" 的多级路径
   */
  static getValueFromCode(data: HippyMap, code: string): HippyAny {
    if (!data || !code) {
      return null;
    }
    if(code.includes('.')){
      let parts: Array<string> = code.split(".");
      let result: HippyMap = data;

      for(let i =0;i < parts.length; i ++){
        let key = parts[i]
        let obj = result.has(key) ? result.get(key) : null
        if(i == parts.length - 1){
          return obj
        }else{
          if(obj instanceof Map){
            result = obj
          }else if(obj != null){
            console.error(`item Data 暂只支持map key:"${key},code:"${code}`)
          }
        }
      }
      return null;
    }else{
      return data.get(code)
    }
  }

  static parsePlaceholderProp(prop: string, map: HippyMap): string | null {

    let object: HippyAny = map.get(prop);
    const valueKey: string | null= TemplateCodeParser.parsePendingProp(object);

    if (valueKey != null && valueKey != '') {
      return valueKey;
    } else {
      const index: number = TemplateCodeParser.PENDING_PROPS_EVENT.indexOf(prop)
      if (index > -1) {
        return TemplateCodeParser.PENDING_PROPS_EVENT[index];
      } else {
        return null;
      }
    }
  }
}
