#!/usr/bin/env bash

ABK_STORAGE_ROLLBACK_RESOLVED_TARGET_TAG=""
ABK_STORAGE_ROLLBACK_RESOLVED_KERNEL_BRANCH=""

abk_storage_rollback_common_dir() {
  local common_dir root_dir

  root_dir="$KERNEL_ROOT"
  common_dir="$root_dir/common"

  if [ -d "$common_dir" ]; then
    printf '%s\n' "$common_dir"
    return 0
  fi

  printf '%s\n' "$root_dir"
}

abk_storage_rollback_kernel_version_key() {
  local version patchlevel

  version="$(abk_kernel_make_value VERSION)"
  patchlevel="$(abk_kernel_make_value PATCHLEVEL)"
  printf '%s.%s\n' "$version" "$patchlevel"
}

abk_storage_rollback_kernel_branch() {
  local key

  if [ -n "$ABK_STORAGE_ROLLBACK_RESOLVED_KERNEL_BRANCH" ]; then
    printf '%s\n' "$ABK_STORAGE_ROLLBACK_RESOLVED_KERNEL_BRANCH"
    return 0
  fi

  key="$(abk_storage_rollback_kernel_version_key)"
  case "$key" in
    5.15)
      ABK_STORAGE_ROLLBACK_RESOLVED_KERNEL_BRANCH='android13-5.15'
      ;;
    6.1)
      ABK_STORAGE_ROLLBACK_RESOLVED_KERNEL_BRANCH='android14-6.1'
      ;;
    *)
      return 1
      ;;
  esac

  printf '%s\n' "$ABK_STORAGE_ROLLBACK_RESOLVED_KERNEL_BRANCH"
}

abk_storage_rollback_resolve_target_tag_from_os_patch_level_5_15() {
  case "${ABK_BUILD_OS_PATCH_LEVEL:-}" in
    2024-09) printf '%s\n' 'android13-5.15-2024-09_r8' ;;
    2024-11) printf '%s\n' 'android13-5.15-2024-11_r14' ;;
    2025-01) printf '%s\n' 'android13-5.15-2025-01_r7' ;;
    2025-03) printf '%s\n' 'android13-5.15-2025-03_r13' ;;
    2025-05) printf '%s\n' 'android13-5.15-2025-05_r15' ;;
    2025-07) printf '%s\n' 'android13-5.15-2025-07_r7' ;;
    2025-09) printf '%s\n' 'android13-5.15-2025-09_r12' ;;
    2025-12) printf '%s\n' 'android13-5.15-2025-12_r9' ;;
    2026-03) printf '%s\n' 'android13-5.15-2026-03_r12' ;;
    *) return 1 ;;
  esac
}

abk_storage_rollback_resolve_target_tag_from_os_patch_level_6_1() {
  case "${ABK_BUILD_OS_PATCH_LEVEL:-}" in
    2024-09) printf '%s\n' 'android14-6.1-2024-09_r14' ;;
    2024-10) printf '%s\n' 'android14-6.1-2024-10_r26' ;;
    2024-11) printf '%s\n' 'android14-6.1-2024-11_r14' ;;
    2024-12) printf '%s\n' 'android14-6.1-2024-12_r17' ;;
    2025-01) printf '%s\n' 'android14-6.1-2025-01_r29' ;;
    2025-02) printf '%s\n' 'android14-6.1-2025-02_r20' ;;
    2025-03) printf '%s\n' 'android14-6.1-2025-03_r15' ;;
    2025-04) printf '%s\n' 'android14-6.1-2025-04_r16' ;;
    2025-05) printf '%s\n' 'android14-6.1-2025-05_r13' ;;
    2025-06) printf '%s\n' 'android14-6.1-2025-06_r17' ;;
    2025-07) printf '%s\n' 'android14-6.1-2025-07_r12' ;;
    2025-08) printf '%s\n' 'android14-6.1-2025-08_r11' ;;
    2025-09) printf '%s\n' 'android14-6.1-2025-09_r32' ;;
    2025-12) printf '%s\n' 'android14-6.1-2025-12_r22' ;;
    2026-03) printf '%s\n' 'android14-6.1-2026-03_r15' ;;
    *) return 1 ;;
  esac
}

abk_storage_rollback_resolve_target_tag_from_os_patch_level() {
  local kernel_branch

  kernel_branch="$(abk_storage_rollback_kernel_branch)" || return 1
  case "$kernel_branch" in
    android13-5.15) abk_storage_rollback_resolve_target_tag_from_os_patch_level_5_15 ;;
    android14-6.1) abk_storage_rollback_resolve_target_tag_from_os_patch_level_6_1 ;;
    *) return 1 ;;
  esac
}

abk_storage_rollback_resolve_target_tag_from_sublevel_5_15() {
  case "$1" in
    153) printf '%s\n' 'android13-5.15-2024-09_r8' ;;
    167) printf '%s\n' 'android13-5.15-2024-11_r14' ;;
    170) printf '%s\n' 'android13-5.15-2025-01_r7' ;;
    178) printf '%s\n' 'android13-5.15-2025-03_r13' ;;
    180) printf '%s\n' 'android13-5.15-2025-05_r15' ;;
    185) printf '%s\n' 'android13-5.15-2025-07_r7' ;;
    189) printf '%s\n' 'android13-5.15-2025-09_r12' ;;
    194) printf '%s\n' 'android13-5.15-2025-12_r9' ;;
    197) printf '%s\n' 'android13-5.15-2026-03_r12' ;;
    *) return 1 ;;
  esac
}

abk_storage_rollback_resolve_target_tag_from_sublevel_6_1() {
  case "$1" in
    9[3-8]) printf '%s\n' 'android14-6.1-2024-09_r14' ;;
    99|10[0-9]|11[01]) printf '%s\n' 'android14-6.1-2024-10_r26' ;;
    11[2-4]) printf '%s\n' 'android14-6.1-2024-11_r14' ;;
    11[5-7]) printf '%s\n' 'android14-6.1-2024-12_r17' ;;
    11[89]|12[0-3]) printf '%s\n' 'android14-6.1-2025-01_r29' ;;
    12[4-7]) printf '%s\n' 'android14-6.1-2025-02_r20' ;;
    128) printf '%s\n' 'android14-6.1-2025-03_r15' ;;
    12[9]|13[0-3]) printf '%s\n' 'android14-6.1-2025-04_r16' ;;
    13[4-7]) printf '%s\n' 'android14-6.1-2025-05_r13' ;;
    13[89]|140) printf '%s\n' 'android14-6.1-2025-06_r17' ;;
    14[1-4]) printf '%s\n' 'android14-6.1-2025-07_r12' ;;
    14[5-6]) printf '%s\n' 'android14-6.1-2025-09_r32' ;;
    15[7-9]|160|161) printf '%s\n' 'android14-6.1-2025-12_r22' ;;
    162) printf '%s\n' 'android14-6.1-2026-03_r15' ;;
    *) return 1 ;;
  esac
}

abk_storage_rollback_resolve_target_tag_from_sublevel() {
  local sublevel="${1:-}"
  local kernel_branch

  kernel_branch="$(abk_storage_rollback_kernel_branch)" || return 1
  case "$kernel_branch" in
    android13-5.15) abk_storage_rollback_resolve_target_tag_from_sublevel_5_15 "$sublevel" ;;
    android14-6.1) abk_storage_rollback_resolve_target_tag_from_sublevel_6_1 "$sublevel" ;;
    *) return 1 ;;
  esac
}

abk_storage_rollback_resolve_target_tag() {
  local tag sublevel

  if [ -n "$ABK_STORAGE_ROLLBACK_RESOLVED_TARGET_TAG" ]; then
    printf '%s\n' "$ABK_STORAGE_ROLLBACK_RESOLVED_TARGET_TAG"
    return 0
  fi

  if tag="$(abk_storage_rollback_resolve_target_tag_from_os_patch_level 2>/dev/null)"; then
    ABK_STORAGE_ROLLBACK_RESOLVED_TARGET_TAG="$tag"
    printf '%s\n' "$ABK_STORAGE_ROLLBACK_RESOLVED_TARGET_TAG"
    return 0
  fi

  sublevel="${ABK_BUILD_SUB_LEVEL:-$(abk_kernel_sublevel)}"
  if tag="$(abk_storage_rollback_resolve_target_tag_from_sublevel "$sublevel" 2>/dev/null)"; then
    ABK_STORAGE_ROLLBACK_RESOLVED_TARGET_TAG="$tag"
    printf '%s\n' "$ABK_STORAGE_ROLLBACK_RESOLVED_TARGET_TAG"
    return 0
  fi

  abk_die "unsupported storage rollback target for kernel=${ABK_STORAGE_ROLLBACK_RESOLVED_KERNEL_BRANCH:-unknown}: os_patch_level=${ABK_BUILD_OS_PATCH_LEVEL:-unknown}, sublevel=${sublevel:-unknown}"
}

abk_storage_rollback_patch_file() {
  local patch_subdir="$1"
  local target_tag patch_file

  target_tag="$(abk_storage_rollback_resolve_target_tag)"
  abk_log "resolved target tag: $target_tag" >&2
  patch_file="$MODULE_DIR/patches/$patch_subdir/${target_tag}.patch"
  abk_require_file "$patch_file"
  printf '%s\n' "$patch_file"
}

abk_storage_rollback_patch_candidates() {
  local patch_subdir="$1"
  local target_tag kernel_branch patch_dir
  local -a candidates=() ordered=()
  local total index left right found

  target_tag="$(abk_storage_rollback_resolve_target_tag)"
  kernel_branch="$(abk_storage_rollback_kernel_branch)"
  patch_dir="$MODULE_DIR/patches/$patch_subdir"

  mapfile -t ordered < <(
    find "$patch_dir" -maxdepth 1 -type f -name "${kernel_branch}-*.patch" -printf '%f\n' |
      LC_ALL=C sort
  )

  total="${#ordered[@]}"
  if [ "$total" -eq 0 ]; then
    return 1
  fi

  found=-1
  for index in "${!ordered[@]}"; do
    if [ "${ordered[$index]}" = "${target_tag}.patch" ]; then
      found="$index"
      break
    fi
  done

  if [ "$found" -lt 0 ]; then
    for index in "${!ordered[@]}"; do
      if [[ "${ordered[$index]}" > "${target_tag}.patch" ]]; then
        found="$index"
        break
      fi
    done
    if [ "$found" -lt 0 ]; then
      found=$((total - 1))
    fi
  fi

  left="$found"
  right=$((found + 1))

  while [ "$left" -ge 0 ] || [ "$right" -lt "$total" ]; do
    if [ "$left" -ge 0 ]; then
      candidates+=("$patch_dir/${ordered[$left]}")
      left=$((left - 1))
    fi
    if [ "$right" -lt "$total" ]; then
      candidates+=("$patch_dir/${ordered[$right]}")
      right=$((right + 1))
    fi
  done

  printf '%s\n' "${candidates[@]}"
}

abk_storage_rollback_probe_patch_file() {
  local patch_file="$1"
  local target_dir="$2"

  (
    cd "$target_dir" || exit
    if git apply --reverse --check --allow-empty "$patch_file" >/dev/null 2>&1; then
      printf '%s\n' "reverse|$patch_file"
      exit 0
    fi

    if git apply --check --allow-empty "$patch_file" >/dev/null 2>&1; then
      printf '%s\n' "already|$patch_file"
      exit 0
    fi
  )
}

abk_storage_rollback_select_patch() {
  local patch_subdir="$1"
  local target_dir="$2"
  local target_tag patch_file result selected_file selected_name
  local exact_file=""
  local -a candidates=()

  target_tag="$(abk_storage_rollback_resolve_target_tag)"
  exact_file="$MODULE_DIR/patches/$patch_subdir/${target_tag}.patch"

  if [ -f "$exact_file" ]; then
    candidates+=("$exact_file")
  fi

  while IFS= read -r patch_file; do
    [ -n "$patch_file" ] || continue
    if [ "$patch_file" = "$exact_file" ]; then
      continue
    fi
    candidates+=("$patch_file")
  done < <(abk_storage_rollback_patch_candidates "$patch_subdir")

  for patch_file in "${candidates[@]}"; do
    result="$(abk_storage_rollback_probe_patch_file "$patch_file" "$target_dir" || true)"
    if [ -z "$result" ]; then
      continue
    fi

    selected_file="${result#*|}"
    selected_name="$(basename "$selected_file" .patch)"
    if [ "$selected_name" != "$target_tag" ]; then
      abk_warn "target patch $target_tag did not match; fallback to $selected_name"
    fi
    printf '%s\n' "$result"
    return 0
  done

  return 1
}

abk_storage_rollback_apply_selected_patch() {
  local patch_subdir="$1"
  local target_dir="$2"
  local result mode patch_file

  result="$(abk_storage_rollback_select_patch "$patch_subdir" "$target_dir")" || return 1
  mode="${result%%|*}"
  patch_file="${result#*|}"

  case "$mode" in
    reverse)
      (
        cd "$target_dir" || exit
        git apply --reverse --allow-empty "$patch_file"
      )
      abk_log "applied rollback patch: $patch_file"
      ;;
    already)
      abk_log "rollback patch already applied: $patch_file"
      ;;
    *)
      return 1
      ;;
  esac
}

abk_storage_rollback_patch() {
  local patch_subdir="$1"
  local common_dir

  common_dir="$(abk_storage_rollback_common_dir)"
  abk_require_dir "$common_dir"

  abk_storage_rollback_apply_selected_patch "$patch_subdir" "$common_dir" ||
    abk_die "rollback patch does not match current kernel tree: $(abk_storage_rollback_resolve_target_tag)"
}

abk_storage_rollback_optional_patch() {
  local patch_subdir="$1"
  local common_dir

  common_dir="$(abk_storage_rollback_common_dir)"
  abk_require_dir "$common_dir"

  abk_storage_rollback_apply_selected_patch "$patch_subdir" "$common_dir"
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
  local common_dir

  common_dir="$(abk_storage_rollback_common_dir)"
  abk_require_dir "$common_dir"

  if abk_storage_rollback_apply_selected_patch "storage_f2fs_rollback" "$common_dir"; then
    return 0
  fi

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
      local common_dir ufs_dir

      abk_log "apply child: $child_id"
      common_dir="$(abk_storage_rollback_common_dir)"
      case "$(abk_storage_rollback_kernel_branch)" in
        android13-5.15) ufs_dir="$common_dir/drivers/scsi/ufs" ;;
        android14-6.1) ufs_dir="$common_dir/drivers/ufs" ;;
        *) abk_die "unsupported kernel branch for UFS rollback" ;;
      esac
      abk_require_dir "$ufs_dir"
      if ! abk_storage_rollback_optional_patch "storage_ufs_rollback"; then
        if [ "$(abk_storage_rollback_kernel_branch)" = "android13-5.15" ]; then
          abk_log "no UFS rollback patch for $(abk_storage_rollback_resolve_target_tag); skipping"
          return 0
        fi
        abk_die "rollback patch does not match current kernel tree: $(abk_storage_rollback_resolve_target_tag)"
      fi
      ;;
    storage_block_rollback)
      abk_log "apply child: $child_id"
      abk_require_dir "$(abk_storage_rollback_common_dir)/block"
      abk_storage_rollback_patch "storage_block_rollback"
      ;;
    storage_dm_core_crypto_rollback)
      abk_log "apply child: $child_id"
      abk_require_dir "$(abk_storage_rollback_common_dir)/drivers/md"
      abk_storage_rollback_patch "storage_dm_core_crypto_rollback"
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
