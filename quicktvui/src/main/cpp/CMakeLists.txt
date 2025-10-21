
# 对于需要源码依赖 Hippy c++ 代码的特别需求，需要做2点：
# 1 集成 Hippy c++ 源码，生成使用方自己的 so，类似下面配置。
# 2 Hippy 内部不再编译 hippy so，注释掉 Hippy/framework/ohos/src/main/cpp/CMakeLists.txt 里内容。


cmake_minimum_required(VERSION 3.5.0)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS OFF)

# 通过环境变量或构建变量获取 HAR 包路径
set(HIPPY_HAR_NAME "hippy")  # 你的 HAR 包名称

project(quicktvui)


set(QUICK_TV_UI_RROJECT_DIR "${CMAKE_CURRENT_SOURCE_DIR}/../../../../")
set(HIPPY_PROJECT_ROOT_DIR "${QUICK_TV_UI_RROJECT_DIR}/../hippy_ohos_tv/")
set(HIPPY_OHOS_FRAMEWORK_DIR "${HIPPY_PROJECT_ROOT_DIR}/framework/ohos/")


get_filename_component(QUICK_TV_UI_RROJECT_DIR ${QUICK_TV_UI_RROJECT_DIR} ABSOLUTE)
# 自定义函数检查依赖项目
# 首先确定项目根目录
#get_filename_component(PROJECT_ROOT_DIR "${CMAKE_CURRENT_SOURCE_DIR}/../../.." ABSOLUTE)
message("项目根目录: ${QUICK_TV_UI_RROJECT_DIR}")

# 自定义函数检查依赖项目
function(check_dependency_project proj_name)
    set(proj_path "${QUICK_TV_UI_RROJECT_DIR}/../${proj_name}")
    get_filename_component(absolute_proj_path "${proj_path}" ABSOLUTE)

    message("检查依赖: ${proj_name}")
    message("  路径: ${absolute_proj_path}")

    if(NOT EXISTS ${absolute_proj_path})
        message(FATAL_ERROR "
❌ 缺少依赖项目: ${proj_name}

预期位置: ${absolute_proj_path}

当前项目: ${QUICK_TV_UI_RROJECT_DIR}

请确保以下项目结构：
Workspace/
├── quicktvui-ohos/     (当前项目)
├── hippy_ohos_tv/      (依赖项目)
└── hippy_ohos_tv_extend/ (依赖项目)
        ")
    endif()

#    # 检查构建产物（根据实际情况调整）
#    set(hippy_lib_path "${absolute_proj_path}/framework/ohos/build/default/intermediates/libs/default/${OHOS_ARCH}/libhippy.so")
#    if(EXISTS ${hippy_lib_path})
#        message("✓ 找到编译产物: libhippy.so")
#    else()
#        message(FATAL_ERROR "⚠ 依赖项目可能未编译，缺少: ${hippy_lib_path}")
#    endif()
    message("✓ ${proj_name} 检查完成")
endfunction()

# 检查所有依赖
message("=== quicktvui模块编译调试信息 ===")
check_dependency_project(hippy_ohos_tv)
check_dependency_project(hippy_ohos_tv_extend)


# 1. 指定头文件路径
include_directories(
    # 添加 Hippy 核心头文件路径
    ${HIPPY_PROJECT_ROOT_DIR}/dom/include
    ${HIPPY_PROJECT_ROOT_DIR}/modules/footstone/include
    ${HIPPY_PROJECT_ROOT_DIR}/modules/ohos/oh_napi/include
    ${HIPPY_OHOS_FRAMEWORK_DIR}/src/main/cpp/impl/renderer/native/include
    # quicktvui 头文件
    ${CMAKE_CURRENT_SOURCE_DIR}/../include/my_object.h
  )

# 2. 编译源文件
add_library(quicktvui SHARED
  quicktvui/src/napi_init.cpp
  quicktvui/src/my_object.cpp
  quicktvui/src/dom_layout.cpp
  quicktvui/src/util.cpp
)

message("检查har包中libhipy.so位置")
#message("CMAKE_CURRENT_SOURCE_DIR:${CMAKE_CURRENT_SOURCE_DIR}")
#message("QUICK_TV_UI_RROJECT_DIR:${QUICK_TV_UI_RROJECT_DIR}")

#尝试自动发现 hippy HAR 包路径
file(GLOB HIPPY_HAR_PATHS
    "${QUICK_TV_UI_RROJECT_DIR}/oh_modules/.ohpm/${HIPPY_HAR_NAME}@*/oh_modules/${HIPPY_HAR_NAME}"
)


if(HIPPY_HAR_PATHS)
    list(GET HIPPY_HAR_PATHS 0 HIPPY_HAR_PATH)
    message("Found hippy HAR at: ${HIPPY_HAR_PATH}")

    set(HIPPY_LIB_PATH "${HIPPY_HAR_PATH}/libs/${OHOS_ARCH}/libhippy.so")

    if(EXISTS ${HIPPY_LIB_PATH})
        # 正确配置 IMPORTED 库
        add_library(hippy SHARED IMPORTED)
        set_target_properties(hippy PROPERTIES
            IMPORTED_LOCATION ${HIPPY_LIB_PATH}
            IMPORTED_NO_SONAME ON
        )
        message("Using libhippy.so from: ${HIPPY_LIB_PATH}")
    else()
        message(FATAL_ERROR "hippy library not found at: ${HIPPY_LIB_PATH}")
    endif()
else()
    message(FATAL_ERROR "hippy HAR package not found")
endif()


target_link_libraries(quicktvui
    PUBLIC
        libace_napi.z.so  # libace_napi
        hippy             # libhippy
        libhilog_ndk.z.so
)
