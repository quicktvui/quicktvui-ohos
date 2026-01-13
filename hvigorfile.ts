import { appTasks } from '@ohos/hvigor-ohos-plugin';

import {
  appTasks, OhosPluginId, OhosAppContext, OhosHapContext
} from '@ohos/hvigor-ohos-plugin';
import { hvigor } from '@ohos/hvigor';
import * as fs from 'fs';
import * as path from 'path';

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
                  const fileContent = fs.readFileSync(configPath, 'utf-8');
                  const jsonContent = fileContent.replace(/\/\/.*|\/\*[\s\S]*?\*\//g, '');
                  const newConfigObj = JSON.parse(jsonContent);
                  hapContext.setModuleJsonOpt(newConfigObj);
                  console.log(`✅ [SUCCESS] 已为模块 [runtime] 注入 module.json5 (Bundle: ${bundleName})`);
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