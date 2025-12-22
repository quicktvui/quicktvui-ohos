#!/bin/bash
set -e

# 当前执行目录（终端执行脚本时所在目录）
PROJECT_ROOT="$(pwd)"

# 或者，如果你想用脚本文件所在目录，替换上面那行：
# PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

API_URL="https://api.extscreen.com/v1/client/appinfo"

INPUT_JSON="app_info_list.json"

if [ ! -f "$INPUT_JSON" ]; then
  echo "❌ 输入文件 $INPUT_JSON 不存在"
  exit 1
fi

jq -c '.[]' "$INPUT_JSON" | while read -r item; do
  CHANNEL=$(echo "$item" | jq -r '.channel')
  PACKAGE=$(echo "$item" | jq -r '.package')

  echo ">>> 处理渠道: $CHANNEL，包名: $PACKAGE"

  STRING_JSON_PATH="$PROJECT_ROOT/runtime/src/$CHANNEL/resources/base/element/string.json"
  MEDIA_DIR="$PROJECT_ROOT/runtime/src/$CHANNEL/resources/base/media"
  APP_ICON_PATH="$MEDIA_DIR/app_icon.png"

  mkdir -p "$MEDIA_DIR"
  mkdir -p "$(dirname "$STRING_JSON_PATH")"

  if [ ! -f "$STRING_JSON_PATH" ]; then
    echo '{ "string": [ { "name": "app_name", "value": "default" } ] }' > "$STRING_JSON_PATH"
  fi

  RESPONSE=$(curl -s --location "$API_URL" --form "package_name=$PACKAGE")

  CODE=$(echo "$RESPONSE" | jq -r '.code')
  if [[ "$CODE" != "200" ]]; then
    echo "❌ 接口失败: $PACKAGE"
    continue
  fi

  DATA=$(echo "$RESPONSE" | jq '.data')

  APP_NAME=$(echo "$DATA" | jq -r '.name')
  if [[ -z "$APP_NAME" || "$APP_NAME" == "null" ]]; then
    echo "⚠️ 未获取到名称，跳过 $PACKAGE"
    continue
  fi

  echo "  获取到名称: $APP_NAME"

  jq --arg val "$APP_NAME" '
    if (.string | type == "array") then
      ( .string[] | select(.name == "app_name") ).value = $val
    else
      .string = [ { "name": "app_name", "value": $val } ]
    end
  ' "$STRING_JSON_PATH" > "$STRING_JSON_PATH.tmp" && mv "$STRING_JSON_PATH.tmp" "$STRING_JSON_PATH"

  echo "  ✅ 更新了 $STRING_JSON_PATH"

  ICON_URL=$(echo "$DATA" | jq -r '.icon')
  if [[ "$ICON_URL" != "null" && -n "$ICON_URL" ]]; then
    echo "  准备下载图标：$ICON_URL"
    curl -L "$ICON_URL" -o "$APP_ICON_PATH"
    echo "  ✅ 图标保存到 $APP_ICON_PATH"
  else
    echo "  ⚠️ 无图标 URL，跳过图标下载"
  fi

done

echo ""
echo "🎉 全部处理完成"