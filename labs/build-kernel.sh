#!/usr/bin/env bash
set -euo pipefail
book_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
work_dir=${WORK_DIR:-"$book_dir/work"}
src_dir="$work_dir/linux"
out_dir="$work_dir/out"
cross=${CROSS_COMPILE:-aarch64-linux-gnu-}
[[ -f "$src_dir/Makefile" ]] || { echo 'Run fetch-kernel.sh first' >&2; exit 1; }
mkdir -p "$out_dir"
make -C "$src_dir" O="$out_dir" ARCH=arm64 CROSS_COMPILE="$cross" defconfig
cfg="$src_dir/scripts/config"
"$cfg" --file "$out_dir/.config" -e ARM64_4K_PAGES -e SMP \
    -e DEBUG_INFO -e DEBUG_INFO_DWARF4 -e GDB_SCRIPTS -e FRAME_POINTER -e KALLSYMS -e KALLSYMS_ALL \
    -e BLK_DEV_INITRD -e RD_GZIP -e BINFMT_ELF -e BINFMT_SCRIPT \
    -e DEVTMPFS -e PROC_FS -e SYSFS -e SERIAL_AMBA_PL011 -e SERIAL_AMBA_PL011_CONSOLE \
    -e ARM_GIC_V3 -e ARM_ARCH_TIMER -e SLUB \
    -d RANDOMIZE_BASE -d DEBUG_INFO_REDUCED -d DEBUG_INFO_COMPRESSED \
    --set-str SYSTEM_TRUSTED_KEYS '' --set-str INITRAMFS_SOURCE ''
make -C "$src_dir" O="$out_dir" ARCH=arm64 CROSS_COMPILE="$cross" olddefconfig
make -C "$src_dir" O="$out_dir" ARCH=arm64 CROSS_COMPILE="$cross" -j"${JOBS:-$(nproc)}" Image vmlinux
sha256sum "$out_dir/.config" "$out_dir/vmlinux" "$out_dir/arch/arm64/boot/Image"
echo "Build completed in $out_dir"
