// entry/src/main/cpp/napi_init.cpp
#include <hilog/log.h>
#include <napi/native_api.h>
#include <stdio.h>
// entry/src/main/cpp/napi_init.cpp
 #include "../include/layout.h"
#include "../include/my_object.h"
 using namespace quicktvui::layout;

//static napi_value CallNative(napi_env env, napi_callback_info info) {
//  size_t argc = 2;
//  // 声明参数数组
//  napi_value args[2] = {nullptr};
//
//  // 获取传入的参数并依次放入参数数组中
//  napi_get_cb_info(env, info, &argc, args, nullptr, nullptr);
//
//  // 依次获取参数
//  double value0;
//  napi_get_value_double(env, args[0], &value0);
//  double value1;
//  napi_get_value_double(env, args[1], &value1);
//
//  // 返回两数相加的结果
//  napi_value sum;
//  napi_create_double(env, value0 + value1, &sum);
//  return sum;
//}

//static napi_value NativeCallArkTS(napi_env env, napi_callback_info info) {
//  size_t argc = 1;
//  // 声明参数数组
//  napi_value args[1] = {nullptr};
//
//  // 获取传入的参数并依次放入参数数组中
//  napi_get_cb_info(env, info, &argc, args, nullptr, nullptr);
//
//  // 创建一个int，作为ArkTS的入参
//  napi_value argv = nullptr;
//  napi_create_int32(env, 2, &argv);
//
//  // 调用传入的callback，并将其结果返回
//  napi_value result = nullptr;
//  napi_call_function(env, nullptr, args[0], 1, &argv, &result);
//  return result;
//}

EXTERN_C_START
// 模块初始化
static napi_value Init(napi_env env, napi_value exports) {
//   MyObject::Init(env, exports);
  quicktvui::LayoutNapi::Init(env, exports);
    
//  // ArkTS接口与C++接口的绑定和映射
//  napi_property_descriptor desc[] = {
//      // 注：仅需复制以下两行代码，Init在完成创建Native C++工程以后在napi_init.cpp中已配置好。
//      {"callNative", nullptr, CallNative, nullptr, nullptr, nullptr, napi_default, nullptr},
//      {"nativeCallArkTS", nullptr, NativeCallArkTS, nullptr, nullptr, nullptr, napi_default,
//       nullptr}};
//  // 在exports对象上挂载CallNative/NativeCallArkTS两个Native方法
//  napi_define_properties(env, exports, sizeof(desc) / sizeof(desc[0]), desc);
  return exports;
}
EXTERN_C_END

// 准备模块加载相关信息，将上述Init函数与本模块名等信息记录下来。
static napi_module demoModule = {
    .nm_version = 1,
    .nm_flags = 0,
    .nm_filename = nullptr,
    .nm_register_func = Init,
    .nm_modname = "quicktvui",
    .nm_priv = ((void *)0),
    .reserved = {0},
};

// 加载so时，该函数会自动被调用，将上述demoModule模块注册到系统中。
extern "C" __attribute__((constructor)) void RegisterDemoModule() {
  napi_module_register(&demoModule);
}
