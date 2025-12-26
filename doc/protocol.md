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
hdc shell aa start -b es.hello.world -a EntryAbility -u "esapp://es.hello.world/2.0?entry=Debug&uri=assets%3A%2F%2F%2Fvue%2F&params=%7B%22key%22%3A%22value%22%7D&debug=true&from=cmd"
```
