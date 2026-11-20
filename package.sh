#!/bin/bash
# scripts/package.sh - 打包 VMEngine 工程为 ZIP
set -e

PROJECT_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
BUILD_TYPE=${1:-debug}
ZIP_NAME=${2:-VMEngine}

echo "============================================"
echo "  VMEngine 打包脚本"
echo "  项目: $PROJECT_ROOT"
echo "============================================"

TMP_DIR=$(mktemp -d)
PKG_DIR="$TMP_DIR/$ZIP_NAME"
mkdir -p "$PKG_DIR"

echo "[1/5] 编译 native 库..."
if [ -x "$PROJECT_ROOT/scripts/build.sh" ]; then
    "$PROJECT_ROOT/scripts/build.sh" "$BUILD_TYPE" || true
fi

echo "[2/5] 打包 APK..."
if [ -f "$PROJECT_ROOT/gradlew" ]; then
    cd "$PROJECT_ROOT"
    if [ "$BUILD_TYPE" = "release" ]; then
        ./gradlew assembleRelease || true
    else
        ./gradlew assembleDebug || true
    fi
fi

echo "[3/5] 收集文件..."
cp -r "$PROJECT_ROOT/jni"      "$PKG_DIR/" 2>/dev/null || true
cp -r "$PROJECT_ROOT/app"      "$PKG_DIR/" 2>/dev/null || true
cp -r "$PROJECT_ROOT/scripts"  "$PKG_DIR/" 2>/dev/null || true
cp -r "$PROJECT_ROOT/gradle"   "$PKG_DIR/" 2>/dev/null || true
cp    "$PROJECT_ROOT/build.gradle" "$PKG_DIR/" 2>/dev/null || true
cp    "$PROJECT_ROOT/settings.gradle" "$PKG_DIR/" 2>/dev/null || true
cp    "$PROJECT_ROOT/gradlew"  "$PKG_DIR/" 2>/dev/null || true
cp    "$PROJECT_ROOT/gradlew.bat" "$PKG_DIR/" 2>/dev/null || true
cp    "$PROJECT_ROOT/README.md" "$PKG_DIR/" 2>/dev/null || true

mkdir -p "$PKG_DIR/build"
cp -r "$PROJECT_ROOT/libs" "$PKG_DIR/build/" 2>/dev/null || true
APK_DIR="$PROJECT_ROOT/app/build/outputs/apk/$BUILD_TYPE"
cp "$APK_DIR"/*.apk "$PKG_DIR/build/" 2>/dev/null || true
cp -r "$PROJECT_ROOT/test_images" "$PKG_DIR/" 2>/dev/null || true

echo "[4/5] 生成 ZIP..."
cd "$TMP_DIR"
ZIP_PATH="$PROJECT_ROOT/${ZIP_NAME}.zip"
rm -f "$ZIP_PATH"
if command -v zip >/dev/null; then
    zip -r -q "$ZIP_PATH" "$ZIP_NAME"
else
    tar czf "${ZIP_PATH%.zip}.tar.gz" "$ZIP_NAME"
    ZIP_PATH="${ZIP_PATH%.zip}.tar.gz"
fi

rm -rf "$TMP_DIR"

echo "[5/5] 完成!"
echo ""
echo "打包: $ZIP_PATH"
echo "大小: $(du -h "$ZIP_PATH" | cut -f1)"
