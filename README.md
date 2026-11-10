# 从零读懂 Linux 5.10 ARM64 内核

本包包含 32 章完整初稿与配套图文、脚本。建议先阅读 [全书合订 Markdown](Linux_5.10_ARM64_全书.md)，也可按以下目录分章阅读。

## 开始实验

准备 Ubuntu 22.04 / WSL2 主机与第二章列出的依赖，在本目录按顺序执行：

```sh
bash labs/fetch-kernel.sh
JOBS=4 bash labs/build-kernel.sh
bash labs/build-initramfs.sh
bash labs/run-qemu.sh
```

程序与工具运行所需源码、工具链、Image 和第三方 BusyBox 不打包在本书中；脚本按固定标签获取源码。当前验证范围见 [VALIDATION.md](VALIDATION.md)，所有客户机输出示例是验收预期。

## 分章目录


### 第一篇 读懂内核之前

- [第 1 章 Linux 启动全景](chapters/01_boot_overview.md)
- [第 2 章 搭建能够重复验证的实验环境](chapters/02_environment.md)
- [第 3 章 阅读内核必需的 C 语言](chapters/03_kernel_c.md)
- [第 4 章 AArch64 汇编入门](chapters/04_aarch64_assembly.md)
- [第 5 章 ARM64 系统架构基础](chapters/05_arm64_architecture.md)

### 第二篇 内核镜像的形成

- [第 6 章 源码目录 Kconfig 与 Kbuild](chapters/06_kbuild.md)
- [第 7 章 从目标文件到 vmlinux](chapters/07_linking.md)
- [第 8 章 Bootloader 与内核的交接契约](chapters/08_boot_protocol.md)

### 第三篇 建立 C 语言运行环境

- [第 9 章 镜像头与启动入口](chapters/09_image_entry.md)
- [第 10 章 异常级与 CPU 初始状态](chapters/10_exception_levels.md)
- [第 11 章 构造最初的页表](chapters/11_early_page_tables.md)
- [第 12 章 初始化 CPU 并打开 MMU](chapters/12_enable_mmu.md)
- [第 13 章 从汇编进入 start_kernel](chapters/13_enter_c.md)

### 第四篇 组织起操作系统

- [第 14 章 start_kernel 的初始化顺序](chapters/14_start_kernel.md)
- [第 15 章 setup_arch 与平台识别](chapters/15_setup_arch.md)
- [第 16 章 memblock 与早期内存分配](chapters/16_memblock.md)
- [第 17 章 建立正式的内核地址空间](chapters/17_kernel_mapping.md)
- [第 18 章 伙伴系统与 SLUB](chapters/18_allocators.md)

### 第五篇 异常 时间与调度

- [第 19 章 异常向量与异常现场](chapters/19_exception_vectors.md)
- [第 20 章 中断子系统与 GIC](chapters/20_gic_irq.md)
- [第 21 章 时间子系统与通用定时器](chapters/21_timekeeping.md)
- [第 22 章 调度器初始化与第一个任务](chapters/22_scheduler.md)
- [第 23 章 启动其他 CPU](chapters/23_smp.md)

### 第六篇 创建 PID 1

- [第 24 章 rest_init 与 init kthreadd](chapters/24_rest_init.md)
- [第 25 章 内核线程创建与首次运行](chapters/25_fork_context.md)
- [第 26 章 kernel_init_freeable 与 initcall](chapters/26_initcalls.md)

### 第七篇 准备用户世界

- [第 27 章 VFS 与最初的根文件系统](chapters/27_vfs_root.md)
- [第 28 章 initramfs initrd 与真实根文件系统](chapters/28_initramfs.md)
- [第 29 章 PID 1 执行用户程序](chapters/29_exec_init.md)
- [第 30 章 ELF 加载与第一次进入 EL0](chapters/30_elf_el0.md)

### 第八篇 完整验证启动过程

- [第 31 章 编写最小 init 并启动 Shell](chapters/31_minimal_init.md)
- [第 32 章 完整启动链与故障定位](chapters/32_full_boot_validation.md)

## 其他材料

- [附录速查](appendices.md)
- [验证范围](VALIDATION.md)
- [源码地图](source_map.json)
- [上游文件核对记录](source_manifest.json)

`images/` 含 39 幅图的 PNG 与 SVG，`diagram_sources/` 含对应 DOT 源文件。图中的地址与内存关系以各章前提为准。
