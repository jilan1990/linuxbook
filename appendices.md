# 附录

## 附录 A AArch64 指令与系统寄存器速查

| 项目 | 读代码时要确认的内容 |
| --- | --- |
| `mov`、`add`、`sub` | 位宽、是否更新标志、输入值的语义 |
| `ldr`、`str`、`ldp`、`stp` | 访问宽度、寻址方式、基址是否写回 |
| `adr`、`adrp` | PC 相对计算、重定位以及链接与加载的关系 |
| `b`、`bl`、`br`、`blr`、`ret` | 是否更新链接寄存器、目标来自哪里 |
| `mrs`、`msr` | 系统寄存器所属异常级、访问权限与保留位 |
| `eret` | 使用哪个 ELR/SPSR，目标 PC 与目标状态 |
| `dmb`、`dsb`、`isb` | 内存顺序、完成条件或指令执行上下文同步 |
| `tlbi`、`dc`、`ic` | 失效或维护的对象、范围与所需屏障 |

`SCTLR_EL1` 控制位、`TCR_EL1` 配置、TTBR 基址与页表属性必须一起解释。系统寄存器完整位域应参考所用 CPU 对应的 Arm 架构手册；本书不为所有架构修订提供一张混用的固定掩码表。

## 附录 B 内核 C 宏与汇编宏

| 宏或标注 | 用途 | 常见误解 |
| --- | --- | --- |
| `__init`、`__initdata` | 放入可按阶段回收的初始化区域 | 第一次使用后立即销毁 |
| `__ro_after_init` | 初始化完成后可转为只读的数据类别 | 从启动第一条指令开始就只读 |
| `container_of` | 从嵌入成员地址定位外层对象 | 任意指针都可安全反推 |
| `READ_ONCE`、`WRITE_ONCE` | 约束单次访问的编译行为 | 自动解决所有跨 CPU 顺序问题 |
| `early_param`、`__setup` | 在相应参数处理阶段登记处理函数 | 所有参数在同一阶段执行 |
| initcall 宏 | 通过节登记初始化函数 | 宏使用处立即调用该函数 |
| `SYM_CODE_START`、`SYM_FUNC_START` | 汇编符号与相关属性声明 | 两者拥有完全相同调用约定 |
| `kernel_entry`、`kernel_exit` | 保存与恢复异常现场的汇编宏 | 一定存在同名可断点 C 函数 |

不要通过修改标注消除生命周期警告后就认定问题解决。应沿所有持久引用和异步工作确认对象失效时机。

## 附录 C 实验目录与命令约定

完整包的根目录称为 BOOK_DIR。脚本默认把源码、构建输出和归档放在 `BOOK_DIR/work`；设置 `WORK_DIR` 可改变此位置，建议使用绝对路径。后续直接运行命令时，相对路径都以书包根目录为基准，源码根目录内的 `rg` 练习需先进入 `work/linux`。

```sh
# 在解压后的 linux510_arm64_complete 根目录
bash labs/fetch-kernel.sh
JOBS=4 bash labs/build-kernel.sh
bash labs/build-initramfs.sh
bash labs/record-env.sh
bash labs/run-qemu.sh
```

调试使用两个终端，均从书包根目录开始：

```sh
# 终端一
bash labs/run-qemu.sh --debug
# 终端二
gdb-multiarch -x labs/boot.gdb work/out/vmlinux
```

可选 BusyBox 启动：

```sh
BUSYBOX=/绝对路径/busybox bash labs/build-initramfs.sh --busybox
INITRAMFS="$PWD/work/initramfs-busybox.cpio.gz" bash labs/run-qemu.sh
```

BusyBox 必须是适用 AArch64 的静态构建，并包含 sh、mount、mkdir、setsid、cttyhack、sleep。该实验脚本监督一个前台 Shell；它不是通用服务管理器，也不替代生产 init 对服务、信号和孤儿进程的完整管理。

导出与当前实验匹配的 DTB：

```sh
qemu-system-aarch64 -machine virt,gic-version=3,virtualization=off,dumpdtb=work/virt.dtb \
  -cpu cortex-a57 -smp 1 -m 512M -display none
# 需要在主机额外安装 device-tree-compiler
dtc -I dtb -O dts -o work/virt.dts work/virt.dtb
```

QEMU 的 `virt` 不加版本后缀时会使用当前程序版本对应的 machine 行为。复现实验应记录 QEMU 版本；需要跨版本精确复现时，再选定双方支持的 `virt-X.Y` machine，并同步设备树与设备布局分析。

## 附录 D 关键源码定位索引

| 阶段 | 文件 | 关键符号 |
| --- | --- | --- |
| 汇编入口 | `arch/arm64/kernel/head.S` | `primary_entry`、`el2_setup` |
| 早期页表 | 同上 | `__create_page_tables`、`__enable_mmu` |
| 进入 C | 同上 | `__primary_switch`、`__primary_switched` |
| CPU 设置 | `arch/arm64/mm/proc.S` | `__cpu_setup` |
| 主初始化 | `init/main.c` | `start_kernel`、`mm_init`、`rest_init` |
| 平台设置 | `arch/arm64/kernel/setup.c` | `setup_arch`、`setup_machine_fdt` |
| 正式映射 | `arch/arm64/mm/mmu.c` | `paging_init`、`map_mem` |
| 内存移交 | `arch/arm64/mm/init.c` | `bootmem_init`、`mem_init` |
| 早期范围管理 | `mm/memblock.c` | `memblock_add`、`memblock_reserve`、`memblock_free_all` |
| 分配器 | `mm/page_alloc.c`、`mm/slub.c` | 页分配及对象缓存相关实现 |
| 异常与切换 | `arch/arm64/kernel/entry.S` | `vectors`、`cpu_switch_to`、`ret_from_fork` |
| 调度 | `kernel/sched/core.c` | `sched_init`、`__schedule`、`context_switch` |
| 多核 | `arch/arm64/kernel/smp.c` | `__cpu_up`、`secondary_start_kernel` |
| 创建任务 | `kernel/fork.c` | `kernel_thread`、`kernel_clone`、`copy_process` |
| 构造现场 | `arch/arm64/kernel/process.c` | `copy_thread`、`__switch_to` |
| initramfs | `init/initramfs.c` | `populate_rootfs` |
| 真实根 | `init/do_mounts.c` | `prepare_namespace`、`init_rootfs` |
| 通用 exec | `fs/exec.c` | `kernel_execve`、`bprm_execve`、`exec_binprm` |
| ELF | `fs/binfmt_elf.c` | `load_elf_binary`、`create_elf_tables` |
| 用户现场 | `arch/arm64/include/asm/processor.h` | `start_thread` |

配套 `source_map.json` 列出按章使用的源码路径，`source_manifest.json` 记录本次核对的上游文件与 SHA256。它们帮助定位材料，不表示已经验证全部内核代码。

## 附录 E 配置与启动参数

| 选项或参数 | 本书用途 | 注意事项 |
| --- | --- | --- |
| `ARCH=arm64` | 构建 ARM64 | 不是 `arch64` |
| `CONFIG_ARM64_4K_PAGES` | 固定页大小起点 | 索引级数仍取决于 VA 宽度 |
| `CONFIG_SMP` | 支持后续多核实验 | 起步仍可 `-smp 1` |
| `CONFIG_DEBUG_INFO` | 提供源码调试信息 | 必须使用匹配的 vmlinux |
| `CONFIG_DEBUG_INFO_DWARF4` | 请求 DWARF4 调试信息 | 以 olddefconfig 后结果为准 |
| `CONFIG_RANDOMIZE_BASE=n` | 简化符号地址观察 | `nokaslr` 也作为启动参数 |
| `CONFIG_BLK_DEV_INITRD`、`CONFIG_RD_GZIP` | 外部 gzip 归档 | 镜像必须包含解包支持 |
| `CONFIG_BINFMT_ELF` | 加载静态 ELF init | 文件本身仍需正确架构 |
| `CONFIG_DEVTMPFS` | 提供设备文件系统 | 早期归档仍先放 console 节点 |
| `console=ttyAMA0` | PL011 控制台 | 需对应驱动与虚拟硬件 |
| `earlycon` | 请求早期控制台 | 依赖可识别的早期描述与支持 |
| `rdinit=/init` | 指定早期用户程序 | 与 `init=` 分开 |
| `initcall_debug` | 观察初始化调用 | 会增加日志与时间开销 |
| `root=` | 真实根设备选择 | 本书基础 initramfs 实验不必指定 |

附带构建脚本会从 defconfig 重建配置，适合作为基线，不用于保留你已手工修改的复杂配置。实验前复制自己的 `.config`；若需要自定义配置，单独运行配置和构建流程。

## 附录 F 地址与栈的手算实例

以四级、4KB、48 位 VA 示例为前提，索引计算公式为：L0=`(VA >> 39) & 0x1ff`，L1=`(VA >> 30) & 0x1ff`，L2=`(VA >> 21) & 0x1ff`，L3=`(VA >> 12) & 0x1ff`。页内偏移为 `VA & 0xfff`。

```sh
python3 labs/walk-va.py 0x40201234
```

预期索引为 0、1、1、1，偏移为 0x234。若在 L2 使用 2MB block，则不再读取 L3，而使用 21 位块内偏移。必须根据描述符类型决定停止层级。

栈示例：初始 SP 为对齐地址 S，执行 `stp x29, x30, [sp, #-16]!` 后，SP 为 S−16，两个 64 位值分别存放在对应的连续位置。对照保存与恢复顺序，检查是否把帧指针值和链接寄存器值交换。

早期物理断点公式：`P(symbol) = P(Image_start) + V(symbol) − V(_text)`，仅在已经确认 Image 首地址与 `_text` 对应、且该段未因其他搬移改变关系的前提下使用。公式是推导工具，不替代对实际加载位置的观察。

## 附录 G 日志 断点与故障证据

| 现象 | 先确认什么 | 下一层检查 |
| --- | --- | --- |
| 完全无输出 | QEMU 参数、串口、Image 与入口 PC | MMU 及早期异常 |
| 版本字符串后停止 | 控制台时机与 setup_arch | 设备树及内存初始化 |
| CPU 启动超时 | 次级入口与启动操作 | 共享数据、特性和 online 条件 |
| 根设备无法挂载 | root= 与虚拟盘 | 块驱动及文件系统驱动 |
| init 文件存在却 ENOENT | 目标及解释器路径 | ELF 的 PT_INTERP |
| exec 格式错误 | ELF 架构与头 | binfmt 支持和文件完整性 |
| 尝试终止 init | PID 1 是否退出 | 程序主循环、信号和错误处理 |

日志是观察证据，不总是执行顺序的完整记录。多核交错、缓冲和控制台注册时机会改变呈现方式。断点同样会改变时序，不能凭一次调试结果证明所有并发执行都成立。

## 附录 H 如何比较 5.10.y 或厂商内核

本书固定上游 v5.10，没有把某个未核对的 5.10.y 版本声明为等价实现。比较时记录两个提交 ID，优先对本书关键文件执行 `git diff`，再检查 Kconfig、生成头文件、接口签名和构建选项。

稳定分支可能回移上游新实现，版本号相近不代表内部代码完全相同。厂商还可能加入平台启动、自定义驱动、安全检查和工具链修复。逐项更新源码地图和断点位置，再重跑同一验收链。

```sh
# 在拥有两个引用的内核 Git 仓库中；OTHER_REF 换成已核对引用
git diff v5.10 OTHER_REF -- init/main.c arch/arm64/kernel/head.S \
  arch/arm64/kernel/entry.S kernel/fork.c fs/exec.c
```

若目标只是学习主线，先在原始 v5.10 完成闭环；若目标是维护产品，则以实际产品提交、配置和补丁集作为最终证据，不能直接用本书结论替代产品评估。

## 附录 I 验证范围与使用方式

本书图文与脚本分开记录验证范围。配图为源码关系示意，不是真机内存快照；所有地址示例均有配置前提。构建脚本、CPIO 格式及最小 init 的验证结果见同目录 `VALIDATION.md`。

当前创作环境未安装 AArch64 交叉编译器和 QEMU，因此没有声称完成 ARM64 内核编译或客户机启动。主机 C 冒烟测试只验证可移植代码部分，不能替代 AArch64 ABI、设备初始化和进入 EL0 的实际实验。读者应在第二章指定环境完成端到端验收，并保留自己的记录。
