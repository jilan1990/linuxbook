#!/usr/bin/env bash
set -euo pipefail
book_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
work_dir=${WORK_DIR:-"$book_dir/work"}
mkdir -p "$work_dir"
{
    date -u '+%Y-%m-%dT%H:%M:%SZ'
    uname -a
    for tool in aarch64-linux-gnu-gcc aarch64-linux-gnu-ld qemu-system-aarch64 gdb-multiarch make; do
        if command -v "$tool" >/dev/null 2>&1; then "$tool" --version | sed -n '1p'
        else printf '%s: unavailable\n' "$tool"; fi
    done
    if [[ -d "$work_dir/linux/.git" ]]; then git -C "$work_dir/linux" rev-parse HEAD; fi
    for f in "$work_dir/out/.config" "$work_dir/out/vmlinux" \
        "$work_dir/out/arch/arm64/boot/Image" "$work_dir/initramfs.cpio.gz"; do
        if [[ -f "$f" ]]; then sha256sum "$f"; fi
    done
} > "$work_dir/environment.txt"
cat "$work_dir/environment.txt"
