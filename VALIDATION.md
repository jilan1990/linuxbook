# 验证记录

## 已执行

- 32 sequential chapter files
- All Markdown local links and code fences
- 39 PNG + 39 SVG + 39 DOT files
- Per-chapter source paths and search symbols exist in v5.10 files
- Shell scripts pass syntax checks
- Native C compile with warnings as errors; fork/wait and exec-child modes
- Deterministic gzip/newc, executable mode, symlink and console device 5:1
- Four-level page-table index example

## 尚未执行

本次环境没有 `aarch64-linux-gnu-gcc`、`qemu-system-aarch64` 和 `gdb-multiarch`。因此未执行 ARM64 内核构建、静态 AArch64 minit 构建、QEMU 启动和 GDB 断点链，也未构建第三方 BusyBox。书中的客户机输出是预期验收现象，不能视为已取得的启动日志。

主机 C 测试不挂载文件系统、不运行 PID 1 路径，不替代客户机功能验证。CPIO 测试独立解析 newc 记录并核对权限、软链接、对齐与 console 设备号。源码符号验证仅证明定位入口存在，不证明对全部内核执行路径的覆盖。
