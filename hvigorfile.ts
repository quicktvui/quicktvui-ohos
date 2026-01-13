import { appTasks } from '@ohos/hvigor-ohos-plugin';

import {
  appTasks, OhosPluginId, OhosAppContext, OhosHapContext
} from '@ohos/hvigor-ohos-plugin';
import { hvigor } from '@ohos/hvigor';
import * as fs from 'fs';
import * as path from 'path';

// 辅助函数：读取并解析 json5 (支持注释和尾部逗号)
function readJson5(filePath: string) {
  if (!fs.existsSync(filePath)) return null;
  const content = fs.readFileSync(filePath, 'utf-8');
  // 使用 new Function 解析，完美兼容 JSON5 语法
  try {
    return (new Function("return " + content))();
  } catch (e) {
    console.error(`[PermissionSwitch] JSON5 解析失败: ${filePath}`, e);
    return null;
  }
}

export default {
  system: appTasks,
  plugins: [{
    pluginId: 'bundleName-permission-switch',
    apply(rootNode) {
      hvigor.nodesEvaluated(() => {
        const appContext = rootNode.getContext(OhosPluginId.OHOS_APP_PLUGIN) as OhosAppContext;
        if (!appContext) {
          console.error('❌ [ERROR] 无法获取 AppContext，请检查 system 配置是否为 appTasks');
          return;
        }
        const currentProduct = appContext.getCurrentProduct();
        const bundleName = currentProduct.getBundleName();
        console.log(`>>> [PermissionSwitch] 当前构建 BundleName: ${bundleName}`);

        //商店渠道
        if (bundleName === 'tv.harmonyos.appstore') {
          console.log(`>>> [PermissionSwitch] 命中目标包名，准备注入权限配置...`);
          rootNode.subNodes((subNode) => {
            if (subNode.getNodeName() === 'runtime') {
              const hapContext = subNode.getContext(OhosPluginId.OHOS_HAP_PLUGIN) as OhosHapContext;
              if (!hapContext) {
                return;
              }
              const configPath = path.join(hapContext.getModulePath(), 'configs', 'module_appstore.json5');
              if (fs.existsSync(configPath)) {
                try {
                  const newConfigObj = readJson5(configPath); // 使用增强的读取函数
                  if (newConfigObj) {
                    hapContext.setModuleJsonOpt(newConfigObj);
                    console.log(`✅ [SUCCESS] 已为模块 [runtime] 注入 module.json5`);
                  }
                } catch (e) {
                  console.error(`❌ [ERROR] 注入失败: ${e}`);
                }
              } else {
                console.warn(`⚠️ 未找到配置文件: ${configPath}`);
              }
            }
          });
        } else {
          console.log(`>>> [PermissionSwitch] 包名不匹配，跳过注入逻辑。`);
        }
      });
    }
  }]
};