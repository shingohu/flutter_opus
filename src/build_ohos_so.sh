#!/bin/bash

export NDK_ROOT="/Applications/DevEco-Studio.app/Contents/sdk/default/openharmony/native"
# 定义支持的 ABI 列表
ABIS=("armeabi-v7a" "arm64-v8a")

cd opus
#./autogen.sh
#./configure
rm -rf ohos-so
mkdir -p ohos-so
cd ohos-so
# 遍历每个 ABI 进行编译
for ABI in "${ABIS[@]}"
do
    rm -rf $ABI
    mkdir -p $ABI
    cd $ABI

    # 配置 CMake
    cmake -DCMAKE_TOOLCHAIN_FILE=$NDK_ROOT/build/cmake/ohos.toolchain.cmake \
          -DOHOS_ARCH=$ABI \
          -DOHOS_PLATFORM=OHOS \
          -DOPUS_BUILD_PROGRAMS=OFF \
          -DOPUS_BUILD_SHARED_LIBRARY=ON \
          -DOPUS_BUILD_TESTING=OFF \
          -DOPUS_CUSTOM_MODES=OFF \
          ../..

    # 执行编译
    cmake --build . --target all

    cd ..
done