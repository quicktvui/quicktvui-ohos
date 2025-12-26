#!/bin/bash
set -e

# ========================================================
# 1. 基础环境（以脚本执行目录为工程根）
# ========================================================
PROJECT_ROOT=$(pwd)
cd "$PROJECT_ROOT"

# ========================================================
# 2. 构建参数
# ========================================================
MODULE_NAME="runtime"
BUILD_MODE="release"
DEVICE_TYPE="tablet"

# 构建时间戳（如 202512221636）
BUILD_TIME=$(date +"%Y%m%d%H%M")

# 输出目录：dist/时间戳/
OUT_DIR="$PROJECT_ROOT/dist/$BUILD_TIME"
mkdir -p "$OUT_DIR"

echo "📦 构建输出目录: $OUT_DIR"

# ========================================================
# 3. 构建函数
# ========================================================
build_channel() {
  CHANNEL=$1

  echo ""
  echo "=========================================="
  echo ">>> 开始构建渠道: $CHANNEL"
  echo ">>> 构建时间: $BUILD_TIME"
  echo "=========================================="

  hvigorw \
    --mode module \
    -p module=${MODULE_NAME}@${CHANNEL} \
    -p product=${CHANNEL} \
    -p buildMode=${BUILD_MODE} \
    -p requiredDeviceType=${DEVICE_TYPE} \
    assembleHap \
    --analyze=normal \
    --parallel \
    --incremental \
    --daemon

  # 查找 signed hap（保持原始命名）
  HAP_PATH=$(find "${MODULE_NAME}/build" \
    -name "*${CHANNEL}*-signed.hap" | head -n 1)

  if [[ -z "$HAP_PATH" ]]; then
    echo "❌ 未找到 ${CHANNEL} 的 HAP 产物"
    exit 1
  fi

  # 原始文件名
  ORIGINAL_NAME=$(basename "$HAP_PATH")

  # 新文件名：原名 + 时间戳
  TARGET_NAME="${ORIGINAL_NAME%.hap}_${BUILD_TIME}.hap"

  cp "$HAP_PATH" "$OUT_DIR/$TARGET_NAME"

  echo "✅ 构建完成: $OUT_DIR/$TARGET_NAME"
}

# ========================================================
# 4. 渠道列表
# ========================================================
CHANNELS=(
app_center
#ke_ting_jian_shen
#tudoudou
#baduanjin
#wm_baduanjin
#  g_2048
#  g_2048_rectangle
#  g_black_white
#  g_box
#  g_brush
#  g_chess
#  g_fog_lock
#  g_fruit_sort
#  g_guess_location
#  g_hannuota
#  g_pacman
#  g_rectangle
#  g_road
#  g_snake
)

# ========================================================
# 5. 执行构建
# ========================================================
for CHANNEL in "${CHANNELS[@]}"; do
  build_channel "$CHANNEL"
done

echo ""
echo "🎉 所有渠道构建完成"
echo "📦 构建产物目录: $OUT_DIR"