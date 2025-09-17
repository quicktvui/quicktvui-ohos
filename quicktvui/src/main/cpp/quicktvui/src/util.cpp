//
// Created on 2025/9/3.
//
// Node APIs are not fully supported. To solve the compilation error of the interface cannot be found,
// please include "napi/native_api.h".

#include "../include/utils.h"
#include <hilog/log.h>
#include "footstone/logging.h"

namespace qt_util {
using namespace footstone;
std::string HippyValueToString(const std::shared_ptr<footstone::value::HippyValue>& value) {
    if (value == nullptr) {
        return "null";
    }
    std::stringstream ss;
    if (value->IsNumber()) {
        double num_val;
        if (value->ToDouble(num_val)) {
            ss << num_val;
        } else {
            ss << "[Number conversion failed]";
        }
    } else if (value->IsString()) {
        std::string str_val;
        if (value->ToString(str_val)) {
            ss << "\"" << str_val << "\"";
        } else {
            ss << "[String conversion failed]";
        }
    } else if (value->IsBoolean()) {
        bool bool_val;
        if (value->ToBoolean(bool_val)) {
            ss << (bool_val ? "true" : "false");
        } else {
            ss << "[Boolean conversion failed]";
        }
    } else if (value->IsNull()) {
        ss << "null";
    } else if (value->IsUndefined()) {
        ss << "undefined";
    } else if (value->IsArray()) {
        ss << "[Array]";
    } else if (value->IsObject()) {
        ss << "[Object]";
    } else {
        ss << "[Unknown Type: " << static_cast<int>(value->GetType()) << "]";
    }
    return ss.str();
}

// 辅助函数：使用正确的 HiLog 宏
void LogInfo(unsigned int domain, const char* tag, const char* format, ...) {
//    va_list args;
//    va_start(args, format);
//    OH_LOG_Print(LOG_APP, LOG_INFO, domain, tag, format, args);
//    va_end(args);
}

void LogDebug(unsigned int domain, const char* tag, const char* format, ...) {
//    va_list args;
//    va_start(args, format);
//    OH_LOG_Print(LOG_APP, LOG_DEBUG, domain, tag, format, args);
//    va_end(args);
}

void LogWarn(unsigned int domain, const char* tag, const char* format, ...) {
//    va_list args;
//    va_start(args, format);
//    OH_LOG_Print(LOG_APP, LOG_WARN, domain, tag, format, args);
//    va_end(args);
}

void PrintAllMapEntries(
    const std::unordered_map<std::string, std::shared_ptr<footstone::value::HippyValue>>& target_map,
    const std::string& map_name,
    unsigned int domain,
    const char* tag) {
    FOOTSTONE_DLOG(ERROR) << "PrintAllMapEntries";
    if (target_map.empty()) {
         FOOTSTONE_DLOG(ERROR) << "target_map.empty()";
        return;
    }
    
    std::string start_msg = map_name.empty() ? "Printing all map entries:" : 
                           "Printing all entries of map '" + map_name + "':";
    LogInfo(domain, tag, "%s", start_msg.c_str());
    LogInfo(domain, tag, "----------------------------------------");
    
    for (const auto& pair : target_map) {
        const std::string& key = pair.first;
        const auto& value = pair.second;
        
        std::string value_str = HippyValueToString(value);
       // LogInfo(domain, tag, "  %s: %s", key.c_str(), value_str.c_str());
        FOOTSTONE_DLOG(ERROR) << "UpdateNodeSize root_node is nullptr key" << key.c_str() << value_str.c_str();
    }
    
    LogInfo(domain, tag, "----------------------------------------");
    LogInfo(domain, tag, "Total entries: %zu", target_map.size());
}

void PrintAllMapEntriesWithPrivacy(
    const std::unordered_map<std::string, std::shared_ptr<footstone::value::HippyValue>>& target_map,
    const std::unordered_set<std::string>& sensitive_keys,
    const std::string& map_name,
    unsigned int domain,
    const char* tag) {
    
    if (target_map.empty()) {
        std::string log_msg = map_name.empty() ? "Map is empty" : "Map '" + map_name + "' is empty";
        LogInfo(domain, tag, "%s", log_msg.c_str());
        return;
    }
    
    std::string start_msg = map_name.empty() ? "Printing all map entries (with privacy):" : 
                           "Printing all entries of map '" + map_name + "' (with privacy):";
    LogInfo(domain, tag, "%s", start_msg.c_str());
    LogInfo(domain, tag, "----------------------------------------");
    
    for (const auto& pair : target_map) {
        const std::string& key = pair.first;
        const auto& value = pair.second;
        
        std::string value_str = HippyValueToString(value);
        bool is_sensitive = (sensitive_keys.find(key) != sensitive_keys.end());
        
        if (is_sensitive) {
            // 对于敏感信息，我们只显示key，value用"<private>"代替
            LogInfo(domain, tag, "  %s: <private>", key.c_str());
        } else {
            LogInfo(domain, tag, "  %s: %s", key.c_str(), value_str.c_str());
        }
    }
    
    LogInfo(domain, tag, "----------------------------------------");
    LogInfo(domain, tag, "Total entries: %zu", target_map.size());
}

void DebugPrintMap(
    const std::unordered_map<std::string, std::shared_ptr<footstone::value::HippyValue>>& target_map,
    unsigned int domain,
    const char* tag) {
    
    LogDebug(domain, tag, "=== DEBUG: Map Content Dump ===");
    
    for (const auto& pair : target_map) {
        const std::string& key = pair.first;
        const auto& value = pair.second;
        
        if (value == nullptr) {
            LogDebug(domain, tag, "  %s -> nullptr", key.c_str());
            continue;
        }
        
        std::string type_str;
        std::string value_str;
        
        if (value->IsNumber()) {
            type_str = "Number";
            double num_val;
            if (value->ToDouble(num_val)) {
                value_str = std::to_string(num_val);
            } else {
                value_str = "[Conversion failed]";
            }
        } else if (value->IsString()) {
            type_str = "String";
            std::string str_val;
            if (value->ToString(str_val)) {
                value_str = "\"" + str_val + "\"";
            } else {
                value_str = "[Conversion failed]";
            }
        } else if (value->IsBoolean()) {
            type_str = "Boolean";
            bool bool_val;
            if (value->ToBoolean(bool_val)) {
                value_str = bool_val ? "true" : "false";
            } else {
                value_str = "[Conversion failed]";
            }
        } else if (value->IsNull()) {
            type_str = "Null";
            value_str = "null";
        } else if (value->IsUndefined()) {
            type_str = "Undefined";
            value_str = "undefined";
        } else if (value->IsArray()) {
            type_str = "Array";
            value_str = "[Array]";
        } else if (value->IsObject()) {
            type_str = "Object";
            value_str = "[Object]";
        } else {
            type_str = "Unknown";
            value_str = "[Type: " + std::to_string(static_cast<int>(value->GetType())) + "]";
        }
        
        LogDebug(domain, tag, "  %s -> %s (%s)", key.c_str(), value_str.c_str(), type_str.c_str());
    }
    
    LogDebug(domain, tag, "=== Total: %zu entries ===", target_map.size());
}

bool ContainsKey(
    const std::unordered_map<std::string, std::shared_ptr<footstone::value::HippyValue>>& target_map,
    const std::string& key) {
    
    auto it = target_map.find(key);
    return it != target_map.end() && it->second != nullptr;
}

std::shared_ptr<footstone::value::HippyValue> GetValueOrDefault(
    const std::unordered_map<std::string, std::shared_ptr<footstone::value::HippyValue>>& target_map,
    const std::string& key,
    const std::shared_ptr<footstone::value::HippyValue>& default_value) {
    
    auto it = target_map.find(key);
    if (it != target_map.end() && it->second != nullptr) {
        return it->second;
    }
    return default_value;
}

size_t GetMapSize(
    const std::unordered_map<std::string, std::shared_ptr<footstone::value::HippyValue>>& target_map) {
    
    return target_map.size();
}

} // namespace qt_util