#!/bin/bash

ARCHS_DEVICES_IPHONE="arm64;arm64e"
IOS_SDK_PATH=$(xcrun --sdk iphoneos --show-sdk-path)

BUILD_IOS="ON"

ARCHS_SIMULATOR_IPHONE="x86_64;arm64"
SIMULATOR_SDK_PATH=$(xcrun --sdk iphonesimulator --show-sdk-path)

BUILD_IOS_SIMULATOR="ON"

ARCHS_DEVICES_MACOS="x86_64;arm64"
BUILD_MACOS="ON"


cd opus

rm -rf apple-framework
mkdir -p apple-framework
cd apple-framework


if [ "$BUILD_IOS" = "ON" ]; then
  mkdir -p ios
  cd ios

  cmake -G "Unix Makefiles" \
            -DCMAKE_OSX_SYSROOT=$IOS_SDK_PATH \
            -DOPUS_BUILD_FRAMEWORK=ON \
            -DCMAKE_SYSTEM_NAME=iOS \
            -DCMAKE_BUILD_TYPE=Release \
            -DOPUS_BUILD_PROGRAMS=ON \
            -DOPUS_BUILD_TESTING=OFF \
            -DOPUS_CUSTOM_MODES=OFF \
            -DCMAKE_OSX_ARCHITECTURES=$ARCHS_DEVICES_IPHONE \
            ../..

  cmake --build .
  cd ..

fi


if [ "$BUILD_IOS_SIMULATOR" = "ON" ]; then

  mkdir -p ios-simulator
  cd ios-simulator

  cmake -G "Unix Makefiles" \
            -DCMAKE_OSX_SYSROOT=$SIMULATOR_SDK_PATH \
            -DOPUS_BUILD_FRAMEWORK=ON \
            -DCMAKE_SYSTEM_NAME=iOS \
            -DCMAKE_BUILD_TYPE=Release \
            -DOPUS_BUILD_PROGRAMS=ON \
            -DOPUS_BUILD_TESTING=OFF \
            -DOPUS_CUSTOM_MODES=OFF \
            -DCMAKE_OSX_ARCHITECTURES=$ARCHS_SIMULATOR_IPHONE \
            ../..

  cmake --build .
  cd ..
fi


FRAMEWORK_DEVICE="ios/Opus.framework"
FRAMEWORK_SIMULATOR="ios-simulator/Opus.framework"

xcodebuild -create-xcframework \
-framework "$FRAMEWORK_DEVICE" \
-framework "$FRAMEWORK_SIMULATOR" \
-output opus.xcframework

rm -rf ios ios-simulator






if [ "$BUILD_MACOS" = "ON" ]; then
  mkdir -p macos
  cd macos

  cmake -G "Xcode" \
            -DOPUS_BUILD_FRAMEWORK=ON \
            -DCMAKE_BUILD_TYPE=Release \
            -DOPUS_BUILD_PROGRAMS=ON \
            -DOPUS_BUILD_TESTING=OFF \
            -DOPUS_CUSTOM_MODES=OFF \
            -DCMAKE_OSX_ARCHITECTURES=$ARCHS_DEVICES_MACOS \
            ../..

  cmake --build . --config Release
  cd ..

fi

