#
## 对于需要源码依赖 Hippy c++ 代码的特别需求，需要做2点：
## 1 集成 Hippy c++ 源码，生成使用方自己的 so，类似下面配置。
## 2 Hippy 内部不再编译 hippy so，注释掉 Hippy/framework/ohos/src/main/cpp/CMakeLists.txt 里内容。
#
#
#cmake_minimum_required(VERSION 3.5.0)
#
#set(CMAKE_CXX_STANDARD 17)
#set(CMAKE_CXX_STANDARD_REQUIRED ON)
#set(CMAKE_CXX_EXTENSIONS OFF)
#
#project(quicktvui)
#
#set(QUICK_TV_UI_ROOT_DIR "${CMAKE_CURRENT_SOURCE_DIR}/../../")
#set(PROJECT_ROOT_DIR "${QUICK_TV_UI_ROOT_DIR}/../../../")
#set(HIPPY_ROOT_DIR "${PROJECT_ROOT_DIR}/framework/ohos/")
#set(HIPPY_IMPL_CPP_DIR "${HIPPY_ROOT_DIR}/src/main/cpp/impl")
#
## 不指定二进制目录
##add_subdirectory(${HIPPY_ROOT_DIR}/src/main/cpp ${CMAKE_CURRENT_BINARY_DIR}/hippy_build)
#
## 1. 指定头文件路径
#include_directories(
#    # 添加 Hippy 核心头文件路径
#    ${PROJECT_ROOT_DIR}/dom/include
#    ${PROJECT_ROOT_DIR}/modules/footstone/include
#    ${PROJECT_ROOT_DIR}/modules/ohos/oh_napi/include
#    ${HIPPY_ROOT_DIR}/src/main/cpp/impl/renderer/native/include
#    # quicktvui 头文件
#    ${CMAKE_CURRENT_SOURCE_DIR}/../include/my_object.h
#  )
#
## 2. 编译源文件
#add_library(quicktvui SHARED
#  quicktvui/src/napi_init.cpp
#  quicktvui/src/my_object.cpp
#  quicktvui/src/dom_layout.cpp
#  quicktvui/src/util.cpp
#)
#
#
#
## 3. 引入 ohos-hippy 生成的 so
## 假设 hipyy.so 位于 ohos-hippy/out/arm64-v8a/libhippy.so
##add_library(hippy SHARED IMPORTED)
##set_target_properties(hippy PROPERTIES
##    IMPORTED_LOCATION ${PROJECT_ROOT_DIR}/framework/build/ohos/build/intermediates/libs/default/${OHOS_ARCH}/libhippy.so
##)
#
## 只引入编好的 libhippy.so，不要重新编译
#add_library(hippy SHARED IMPORTED)
#set_target_properties(hippy PROPERTIES
#    IMPORTED_LOCATION ${PROJECT_ROOT_DIR}/framework/ohos/build/default/intermediates/libs/default/${OHOS_ARCH}/libhippy.so
#)
#
#target_link_libraries(quicktvui
#    PUBLIC
#        libace_napi.z.so  # libace_napi
#        hippy             # libhippy
#        libhilog_ndk.z.so
#)
