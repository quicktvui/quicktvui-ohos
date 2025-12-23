#!/usr/bin/env bash

set -e

CHANNEL_NAME="$1"

if [ -z "$CHANNEL_NAME" ]; then
  echo "❌ 用法错误："
  echo "   ./app_add.sh xxx"
  exit 1
fi

ROOT_DIR="$(pwd)"
RUNTIME_DIR="$ROOT_DIR/runtime"
SIGN_DIR="$ROOT_DIR/sign"
ROOT_BUILD_PROFILE="$ROOT_DIR/build-profile.json5"
RUNTIME_BUILD_PROFILE="$RUNTIME_DIR/build-profile.json5"

echo "========================================"
echo "🚀 开始添加打包渠道：$CHANNEL_NAME"
echo "📁 项目根目录：$ROOT_DIR"
echo "========================================"

############################################
# 1. runtime/src/template → runtime/src/xxx
############################################
if [ ! -d "$RUNTIME_DIR/src/template" ]; then
  echo "❌ 错误：找不到 runtime/src/template"
  exit 1
fi

if [ -d "$RUNTIME_DIR/src/$CHANNEL_NAME" ]; then
  echo "⚠️ 已存在：runtime/src/$CHANNEL_NAME，跳过拷贝"
else
  echo "📦 拷贝 runtime/src/template → runtime/src/$CHANNEL_NAME"
  cp -R "$RUNTIME_DIR/src/template" "$RUNTIME_DIR/src/$CHANNEL_NAME"
fi

############################################
# 2. runtime/build-profile.json5 添加 target
############################################
echo "📝 修改 runtime/build-profile.json5（追加 target）"

TARGET_BLOCK=$(cat <<EOF

    {
      "name": "$CHANNEL_NAME",
      "resource": {
        "directories": [
          "./src/main/resources",
          "./src/$CHANNEL_NAME/resources"
        ]
      }
    }
EOF
)

sed -i '' "/\"targets\"[[:space:]]*:[[:space:]]*\\[/,/\\][[:space:]]*$/ {
  /]/ i\\
$TARGET_BLOCK,
}" "$RUNTIME_BUILD_PROFILE"

############################################
# 3. sign/template → sign/xxx
############################################
if [ ! -d "$SIGN_DIR/template" ]; then
  echo "❌ 错误：找不到 sign/template"
  exit 1
fi

if [ -d "$SIGN_DIR/$CHANNEL_NAME" ]; then
  echo "⚠️ 已存在：sign/$CHANNEL_NAME，跳过拷贝"
else
  echo "🔐 拷贝 sign/template → sign/$CHANNEL_NAME"
  cp -R "$SIGN_DIR/template" "$SIGN_DIR/$CHANNEL_NAME"
fi

############################################
# 4. 根目录 build-profile.json5
############################################
echo "📝 修改 根目录 build-profile.json5"

# g_ 前缀规则
SIGNING_NAME="$CHANNEL_NAME"
if [[ "$CHANNEL_NAME" == g_* ]]; then
  SIGNING_NAME="${CHANNEL_NAME#g_}"
fi

############################################
# 4.1 products 追加
############################################
PRODUCT_BLOCK=$(cat <<EOF

      {
        "name": "$CHANNEL_NAME",
        "signingConfig": "$SIGNING_NAME",
        "compatibleSdkVersion": 15,
        "compileSdkVersion": 18,
        "targetSdkVersion": 18,
        "bundleName": "tv.huan.$CHANNEL_NAME.hmos",
        "runtimeOS": "OpenHarmony",
        "buildOption": {
          "strictMode": {
            "caseSensitiveCheck": true,
            "useNormalizedOHMUrl": true
          }
        }
      }
EOF
)

sed -i '' "/\"products\"[[:space:]]*:[[:space:]]*\\[/,/\\][[:space:]]*$/ {
  /]/ i\\
$PRODUCT_BLOCK,
}" "$ROOT_BUILD_PROFILE"

############################################
# 4.2 signingConfigs 追加
############################################
SIGN_BLOCK=$(cat <<EOF

      {
        "name": "$SIGNING_NAME",
        "material": {
          "storeFile": "sign_private/$SIGNING_NAME/key.p12",
          "storePassword": "0000001C54E774FF7C244D491F2569227818134F3117E94F9701E989B7906CBD405342F5DF98541586A783F2",
          "keyAlias": "esapp",
          "keyPassword": "0000001C7C201985169C5A190160745832FC25F913B10A76178042CCAD90DDEC8EC3521109DB60D22BFC7A32",
          "signAlg": "SHA256withECDSA",
          "profile": "sign_private/$SIGNING_NAME/key.p7b",
          "certpath": "sign_private/$SIGNING_NAME/key.cer"
        }
      }
EOF
)

sed -i '' "/\"signingConfigs\"[[:space:]]*:[[:space:]]*\\[/,/\\][[:space:]]*$/ {
  /]/ i\\
$SIGN_BLOCK,
}" "$ROOT_BUILD_PROFILE"

############################################
# 4.3 modules.runtime.targets 追加
############################################
MODULE_TARGET_BLOCK=$(cat <<EOF

        {
          "name": "$CHANNEL_NAME",
          "applyToProducts": [
            "$CHANNEL_NAME"
          ]
        }
EOF
)

sed -i '' "/\"name\"[[:space:]]*:[[:space:]]*\"runtime\"/,/\\][[:space:]]*$/ {
  /\"targets\"[[:space:]]*:[[:space:]]*\\[/,/\\][[:space:]]*$/ {
    /]/ i\\
$MODULE_TARGET_BLOCK,
  }
}" "$ROOT_BUILD_PROFILE"

############################################
# 5. 使用者提醒（重点，必须人工处理）
############################################
echo ""
echo "========================================"
echo "⚠️ 重要提醒（必须人工确认 / 修改）"
echo "========================================"
echo ""
echo "1️⃣ 修改应用名称"
echo "   文件：runtime/src/$CHANNEL_NAME/resources/base/element/string.json"
echo "   字段：app_name → 改为正式应用名称"
echo ""
echo "2️⃣ 替换应用图标"
echo "   文件：runtime/src/$CHANNEL_NAME/resources/base/media/app_icon.png"
echo "   ⚠️ 必须替换为正式图标"
echo ""
echo "3️⃣ 添加快应用代码"
echo "   目录：runtime/src/$CHANNEL_NAME/resources/rawfile/vue"
echo "   ⚠️ 放入对应渠道的快应用代码"
echo ""
echo "4️⃣ 替换正式签名文件（非常重要）"
echo "   目录：sign/$CHANNEL_NAME/"
echo "   文件：key.p12 / key.p7b / key.cer"
echo ""
echo "5️⃣ 检查 bundleName"
echo "   当前生成：tv.huan.$CHANNEL_NAME.hmos"
echo "   ⚠️ 上线前务必替换为真实包名"
echo ""
echo "6️⃣ g_ 前缀规则说明"
echo "   如果渠道名是 g_xxx："
echo "   - signingConfig 使用 xxx"
echo "   - 签名目录使用 sign_private/xxx/"
echo ""
echo "7️⃣ 本脚本为『文本级追加』"
echo "   - 不校验 json5 合法性"
echo "   - 不调整原有格式和顺序"
echo "   - 手动修改 json5 时请注意逗号和结构"
echo ""
echo "========================================"
echo "✅ 渠道 $CHANNEL_NAME 生成完成"
echo "========================================"