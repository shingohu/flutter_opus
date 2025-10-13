cmake_minimum_required(VERSION 3.10)
project(OpusHarmonyOS LANGUAGES C)

# 配置 Opus 编译选项（与原脚本保持一致）
set(OPUS_BUILD_PROGRAMS OFF CACHE BOOL "Disable Opus programs")
set(OPUS_BUILD_SHARED_LIBRARY ON CACHE BOOL "Build shared library")
set(OPUS_BUILD_TESTING OFF CACHE BOOL "Disable testing")
set(OPUS_CUSTOM_MODES OFF CACHE BOOL "Disable custom modes")

# 加入 Opus 源码目录（假设 Opus 源码在当前目录的 opus 子目录中）
add_subdirectory(opus)

# 输出编译信息
message(STATUS "Target ABI: ${OHOS_ARCH}")
message(STATUS "HarmonyOS API Level: ${OHOS_API_LEVEL}")
message(STATUS "Opus shared library will be built: ${OPUS_BUILD_SHARED_LIBRARY}")