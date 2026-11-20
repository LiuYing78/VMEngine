# VMEngine - Android 上的 ARM64 虚拟机

一个免 Root 的用户态 ARM64 全系统模拟器，可在 Android 手机上运行
Linux / Android Guest 系统，支持多 vCPU、Vulkan 渲染、宿主内存共享、
WiFi/蓝牙桥接、ART 镜像生成。

## 架构

| 模块 | 说明 |
|------|------|
| TCG | ARM64 指令 → 本地代码翻译执行，TB 基本块缓存 |
| CPU | ARM64 指令解码器（ADD/ADDS/SUB/SUBS/MOVZ/MOVK/AND/ORR/EOR/LDR/STR/LDP/STP/B/BL/B.cond/CBZ/CBNZ/TBZ/TBNZ/SVC/MRS/MSR/CSEL 等） |
| MMU | 软件 MMU，GPA↔HVA 直接映射 |
| GIC | GICv2 中断控制器（ISENABLER/ICENABLER/IPRIORITY/ITARGET/ICFGR/SGIR，if-range 分发） |
| Timer | ARM Generic Timer（CNTFRQ/PCT/TVAL，主机时钟驱动） |
| UART | PL011 串口 |
| RTC | PL031 实时时钟 |
| VirtIO | GPU / Blk / Net / BT / Input / WiFi 虚拟设备 |
| Memory | mmap MAP_SHARED，GPA↔HVA 直接映射，共享宿主进程地址空间 |
| ART | boot.art / boot.oat 镜像生成 |

## 构建

```bash
export ANDROID_NDK_HOME=/path/to/android-ndk-r25c
./scripts/build.sh debug       # 调试版
./scripts/build.sh release     # 发布版
```

### 主机编译验证（无需 NDK）

工程提供桩头文件 `host_stub.h`，可在 Linux/macOS 开发机上做语法验证：

```bash
cd jni
make -f Makefile.host         # 检查全部源文件语法
```

`vm_logger.h` 会根据 `__ANDROID__` 宏自动选择 `<android/log.h>` 或主机桩实现，
无需手动定义 `USE_HOST_STUB`。

## 使用

1. 制作镜像: `./scripts/make_test_image.sh all`
2. 推送镜像到设备:
   ```
   adb push test_images/Image /sdcard/Android/data/com.vmengine/files/
   adb push test_images/rootfs.img /sdcard/Android/data/com.vmengine/files/
   ```
3. 安装 APK: `adb install -r app/build/outputs/apk/debug/app-debug.apk`
4. 打开 App → 选择内核/磁盘 → 设置 CPU/内存 → 启动

## 内存模式

- **MAP_SHARED**: Guest RAM 直接映射宿主进程地址空间，零拷贝
- **memfd**: Android 10+ 现代方案
- **ashmem**: Android ≤9 兼容方案
- 自动限制为宿主空闲内存的 70%，防止系统卡顿

## 已知限制

- 免 Root 下无法使用 KVM，纯软件模拟，性能约为原生 5-15%
- 第三方 ROM 需提取 system.img 并适配 init
- VirtIO 网络在免 Root 下运行于 loopback 模式（需 Root 打开 /dev/tun）
- TCG 采用线性扫描+TB 缓存，寄存器分配可进一步优化
- ART 镜像生成为结构占位，真实 dex2oat 需在 Guest 内执行

## 修复记录

- `decode.h` 枚举名与 `decode.c` 对齐：`ARM64_INSN_ADDS`、`ARM64_INSN_SUBS`、`ARM64_INSN_LDRW_IMM`
- `virtio-mmio.h` 签名与 `virtio.h` 统一；导出 `virtio_mmio_read/write`
- `vm_logger.h` 用 `__ANDROID__` 自动选择平台日志实现，避免 TAG 重定义与隐式声明
- `pl031.c`、`virtio-gpu.c` 补齐 `hw/arm/virt.h` 引入 `RTC_BASE`/`VIRTIO_MMIO_BASE`
- `virt.c` 修正 `fdt_prop_str` 调用参数
- `cpu-exec.c` 的 `tb_free` 与 `tb.h` 声明保持一致（非 static）

## 文件结构

```
VMEngine/
├── jni/           # native 源码
│   ├── tcg/       # TCG 翻译器
│   ├── target/arm/ # ARM64 解码 + 执行
│   ├── exec/      # 内存管理 + MMIO
│   ├── hw/        # 设备模拟
│   ├── android/   # ART 镜像
│   ├── host_stub.h
│   ├── Makefile.host
│   └── Android.mk
├── app/           # Java 控制层
├── scripts/       # 构建/镜像/打包脚本
├── build.gradle
└── README.md
```

## 许可证

MIT
