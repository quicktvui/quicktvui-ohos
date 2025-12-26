# HDC

## 启动命令

`hdc shell aa start -b <BundleName> -a <AbilityName>`

例子：启动应用中心

`hdc shell aa start -b cn.openharmony.app.center -a EntryAbility`
`hdc shell aa start -b cn.openharmony.app.center -a EntryAbility -m runtime`

```
hdc shell
aa start -b cn.openharmony.app.center -a EntryAbility
```

## 启动传递参数

### 传递字符串

```
hdc shell aa start -b cn.openharmony.app.center -m runtime -a EntryAbility -s "userName" "HuanTV" -s "token" "abcdefg"
```

### 传递整数

```
hdc shell aa start -b cn.openharmony.app.center -m runtime -a default -i "userId" 10086
```