#!/bin/bash
# scripts/make_test_image.sh - 制作测试镜像
set -e

PROJECT_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
IMG_DIR="$PROJECT_ROOT/test_images"
KERNEL_URL="${KERNEL_URL:-https://github.com/.../Image}"

mkdir -p "$IMG_DIR"
cmd=${1:-all}

case "$cmd" in
    kernel)
        echo "下载 ARM64 测试内核..."
        if command -v curl >/dev/null; then
            curl -L -o "$IMG_DIR/Image" "$KERNEL_URL" || echo "请手动放置 Image 到 $IMG_DIR/"
        else
            echo "请手动放置 Image 到 $IMG_DIR/"
        fi
        ;;
    initramfs)
        echo "制作最小 initramfs..."
        WORK=$(mktemp -d)
        mkdir -p "$WORK/bin" "$WORK/sbin" "$WORK/dev" "$WORK/proc" "$WORK/sys"
        cat > "$WORK/init" <<'EOF'
#!/bin/sh
mount -t proc none /proc
mount -t sysfs none /sys
echo "VMEngine: init started"
echo "Welcome to VMEngine ARM64 Virtual Machine"
while true; do
    echo "VMEngine shell ready"
    sh 2>/dev/null || busybox sh 2>/dev/null || ash
    echo "VMEngine: restarting shell"
done
EOF
        chmod +x "$WORK/init"
        (cd "$WORK" && find . | cpio -H newc -o 2>/dev/null | gzip > "$IMG_DIR/initramfs.cpio.gz")
        rm -rf "$WORK"
        echo "initramfs 完成: $IMG_DIR/initramfs.cpio.gz"
        ;;
    rootfs)
        SIZE=${2:-2048}
        echo "制作 ${SIZE}MB rootfs..."
        dd if=/dev/zero of="$IMG_DIR/rootfs.img" bs=1M count=$SIZE 2>/dev/null
        mkfs.ext4 -F "$IMG_DIR/rootfs.img" 2>/dev/null || true
        echo "rootfs 镜像已创建: $IMG_DIR/rootfs.img"
        ;;
    all)
        $0 kernel
        $0 initramfs
        $0 rootfs 2048
        ;;
    clean)
        rm -rf "$IMG_DIR"
        ;;
    *)
        echo "用法: $0 {all|kernel|initramfs|rootfs [size_mb]|clean}"
        ;;
esac
