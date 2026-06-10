#!/usr/bin/env bash

abk_storage_rollback_common_dir() {
  abk_common_dir
}

abk_storage_rollback_patch() {
  local patch_subdir="$1"
  local common_dir

  common_dir="$(abk_storage_rollback_common_dir)"
  abk_require_dir "$common_dir"
  abk_apply_reverse_patch "$MODULE_DIR/patches/$patch_subdir/rollback.patch" "$common_dir"
}

abk_storage_rollback_f2fs_is_applied() {
  local common_dir f2fs_header

  common_dir="$(abk_storage_rollback_common_dir)"
  f2fs_header="$common_dir/fs/f2fs/f2fs.h"

  abk_require_file "$f2fs_header"

  grep -qF "FI_INLINE_DOTS" "$f2fs_header" &&
    ! grep -qF "FI_ATOMIC_DIRTIED" "$f2fs_header"
}

abk_storage_rollback_f2fs_patch() {
  local common_dir patch_file

  common_dir="$(abk_storage_rollback_common_dir)"
  patch_file="$MODULE_DIR/patches/storage_f2fs_rollback/rollback.patch"

  abk_require_dir "$common_dir"
  abk_require_file "$patch_file"

  (
    cd "$common_dir" || exit
    if git apply --reverse --check "$patch_file" >/dev/null 2>&1; then
      git apply --reverse "$patch_file"
      abk_log "applied rollback patch: $patch_file"
      exit 0
    fi

    if git apply --check "$patch_file" >/dev/null 2>&1; then
      abk_log "rollback patch already applied: $patch_file"
      exit 0
    fi
  )

  if abk_storage_rollback_f2fs_is_applied; then
    abk_log "F2FS rollback already applied with compatibility fixups"
    return 0
  fi

  abk_die "rollback patch does not match current kernel tree: $patch_file"
}

abk_storage_rollback_fix_is_dot_dotdot_conflict() {
  local common_dir f2fs_header fs_header

  common_dir="$(abk_storage_rollback_common_dir)"
  f2fs_header="$common_dir/fs/f2fs/f2fs.h"
  fs_header="$common_dir/include/linux/fs.h"

  abk_require_file "$f2fs_header"
  abk_require_file "$fs_header"

  python3 - "$f2fs_header" "$fs_header" <<'PY'
from pathlib import Path
import sys

f2fs_header = Path(sys.argv[1])
fs_header = Path(sys.argv[2])
text = f2fs_header.read_text()
fs_text = fs_header.read_text()

if "static inline bool is_dot_dotdot(const char *name, size_t len)" not in fs_text:
    raise SystemExit(0)

block = """static inline bool is_dot_dotdot(const u8 *name, size_t len)
{
\tif (len == 1 && name[0] == '.')
\t\treturn true;

\tif (len == 2 && name[0] == '.' && name[1] == '.')
\t\treturn true;

\treturn false;
}

"""

if block in text:
    f2fs_header.write_text(text.replace(block, "", 1))
PY
}

abk_storage_rollback_apply_common_fixups() {
  local common_dir f2fs_header trace_header super_c data_c node_c

  common_dir="$(abk_storage_rollback_common_dir)"
  f2fs_header="$common_dir/fs/f2fs/f2fs.h"
  trace_header="$common_dir/include/trace/events/f2fs.h"
  super_c="$common_dir/fs/f2fs/super.c"
  data_c="$common_dir/fs/f2fs/data.c"
  node_c="$common_dir/fs/f2fs/node.c"

  abk_require_file "$f2fs_header"
  abk_require_file "$trace_header"
  abk_require_file "$super_c"
  abk_require_file "$data_c"
  abk_require_file "$node_c"

  python3 - "$f2fs_header" "$trace_header" "$super_c" "$data_c" "$node_c" <<'PY'
from pathlib import Path
import re
import sys

f2fs_header = Path(sys.argv[1])
trace_header = Path(sys.argv[2])
super_c = Path(sys.argv[3])
data_c = Path(sys.argv[4])
node_c = Path(sys.argv[5])

f2fs_text = f2fs_header.read_text()
trace_text = trace_header.read_text()
super_text = super_c.read_text()
data_text = data_c.read_text()
node_text = node_c.read_text()

changed = False

if "CP_XATTR_DIR" not in f2fs_text and "CP_XATTR_DIR" in trace_text:
    lines = trace_text.splitlines()
    for index, line in enumerate(lines[:-1]):
        if "CP_RECOVER_DIR" not in line:
            continue
        if "CP_XATTR_DIR" not in lines[index + 1]:
            continue
        lines[index] = re.sub(r",\s*\\\s*$", "", line.rstrip()) + ")"
        del lines[index + 1]
        trace_header.write_text("\n".join(lines) + "\n")
        changed = True
        break

if "PAGE_SIZE(%lu) != %d\\n" in super_text:
    super_text = super_text.replace("PAGE_SIZE(%lu) != %d\\n", "PAGE_SIZE(%lu) != %lu\\n", 1)
    super_text = super_text.replace(
        "PAGE_SIZE, F2FS_BLKSIZE);",
        "PAGE_SIZE, (unsigned long)F2FS_BLKSIZE);",
        1,
    )
    super_c.write_text(super_text)
    changed = True

if "fallocate(%u * N)" in data_text:
    data_text = data_text.replace("fallocate(%u * N)", "fallocate(%lu * N)", 1)
    data_text = data_text.replace(
        "not_aligned, blks_per_sec * F2FS_BLKSIZE);",
        "not_aligned, (unsigned long)(blks_per_sec * F2FS_BLKSIZE));",
        1,
    )
    data_c.write_text(data_text)
    changed = True

if "end = min(end, NIDS_PER_BLOCK);" in node_text:
    node_text = node_text.replace(
        "end = min(end, NIDS_PER_BLOCK);",
        "end = min(end, (int)NIDS_PER_BLOCK);",
        1,
    )
    node_c.write_text(node_text)
    changed = True

print("updated" if changed else "unchanged")
PY
}

abk_storage_rollback_apply_child() {
  local child_id="$1"

  case "$child_id" in
    storage_ufs_rollback)
      abk_log "apply child: $child_id"
      abk_require_dir "$(abk_storage_rollback_common_dir)/drivers/ufs"
      abk_storage_rollback_patch "storage_ufs_rollback"
      ;;
    storage_block_rollback)
      abk_log "apply child: $child_id"
      abk_require_dir "$(abk_storage_rollback_common_dir)/block"
      abk_storage_rollback_patch "storage_block_rollback"
      ;;
    storage_f2fs_rollback)
      abk_log "apply child: $child_id"
      abk_require_dir "$(abk_storage_rollback_common_dir)/fs/f2fs"
      abk_storage_rollback_f2fs_patch
      abk_storage_rollback_fix_is_dot_dotdot_conflict
      ;;
    storage_common_fixups)
      abk_log "apply child: $child_id"
      abk_storage_rollback_apply_common_fixups
      ;;
    *)
      abk_die "unsupported ABK module-set child id: $child_id"
      ;;
  esac
}

abk_storage_rollback_suite_apply_selected() {
  local child_id="${ABK_MODULE_CHILD_ID:-}"

  if [ -n "$child_id" ]; then
    abk_storage_rollback_apply_child "$child_id"
    return 0
  fi

  abk_log "no ABK_MODULE_CHILD_ID provided; apply all storage rollback children"
  abk_storage_rollback_apply_child "storage_ufs_rollback"
  abk_storage_rollback_apply_child "storage_block_rollback"
  abk_storage_rollback_apply_child "storage_f2fs_rollback"
  abk_storage_rollback_apply_child "storage_common_fixups"
}
