#ifndef LAYOUT_NODE_NAPI_H
#define LAYOUT_NODE_NAPI_H

#include "napi/native_api.h"
#include <unordered_map>
#include <string>
#include "dom/layout_node.h"

using namespace hippy::dom;
using namespace footstone::value;  // 用于 HippyValue
namespace quicktvui {
inline namespace layout {

// 模板函数声明
template<typename T>
T GetArg(napi_env env, napi_value value);

// 模板特化声明
template<>
float GetArg<float>(napi_env env, napi_value value);

template<>
int32_t GetArg<int32_t>(napi_env env, napi_value value);

template<>
bool GetArg<bool>(napi_env env, napi_value value);

class LayoutNapi{

private:
// 包装和拆包函数
  // 创建布局节点
  static napi_value CreateLayoutNodeNapi(napi_env env, napi_callback_info info);
  // Getter 方法
  static napi_value CopyStyleNode(napi_env env,napi_callback_info info);
  static napi_value GetWidthNapi(napi_env env, napi_callback_info info);
  static napi_value GetHeightNapi(napi_env env, napi_callback_info info);
  static napi_value GetLeftNapi(napi_env env, napi_callback_info info);
  static napi_value GetPaddingNapi(napi_env env, napi_callback_info info);
  static napi_value GetMarginNapi(napi_env env, napi_callback_info info);
  static napi_value GetTopNapi(napi_env env, napi_callback_info info);
  static napi_value GetRightNapi(napi_env env, napi_callback_info info);
  static napi_value GetBottomNapi(napi_env env, napi_callback_info info);
  static napi_value GetStyleWidthNapi(napi_env env, napi_callback_info info);
  static napi_value GetStyleHeightNapi(napi_env env, napi_callback_info info);
  
  // Setter 方法
  static napi_value SetWidthNapi(napi_env env, napi_callback_info info);
  static napi_value SetHeightNapi(napi_env env, napi_callback_info info);
  static napi_value SetMaxWidthNapi(napi_env env, napi_callback_info info);
  static napi_value SetMaxHeightNapi(napi_env env, napi_callback_info info);
  static napi_value SetScaleFactorNapi(napi_env env, napi_callback_info info);
  static napi_value SetPositionNapi(napi_env env, napi_callback_info info);
  // 样式设置方法
  static napi_value SetLayoutStylesNapi(napi_env env, napi_callback_info info);
  // 布局状态方法
  static napi_value HasNewLayoutNapi(napi_env env, napi_callback_info info);
  static napi_value IsDirtyNapi(napi_env env, napi_callback_info info);
  static napi_value MarkDirtyNapi(napi_env env, napi_callback_info info);
  
  // 布局计算方法
  static napi_value CalculateLayoutNapi(napi_env env, napi_callback_info info);
  
  // 子节点操作
  static napi_value InsertChildNapi(napi_env env, napi_callback_info info);
  static napi_value RemoveChildNapi(napi_env env, napi_callback_info info);
  
  // 缓存管理
  static napi_value ResetLayoutCacheNapi(napi_env env, napi_callback_info info);
  
  // 枚举创建工具函数
  static napi_value CreateEnumObject(napi_env env, const std::unordered_map<std::string, int32_t>& map);
//  std::shared_ptr<LayoutNode> nativeInstance_;
// NAPI 模块初始化
public:
    LayoutNapi();
    ~LayoutNapi();
  struct LayoutNodeWrapper {
    std::shared_ptr<LayoutNode> node;
  };
  static napi_value Constructor(napi_env env, napi_callback_info info);
  static void Destructor(napi_env env, void* nativeObject, void* finalize_hint);
  static LayoutNodeWrapper* UnwrapNode(napi_env env, napi_value thisVar);
  static napi_value Init(napi_env env, napi_value exports);
  };
}
}


#endif // LAYOUT_NODE_NAPI_H
