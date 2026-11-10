#!/usr/bin/env bash
set -euo pipefail
book_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
work_dir=${WORK_DIR:-"$book_dir/work"}
image=${IMAGE:-"$work_dir/out/arch/arm64/boot/Image"}
initramfs=${INITRAMFS:-"$work_dir/initramfs.cpio.gz"}
[[ -f "$image" && -f "$initramfs" ]] || { echo 'Build Image and initramfs first' >&2; exit 1; }
extra=()
if [[ ${1:-} == --debug ]]; then extra=(-S -gdb tcp:127.0.0.1:1234)
elif [[ $# != 0 ]]; then echo 'Usage: run-qemu.sh [--debug]' >&2; exit 2
fi
exec "${QEMU:-qemu-system-aarch64}" \
    -machine virt,gic-version=3,virtualization=off -cpu cortex-a57 \
    -smp "${SMP:-1}" -m "${MEMORY:-512M}" -nographic -no-reboot \
    -kernel "$image" -initrd "$initramfs" \
    -append "${CMDLINE:-console=ttyAMA0 earlycon rdinit=/init nokaslr initcall_debug loglevel=7}" \
    "${extra[@]}"
