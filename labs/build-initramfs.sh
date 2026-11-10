#!/usr/bin/env bash
set -euo pipefail
book_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
work_dir=${WORK_DIR:-"$book_dir/work"}
rootfs_dir="$work_dir/rootfs-minit"
archive="$work_dir/initramfs.cpio.gz"
cross=${CROSS_COMPILE:-aarch64-linux-gnu-}
if [[ ${1:-} == --busybox ]]; then
    [[ -f ${BUSYBOX:-} ]] || { echo 'Set BUSYBOX to an AArch64 static BusyBox file' >&2; exit 1; }
    rootfs_dir="$work_dir/rootfs-busybox"
    mkdir -p "$rootfs_dir"/{bin,sbin,proc,sys,dev,tmp}
    "${cross}readelf" -h "$BUSYBOX" | grep -q AArch64 || { echo 'BusyBox must be AArch64' >&2; exit 1; }
    if "${cross}readelf" -l "$BUSYBOX" | grep -q INTERP; then
        echo 'This package requires static BusyBox without PT_INTERP' >&2; exit 1
    fi
    cp -- "$BUSYBOX" "$rootfs_dir/bin/busybox"
    chmod 755 "$rootfs_dir/bin/busybox"
    for applet in sh mount mkdir setsid cttyhack sleep; do ln -sfn busybox "$rootfs_dir/bin/$applet"; done
    cp "$book_dir/labs/busybox-init.sh" "$rootfs_dir/init"
    chmod 755 "$rootfs_dir/init"
    archive="$work_dir/initramfs-busybox.cpio.gz"
elif [[ $# == 0 ]]; then
    mkdir -p "$rootfs_dir"/{proc,sys,dev,tmp}
    "${cross}gcc" -static -O2 -Wall -Wextra -Werror -o "$rootfs_dir/init" "$book_dir/labs/minit.c"
    "${cross}readelf" -h "$rootfs_dir/init" | grep -q AArch64
else
    echo 'Usage: build-initramfs.sh [--busybox]' >&2; exit 2
fi
python3 "$book_dir/labs/mkinitramfs.py" "$rootfs_dir" "$archive"
sha256sum "$archive"
