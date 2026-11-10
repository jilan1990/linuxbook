#!/usr/bin/env bash
set -euo pipefail
book_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
work_dir=${WORK_DIR:-"$book_dir/work"}
mkdir -p "$work_dir"
src_dir="$work_dir/linux"
if [[ ! -d "$src_dir/.git" ]]; then
    [[ ! -e "$src_dir" ]] || { echo "Refusing to overwrite $src_dir" >&2; exit 1; }
    git clone --depth 1 --branch v5.10 https://github.com/torvalds/linux.git "$src_dir"
fi
tag=$(git -C "$src_dir" describe --tags --exact-match HEAD)
[[ "$tag" == v5.10 ]] || { echo "Expected v5.10, got $tag" >&2; exit 1; }
[[ -z $(git -C "$src_dir" status --porcelain --untracked-files=no) ]] || {
    echo 'Tracked changes found; review before using the baseline.' >&2; exit 1;
}
git -C "$src_dir" rev-parse HEAD
