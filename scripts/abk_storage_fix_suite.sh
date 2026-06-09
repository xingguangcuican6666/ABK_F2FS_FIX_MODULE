#!/usr/bin/env bash

abk_storage_fix_suite_common_dir() {
  abk_common_dir
}

abk_storage_fix_suite_apply_patch_dir() {
  local patch_subdir="$1"
  local common_dir

  common_dir="$(abk_storage_fix_suite_common_dir)"
  abk_require_dir "$common_dir"
  abk_require_dir "$MODULE_DIR/patches/$patch_subdir"
  abk_apply_patch_dir "$MODULE_DIR/patches/$patch_subdir" "$common_dir"
}

abk_storage_fix_suite_apply_child() {
  local child_id="$1"

  case "$child_id" in
    abk_f2fs_perf_fix)
      abk_log "apply child: $child_id"
      abk_require_dir "$(abk_storage_fix_suite_common_dir)/fs/f2fs"
      abk_storage_fix_suite_apply_patch_dir "abk_f2fs_perf_fix"
      ;;
    abk_f2fs_lowdepth_fix)
      abk_log "apply child: $child_id"
      abk_require_dir "$(abk_storage_fix_suite_common_dir)/fs/f2fs"
      abk_storage_fix_suite_apply_patch_dir "abk_f2fs_lowdepth_fix"
      ;;
    abk_ufs_pm_fix)
      abk_log "apply child: $child_id"
      abk_require_dir "$(abk_storage_fix_suite_common_dir)/drivers/ufs/core"
      abk_storage_fix_suite_apply_patch_dir "abk_ufs_pm_fix"
      ;;
    abk_dm_default_key_fix)
      abk_log "apply child: $child_id"
      abk_require_dir "$(abk_storage_fix_suite_common_dir)/drivers/md"
      abk_storage_fix_suite_apply_patch_dir "abk_dm_default_key_fix"
      ;;
    *)
      abk_die "unsupported ABK module-set child id: $child_id"
      ;;
  esac
}

abk_storage_fix_suite_apply_selected() {
  local child_id="${ABK_MODULE_CHILD_ID:-}"

  if [ -n "$child_id" ]; then
    abk_storage_fix_suite_apply_child "$child_id"
    return 0
  fi

  abk_log "no ABK_MODULE_CHILD_ID provided; apply all storage fix children"
  abk_storage_fix_suite_apply_child "abk_f2fs_perf_fix"
  abk_storage_fix_suite_apply_child "abk_f2fs_lowdepth_fix"
  abk_storage_fix_suite_apply_child "abk_ufs_pm_fix"
  abk_storage_fix_suite_apply_child "abk_dm_default_key_fix"
}
