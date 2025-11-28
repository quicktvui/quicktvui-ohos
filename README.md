# quicktvui-ohos

## build
本项目依赖`hippy_ohos_tv`及`hippy_ohos_tv_extend`请确保以下项目结构：
```
Workspace/
├── quicktvui-ohos/     (当前项目)__
├── hippy_ohos_tv/      (依赖项目)
└── hippy_ohos_tv_extend/ (依赖项目)
```


## 临时打包方法

### 1.替换应用名称
修改 AppScope/resources/base/element/string.json

### 2.替换icon
替换 ppScope/resources/base/media/app_icon.png

### 3.替换vue代码
替换 runtime/src/main/resources/rawfile/vue下内容

### 资源
