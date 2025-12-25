#!/bin/bash
set -e

# 1. 配置输入和输出文件
INPUT_JSON="app_info_list.json"
OUTPUT_FILE="output_app_data.json"
API_URL="https://api.extscreen.com/v1/client/appinfo"
TEMP_FILE="temp_data.txt"

# 检查输入文件是否存在
if [ ! -f "$INPUT_JSON" ]; then
  echo "❌ 错误：找不到输入文件 $INPUT_JSON"
  echo "请确保目录下有该文件，内容为提供的包名列表。"
  exit 1
fi

# 清空临时文件
> "$TEMP_FILE"

echo "🚀 开始处理..."

# 2. 循环读取输入 JSON 数组
jq -c '.[]' "$INPUT_JSON" | while read -r item; do
  PACKAGE=$(echo "$item" | jq -r '.package')
  # 如果需要渠道也可以获取，但输出格式里似乎不需要
  # CHANNEL=$(echo "$item" | jq -r '.channel')

  echo -n "👉 处理包名: $PACKAGE ... "

  # 3. 请求接口
  RESPONSE=$(curl -s --location "$API_URL" --form "package_name=$PACKAGE")

  # 检查 HTTP 状态或业务 Code
  CODE=$(echo "$RESPONSE" | jq -r '.code')

  if [[ "$CODE" != "200" ]]; then
    echo "❌ 接口请求失败 (Code: $CODE)"
    # 即使失败，也可以选择跳过或写入默认值，这里选择跳过
    continue
  fi

  # 4. 提取数据
  DATA=$(echo "$RESPONSE" | jq '.data')
  APP_NAME=$(echo "$DATA" | jq -r '.name // empty')
  ICON_URL=$(echo "$DATA" | jq -r '.icon // empty')

  # 简单的判空处理
  if [[ -z "$APP_NAME" ]]; then
      APP_NAME="未知应用"
  fi
  if [[ -z "$ICON_URL" ]]; then
      ICON_URL=""
  fi

  echo "✅ 获取成功: $APP_NAME"

  # 5. 拼装单条 JSON 对象并写入临时文件
  # 使用 jq 构造合法的 JSON 对象对象
  jq -n \
    --arg name "$APP_NAME" \
    --arg pkg "$PACKAGE" \
    --arg icon "$ICON_URL" \
    '{name: $name, pkg: $pkg, icon: $icon}' >> "$TEMP_FILE"

done

# 6. 合并结果并生成最终文件
echo ""
echo "📦 正在生成最终 JSON 文件..."

# 使用 jq -s 将多行 JSON 对象合并为一个 JSON 数组
jq -s '.' "$TEMP_FILE" > "$OUTPUT_FILE"

# 清理临时文件
rm "$TEMP_FILE"

echo "🎉 完成！结果已保存到: $OUTPUT_FILE"
echo "你可以直接复制该文件的内容到 Vue 代码中。"