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
build-package文件夹资源如下:

应用名称 | 包名 | 图标 | 代码包
--|--|--|--|
土豆逗科普|tv.huan.tudoudou|土豆逗科普.png|土豆逗科普.zip
传统相声评书荟|tv.huan.xiangsheng|传统相声评书荟.png|传统相声评书荟.zip
学国学学古诗|tv.huan.xiangsheng|学国学学古诗.png|学国学学古诗.zip
吴蔓八段锦|tv.huan.wmbdj|吴蔓八段锦.png|吴蔓八段锦.zip
JJ斗地主赛事|tv.huan.jjddzss|JJ斗地主赛事.png|JJ斗地主赛事.zip




### 1.替换应用名称
修改 AppScope/resources/base/element/string.json

### 2.替换icon
替换 ppScope/resources/base/media/app_icon.png

### 3.替换vue代码
替换 runtime/src/main/resources/rawfile/vue下内容

