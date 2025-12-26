# 启动

## 启动应用中心

`hdc shell aa start -b <BundleName> -a <AbilityName>`

例子：启动应用中心

`hdc shell aa start -b cn.openharmony.app.center -a EntryAbility`
`hdc shell aa start -b cn.openharmony.app.center -a EntryAbility -m runtime`

```
hdc shell
aa start -b cn.openharmony.app.center -a EntryAbility
```

## 启动传递参数


```
hdc shell aa start -b cn.openharmony.app.center -m runtime -a default -u "esapp://action/start?es_pkg=test&from=cmd&uri=192.168.40.92:38989"
```