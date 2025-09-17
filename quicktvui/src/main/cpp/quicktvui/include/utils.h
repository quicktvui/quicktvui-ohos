//
// Created on 2025/9/3.
//
// Node APIs are not fully supported. To solve the compilation error of the interface cannot be found,
// please include "napi/native_api.h".

#ifndef HIPPY_UTILS_H
#define HIPPY_UTILS_H

#endif //HIPPY_UTILS_H
#ifndef MAP_PRINTER_H
#define MAP_PRINTER_H

#include <hilog/log.h>
#include <unordered_map>
#include <memory>
#include <string>
#include <unordered_set>
#include <sstream>

// 假设 HippyValue 的头文件路径，根据实际情况调整
#include <string>
#include "dom/layout_node.h"

// 定义你的 Domain 和 Tag
constexpr unsigned int MAP_PRINTER_DOMAIN = 0x12345; // 替换为你的实际domain
constexpr char MAP_PRINTER_TAG[] = "quicktvui";
using namespace hippy::dom;
using namespace footstone::value; 
namespace qt_util {

/**
 * @brief 将 HippyValue 转换为可读的字符串表示
 * @param value HippyValue 的 shared_ptr
 * @return 值的字符串表示
 */
std::string HippyValueToString(const std::shared_ptr<footstone::value::HippyValue>& value);

/**
 * @brief 打印 map 中所有的 key-value 对
 * @param target_map 要打印的 map 引用
 * @param map_name map 的名称（用于日志标识，可选）
 * @param domain 日志domain（可选，使用默认值）
 * @param tag 日志tag（可选，使用默认值）
 */
void PrintAllMapEntries(
    const std::unordered_map<std::string, std::shared_ptr<footstone::value::HippyValue>>& target_map,
    const std::string& map_name = "",
    unsigned int domain = MAP_PRINTER_DOMAIN,
    const char* tag = MAP_PRINTER_TAG);

/**
 * @brief 带隐私保护的打印方法（敏感信息用private标记）
 * @param target_map 要打印的 map
 * @param sensitive_keys 包含敏感key的集合，这些key的value会被标记为private
 * @param map_name map 的名称
 * @param domain 日志domain（可选，使用默认值）
 * @param tag 日志tag（可选，使用默认值）
 */
void PrintAllMapEntriesWithPrivacy(
    const std::unordered_map<std::string, std::shared_ptr<footstone::value::HippyValue>>& target_map,
    const std::unordered_set<std::string>& sensitive_keys = {},
    const std::string& map_name = "",
    unsigned int domain = MAP_PRINTER_DOMAIN,
    const char* tag = MAP_PRINTER_TAG);

/**
 * @brief 调试专用的详细打印方法
 * @param target_map 要打印的 map
 * @param domain 日志domain（可选，使用默认值）
 * @param tag 日志tag（可选，使用默认值）
 */
void DebugPrintMap(
    const std::unordered_map<std::string, std::shared_ptr<footstone::value::HippyValue>>& target_map,
    unsigned int domain = MAP_PRINTER_DOMAIN,
    const char* tag = MAP_PRINTER_TAG);

/**
 * @brief 检查map中是否包含指定的key
 * @param target_map 要检查的map
 * @param key 要查找的key
 * @return 如果key存在且值不为nullptr则返回true
 */
bool ContainsKey(
    const std::unordered_map<std::string, std::shared_ptr<footstone::value::HippyValue>>& target_map,
    const std::string& key);

/**
 * @brief 获取指定key的值，如果不存在返回默认值
 * @param target_map 要查找的map
 * @param key 要查找的key
 * @param default_value 默认值
 * @return 找到的值或默认值
 */
std::shared_ptr<footstone::value::HippyValue> GetValueOrDefault(
    const std::unordered_map<std::string, std::shared_ptr<footstone::value::HippyValue>>& target_map,
    const std::string& key,
    const std::shared_ptr<footstone::value::HippyValue>& default_value = nullptr);

/**
 * @brief 获取map的大小
 * @param target_map 要检查的map
 * @return map中元素的数量
 */
size_t GetMapSize(
    const std::unordered_map<std::string, std::shared_ptr<footstone::value::HippyValue>>& target_map);

} // namespace qt_util

#endif // MAP_PRINTER_H