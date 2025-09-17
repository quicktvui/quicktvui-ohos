#include "../include/my_object.h"
#include "dom/layout_node.h"
#include "napi/native_api.h"

napi_value MyObject::New(napi_env env, napi_callback_info info) {
    
  size_t argc = 1;
  napi_value args[1];
  napi_value jsThis;
  napi_get_cb_info(env, info, &argc, args, &jsThis, nullptr);

  double value = 0;
  if (argc >= 1) {
    napi_get_value_double(env, args[0], &value);
  }

  MyObject *obj = new MyObject(value);
  obj->env_ = env;

  napi_status status = napi_wrap(env, jsThis, obj, MyObject::Destructor, nullptr, &obj->wrapper_);
  if (status != napi_ok) {
    delete obj;
    return nullptr;
  }
  return jsThis;
}

// ============ 属性 Getter ============
napi_value MyObject::GetValue(napi_env env, napi_callback_info info) {
  napi_value jsThis;
  napi_get_cb_info(env, info, nullptr, nullptr, &jsThis, nullptr);

  MyObject *obj;
  napi_unwrap(env, jsThis, reinterpret_cast<void **>(&obj));
    
    FOOTSTONE_LOG(WARNING) << "=======1======GetValue===========>>>>>";
    
  napi_value result;

        obj->layout_node_->CalculateLayout(200, 200);
    //TODO 调用泰坦的方法
  napi_create_double(env, obj->layout_node_->GetWidth() * 2, &result);

        FOOTSTONE_LOG(WARNING) << "====2=========GetValue===========>>>>>" << obj->layout_node_->GetWidth();
  return result;
}

// ============ 属性 Setter ============
napi_value MyObject::SetValue(napi_env env, napi_callback_info info) {
  size_t argc = 1;
  napi_value args[1];
  napi_value jsThis;
  napi_get_cb_info(env, info, &argc, args, &jsThis, nullptr);

  MyObject *obj;
  napi_unwrap(env, jsThis, reinterpret_cast<void **>(&obj));

  double newValue;
  napi_get_value_double(env, args[0], &newValue);
            FOOTSTONE_LOG(WARNING) << "===========SetValue===========>>>>>" << newValue;
//  obj->value_ = newValue;
    //TODO 调用泰坦的方法
    obj->layout_node_->SetHeight(newValue);
    obj->layout_node_->SetWidth(newValue);
    
  return nullptr;
}

// ============ 实例方法 PlusOne ============
napi_value MyObject::PlusOne(napi_env env, napi_callback_info info) {
  napi_value jsThis;
  napi_get_cb_info(env, info, nullptr, nullptr, &jsThis, nullptr);

  MyObject *obj;
  napi_unwrap(env, jsThis, reinterpret_cast<void **>(&obj));

  obj->value_ += 1;

  napi_value result;
  napi_create_double(env, obj->value_, &result);
  return result;
}

// ============ Init 定义 class 并导出 ============
napi_value MyObject::Init(napi_env env, napi_value exports) {
  napi_property_descriptor props[] = {
      {"value", nullptr, nullptr, GetValue, SetValue, nullptr, napi_default, nullptr},
      {"plusOne", nullptr, PlusOne, nullptr, nullptr, nullptr, napi_default, nullptr}
  };

  napi_value cons;
  napi_define_class(env, "MyObject", NAPI_AUTO_LENGTH, New, nullptr,
                    sizeof(props) / sizeof(props[0]), props, &cons);

  napi_create_reference(env, cons, 1, &constructorRef);
  napi_set_named_property(env, exports, "MyObject", cons);
  return exports;
}