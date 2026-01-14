# 协议

对安卓中的协议进行兼容

## 使用最新版本

```
esapp://es.hello.world?from=cmd
```

## 指定版本

```
esapp://es.hello.world/2.0?from=cmd
```

## 全部参数

```
esapp://es.hello.world/2.0?entry=Debug&uri=assets:///vue/&params={"key":"value"}&debug=true&from=cmd
```

## 命令调用

```
hdc shell "aa start -b es.hello.world -a EntryAbility -U 'esapp://es.hello.world/2.0?entry=Debug&uri=assets%3A%2F%2F%2Fvue&params=%7B%22key%22%3A%22value%22%7D&debug=true&from=cmd'"
```

## 启动 runtime

```
hdc shell "aa start -b com.extscreen.runtime -a EntryAbility"
```

## 启动 runtime & es.com.elsbharmony.tv & 最新版本 & 正式环境

```
hdc shell "aa start -b com.extscreen.runtime -a EntryAbility -U 'esapp://es.com.elsbharmony.tv?from=cmd&entry=Application'"

```

## 启动 runtime & es.com.elsbharmony.tv & 0.0.2 & 正式环境

```
hdc shell "aa start -b com.extscreen.runtime -a EntryAbility -U 'esapp://es.com.elsbharmony.tv/0.0.2?from=cmd&entry=Application'"

```

## 启动 runtime & es.com.elsbharmony.tv & 0.0.2 & 测试环境

`http://test-api.extscreen.com/extscreenapi/api/extend_screen/v2/hili/client/tvinfo/harmony`
进行编码
`http%3A%2F%2Ftest-api.extscreen.com%2Fextscreenapi%2Fapi%2Fextend_screen%2Fv2%2Fhili%2Fclient%2Ftvinfo%2Fharmony`

```
hdc shell "aa start -b com.extscreen.runtime -a EntryAbility -U 'esapp://es.com.elsbharmony.tv/0.0.2?from=cmd&entry=Application&uri=http%3A%2F%2Ftest-api.extscreen.com%2Fextscreenapi%2Fapi%2Fextend_screen%2Fv2%2Fhili%2Fclient%2Ftvinfo%2Fharmony'"
```


## 启动 runtime & es.com.elsbharmony.tv & 本地代码

`assets:///vue`
进行编码
`assets%3A%2F%2F%2Fvue`

```
hdc shell "aa start -b com.extscreen.runtime -a EntryAbility -U 'esapp://es.com.elsbharmony.tv/0.0.2?from=cmd&uri=assets%3A%2F%2F%2Fvue'"
```

## 启动本地调试

`192.168.40.67 `
无需编码
hdc shell aa start \
-b com.extscreen.runtime \
-a EntryAbility \
-U "esapp://es.hello.world/2.0?entry=Debug?uri=192.168.40.98&debug=true&from=cmd"

```
hdc shell "aa start -b com.extscreen.runtime -a EntryAbility -U 'esapp://es.hello.world/2.0?uri=192.168.40.98&debug=true&from=cmd&entry=Debug'"
```

```
hdc shell "aa start -b com.extscreen.runtime -a EntryAbility -U 'esapp://es.hello.world/2.0?uri=192.168.40.67&debug=true&from=cmd&entry=Debug'"
```