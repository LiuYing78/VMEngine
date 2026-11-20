#!/bin/bash
# scripts/build.sh - VMEngine 一键编译打包
set -e

NDK=${ANDROID_NDK_HOME:-$NDROID_NDK_ROOT}
if [ -z "$NDK" ]; then
    echo "错误: 请设置 ANDROID_NDK_HOME"
    echo "  export ANDROID_NDK_HOME=/path/to/android-ndk-r25c"
    exit 1
fi

BUILD_TYPE=${1:-debug}
JOBS=$(nproc 2>/dev/null || echo 4)

PROJECT_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
JNI_DIR="$PROJECT_ROOT/jni"

echo "============================================"
echo "  VMEngine 编译脚本"
echo "  NDK: $NDK"
echo "  类型: $BUILD_TYPE"
echo "  并行: $JOBS"
echo "============================================"

echo "[1/4] 编译 native 库..."
cd "$JNI_DIR"
$NDK/ndk-build NDK_PROJECT_PATH="$PROJECT_ROOT" \
               NDK_APPLICATION_MK="$JNI_DIR/Application.mk" \
               -j$JOBS
cd "$PROJECT_ROOT"

echo "[2/4] 拷贝动态库..."
mkdir -p "$PROJECT_ROOT/app/src/main/jniLibs/arm64-v8a"
cp "$PROJECT_ROOT/libs/arm64-v8a/libvmengine.so" \
   "$PROJECT_ROOT/app/src/main/jniLibs/arm64-v8a/" 2>/dev/null || true

echo "[3/4] Gradle 打包 ($BUILD_TYPE)..."
cd "$PROJECT_ROOT"
if [ -x ./gradlew ]; then
    if [ "$BUILD_TYPE" = "release" ]; then
        ./gradlew assembleRelease
        APK="$PROJECT_ROOT/app/build/outputs/apk/release/app-release-unsigned.apk"
    else
        ./gradlew assembleDebug
        APK="$PROJECT_ROOT/app/build/outputs/apk/debug/app-debug.apk"
    fi
    if [ -f "$APK" ]; then
        echo "[4/4] 完成!"
        echo ""
        echo "APK: $APK"
        echo "大小: $(du -h "$APK" | cut -f1)"
    else
        echo "[4/4] Gradle 构建跳过 (无 gradlew)"
    fi
else
    echo "[4/4] 无 gradlew, 仅编译 native 库"
fi
