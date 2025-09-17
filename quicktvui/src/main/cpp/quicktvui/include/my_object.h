#include "dom/dom_node.h"
#include "dom/layout_node.h"
#include "napi/native_api.h"
#include <string>
#include "footstone/logging.h"

// ============ MyObject C++类 =============
class MyObject {
  public:
  explicit MyObject(double value = 0) : value_(value), env_(nullptr), wrapper_(nullptr) {
    layout_node_ = hippy::dom::CreateLayoutNode(hippy::LayoutEngineTaitank);
  }
  ~MyObject() {}

  // 析构时调用
  static void Destructor(napi_env env, void *nativeObject, void *finalize_hint) {
    MyObject *obj = static_cast<MyObject *>(nativeObject);
    delete obj;
  }

  // 构造函数回调
  static napi_value New(napi_env env, napi_callback_info info);

  // 属性 getter
  static napi_value GetValue(napi_env env, napi_callback_info info);
  // 属性 setter
  static napi_value SetValue(napi_env env, napi_callback_info info);

  // 实例方法
  static napi_value PlusOne(napi_env env, napi_callback_info info);

  // 初始化模块时注册 class
  static napi_value Init(napi_env env, napi_value exports);

  private:
  double value_;
  napi_env env_;
  napi_ref wrapper_; // 保存 JS 对象的引用，防止被 GC
  std::shared_ptr<hippy::LayoutNode> layout_node_;
};

// ============ 全局变量 =============
static napi_ref constructorRef; // 保存类构造函数的引用