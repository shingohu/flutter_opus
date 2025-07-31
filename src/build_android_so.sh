#!/bin/bash

NDK_VERSION="27.0.12077973"
export NDK_ROOT="$ANDROID_HOME/ndk/$NDK_VERSION"
# 定义支持的 ABI 列表
ABIS=("armeabi-v7a" "arm64-v8a" "x86" "x86_64")

cd opus
#./autogen.sh
#./configure
rm -rf android-so
mkdir -p android-so
cd android-so
# 遍历每个 ABI 进行编译
for ABI in "${ABIS[@]}"
do
    rm -rf $ABI
    mkdir -p $ABI
    cd $ABI

    # 配置 CMake
    cmake -DCMAKE_TOOLCHAIN_FILE=$NDK_ROOT/build/cmake/android.toolchain.cmake \
          -DANDROID_ABI=$ABI \
          -DOPUS_BUILD_PROGRAMS=OFF \
          -DOPUS_BUILD_SHARED_LIBRARY=ON \
          -DOPUS_BUILD_TESTING=OFF \
          -DOPUS_CUSTOM_MODES=OFF \
          ../..

    # 执行编译
    cmake --build . --target all

    cd ..
done